(*
 * Copyright (c) 2020 Tarides - Antonin Décimo <antonin@tarides.com>
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

let install_vc_redist ?version:(version="16") () =
  add ~src:["https://aka.ms/vs/" ^ version ^ "/release/vc_redist.x64.exe"] ~dst:{|C:\TEMP\|} ()
  @@ run {|C:\TEMP\vc_redist.x64.exe /install /passive /norestart /log C:\TEMP\vc_redist.log|}

let install_visual_studio_build_tools ?version:(version="16") components =
  (* https://docs.microsoft.com/en-us/visualstudio/install/advanced-build-tools-container?view=vs-2019#install-script *)
  (* FIXME: don't download from here? *)
  add ~src:["https://raw.githubusercontent.com/MisterDA/Windows-OCaml-Docker/images/Install.cmd"]
    ~dst:{|C:\TEMP\|} ()
  @@ add ~src:["https://aka.ms/vscollect.exe"] ~dst:{|C:\TEMP\collect.exe|} ()
  @@ add ~src:["https://aka.ms/vs/" ^ version ^ "/release/channel"] ~dst:{|C:\TEMP\VisualStudio.chman|} ()
  @@ add ~src:["https://aka.ms/vs/" ^ version ^ "/release/vs_buildtools.exe"] ~dst:{|C:\TEMP\vs_buildtools.exe|} ()
  @@ run {|C:\TEMP\Install.cmd C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
        --installPath C:\BuildTools --channelUri C:\TEMP\VisualStudio.chman `
        --installChannelUri C:\TEMP\VisualStudio.chman%s|}
       (List.fold_left (fun acc component ->
            acc ^ " `\n        --add " ^ component) "" components)

let cleanup () =
  run_powershell {|Remove-Item 'C:\TEMP' -Recurse|}

module Cygwin = struct
  type cyg = {
      root : string;
      mirror : string;
    }

  let run_sh cyg fmt = ksprintf (run {|%s\bin\bash.exe --login -c "%s"|} cyg.root) fmt

  let cygsetup = {|C:\cygwin-setup-x86_64.exe|}
  let cygcache = {|C:\TEMP\cache|}

  let install_cygsympathy_from_source cyg =
    let cygsympathy = "dra27" in
    run {|mkdir %s\lib\cygsympathy\|} cyg.root
    @@ add ~src:["https://raw.githubusercontent.com/" ^ cygsympathy ^ "/cygsympathy/script/cygsympathy.cmd"]
         ~dst:(cyg.root ^ {|\lib\cygsympathy\|}) ()
    @@ add ~src:["https://raw.githubusercontent.com/" ^ cygsympathy ^ "/cygsympathy/script/cygsympathy.sh"]
         ~dst:(cyg.root ^ {|\lib\cygsympathy\cygsympathy|}) ()
    @@ run {|mkdir %s\etc\postinstall\|} cyg.root
    @@ run {|mklink %s\etc\postinstall\zp_cygsympathy.sh %s\lib\cygsympathy\cygsympathy|} cyg.root cyg.root

  let install_msvs_tools_from_source cyg ?version:(version="0.4.1") () =
    add ~src:["https://github.com/metastack/msvs-tools/archive/" ^ version ^ ".tar.gz"]
      ~dst:({|C:\TEMP\msvs-tools.tar.gz|}) ()
    @@ run_sh cyg {|cd /home && tar -xf /cygdrive/c/TEMP/msvs-tools.tar.gz && cp msvs-tools-%s/msvs-detect msvs-tools-%s/msvs-promote-path /usr/bin|} version version

  let setup cyg =
    add ~src:["https://www.cygwin.com/setup-x86_64.exe"] ~dst:{|C:\cygwin-setup-x86_64.exe|} ()
    @@ install_cygsympathy_from_source cyg
    @@ run {|%s --quiet-mode --no-shortcuts --no-startmenu --no-desktop --only-site `
        --root %s --site %s --local-package-dir %s|} cygsetup cyg.root cyg.mirror cygcache
    @@ install_msvs_tools_from_source cyg ()

  let install cyg fmt =
    ksprintf (run {|%s --quiet-mode --no-shortcuts --no-startmenu --no-desktop --only-site `
        --root %s --site %s --local-package-dir %s `
        --packages %s|}
                cygsetup cyg.root cyg.mirror cygcache) fmt

  let update cyg =
    run {|%s --quiet-mode --no-shortcuts --no-startmenu --no-desktop --only-site --root %s `
        --site %s --local-package-dir %s --upgrade-also|}
      cygsetup cyg.root cyg.mirror cygcache

  let packages cyg base extra =
    install cyg base
      (match extra with
       | None -> ""
       | Some x -> "," ^ (String.map (function ' ' -> ',' | c -> c) x))

  let cygwin_packages cyg ?extra () = packages cyg "make,diffutils,ocaml,gcc-core,flexlink%s" extra
  let mingw_packages cyg ?extra () = packages cyg "make,diffutils,mingw64-x86_64-gcc-core%s" extra
  let msvc_packages cyg ?extra () = packages cyg "make,diffutils%s" extra
  let ocaml_for_windows_packages cyg ?extra ?version:(version="0.0.0.2") () =
    packages cyg "make,diffutils,mingw64-x86_64-gcc-g++,vim,git,curl,rsync,unzip,patch,m4%s" extra
    @@ add ~src:["https://github.com/fdopen/opam-repository-mingw/releases/download/" ^ version ^ "/opam64.tar.xz"]
         ~dst:{|C:\TEMP\|} ()
    @@ run_sh cyg {|cd /home && tar -xf /cygdrive/c/TEMP/opam64.tar.xz && ./opam64/install.sh --prefix=/usr && rm -rf opam64 opam64.tar.xz|}

  module Git = struct
    let init cyg ?(name="Docker") ?(email="docker@example.com") () =
      run_sh cyg "git config --global user.email '%s'" email
      @@ run_sh cyg "git config --global user.name '%s'" name
  end
end

module Winget = struct
  let setup ?version:(version="v0.2.3162-preview") () =
    add ~src:["https://github.com/microsoft/winget-cli/releases/download/" ^ version ^ "/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"]
      ~dst:{|C:\TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.zip|} ()
    @@ run_powershell {|Expand-Archive -LiteralPath C:\TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.zip -DestinationPath C:\TEMP\winget-cli\ -Force|}
    @@ run {|ren C:\TEMP\winget-cli\AppInstaller_x64.appx AppInstaller_x64.zip|}
    @@ run_powershell {|Expand-Archive -LiteralPath C:\TEMP\winget-cli\AppInstaller_x64.zip -DestinationPath C:\TEMP\winget-cli\ -Force|}
    @@ run {|mkdir "C:\Program Files\winget-cli"|}
    @@ run {|move "C:\TEMP\winget-cli\AppInstallerCLI.exe" "C:\Program Files\winget-cli\winget.exe"|}
    @@ run {|move "C:\TEMP\winget-cli\resources.pri" "C:\Program Files\winget-cli"|}
    @@ run "%s"
         {|for /f "tokens=1,2,*" %a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V Path ^| findstr /r "^[^H]"') do `
             reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V Path /t REG_EXPAND_SZ /f /d "%c;C:\Program Files\winget-cli"|}

  let install fmt = ksprintf (run "winget install %s && echo \027[0m") fmt

  let dev_packages ?extra () =
    let git = install "git" in
    match extra with
    | None -> git
    | Some packages ->
       List.fold_left (fun acc package -> acc @@ install "%s" package) git packages

  module Git = struct
    let init ?(name="Docker") ?(email="docker@example.com") () =
      run "git config --global user.email %S" email
      @@ run "git config --global user.name %S" name
  end
end
