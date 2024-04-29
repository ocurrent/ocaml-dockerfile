(*
 * Copyright (c) 2015 Anil Madhavapeddy <anil@recoil.org>
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
module D = Distro
module OV = Ocaml_version

let personality ?arch distro =
  match arch with
  | None -> None
  | Some arch -> D.personality (D.os_family_of_distro distro) arch

let run_as_opam fmt = Linux.run_as_user "opam" fmt

let maybe_link_opam add_default_link prefix branch =
  if add_default_link then
    run "ln %s/bin/opam-%s %s/bin/opam" prefix branch prefix
  else empty

(* Build opam in a separate worktree from an already cloned opam *)
let install_opam_from_source ?(add_default_link = true) ?(prefix = "/usr/local")
    ?(enable_0install_solver = false) ?(with_vendored_deps = false) ~branch
    ~hash () =
  run
    "cd /tmp/opam-sources && cp -P -R -p . ../opam-build-%s && cd \
     ../opam-build-%s && git checkout %s && ln -s ../opam/src_ext/archives \
     src_ext/archives && env PATH=\"/tmp/opam/bootstrap/ocaml/bin:$PATH\" \
     ./configure --enable-cold-check%s%s && env \
     PATH=\"/tmp/opam/bootstrap/ocaml/bin:$PATH\" make lib-ext all && mkdir -p \
     %s/bin && cp /tmp/opam-build-%s/opam %s/bin/opam-%s && chmod a+x \
     %s/bin/opam-%s && rm -rf /tmp/opam-build-%s"
    branch branch hash
    (if enable_0install_solver then " --with-0install-solver" else "")
    (if with_vendored_deps then " --with-vendored-deps" else "")
    prefix branch prefix branch prefix branch branch
  @@ maybe_link_opam add_default_link prefix branch

(* Build opam in a separate worktree from an already cloned opam *)
let install_opam_from_source_windows ?cyg ?prefix
    ?(enable_0install_solver = false) ?(with_vendored_deps = false)
    ?(msvs = false) ~branch ~hash () =
  (* Although opam's readme states it can autodetec the environment
     with MSVS, it doesn't always work. It's set explicitly here. *)
  let msvs_env =
    {|eval $(msvs-detect --arch=x64) && export PATH="$MSVS_PATH:$PATH" && export LIB="$MSVS_LIB" && export INCLUDE="$MSVS_INC" && |}
  and ocaml_port = "OCAML_PORT=msvc64 " in
  Windows.Cygwin.run_sh ?cyg
    "cd /tmp/opam-sources && cp -P -R -p . ../opam-build-%s && cd \
     ../opam-build-%s && git checkout %s && git config --global --add \
     safe.directory /tmp/opam-build-%s"
    branch branch hash branch
  @@ Windows.Cygwin.run_sh ?cyg
       "cd /tmp/opam-build-%s && %smake compiler %s&& make lib-pkg" branch
       (if msvs then msvs_env else "")
       (if msvs then ocaml_port else "")
  @@ Windows.Cygwin.run_sh ?cyg
       "cd /tmp/opam-build-%s && %s./configure --enable-cold-check %s%s%s%s && \
        make && make install"
       branch
       (if msvs then msvs_env else "")
       (if msvs then "" else "--with-private-runtime")
       (if with_vendored_deps then "" else "--with-vendored_deps")
       (Option.fold prefix ~none:"" ~some:(fun prefix ->
            Printf.sprintf {| --prefix="%s"|} prefix))
       (if enable_0install_solver then " --with-0install-solver" else "")
  (* Docker doesn't allow copying executables from /usr/local/bin
     (why??), so tar the opam installation. *)
  @@ Windows.Cygwin.run_sh ?cyg
       {|cd /usr/local/bin && tar -cf /cygdrive/c/opam.tar .|}

let bubblewrap_minimum = (0, 4, 1)
let bubblewrap_latest = (0, 8, 0)

let maybe_build_bubblewrap_from_source ?(prefix = "/usr/local") distro =
  match D.bubblewrap_version distro with
  | Some release when release >= bubblewrap_minimum -> empty
  | _ ->
      let major, minor, revision = bubblewrap_latest in
      let rel = Printf.sprintf "%d.%d.%d" major minor revision in
      let file = Printf.sprintf "bubblewrap-%s.tar.xz" rel in
      let url =
        Printf.sprintf
          "https://github.com/containers/bubblewrap/releases/download/v%s/bubblewrap-%s.tar.xz"
          rel rel
      in
      run "curl -fOL %s" url @@ run "tar xf %s" file
      @@ run
           "cd bubblewrap-%s && ./configure --prefix=%s && make && sudo make \
            install"
           rel prefix
      @@ run "rm -rf %s bubblewrap-%s" file rel

let bubblewrap_and_dev_packages distro =
  let dev_packages =
    match D.package_manager distro with
    | `Apk -> Linux.Apk.dev_packages
    | `Apt -> Linux.Apt.dev_packages
    | `Yum -> Linux.RPM.dev_packages
    | `Zypper -> Linux.Zypper.dev_packages
    | `Pacman -> Linux.Pacman.dev_packages
    | `Cygwin | `Windows -> assert false
  in
  match D.bubblewrap_version distro with
  | Some version when version >= bubblewrap_minimum ->
      dev_packages ~extra:"bubblewrap" ()
  | _ ->
      copy ~from:"0" ~src:[ "/usr/local/bin/bwrap" ] ~dst:"/usr/bin/bwrap" ()
      @@ dev_packages ()

let install_bubblewrap_wrappers =
  let strip = true in
  let opamrc_sandbox =
    heredoc ~strip
      {|	wrap-build-commands: ["%%{hooks}%%/sandbox.sh" "build"]
	wrap-install-commands: ["%%{hooks}%%/sandbox.sh" "install"]
	wrap-remove-commands: ["%%{hooks}%%/sandbox.sh" "remove"]|}
  in
  let opamrc_nosandbox =
    heredoc ~strip
      {|	wrap-build-commands: []
	wrap-install-commands: []
	wrap-remove-commands: []
	required-tools: []|}
  in
  let sandbox_enable =
    heredoc ~strip
      {|	#!/bin/sh
	cp ~/.opamrc-sandbox ~/.opamrc
	echo --- opam sandboxing enabled|}
  in
  let sandbox_disable =
    heredoc ~strip
      {|	#!/bin/sh
	cp ~/.opamrc-nosandbox ~/.opamrc
	echo --- opam sandboxing disabled|}
  in
  (* Disable bubblewrap *)
  copy_heredoc ~chown:"opam" ~src:[ opamrc_nosandbox ]
    ~dst:"/home/opam/.opamrc-nosandbox" ()
  @@ copy_heredoc ~chown:"opam" ~src:[ sandbox_disable ]
       ~dst:"/home/opam/opam-sandbox-disable" ()
  @@ run "chmod a+x /home/opam/opam-sandbox-disable"
  @@ run "sudo mv /home/opam/opam-sandbox-disable /usr/bin/opam-sandbox-disable"
  (* Enable bubblewrap *)
  @@ copy_heredoc ~chown:"opam" ~src:[ opamrc_sandbox ]
       ~dst:"/home/opam/.opamrc-sandbox" ()
  @@ copy_heredoc ~chown:"opam" ~src:[ sandbox_enable ]
       ~dst:"/home/opam/opam-sandbox-enable" ()
  @@ run "chmod a+x /home/opam/opam-sandbox-enable"
  @@ run "sudo mv /home/opam/opam-sandbox-enable /usr/bin/opam-sandbox-enable"

let from ?arch ?maintainer ?img ?tag d =
  let platform =
    match arch with
    | Some `I386 -> Some "386"
    | Some `Aarch32 -> Some "arm"
    | _ -> None
  in
  let shell =
    match personality ?arch d with
    | Some pers -> shell [ pers; "/bin/bash"; "-c" ]
    | None -> empty
  in
  let maintainer =
    match maintainer with
    | Some t -> Dockerfile.maintainer "%s" t
    | None -> empty
  in
  let img, tag =
    let dimg, dtag = D.base_distro_tag ?arch d in
    let value default = function None -> default | Some str -> str in
    (value dimg img, value dtag tag)
  in
  from ?platform ~tag img @@ maintainer @@ shell

let header ?arch ?maintainer ?img ?tag d =
  let parser_directives =
    match D.os_family_of_distro d with
    | `Windows | `Cygwin -> empty
    | _ -> buildkit_syntax
  in
  parser_directives
  @@ comment "Autogenerated by OCaml-Dockerfile scripts"
  @@ from ?arch ?maintainer ?img ?tag d

type opam_hashes = {
  opam_2_0_hash : string;
  opam_2_1_hash : string;
  opam_master_hash : string;
}

type opam_branch = {
  branch : string;
  hash : string;
  enable_0install_solver : bool;
  with_vendored_deps : bool;
  public_name : string;
  aliases : string list;
}

let opam_master_branch opam_master_hash =
  {
    branch = "master";
    hash = opam_master_hash;
    enable_0install_solver = true;
    with_vendored_deps = true;
    public_name = "opam-dev";
    aliases = [ "opam-2.2" ];
    (* TODO: Remove/update when opam 2.2 is branched *)
  }

let create_opam_branches opam_hashes =
  let { opam_2_0_hash; opam_2_1_hash; opam_master_hash } = opam_hashes in
  ( opam_master_hash,
    [
      {
        branch = "2.0";
        hash = opam_2_0_hash;
        enable_0install_solver = false;
        with_vendored_deps = false;
        public_name = "opam-2.0";
        aliases = [ "opam" ];
        (* Default *)
      };
      {
        branch = "2.1";
        hash = opam_2_1_hash;
        enable_0install_solver = true;
        with_vendored_deps = false;
        public_name = "opam-2.1";
        aliases = [];
      };
      opam_master_branch opam_master_hash;
    ] )

let create_opam_branches_windows opam_hashes =
  let { opam_master_hash; _ } = opam_hashes in
  (opam_master_hash, [ opam_master_branch opam_master_hash ])

let install_opams ?prefix opam_master_hash opam_branches =
  run
    "git clone https://github.com/ocaml/opam /tmp/opam && cd /tmp/opam && cp \
     -P -R -p . ../opam-sources && git checkout %s && env MAKE='make -j' \
     shell/bootstrap-ocaml.sh && make -C src_ext cache-archives"
    opam_master_hash
  @@ List.fold_left
       (fun acc { branch; hash; enable_0install_solver; with_vendored_deps; _ } ->
         acc
         @@ install_opam_from_source ~add_default_link:false ?prefix
              ~enable_0install_solver ~with_vendored_deps ~branch ~hash ())
       empty opam_branches

let install_opams_windows ?cyg ?prefix ?msvs opam_master_hash opam_branches =
  Windows.Cygwin.Git.init ?cyg ~repos:[ "/tmp/opam-sources" ] ()
  @@ Windows.Cygwin.run_sh ?cyg
       "git clone https://github.com/ocaml/opam /tmp/opam && cd /tmp/opam && \
        cp -P -R -p . ../opam-sources && git checkout %s"
       opam_master_hash
  @@ List.fold_left
       (fun acc { branch; hash; enable_0install_solver; with_vendored_deps; _ } ->
         acc
         @@ install_opam_from_source_windows ?cyg ?prefix ?msvs
              ~enable_0install_solver ~with_vendored_deps ~branch ~hash ())
       empty opam_branches

let copy_opams ~src ~dst opam_branches =
  List.fold_left
    (fun acc { branch; public_name; aliases; _ } ->
      acc
      @@ copy ~from:"0"
           ~src:[ src ^ "/opam-" ^ branch ]
           ~dst:(dst ^ "/" ^ public_name)
           ()
      @@@ List.map
            (fun alias -> run "ln %s/%s %s/%s" dst public_name dst alias)
            aliases)
    empty opam_branches

(* FIXME: only support building opam master for now *)
let copy_opams_windows = function
  | [ { public_name; aliases; _ } ] ->
      copy ~from:"opam-builder" ~src:[ {|C:\opam.tar|} ] ~dst:{|C:\TEMP\|} ()
      @@ run
           {|C:\cygwin64\bin\tar.exe -xf /cygdrive/c/TEMP/opam.tar -C /usr/local/bin && del C:\TEMP\opam.tar|}
      @@ run
           {|mklink C:\cygwin64\bin\%s.exe C:\cygwin64\usr\local\bin\opam.exe|}
           public_name
      @@@ List.map
            (fun alias ->
              run {|mklink C:\cygwin64\bin\%s.exe C:\cygwin64\bin\%s.exe|} alias
                public_name)
            aliases
      |> crunch
  | _ -> invalid_arg "Only a single opam branch can be build on Windows."

(* Apk based Dockerfile *)
let apk_opam2 ?(labels = []) ?arch ~opam_hashes distro () =
  let opam_master_hash, opam_branches = create_opam_branches opam_hashes in
  header ?arch distro
  @@ label (("distro_style", "apk") :: labels)
  @@ Linux.Apk.install "build-base bzip2 git tar curl ca-certificates openssl"
  @@ Linux.Git.init ()
  @@ maybe_build_bubblewrap_from_source distro
  @@ install_opams opam_master_hash opam_branches
  @@ run "strip /usr/local/bin/opam*"
  @@ from ?arch distro
  @@ Linux.Apk.add_repositories
       [
         (Some "edge", "https://dl-cdn.alpinelinux.org/alpine/edge/main");
         ( Some "edgecommunity",
           "https://dl-cdn.alpinelinux.org/alpine/edge/community" );
         (Some "testing", "https://dl-cdn.alpinelinux.org/alpine/edge/testing");
       ]
  @@ bubblewrap_and_dev_packages distro
  @@ copy_opams ~src:"/usr/local/bin" ~dst:"/usr/bin" opam_branches
  @@ Linux.Apk.add_user ~uid:1000 ~gid:1000 ~sudo:true "opam"
  @@ install_bubblewrap_wrappers @@ Linux.Git.init ()

(* Debian based Dockerfile *)
let apt_opam2 ?(labels = []) ?arch distro ~opam_hashes () =
  let opam_master_hash, opam_branches = create_opam_branches opam_hashes in
  header ?arch distro
  @@ label (("distro_style", "apt") :: labels)
  @@ Linux.Apt.install "build-essential curl git libcap-dev sudo"
  @@ Linux.Git.init ()
  @@ maybe_build_bubblewrap_from_source distro
  @@ install_opams opam_master_hash opam_branches
  @@ from ?arch distro
  @@ run "ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime"
  @@ bubblewrap_and_dev_packages distro
  @@ copy_opams ~src:"/usr/local/bin" ~dst:"/usr/bin" opam_branches
  @@ run
       "echo 'debconf debconf/frontend select Noninteractive' | \
        debconf-set-selections"
  @@ Linux.Apt.add_user ~uid:1000 ~sudo:true "opam"
  @@ install_bubblewrap_wrappers @@ Linux.Git.init ()

(* RPM based Dockerfile.

   [yum_workaround] activates the overlay/yum workaround needed
   for older versions of yum as found in CentOS 7 and earlier

   [enable_powertools] enables the PowerTools repository on CentOS 8 and above.
   This is needed to get most of *-devel packages frequently used by opam packages.

   [c_devtools_libs] uses the "C Development Tools and Libraries" package group.
   If [false], defaults to the "Development Tools" package group. *)
let yum_opam2 ?(labels = []) ?arch ~yum_workaround ~enable_powertools
    ~c_devtools_libs ~opam_hashes distro () =
  let opam_master_hash, opam_branches = create_opam_branches opam_hashes in
  let workaround =
    if yum_workaround then
      run "touch /var/lib/rpm/*" @@ Linux.RPM.install "yum-plugin-ovl"
    else empty
  in
  header ?arch distro
  @@ label (("distro_style", "rpm") :: labels)
  @@ run "yum --version || dnf install -y yum"
  @@ workaround @@ Linux.RPM.update
  @@ Linux.RPM.groupinstall
       (if c_devtools_libs then {|"C Development Tools and Libraries"|}
        else {|"Development Tools"|})
  @@ Linux.RPM.install
       "git patch unzip which tar curl xz libcap-devel openssl sudo bzip2"
  @@ Linux.Git.init ()
  @@ maybe_build_bubblewrap_from_source distro
  @@ install_opams ~prefix:"/usr" opam_master_hash opam_branches
  @@ from ?arch distro
  @@ run "yum --version || dnf install -y yum"
  @@ workaround @@ Linux.RPM.update
  @@ Linux.RPM.groupinstall
       (if c_devtools_libs then {|"C Development Tools and Libraries"|}
        else {|"Development Tools"|})
  @@ bubblewrap_and_dev_packages distro
  @@ copy_opams ~src:"/usr/bin" ~dst:"/usr/bin" opam_branches
  @@ (if enable_powertools then
        run "yum config-manager --set-enabled powertools" @@ Linux.RPM.update
      else empty)
  @@ run
       "sed -i.bak '/LC_TIME LC_ALL LANGUAGE/aDefaults    env_keep += \
        \"OPAMYES OPAMJOBS OPAMVERBOSE\"' /etc/sudoers"
  @@ Linux.RPM.add_user ~uid:1000 ~sudo:true "opam"
  @@ install_bubblewrap_wrappers @@ Linux.Git.init ()

(* Zypper based Dockerfile *)
let zypper_opam2 ?(labels = []) ?arch ~opam_hashes distro () =
  let opam_master_hash, opam_branches = create_opam_branches opam_hashes in
  header ?arch distro
  @@ label (("distro_style", "zypper") :: labels)
  @@ Linux.Zypper.dev_packages ()
  @@ Linux.Git.init ()
  @@ maybe_build_bubblewrap_from_source distro
  @@ install_opams ~prefix:"/usr" opam_master_hash opam_branches
  @@ from ?arch distro
  @@ bubblewrap_and_dev_packages distro
  @@ copy_opams ~src:"/usr/bin" ~dst:"/usr/bin" opam_branches
  @@ Linux.Zypper.add_user ~uid:1000 ~sudo:true "opam"
  @@ install_bubblewrap_wrappers @@ Linux.Git.init ()

(* Pacman based Dockerfile *)
let pacman_opam2 ?(labels = []) ?arch ~opam_hashes distro () =
  let opam_master_hash, opam_branches = create_opam_branches opam_hashes in
  header ?arch distro
  @@ label (("distro_style", "pacman") :: labels)
  @@ Linux.Pacman.dev_packages ()
  @@ Linux.Git.init ()
  @@ maybe_build_bubblewrap_from_source distro
  @@ install_opams opam_master_hash opam_branches
  @@ run "strip /usr/local/bin/opam*"
  @@ from ?arch distro
  @@ bubblewrap_and_dev_packages distro
  @@ copy_opams ~src:"/usr/local/bin" ~dst:"/usr/bin" opam_branches
  @@ Linux.Pacman.add_user ~uid:1000 ~sudo:true "opam"
  @@ install_bubblewrap_wrappers @@ Linux.Git.init ()

let install_winget distro override_tag =
  ( Windows.header ~alias:"winget-builder" ~override_tag distro
    @@ Windows.Winget.install_from_release (),
    Windows.install_vc_redist ()
    @@ Windows.Winget.setup ~from:"winget-builder" ()
    @@ Windows.Winget.dev_packages ~distro () )

let aslr_state = function
  | `Windows _ -> true
  | `WindowsServer _ -> false
  | _ -> assert false

(* Native Windows with mingw-w64 and WinGet. *)
let windows_mingw_opam2 ?(labels = []) ~override_tag ~opam_hashes
    (distro : D.t) () =
  let opam_master_hash, opam_branches =
    create_opam_branches_windows opam_hashes
  in
  let winget_image, winget_setup = install_winget distro override_tag in
  let opams_image =
    let packages =
      (* dra27: we only need g++ in the "builder" image so that
         opam-putenv gets built properly and so that opam is built
         with the internal solver as well *)
      "mingw64-x86_64-gcc-g++" :: "mingw64-i686-gcc-g++"
      :: Windows.Cygwin.mingw_packages
    in
    Windows.header ~alias:"opam-builder" ~override_tag distro
    @@ Windows.sanitize_reg_path ()
    @@ Windows.Cygwin.install_cygwin ~aslr_off:(aslr_state distro)
         ~extra:packages ()
    @@ install_opams_windows opam_master_hash opam_branches
  in
  (* 2022-10-12: Docker Engine 20.10.18 on Windows fails copying
     C:\cygwin64, so we cannot build Cygwin in a separate image. *)
  let ocaml_for_windows =
    let packages, setup = Windows.Cygwin.install_ocaml_for_windows () in
    let packages = Windows.Cygwin.mingw_packages @ packages in
    Windows.Cygwin.install_cygwin ~aslr_off:(aslr_state distro) ~extra:packages
      ()
    @@ setup
  in
  parser_directive (`Escape '`')
  @@ comment "Autogenerated by OCaml-Dockerfile scripts"
  @@ winget_image @@ opams_image @@ Windows.header ~override_tag distro
  @@ label (("distro_style", "windows") :: labels)
  @@ user "ContainerAdministrator"
  @@ Windows.sanitize_reg_path ()
  @@ winget_setup @@ ocaml_for_windows
  @@ copy_opams_windows opam_branches
  @@ Windows.Cygwin.setup () @@ Windows.Cygwin.Git.init ()

