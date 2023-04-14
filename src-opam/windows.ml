(*
 * Copyright (c) 2020 - 2021 Tarides - Antonin Décimo <antonin@tarides.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

open Dockerfile
open Printf

let run_cmd fmt = ksprintf (run "cmd /S /C %s") fmt

let run_powershell ?(escape = Fun.id) fmt =
  ksprintf (fun s -> run {|powershell -Command "%s"|} (escape s)) fmt

let run_vc ~arch fmt =
  let arch =
    match arch with
    | `I386 -> "x86"
    | `X86_64 -> "amd64"
    | `Aarch64 | `Aarch32 | `Ppc64le | `S390x | `Riscv64 ->
        invalid_arg "Unsupported architecture"
  in
  ksprintf
    (run {|cd C:\BuildTools\VC\Auxiliary\Build && vcvarsall.bat %s && %s|} arch)
    fmt

let run_ocaml_env args fmt =
  ksprintf (run {|ocaml-env exec %s -- %s|} (String.concat " " args)) fmt

let cleanup t = t @@ run_powershell {|Remove-Item 'C:\TEMP' -Recurse|} |> crunch

(* VC redist is needed to run WinGet. *)
let install_vc_redist ?(vs_version = "16") () =
  add
    ~src:[ "https://aka.ms/vs/" ^ vs_version ^ "/release/vc_redist.x64.exe" ]
    ~dst:{|C:\TEMP\|} ()
  @@ run
       {|C:\TEMP\vc_redist.x64.exe /install /passive /norestart /log C:\TEMP\vc_redist.log|}
  |> cleanup

let install_visual_studio_build_tools ?(vs_version = "16") components =
  let install =
    let fmt =
      format_of_string
        {|C:\TEMP\Install.cmd C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
        --installPath C:\BuildTools --channelUri C:\TEMP\VisualStudio.chman `
        --installChannelUri C:\TEMP\VisualStudio.chman%s|}
    in
    run fmt
      (List.fold_left
         (fun acc component -> acc ^ " `\n        --add " ^ component)
         "" components)
  in
  (* https://docs.microsoft.com/en-us/visualstudio/install/advanced-build-tools-container?view=vs-2019#install-script *)
  add
    ~src:
      [
        "https://raw.githubusercontent.com/ocurrent/ocaml-dockerfile/master/src-opam/Install.cmd";
      ]
    ~dst:{|C:\TEMP\|} ()
  @@ add ~src:[ "https://aka.ms/vscollect.exe" ] ~dst:{|C:\TEMP\collect.exe|} ()
  @@ add
       ~src:[ "https://aka.ms/vs/" ^ vs_version ^ "/release/channel" ]
       ~dst:{|C:\TEMP\VisualStudio.chman|} ()
  @@ add
       ~src:[ "https://aka.ms/vs/" ^ vs_version ^ "/release/vs_buildtools.exe" ]
       ~dst:{|C:\TEMP\vs_buildtools.exe|} ()
  @@ install

let header ~alias ?win10_revision
    ?(version =
      (Distro.win10_latest_image : Distro.win10_release :> Distro.win_all)) () =
  let img, tag = Distro.win10_base_tag ?win10_revision `Windows version in
  parser_directive (`Escape '`')
  @@ from ~alias ~tag img
  @@ user "ContainerAdministrator"

let sanitize_reg_path () =
  run
    {|for /f "tokens=1,2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V Path ^| findstr /r "\\$"') do `
          for /f "delims=" %%l in ('cmd /v:on /c "set v=%%c&& echo !v:~0,-1!"') do `
            reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V Path /t REG_EXPAND_SZ /f /d "%%l"|}

let prepend_path paths =
  let paths = String.concat ";" paths in
  run
    {|for /f "tokens=1,2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V Path ^| findstr /r "^[^H]"') do `
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V Path /t REG_EXPAND_SZ /f /d "%s;%%c"|}
    paths

