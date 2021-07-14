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
let run_powershell fmt = ksprintf (run {|powershell -Command "%s"|}) fmt
let run_vc ~arch fmt =
  let arch = match arch with
    | `I386 -> "x86" | `X86_64 -> "amd64"
    | `Aarch64 | `Aarch32 | `Ppc64le -> invalid_arg "Unsupported architecture"
  in
  ksprintf (run {|cd C:\BuildTools\VC\Auxiliary\Build && vcvarsall.bat %s && %s|} arch) fmt
let run_ocaml_env args fmt = ksprintf (run {|ocaml-env exec %s -- %s|} (String.concat " " args)) fmt

let install_vc_redist ?(vs_version="16") () =
  add ~src:["https://aka.ms/vs/" ^ vs_version ^ "/release/vc_redist.x64.exe"] ~dst:{|C:\TEMP\|} ()
  @@ run {|C:\TEMP\vc_redist.x64.exe /install /passive /norestart /log C:\TEMP\vc_redist.log|}

let install_visual_studio_build_tools ?(vs_version="16") components =
  let install =
    let fmt = format_of_string
      {|C:\TEMP\Install.cmd C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
        --installPath C:\BuildTools --channelUri C:\TEMP\VisualStudio.chman `
        --installChannelUri C:\TEMP\VisualStudio.chman%s|} in
      run fmt (List.fold_left (fun acc component ->
                   acc ^ " `\n        --add " ^ component) "" components)
  in
  (* https://docs.microsoft.com/en-us/visualstudio/install/advanced-build-tools-container?view=vs-2019#install-script *)
  (* FIXME: don't download from here? *)
  add ~src:["https://raw.githubusercontent.com/MisterDA/Windows-OCaml-Docker/images/Install.cmd"]
    ~dst:{|C:\TEMP\|} ()
  @@ add ~src:["https://aka.ms/vscollect.exe"] ~dst:{|C:\TEMP\collect.exe|} ()
  @@ add ~src:["https://aka.ms/vs/" ^ vs_version ^ "/release/channel"] ~dst:{|C:\TEMP\VisualStudio.chman|} ()
  @@ add ~src:["https://aka.ms/vs/" ^ vs_version ^ "/release/vs_buildtools.exe"] ~dst:{|C:\TEMP\vs_buildtools.exe|} ()
  @@ install

let prepend_path paths =
  let paths = String.concat ";" paths in
  run {|for /f "tokens=1,2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V Path ^| findstr /r "^[^H]"') do `
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V Path /t REG_EXPAND_SZ /f /d "%s;%%c"|} paths

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

let cleanup () =
  run_powershell {|Remove-Item 'C:\TEMP' -Recurse|}

module Cygwin = struct
  type cyg = {
      root : string;
      site : string;
      args : string list;
    }

  let cygsetup = {|C:\cygwin-setup-x86_64.exe|}
  let cygcache = {|C:\TEMP\cache|}

  let default = {
      root = {|C:\cygwin64|};
      site = "http://mirrors.kernel.org/sourceware/cygwin/";
      args = ["--quiet-mode"; "--no-shortcuts"; "--no-startmenu"; "--no-desktop";
              "--only-site"; "--local-package-dir"; cygcache];
    }

  let run_sh ?(cyg=default) fmt = ksprintf (run {|%s\bin\bash.exe --login -c "%s"|} cyg.root) fmt
  let run_sh_ocaml_env ?(cyg=default) args fmt = ksprintf (run_sh ~cyg "ocaml-env exec %s -- %s" (String.concat " " args)) fmt

  let install_cygsympathy_from_source cyg =
    run {|mkdir %s\lib\cygsympathy && mkdir %s\etc\postinstall|} cyg.root cyg.root
    @@ add ~src:["https://raw.githubusercontent.com/metastack/cygsympathy/master/cygsympathy.cmd"]
         ~dst:(cyg.root ^ {|\lib\cygsympathy\|}) ()
    @@ add ~src:["https://raw.githubusercontent.com/metastack/cygsympathy/master/cygsympathy.sh"]
         ~dst:(cyg.root ^ {|\lib\cygsympathy\cygsympathy|}) ()
    (* Beware: CygSymPathy must be executed last, or it may miss files
       installed by other post-install scripts. Use a name that is
       greater than every other script in the lexicographic order. *)
    @@ run {|mklink %s\etc\postinstall\zp_zcygsympathy.sh %s\lib\cygsympathy\cygsympathy|} cyg.root cyg.root

  let install_msvs_tools_from_source ?(version="0.4.1") cyg =
    add ~src:["https://github.com/metastack/msvs-tools/archive/" ^ version ^ ".tar.gz"]
      ~dst:({|C:\TEMP\msvs-tools.tar.gz|}) ()
    @@ run_sh ~cyg {|cd /tmp && tar -xf /cygdrive/c/TEMP/msvs-tools.tar.gz && cp msvs-tools-%s/msvs-detect msvs-tools-%s/msvs-promote-path /bin|} version version

  let cygwin ?(cyg=default) fmt =
    ksprintf (run {|%s %s --root %s --site %s %s|} cygsetup (String.concat " " cyg.args) cyg.root cyg.site) fmt

  let install ?(cyg=default) fmt =
    ksprintf (cygwin ~cyg "--packages %s") fmt

  let setup ?(cyg=default) ?(winsymlinks_native=true) ?(extra=[]) () =
    (if winsymlinks_native then env [("CYGWIN", "winsymlinks:native")] else empty)
    @@ add ~src:["https://www.cygwin.com/setup-x86_64.exe"] ~dst:{|C:\cygwin-setup-x86_64.exe|} ()
    @@ install_cygsympathy_from_source cyg
    @@ cygwin ~cyg "--packages %s" (extra |> List.sort_uniq String.compare |> String.concat ",")
    @@ install_msvs_tools_from_source cyg
    @@ prepend_path (List.map ((^) cyg.root) [{|\bin|}])
    @@ run {|awk -i inplace "/(^#)|(^$)/{print;next}{$4=""noacl,""$4; print}" %s\etc\fstab|} cyg.root
    @@ workdir {|%s\home\opam|} cyg.root

  let update ?(cyg=default) () =
    run {|%s %s --root %s --site %s --upgrade-also|} cygsetup (String.concat " " cyg.args) cyg.root cyg.site

  let cygwin_packages ?(extra=[]) ?(flexdll_version="0.39-1") () =
    (* 2021-03-19: flexdll 0.39 is required, but is in Cygwin testing *)
    "make" :: "diffutils" :: "ocaml" :: "gcc-core" :: "git" :: "patch" :: "m4"
    :: "cygport" :: ("flexdll="^flexdll_version) :: extra

  (* GNU ld (found in binutils) 2.36 broke OCaml. Stay with 2.35 until
     a fix is available in OCaml. *)
  let mingw_packages ?(extra=[]) () = "mingw64-x86_64-binutils=2.35.2-1" :: "make" :: "diffutils" :: "mingw64-x86_64-gcc-core" :: extra
  let msvc_packages ?(extra=[]) () = "mingw64-x86_64-binutils=2.35.2-1" :: "make" :: "diffutils" :: extra

  let ocaml_for_windows_packages ?cyg ?(extra=[]) ?(version="0.0.0.2") () =
    let packages = "make" :: "diffutils" :: "mingw64-x86_64-gcc-g++" :: "vim" :: "git"
                   :: "curl" :: "rsync" :: "unzip" :: "patch" :: "m4" :: extra in
    let t =
      add ~src:["https://github.com/fdopen/opam-repository-mingw/releases/download/" ^ version ^ "/opam64.tar.xz"]
        ~dst:{|C:\TEMP\|} ()
      @@ run_sh ?cyg {|cd /tmp && tar -xf /cygdrive/c/TEMP/opam64.tar.xz && ./opam64/install.sh --prefix=/usr && rm -rf opam64 opam64.tar.xz|} in
    packages, t

  module Git = struct
    let init ?(cyg=default) ?(name="Docker") ?(email="docker@example.com") () =
      env ["HOME", cyg.root ^ {|\home\opam|}]
      @@ run_sh ~cyg "git config --global user.email '%s' && git config --global user.name '%s' && git config --system core.longpaths true" email name
  end
end

module Winget = struct
  let is_supported version =
    not (List.mem version [`V1507; `Ltsc2015; `V1511; `V1607; `Ltsc2016; `V1703; `V1709; `V1803])

  let winget = "winget-builder"

  let header ?win10_revision ?(version=Dockerfile_distro.win10_latest_image) () =
    let tag = Dockerfile_distro.win10_revision_to_string (version, win10_revision) in
    parser_directive (`Escape '`')
    @@ from ~alias:winget ~tag "mcr.microsoft.com/windows"
    @@ user "ContainerAdministrator"

  let footer path =
    run {|mkdir "C:\Program Files\winget-cli"|}
    @@ run {|move "C:\TEMP\winget-cli\%s\AppInstallerCLI.exe" "C:\Program Files\winget-cli\winget.exe"|} path
    @@ run {|move "C:\TEMP\winget-cli\%s\resources.pri" "C:\Program Files\winget-cli\"|} path
    |> crunch

  let build_from_source ?(arch=`X86_64) ?win10_revision ?version ?(winget_version="master") ?(vs_version="16") () =
    header ?win10_revision ?version ()
    @@ install_vc_redist ~vs_version ()
    @@ install_visual_studio_build_tools ~vs_version [
           "Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools"; (* .NET desktop build tools *)
           "Microsoft.VisualStudio.Workload.VCTools"; (* C++ build tools *)
           "Microsoft.VisualStudio.Workload.UniversalBuildTools"; (* Universal Windows Platform build tools *)
           "Microsoft.VisualStudio.Workload.MSBuildTools"; (* MSBuild Tools *)
           "Microsoft.VisualStudio.Component.VC.Tools.x86.x64"; (* VS 2019 C++ x64/x86 build tools *)
           "Microsoft.VisualStudio.Component.Windows10SDK.18362"; (* Windows 10 SDK (10.0.18362.0) *)
         ]
    @@ add ~src:["https://github.com/microsoft/winget-cli/archive/" ^ winget_version ^ ".zip"]
         ~dst:{|C:\TEMP\winget-cli.zip|} ()
    @@ run_powershell {|Expand-Archive -LiteralPath C:\TEMP\winget-cli.zip -DestinationPath C:\TEMP\ -Force|}
    @@ run {|cd C:\TEMP && rename winget-cli-%s winget-cli|} winget_version
    @@ run_vc ~arch {|cd C:\TEMP\winget-cli && msbuild -t:restore -m -p:RestorePackagesConfig=true -p:Configuration=Release src\AppInstallerCLI.sln|}
    @@ run_vc ~arch {|cd C:\TEMP\winget-cli && msbuild -p:Configuration=Release src\AppInstallerCLI.sln|}
    @@ footer {|src\x64\Release\AppInstallerCLI|}

  let install_from_release ?win10_revision ?version ?winget_version () =
    let file = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe." in
    let src =
      let src = "https://github.com/microsoft/winget-cli/releases/" in
      match winget_version with
      | None -> src ^ "latest/download/" ^ file ^ "msixbundle"
      | Some ver -> src ^ "download/" ^ ver ^ "/" ^ file ^ "msixbundle"
    in
    let dst = {|C:\TEMP\|} ^ file ^ "zip" in
    header ?win10_revision ?version ()
    @@ add ~src:[src] ~dst ()
    @@ run_powershell {|Expand-Archive -LiteralPath %s -DestinationPath C:\TEMP\winget-cli -Force|} dst
    @@ run {|ren C:\TEMP\winget-cli\AppInstaller_x64.msix AppInstaller_x64.zip|}
    @@ run_powershell {|Expand-Archive -LiteralPath C:\TEMP\winget-cli\AppInstaller_x64.zip -DestinationPath C:\TEMP\winget-cli\ -Force|}
    @@ footer ""

  let setup ?(from=winget) () =
    copy ~from ~src:[{|C:\Program Files\winget-cli|}] ~dst:{|C:\Program Files\winget-cli|} ()
    @@ prepend_path [{|C:\Program Files\winget-cli|}]
    (* The json parser in Powershell 5 doesn't support comments. *)
    @@ run_powershell {|winget settings ; `
        $path=""""${Env:LocalAppData}\Microsoft\WinGet\Settings\settings.json"""" ; `
        $json=(Get-Content -Encoding ascii $path | Select -SkipLast 1) -Join """"`n"""" ; `
        $json=($json, '    """"telemetry"""": { """"disable"""": true },', """"}"""") -Join """"`n"""" ; `
        $json | Set-Content -Encoding ascii -NoNewLine $path ; `
        winget settings|}

  let install pkgs =
    List.fold_left (fun acc pkg -> acc @@ run "winget install %s" pkg) empty pkgs

  let dev_packages ?version ?extra () =
    match version with
    (* 2021-04-01: Installing git fails with exit-code 2316632065. *)
    | Some `V1809 -> maybe install extra
    | _ -> install ["git"] @@ maybe install extra

  module Git = struct
    let init ?(name="Docker") ?(email="docker@example.com") () =
      run "git config --global user.email %S && git config --global user.name %S && git config --system core.longpaths true" email name
  end
end