(* Native Windows with MSVC and WinGet. *)
let windows_msvc_opam2 ?(labels = []) ~override_tag ~opam_hashes (distro : D.t)
    () =
  let opam_master_hash, opam_branches =
    create_opam_branches_windows opam_hashes
  in
  let winget_image, winget_setup = install_winget distro override_tag in
  let cygwin_msvc_image =
    let packages, vs_build_tools =
      ( Windows.Cygwin.msvc_packages,
        Windows.install_visual_studio_build_tools
          [
            "Microsoft.VisualStudio.Component.VC.Tools.x86.x64";
            (* Without 18362, rc.exe is missing from the Path. *)
            "Microsoft.VisualStudio.Component.Windows10SDK.18362";
          ] )
    in
    Windows.header ~alias:"cygwin-msvc" ~override_tag distro
    @@ Windows.sanitize_reg_path ()
    @@ vs_build_tools
    @@ Windows.Cygwin.install_cygwin ~msvs_tools:true
         ~aslr_off:(aslr_state distro) ~extra:packages ()
  in
  let opams_image =
    Dockerfile.from ~alias:"opam-builder" "cygwin-msvc"
    @@ install_opams_windows ~msvs:true opam_master_hash opam_branches
  in
  (* 2022-10-12: Docker Engine 20.10.18 on Windows fails copying
     C:\cygwin64, so we cannot build Cygwin in a separate image. *)
  let ocaml_for_windows =
    let packages, setup = Windows.Cygwin.install_ocaml_for_windows () in
    Windows.Cygwin.install packages @@ setup
  in
  parser_directive (`Escape '`')
  @@ comment "Autogenerated by OCaml-Dockerfile scripts"
  @@ winget_image @@ cygwin_msvc_image @@ opams_image
  @@ Dockerfile.from "cygwin-msvc"
  @@ label (("distro_style", "windows") :: labels)
  @@ user "ContainerAdministrator"
  @@ ocaml_for_windows @@ winget_setup
  @@ copy_opams_windows opam_branches
  @@ Windows.Cygwin.setup () @@ Windows.Cygwin.Git.init ()

let gen_opam2_distro ?override_tag ?(clone_opam_repo = true) ?arch ?labels
    ~opam_hashes d =
  let fn =
    match D.package_manager d with
    | `Apk -> apk_opam2 ?labels ?arch ~opam_hashes d ()
    | `Apt -> apt_opam2 ?labels ?arch ~opam_hashes d ()
    | `Yum ->
        let yum_workaround = match d with `CentOS `V7 -> true | _ -> false in
        let enable_powertools =
          match d with
          | `CentOS (`V6 | `V7) -> false
          | `CentOS _ -> true
          | _ -> false
        in
        let c_devtools_libs = match d with `Fedora _ -> true | _ -> false in
        yum_opam2 ?labels ?arch ~yum_workaround ~enable_powertools
          ~c_devtools_libs ~opam_hashes d ()
    | `Zypper -> zypper_opam2 ?labels ?arch ~opam_hashes d ()
    | `Pacman -> pacman_opam2 ?labels ?arch ~opam_hashes d ()
    | `Windows -> (
        match d with
        | `WindowsServer (`Mingw, _) | `Windows (`Mingw, _) ->
            windows_mingw_opam2 ?labels ~override_tag ~opam_hashes d ()
        | `WindowsServer (`Msvc, _) | `Windows (`Msvc, _) ->
            windows_msvc_opam2 ?labels ~override_tag ~opam_hashes d ()
        | _ -> assert false)
    | `Cygwin ->
        failwith
          "OCaml/opam Docker images with the Cygwin port are not supported."
  in
  let clone =
    if clone_opam_repo then
      let url = Distro.(os_family_of_distro d |> opam_repository) in
      run "git clone %S /home/opam/opam-repository" url
    else empty
  in
  let pers =
    match personality ?arch d with
    | None -> empty
    | Some pers -> entrypoint_exec [ pers ]
  in
  (D.tag_of_distro d, fn @@ clone @@ pers)

let ocaml_depexts distro v =
  let open Linux in
  let as_root install = function
    | Some depexts -> user "root" @@ install depexts @@ user "opam"
    | None -> empty
  in
  match D.package_manager distro with
  | `Apk -> as_root (Apk.install "%s") (Apk.ocaml_depexts v)
  | `Apt -> as_root (Apt.install "%s") (Apt.ocaml_depexts v)
  | `Yum -> as_root (RPM.install "%s") (RPM.ocaml_depexts v)
  | `Zypper -> as_root (Zypper.install "%s") (Zypper.ocaml_depexts v)
  | `Pacman -> as_root (Pacman.install "%s") (Pacman.ocaml_depexts v)
  | `Windows -> empty
  | `Cygwin -> empty

let create_switch ~arch distro t =
  let create_switch switch pkg =
    run "opam switch create %s %s" (OV.to_string switch) pkg
  in
  let switch = OV.with_patch t None in
  match distro with
  | `Windows (port, _) ->
      let pn, pv = Windows.ocaml_for_windows_package_exn ~port ~arch ~switch in
      create_switch switch (pv ^ pn)
  | _ -> create_switch switch (Ocaml_version.Opam.V2.name switch)

let all_ocaml_compilers hub_id arch distro =
  let distro_tag = D.tag_of_distro distro in
  let os_family = Distro.os_family_of_distro distro in
  let compilers =
    OV.Releases.recent
    |> List.filter (fun ov -> D.distro_supported_on arch ov distro)
    |> fun ovs ->
    let add_beta_remote =
      if List.exists OV.Releases.is_dev ovs then
        run
          "git clone https://github.com/ocaml/ocaml-beta-repository \
           /home/opam/ocaml-beta-repository"
        @@ run
             "opam repo add beta file:///home/opam/opam-beta-repository \
              --set-default"
      else empty
    in
    add_beta_remote @@@ List.map (create_switch ~arch distro) ovs
  in
  let d =
    let pers =
      match personality ~arch distro with None -> [] | Some pers -> [ pers ]
    in
    let sandbox =
      match os_family with
      | `Linux -> run "opam-sandbox-disable"
      | `Windows | `Cygwin -> empty
    in
    header ~arch ~tag:(Printf.sprintf "%s-opam" distro_tag) ~img:hub_id distro
    @@ workdir "/home/opam/opam-repository"
    @@ run "git pull origin master"
    @@ sandbox
    @@ run "opam init -k git -a /home/opam/opam-repository --bare%s"
         (if os_family = `Windows then " --disable-sandboxing" else "")
    @@ compilers
    @@ run "opam switch %s" OV.(to_string (with_patch OV.Releases.latest None))
    @@ entrypoint_exec (pers @ [ "opam"; "config"; "exec"; "--" ])
    @@ run "opam install -y depext%s"
         (if os_family = `Windows then " depext-cygwinports" else "")
    @@ env [ ("OPAMYES", "1") ]
    @@
    match os_family with
    | `Linux | `Cygwin -> cmd "bash"
    | `Windows -> cmd_exec [ "cmd.exe" ]
  in
  (distro_tag, d)

let tag_of_ocaml_version ov =
  Ocaml_version.with_patch ov None
  |> Ocaml_version.to_string
  |> String.map (function '+' -> '-' | x -> x)

let separate_ocaml_compilers hub_id arch distro =
  let distro_tag = D.tag_of_distro distro in
  let os_family = Distro.os_family_of_distro distro in
  OV.Releases.recent_with_dev
  |> List.filter (fun ov -> D.distro_supported_on arch ov distro)
  |> List.map (fun ov ->
         let add_remote =
           if OV.Releases.is_dev ov then
             run
               "opam repo add beta \
                git+https://github.com/ocaml/ocaml-beta-repository \
                --set-default"
           else empty
         in
         let default_switch_name =
           OV.(with_patch (with_variant ov None) None |> to_string)
         in
         let variants =
           empty
           @@@ List.map
                 (create_switch ~arch distro)
                 (OV.Opam.V2.switches arch ov)
         in
         let d =
           let pers =
             match personality ~arch distro with
             | None -> []
             | Some pers -> [ pers ]
           in
           let sandbox =
             match os_family with
             | `Linux -> run "opam-sandbox-disable"
             | `Windows | `Cygwin -> empty
           in
           header ~arch
             ~tag:(Printf.sprintf "%s-opam" distro_tag)
             ~img:hub_id distro
           @@ workdir "/home/opam/opam-repository"
           @@ sandbox
           @@ run "opam init -k git -a /home/opam/opam-repository --bare%s"
                (if os_family = `Windows then "--disable-sandboxing" else "")
           @@ add_remote @@ variants
           @@ run "opam switch %s" default_switch_name
           @@ run "opam install -y depext%s"
                (if os_family = `Windows then "depext-cygwinports" else "")
           @@ env [ ("OPAMYES", "1") ]
           @@ entrypoint_exec (pers @ [ "opam"; "config"; "exec"; "--" ])
           @@
           match os_family with
           | `Linux | `Cygwin -> cmd "bash"
           | `Windows -> cmd_exec [ "cmd.exe" ]
         in
         (Printf.sprintf "%s-ocaml-%s" distro_tag (tag_of_ocaml_version ov), d))

let deprecated =
  header (`Alpine `Latest)
  @@ run
       "echo 'This container is now deprecated and no longer supported. Please \
        see https://github.com/ocaml/infrastructure/wiki/Containers for the \
        latest supported tags.  Try to use the longer term supported aliases \
        instead of specific distribution versions if you want to avoid seeing \
        this message in the future.' && exit 1"

let multiarch_manifest ~target ~platforms =
  let ms =
    List.map
      (fun (image, arch) ->
        Printf.sprintf
          "  -\n\
          \    image: %s\n\
          \    platform:\n\
          \      architecture: %s\n\
          \      os: linux" image arch)
      platforms
    |> String.concat "\n"
  in
  Printf.sprintf "image: %s\nmanifests:\n%s" target ms

(* Clone and build opam from source (legacy function) *)
let install_opam_from_source ?(add_default_link = true) ?(prefix = "/usr/local")
    ?(enable_0install_solver = false) ?(with_vendored_deps = false) ~branch
    ~hash () =
  let configure_args =
    let args =
      if enable_0install_solver then "--with-0install-solver" else ""
    in
    let args =
      args ^ if with_vendored_deps then "--with-vendored-deps" else ""
    in
    if args <> "" then " CONFIGURE_ARGS=" ^ args else ""
  in
  run
    "git clone https://github.com/ocaml/opam /tmp/opam && cd /tmp/opam && git \
     checkout %s"
    hash
  @@ Linux.run_sh
       "cd /tmp/opam && make%s cold && mkdir -p %s/bin && cp /tmp/opam/opam \
        %s/bin/opam-%s && chmod a+x %s/bin/opam-%s && rm -rf /tmp/opam"
       configure_args prefix prefix branch prefix branch
  @@ maybe_link_opam add_default_link prefix branch