let remove_system_attribute ?(recurse = true) path =
  run_powershell
    {|Foreach($file in Get-ChildItem -Path '%s' %s -force) { `
        If (((Get-ItemProperty -Path $file.fullname).attributes -band [io.fileattributes]::System)) { `
            Set-ItemProperty -Path $file.fullname -Name attributes -Value ((Get-ItemProperty $file.fullname).attributes -BXOR [io.fileattributes]::System) `
        } `
     } #end Foreach|}
    path
    (if recurse then "-Recurse" else "")

let ocaml_for_windows_package_exn ~switch ~port ~arch =
  let variant =
    let bitness = if Ocaml_version.arch_is_32bit arch then "32" else "64" in
    match arch with
    | `X86_64 | `I386 ->
        (match port with `Mingw -> "mingw" | `Msvc -> "msvc") ^ bitness
    | _ -> invalid_arg "Unsupported architecture"
  in
  let _, pkgver = Ocaml_version.Opam.V2.package switch in
  ("ocaml-variants", pkgver ^ "+" ^ variant)

let git_init ~name ~email ~repos =
  String.concat " && "
    (sprintf "git config --global user.email '%s'" email
    :: sprintf "git config --global user.name '%s'" name
    :: "git config --system core.longpaths true"
    :: List.map
         (fun repo ->
           sprintf "git config --global --add safe.directory %s" repo)
         repos)

module Cygwin = struct
  type cyg = { root : string; site : string; args : string list }

  let cygcache = {|C:\TEMP\cache|}

  let default =
    {
      root = {|C:\cygwin64|};
      site = "https://mirrors.kernel.org/sourceware/cygwin/";
      args =
        [
          "--quiet-mode";
          "--no-shortcuts";
          "--no-startmenu";
          "--no-desktop";
          "--only-site";
          "--local-package-dir";
          cygcache;
        ];
    }

  let run_sh ?(cyg = default) fmt =
    ksprintf (run {|%s\bin\bash.exe --login -c "%s"|} cyg.root) fmt

  let run_sh_ocaml_env ?(cyg = default) args fmt =
    ksprintf
      (run_sh ~cyg "ocaml-env exec %s -- %s" (String.concat " " args))
      fmt

  let install_cygsympathy_from_source cyg =
    run {|mkdir %s\lib\cygsympathy && mkdir %s\etc\postinstall|} cyg.root
      cyg.root
    @@ add
         ~src:
           [
             "https://raw.githubusercontent.com/metastack/cygsympathy/master/cygsympathy.cmd";
           ]
         ~dst:(cyg.root ^ {|\lib\cygsympathy\|})
         ()
    @@ add
         ~src:
           [
             "https://raw.githubusercontent.com/metastack/cygsympathy/master/cygsympathy.sh";
           ]
         ~dst:(cyg.root ^ {|\lib\cygsympathy\cygsympathy|})
         ()
    (* Beware: CygSymPathy must be executed last, or it may miss files
       installed by other post-install scripts. Use a name that is
       greater than every other script in the lexicographic order. *)
    @@ run
         {|mklink %s\etc\postinstall\zp_zcygsympathy.sh %s\lib\cygsympathy\cygsympathy|}
         cyg.root cyg.root

  let install_msvs_tools_from_source ?(version = "0.4.1") cyg =
    add
      ~src:
        [
          "https://github.com/metastack/msvs-tools/archive/" ^ version
          ^ ".tar.gz";
        ]
      ~dst:{|C:\TEMP\msvs-tools.tar.gz|} ()
    @@ run_sh ~cyg
         {|cd /tmp && tar -xf /cygdrive/c/TEMP/msvs-tools.tar.gz && cp msvs-tools-%s/msvs-detect msvs-tools-%s/msvs-promote-path /bin && rm -rf /cygdrive/c/TEMP/msvs-tools/*|}
         version version

  let cygsetup ?(cyg = default) ?(upgrade = false) fmt =
    ksprintf
      (run
         {|%s\setup-x86_64.exe %s --root %s --site %s --symlink-type=native %s%s|}
         cyg.root
         (String.concat " " cyg.args)
         cyg.root cyg.site
         (if upgrade then " --upgrade-also" else ""))
      fmt

  let install ?(cyg = default) pkgs =
    cygsetup ~cyg "--packages %s"
      (pkgs |> List.sort_uniq String.compare |> String.concat ",")
    |> cleanup

  let update ?(cyg = default) () = cygsetup ~cyg ~upgrade:true "" |> cleanup

  let setup_env ~cyg =
    env [ ("CYGWIN", "nodosfilewarning winsymlinks:native") ]
    @@ prepend_path (List.map (( ^ ) cyg.root) [ {|\bin|} ])

  let install_from_release ?(cyg = default) ?(msvs_tools = false) ?(extra = [])
      () =
    setup_env ~cyg
    @@ add
         ~src:[ "https://www.cygwin.com/setup-x86_64.exe" ]
         ~dst:(cyg.root ^ {|\setup-x86_64.exe|})
         ()
    @@ install_cygsympathy_from_source cyg
    @@ install ~cyg extra
    @@ (if msvs_tools then install_msvs_tools_from_source cyg else empty)
    @@ run
         {|awk -i inplace "/(^#)|(^$)/{print;next}{$4=""noacl,""$4; print}" %s\etc\fstab|}
         cyg.root

  let setup ?(cyg = default) ?from () =
    (match from with
    | Some from ->
        copy ~from ~src:[ default.root ] ~dst:default.root () @@ setup_env ~cyg
        |> cleanup
    | None -> empty)
    @@ workdir {|%s\home\opam|} cyg.root

  let cygwin_packages ?(flexdll_version = "0.39-1") () =
    (* 2021-03-19: flexdll 0.39 is required, but is in Cygwin testing *)
    [
      "make";
      "diffutils";
      "ocaml";
      "gcc-core";
      "git";
      "patch";
      "m4";
      "cygport";
      "flexdll=" ^ flexdll_version;
    ]

  let mingw_packages = [ "make"; "diffutils"; "mingw64-x86_64-gcc-core" ]
  let msvc_packages = [ "make"; "diffutils" ]

  let ocaml_for_windows_packages ?cyg ?(extra = []) ?(version = "0.0.0.2") () =
    let packages =
      "make" :: "diffutils" :: "mingw64-x86_64-gcc-g++" :: "vim" :: "git"
      :: "curl" :: "rsync" :: "unzip" :: "patch" :: "m4" :: extra
    in
    let t =
      add
        ~src:
          [
            "https://github.com/fdopen/opam-repository-mingw/releases/download/"
            ^ version ^ "/opam64.tar.xz";
          ]
        ~dst:{|C:\TEMP\|} ()
      @@ run_sh ?cyg
           {|cd /tmp && tar -xf /cygdrive/c/TEMP/opam64.tar.xz && ./opam64/install.sh --prefix=/usr && rm -rf opam64 opam64.tar.xz|}
    in
    (packages, t)

  module Git = struct
    let init ?(cyg = default) ?(name = "Docker") ?(email = "docker@example.com")
        ?(repos = [ "/home/opam/opam-repository" ]) () =
      env [ ("HOME", cyg.root ^ {|\home\opam|}) ]
      @@ run_sh ~cyg "%s" (git_init ~email ~name ~repos)
  end
end

module Winget = struct
  let is_supported version =
    not
      (List.mem version
         [
           `V1507; `Ltsc2015; `V1511; `V1607; `Ltsc2016; `V1703; `V1709; `V1803;
         ])

  let footer path =
    run {|mkdir "C:\Program Files\winget-cli"|}
    @@ run
         {|move "C:\TEMP\winget-cli\%s\winget.exe" "C:\Program Files\winget-cli\"|}
         path
    @@ run
         {|move "C:\TEMP\winget-cli\%s\WindowsPackageManager.dll" "C:\Program Files\winget-cli\"|}
         path
    @@ run
         {|move "C:\TEMP\winget-cli\%s\resources.pri" "C:\Program Files\winget-cli\"|}
         path
    |> crunch

  let install_from_release ?winget_version () =
    let file = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe." in
    let src =
      let src = "https://github.com/microsoft/winget-cli/releases/" in
      match winget_version with
      | None -> src ^ "latest/download/" ^ file ^ "msixbundle"
      | Some ver -> src ^ "download/" ^ ver ^ "/" ^ file ^ "msixbundle"
    in
    let dst = {|C:\TEMP\|} ^ file ^ "zip" in
    add ~src:[ src ] ~dst ()
    @@ run_powershell
         {|Expand-Archive -LiteralPath %s -DestinationPath C:\TEMP\winget-cli -Force|}
         dst
    @@ run {|ren C:\TEMP\winget-cli\AppInstaller_x64.msix AppInstaller_x64.zip|}
    @@ run_powershell
         {|Expand-Archive -LiteralPath C:\TEMP\winget-cli\AppInstaller_x64.zip -DestinationPath C:\TEMP\winget-cli\ -Force|}
    @@ footer ""

  let setup ?from () =
    let escape s = String.(concat {|""""|} (split_on_char '"' s)) in
    (match from with
    | Some from ->
        copy ~from
          ~src:[ {|C:\Program Files\winget-cli|} ]
          ~dst:{|C:\Program Files\winget-cli|} ()
    | None -> empty)
    @@ prepend_path [ {|C:\Program Files\winget-cli|} ]
    @@ run_powershell ~escape
         {|$path=(Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState'); New-Item $path -ItemType Directory -Force; '{ "$schema": "https://aka.ms/winget-settings.schema.json", "telemetry": { "disable": "true" } }' | Out-File -encoding ASCII (Join-Path $path 'settings.json')|}

  let install pkgs =
    List.fold_left
      (fun acc pkg ->
        acc
        @@ run
             "winget install --exact --accept-source-agreements \
              --accept-package-agreements %s"
             pkg)
      empty pkgs

  let dev_packages ?version ?extra () =
    match version with
    (* 2021-04-01: Installing git fails with exit-code 2316632065. *)
    | Some `V1809 -> maybe install extra
    | _ -> install [ "Git.Git" ] @@ maybe install extra

  module Git = struct
    let init ?(name = "Docker") ?(email = "docker@example.com")
        ?(repos = [ "C:/cygwin64/home/opam/opam-repository" ]) () =
      run "%s" (git_init ~email ~name ~repos)
  end
end
