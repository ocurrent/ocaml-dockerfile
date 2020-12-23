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

let cygarch = "x86_64"
let cygroot = {|C:\cygwin64|}
let cygsetup = cygroot ^ {|\setup-|} ^ cygarch ^ ".exe"
let cygcache = cygroot ^ {|\cache|}
let cygmirror = "https://mirrors.kernel.org/sourceware/cygwin/"

let run_sh fmt = ksprintf (run {|%s\bin\bash.exe --login -c "%s"|} cygroot) fmt
let run_cmd fmt = ksprintf (run "cmd /S /C %s") fmt
let run_powershell fmt = ksprintf (run {|powershell -Command "%s"|}) fmt

let install_cygsympathy_from_source () =
  let cygsympathy = "MisterDA" in
  run {|mkdir C:\cygwin64\lib\cygsympathy\|}
  @@ add ~src:["https://raw.githubusercontent.com/" ^ cygsympathy ^ "/cygsympathy/script/cygsympathy.cmd"]
       ~dst:{|C:\cygwin64\lib\cygsympathy\|} ()
  @@ add ~src:["https://raw.githubusercontent.com/" ^ cygsympathy ^ "/cygsympathy/script/cygsympathy.sh"]
    ~dst:{|C:\cygwin64\lib\cygsympathy\cygsympathy|} ()
  @@ run {|mkdir C:\cygwin64\etc\postinstall\ && mklink C:\cygwin64\etc\postinstall\zp_cygsympathy.sh C:\cygwin64\lib\cygsympathy\cygsympathy|}

let install_cygwin () =
  add ~src:["https://www.cygwin.com/setup-x86_64.exe"] ~dst:{|C:\cygwin64\|} ()
  @@ run {|C:\cygwin64\setup-x86_64.exe --quiet-mode --no-shortcuts --no-startmenu --no-desktop --only-site --root C:\cygwin64 --site %s --local-package-dir C:\cygwin64\cache|} cygmirror

let install_ocaml_for_windows ?version:(version="0.0.0.2") () =
  add ~src:["https://github.com/fdopen/opam-repository-mingw/releases/download/" ^ version ^ "/opam64.tar.xz"]
    ~dst:{|C:\TEMP\|} ()
  @@ run_sh {|cd /home && tar -xf /cygdrive/c/TEMP/opam64.tar.xz && ./opam64/install.sh --prefix=/usr && rm -rf opam64 opam64.tar.xz|}

let install_winget_cli ?version:(version="v0.2.3162-preview") () =
  add ~src:["https://github.com/microsoft/winget-cli/releases/download/" ^ version ^ "/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"]
    ~dst:{|C:\TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.zip|} ()
  @@ run_powershell {|Expand-Archive -LiteralPath C:\TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.zip -DestinationPath C:\TEMP\winget-cli\ -Force|}
  @@ run {|ren C:\TEMP\winget-cli\AppInstaller_x64.appx AppInstaller_x64.zip|}
  @@ run_powershell {|Expand-Archive -LiteralPath C:\TEMP\winget-cli\AppInstaller_x64.zip -DestinationPath C:\TEMP\winget-cli\ -Force|}
  @@ run {|mkdir "C:\Program Files\winget-cli"|}
  @@ run {|move "C:\TEMP\winget-cli\AppInstallerCLI.exe" "C:\Program Files\winget-cli\winget.exe"|}
  @@ run {|move "C:\TEMP\winget-cli\resources.pri" "C:\Program Files\winget-cli"|}
  @@ run "%s" {|for /f "tokens=1,2,*" %a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V Path ^| findstr /r "^[^H]"') do reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V Path /t REG_EXPAND_SZ /f /d "%c;C:\Program Files\winget-cli"|}

let install_vc_redist ?version:(version="16") () =
  add ~src:["https://aka.ms/vs/" ^ version ^ "/release/vc_redist.x64.exe"] ~dst:{|C:\TEMP\|} ()
  @@ run {|C:\TEMP\vc_redist.x64.exe /install /passive /norestart /log C:\TEMP\vc_redist.log|}

let install_visual_studio_compiler ?version:(version="16") () =
  (* FIXME: add Install.cmd to this repository *)
  add ~src:["https://raw.githubusercontent.com/MisterDA/Windows-OCaml-Docker/images/Install.cmd"]
    ~dst:{|C:\TEMP\|} ()
  @@ add ~src:["https://aka.ms/vscollect.exe"] ~dst:{|C:\TEMP\collect.exe|} ()
  @@ add ~src:["https://aka.ms/vs/" ^ version ^ "/release/channel"] ~dst:{|C:\TEMP\VisualStudio.chman|} ()
  @@ add ~src:["https://aka.ms/vs/" ^ version ^ "/release/vs_buildtools.exe"] ~dst:{|C:\TEMP\vs_buildtools.exe|} ()
  @@ run {|C:\TEMP\Install.cmd C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache --installPath C:\BuildTools --channelUri C:\TEMP\VisualStudio.chman --installChannelUri C:\TEMP\VisualStudio.chman --add Microsoft.NetCore.Component.SDK --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK|}

let install_msvs_tools_from_source ?version:(version="0.4.1") () =
  add ~src:["https://github.com/metastack/msvs-tools/archive/" ^ version ^ ".tar.gz"]
    ~dst:({|C:\TEMP\msvs-tools.tar.gz|}) ()
  @@ run_sh {|cd /home && tar -xf /cygdrive/c/TEMP/msvs-tools.tar.gz && cp msvs-tools-%s/msvs-detect msvs-tools-%s/msvs-promote-path /usr/bin|} version version

module Git = struct
  let init ?(name="Docker") ?(email="docker@example.com") () =
    run "git config --global user.email %S" email
    @@ run "git config --global user.name %S" name
    @@ run_sh "git config --global user.email %S" email
    @@ run_sh "git config --global user.name %S" name
end

module Cygwin = struct
  let update =
    run {|%s --quiet-mode --no-shortcuts --no-startmenu --no-desktop --only-site --root %s --site %s --local-package-dir %s --upgrade-also|} cygsetup cygroot cygmirror cygcache

  let install fmt =
    ksprintf (run {|%s --quiet-mode --no-shortcuts --no-startmenu --no-desktop --only-site --root %s --site %s --local-package-dir %s --packages %s|} cygsetup cygroot cygmirror cygcache) fmt

  let dev_packages ?extra () =
    install "make,diffutils,mingw64-i686-gcc-g++,mingw64-x86_64-gcc-g++,gcc-g++,vim,git,curl,rsync,unzip,patch,m4%s"
      (match extra with None -> ""
                      | Some x -> "," ^ (String.map (function ' ' -> ',' | c -> c) x))

  let install_system_ocaml =
    install "ocaml,flexlink"
end

module Winget = struct
  let install fmt = ksprintf (run "winget install %s") fmt
  let dev_packages ?extra () =
    let git = install "git" in
    match extra with
    | None -> git
    | Some packages ->
       List.fold_left (fun acc package -> acc @@ install "%s" package) git packages
end
