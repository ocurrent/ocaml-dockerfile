(*
 * Copyright (c) 2016 Anil Madhavapeddy <anil@recoil.org>
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

(** Distro selection for various OPAM combinations *)
open Dockerfile
open Dockerfile_opam
module Linux = Dockerfile_linux

type t = [ 
  | `Alpine of [ `V3_3 | `V3_4 | `V3_5 | `V3_6 | `Latest ]
  | `CentOS of [ `V6 | `V7 ]
  | `Debian of [ `V10 | `V9 | `V8 | `V7 | `Stable | `Testing | `Unstable ]
  | `Fedora of [ `V21 | `V22 | `V23 | `V24 | `V25 ]
  | `OracleLinux of [ `V7 ]
  | `OpenSUSE of [ `V42_1 | `V42_2 ]
  | `Ubuntu of [ `V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 | `V16_10 | `V17_04 ]
] [@@deriving sexp]

let distros = [ (`Ubuntu `V12_04); (`Ubuntu `V14_04); (`Ubuntu `V16_04); (`Ubuntu `V16_10); (`Ubuntu `V17_04);
                (`Debian `Stable); (`Debian `Testing); (`Debian `Unstable);
                (`Debian `V10); (`Debian `V9); (`Debian `V8); (`Debian `V7);
                (`Fedora `V22); (`Fedora `V23); (`Fedora `V24); (`Fedora `V25);
                (`CentOS `V6); (`CentOS `V7);
                (`OracleLinux `V7); (`OpenSUSE `V42_1); (`OpenSUSE `V42_2);
                (`Alpine `V3_3); (`Alpine `V3_4); (`Alpine `V3_5); (`Alpine `V3_6); (`Alpine `Latest)]

let latest_stable_distros = [
  (`Ubuntu `V16_04); (`Debian `Stable); (`Fedora `V25);
  (`CentOS `V7); (`OracleLinux `V7); (`Alpine `Latest); (`OpenSUSE `V42_2) ]

let master_distro = `Debian `Stable
let stable_ocaml_versions = [ "4.00.1"; "4.01.0"; "4.02.3"; "4.03.0"; "4.03.0+flambda"; "4.04.0"; "4.04.1"; "4.04.2"; "4.04.2+flambda"; "4.05.0"; "4.05.0+flambda" ]
let dev_ocaml_versions = [ "4.06.0"; "4.06.0+flambda" ]
let all_ocaml_versions = stable_ocaml_versions @ dev_ocaml_versions
let latest_ocaml_version = "4.04.2"
let opam_versions = [ "1.2.2" ]
let latest_opam_version = "1.2.2"

(* The distro-supplied version of OCaml *)
let builtin_ocaml_of_distro = function
  |`Debian `V7 -> Some "3.12.1"
  |`Debian `V8 -> Some "4.01.0"
  |`Debian (`V9 | `Stable) -> Some "4.02.3"
  |`Debian (`V10 | `Testing | `Unstable) -> Some "4.02.3"
  |`Ubuntu `V12_04 -> Some "3.12.1"
  |`Ubuntu `V14_04 -> Some "4.01.0"
  |`Ubuntu `V15_04 -> Some "4.01.0"
  |`Ubuntu `V15_10 -> Some "4.01.0"
  |`Ubuntu `V16_04 -> Some "4.02.3"
  |`Ubuntu `V16_10 -> Some "4.02.3"
  |`Ubuntu `V17_04 -> Some "4.02.3"
  |`Alpine `V3_3 -> Some "4.02.3"
  |`Alpine `V3_4 -> Some "4.02.3"
  |`Alpine `V3_5 -> Some "4.04.0"
  |`Alpine (`V3_6 | `Latest) -> Some "4.04.1"
  |`Fedora `V21 -> Some "4.01.0"
  |`Fedora `V22 -> Some "4.02.0"
  |`Fedora `V23 -> Some "4.02.2"
  |`Fedora `V24 -> Some "4.02.3"
  |`Fedora `V25 -> Some "4.02.3"
  |`CentOS `V6 -> Some "3.11.2"
  |`CentOS `V7 -> Some "4.01.0"
  |`OpenSUSE `V42_1 -> Some "4.02.3"
  |`OpenSUSE `V42_2 -> Some "4.03.0"
  |`OracleLinux `V7 -> None

(* The Docker tag for this distro *)
let tag_of_distro = function
  |`Ubuntu `V12_04 -> "ubuntu-12.04"
  |`Ubuntu `V14_04 -> "ubuntu-14.04"
  |`Ubuntu `V15_04 -> "ubuntu-15.04"
  |`Ubuntu `V15_10 -> "ubuntu-15.10"
  |`Ubuntu `V16_04 -> "ubuntu-16.04"
  |`Ubuntu `V16_10 -> "ubuntu-16.10"
  |`Ubuntu `V17_04 -> "ubuntu-17.04"
  |`Debian `Stable -> "debian-stable"
  |`Debian `Unstable -> "debian-unstable"
  |`Debian `Testing -> "debian-testing"
  |`Debian `V10 -> "debian-10"
  |`Debian `V9 -> "debian-9"
  |`Debian `V8 -> "debian-8"
  |`Debian `V7 -> "debian-7"
  |`CentOS `V6 -> "centos-6"
  |`CentOS `V7 -> "centos-7"
  |`Fedora `V21 -> "fedora-21"
  |`Fedora `V22 -> "fedora-22"
  |`Fedora `V23 -> "fedora-23"
  |`Fedora `V24 -> "fedora-24"
  |`Fedora `V25 -> "fedora-25"
  |`OracleLinux `V7 -> "oraclelinux-7"
  |`Alpine `V3_3 -> "alpine-3.3"
  |`Alpine `V3_4 -> "alpine-3.4"
  |`Alpine `V3_5 -> "alpine-3.5"
  |`Alpine `V3_6 -> "alpine-3.6"
  |`Alpine `Latest -> "alpine"
  |`OpenSUSE `V42_1 -> "opensuse-42.1"
  |`OpenSUSE `V42_2 -> "opensuse-42.2"

let distro_of_tag x : t option = match x with
  |"ubuntu-12.04" -> Some (`Ubuntu `V12_04)
  |"ubuntu-14.04" -> Some (`Ubuntu `V14_04)
  |"ubuntu-15.04" -> Some (`Ubuntu `V15_04)
  |"ubuntu-15.10" -> Some (`Ubuntu `V15_10)
  |"ubuntu-16.04" -> Some (`Ubuntu `V16_04)
  |"ubuntu-16.10" -> Some (`Ubuntu `V16_10)
  |"ubuntu-17.04" -> Some (`Ubuntu `V17_04)
  |"debian-stable" -> Some (`Debian `Stable)
  |"debian-unstable" -> Some (`Debian `Unstable)
  |"debian-testing" -> Some (`Debian `Testing)
  |"debian-10" -> Some (`Debian `V10)
  |"debian-9" -> Some (`Debian `V9)
  |"debian-8" -> Some (`Debian `V8)
  |"debian-7" -> Some (`Debian `V7)
  |"centos-6" -> Some (`CentOS `V6)
  |"centos-7" -> Some (`CentOS `V7)
  |"fedora-21" -> Some (`Fedora `V21)
  |"fedora-22" -> Some (`Fedora `V22)
  |"fedora-23" -> Some (`Fedora `V23)
  |"fedora-24" -> Some (`Fedora `V24)
  |"fedora-25" -> Some (`Fedora `V25)
  |"oraclelinux-7" -> Some (`OracleLinux `V7)
  |"alpine-3.3" -> Some (`Alpine `V3_3)
  |"alpine-3.4" -> Some (`Alpine `V3_4)
  |"alpine-3.5" -> Some (`Alpine `V3_5)
  |"alpine-3.6" -> Some (`Alpine `V3_6)
  |"alpine" -> Some (`Alpine `Latest)
  |"opensuse-42.1" -> Some (`OpenSUSE `V42_1)
  |"opensuse-42.2" -> Some (`OpenSUSE `V42_2)
  |_ -> None

let human_readable_string_of_distro = function
  |`Ubuntu `V12_04 -> "Ubuntu 12.04"
  |`Ubuntu `V14_04 -> "Ubuntu 14.04"
  |`Ubuntu `V15_04 -> "Ubuntu 15.04"
  |`Ubuntu `V15_10 -> "Ubuntu 15.10"
  |`Ubuntu `V16_04 -> "Ubuntu 16.04"
  |`Ubuntu `V16_10 -> "Ubuntu 16.10"
  |`Ubuntu `V17_04 -> "Ubuntu 17.04"
  |`Debian `Stable -> "Debian Stable"
  |`Debian `Unstable -> "Debian Unstable"
  |`Debian `Testing -> "Debian Testing"
  |`Debian `V10 -> "Debian 9 (Buster)"
  |`Debian `V9 -> "Debian 9 (Stretch)"
  |`Debian `V8 -> "Debian 8 (Jessie)"
  |`Debian `V7 -> "Debian 7 (Wheezy)"
  |`CentOS `V6 -> "CentOS 6"
  |`CentOS `V7 -> "CentOS 7"
  |`Fedora `V21 -> "Fedora 21"
  |`Fedora `V22 -> "Fedora 22"
  |`Fedora `V23 -> "Fedora 23"
  |`Fedora `V24 -> "Fedora 24"
  |`Fedora `V25 -> "Fedora 25"
  |`OracleLinux `V7 -> "OracleLinux 7"
  |`Alpine `V3_3 -> "Alpine 3.3"
  |`Alpine `V3_4 -> "Alpine 3.4"
  |`Alpine `V3_5 -> "Alpine 3.5"
  |`Alpine `V3_6 -> "Alpine 3.6"
  |`Alpine `Latest -> "Alpine Stable (3.6)"
  |`OpenSUSE `V42_1 -> "OpenSUSE 42.1"
  |`OpenSUSE `V42_2 -> "OpenSUSE 42.2"

let human_readable_short_string_of_distro (t:t) =
  match t with
  |`Ubuntu _ ->  "Ubuntu"
  |`Debian _ -> "Debian"
  |`CentOS _ -> "CentOS"
  |`Fedora _ -> "Fedora"
  |`OracleLinux _ -> "OracleLinux"
  |`Alpine _ -> "Alpine"
  |`OpenSUSE _ -> "OpenSUSE"

(* The alias tag for the latest stable version of this distro *)
let latest_tag_of_distro (t:t) =
  match t with
  |`Ubuntu _ ->  "ubuntu"
  |`Debian _ -> "debian"
  |`CentOS _ -> "centos"
  |`Fedora _ -> "fedora"
  |`OracleLinux _ -> "oraclelinux"
  |`Alpine _ -> "alpine"
  |`OpenSUSE _ -> "opensuse"

let opam_tag_of_distro distro ocaml_version =
  (* Docker rewrites + to _ in tags *)
  let ocaml_version = Str.(global_replace (regexp_string "+") "_" ocaml_version) in
  Printf.sprintf "%s_ocaml-%s"
    (tag_of_distro distro) ocaml_version

(* Build the OPAM distributions from the OCaml base *)
let add_comment ?compiler_version tag =
  comment "OPAM for %s with %s" tag
  (match compiler_version with
      | None -> "system OCaml compiler"
      | Some v -> "local switch of OCaml " ^ v)

let compare a b =
  String.compare (human_readable_string_of_distro a) (human_readable_string_of_distro b)

(* OPAM2 needs to run an upgrade over main opam repository *)
let opam2_test opam_version =
  match opam_version with
  |Some "master" -> opam_version, true, true
  |Some ov -> opam_version, false, false
  |None -> (Some latest_opam_version), false, false

(* Apt based Dockerfile *)
let apt_opam ?pin ?opam_version ?compiler_version labels distro tag =
    let branch, need_upgrade, install_wrappers = opam2_test opam_version in
    add_comment ?compiler_version tag @@
    header "ocaml/ocaml" tag @@
    label (("distro_style", "apt")::labels) @@
    Linux.Apt.install "aspcud" @@
    install_opam_from_source ~install_wrappers ?branch () @@
    Linux.Apt.add_user ~sudo:true "opam" @@
    Linux.Git.init () @@
    opam_init ?compiler_version ~need_upgrade () @@
    (match pin with Some x -> run_as_opam "opam pin add %s" x | None -> empty) @@
    run_as_opam "opam install -y depext travis-opam" @@
    entrypoint_exec ["opam";"config";"exec";"--"] @@
    cmd_exec ["bash"]

(* Yum RPM based Dockerfile *)
let yum_opam ?(extra=[]) ?extra_cmd ?pin ?opam_version ?compiler_version labels distro tag =
    let branch, need_upgrade, install_wrappers = opam2_test opam_version in
    add_comment ?compiler_version tag @@
    header "ocaml/ocaml" tag @@
    label (("distro_style", "yum")::labels) @@
    maybe (fun x -> x) extra_cmd @@
    (* TODO FIXME opam2dev needs openssl as a dependency but review if this is still needed by release *)
    let extra = match need_upgrade with false -> extra | true -> "openssl" :: extra in
    Linux.RPM.dev_packages ~extra:(String.concat " " ("which"::"tar"::"wget"::"xz"::extra)) () @@
    install_opam_from_source ~install_wrappers ~prefix:"/usr" ?branch () @@
    Dockerfile_opam.install_cloud_solver @@
    run "sed -i.bak '/LC_TIME LC_ALL LANGUAGE/aDefaults    env_keep += \"OPAMYES OPAMJOBS OPAMVERBOSE\"' /etc/sudoers" @@
    Linux.RPM.add_user ~sudo:true "opam" @@
    Linux.Git.init () @@
    opam_init ?compiler_version ~need_upgrade () @@
    (match pin with Some x -> run_as_opam "opam pin add %s" x | None -> empty) @@
    run_as_opam "opam install -y depext travis-opam" @@
    entrypoint_exec ["opam";"config";"exec";"--"] @@
    cmd_exec ["bash"]

(* Apk (alpine) Dockerfile *)
let apk_opam ?pin ?opam_version ?compiler_version ~os_version labels tag =
    let branch, need_upgrade, install_wrappers = opam2_test opam_version in
    add_comment ?compiler_version tag @@
    header "ocaml/ocaml" tag @@
    label (("distro_style", "apk")::labels) @@
    (match opam_version with
     |Some "1.2" -> Linux.Apk.install "rsync xz opam"
     |_ -> Linux.Apk.install "rsync xz" @@ install_opam_from_source ~install_wrappers ~prefix:"/usr" ?branch ()) @@
    (match os_version with
     |`Latest|`V3_5 |`V3_6-> Linux.Apk.install "aspcud"
     |`V3_3|`V3_4 -> Dockerfile_opam.install_cloud_solver) @@
    Linux.Apk.add_user ~sudo:true "opam" @@
    Linux.Git.init () @@
    opam_init ?compiler_version ~need_upgrade () @@
    (match pin with Some x -> run_as_opam "opam pin add %s" x | None -> empty) @@
    run_as_opam "opam install -y depext travis-opam" @@
    entrypoint_exec ["opam";"config";"exec";"--"] @@
    cmd_exec ["sh"]

(* Zypper (OpenSUSE) Dockerfile *)
let zypper_opam ?pin ?opam_version ?compiler_version labels tag =
  let branch, need_upgrade, install_wrappers = opam2_test opam_version in 
  add_comment ?compiler_version tag @@
  header "ocaml/ocaml" tag @@
  label (("distro_style", "zypper")::labels) @@
  install_opam_from_source ~prefix:"/usr" ?branch () @@
  Dockerfile_opam.install_cloud_solver @@
  Linux.Zypper.add_user ~sudo:true "opam" @@
  Linux.Git.init () @@
  opam_init ?compiler_version ~need_upgrade () @@
  (match pin with Some x -> run_as_opam "opam pin add %s" x | None -> empty) @@
  run_as_opam "opam install -y depext travis-opam" @@
  entrypoint_exec ["opam";"config";"exec";"--"] @@
  cmd_exec ["sh"]

(* Runes to upgrade Git in ancient CentOS6 to something that works with OPAM *)
let centos6_modern_git =
    run "curl -OL http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm" @@
    run "rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt" @@
    run "rpm -K rpmforge-release-0.5.2-2.el6.rf.*.rpm" @@
    run "rpm -i rpmforge-release-0.5.2-2.el6.rf.*.rpm" @@
    run "rm -f rpmforge-release-0.5.2-2.el6.rf.*.rpm" @@
    run "yum -y --disablerepo=base,updates --enablerepo=rpmforge-extras update git"

(* Construct a Dockerfile for a distro/ocaml combo, using the
   system OCaml if possible, or a custom OPAM switch otherwise *)
let to_dockerfile ?pin ?(opam_version=latest_opam_version) ~ocaml_version ~distro () =
  let labels = [
      "distro", (latest_tag_of_distro distro);
      "distro_long", (tag_of_distro distro);
      "arch", "x86_64";
      "ocaml_version", ocaml_version;
      "opam_version", opam_version;
      "operatingsystem", "linux";
  ] in
  let tag = tag_of_distro distro in
  let compiler_version =
    (* Rewrite the dev version to add a +trunk tag. *)
    let ocaml_version =
      match ocaml_version with
      |"4.06.0" -> "4.06.0+trunk"
      |"4.06.0+flambda" -> "4.06.0+trunk+flambda"
      |_ -> ocaml_version
    in
    match builtin_ocaml_of_distro distro with
    | Some v when v = ocaml_version -> None (* use builtin *)
    | None | Some _ (* when v <> ocaml_version *) -> Some ocaml_version
  in
  (* Turn a concrete OPAM version into a branch or tag.  As a special case, we grab
     OPAM 1.2.2 from the 1.2 branch since there are packaging fixes for Docker in there. *)
  let opam_version =
    match opam_version with
    | "1.2.2" -> "1.2"
    | other -> other
  in
  match distro with
  | `Ubuntu _ | `Debian _ -> apt_opam ?pin ~opam_version ?compiler_version labels distro tag
  | `CentOS `V6 -> yum_opam ?pin ~opam_version ?compiler_version ~extra:["centos-release-xen"] labels distro tag
  | `CentOS _ -> yum_opam ?pin ~opam_version ?compiler_version ~extra:["centos-release-xen"] labels distro tag
  | `Fedora _ -> yum_opam ?pin ~opam_version ?compiler_version ~extra:["redhat-rpm-config"] labels distro tag
  | `OracleLinux _ -> yum_opam ?pin ~opam_version ?compiler_version labels distro tag
  | `Alpine os_version -> apk_opam ?pin ~opam_version ?compiler_version ~os_version labels tag
  | `OpenSUSE _ -> zypper_opam ?pin ~opam_version ?compiler_version labels tag

(* Build up the matrix of Dockerfiles *)
let dockerfile_matrix ?(opam_version=latest_opam_version) ?(extra=[]) ?(extra_ocaml_versions=[]) ?pin () =
  List.map (fun ocaml_version ->
    List.map (fun distro ->
      distro,
      ocaml_version,
      to_dockerfile ?pin ~opam_version ~ocaml_version ~distro ()
    ) (distros @ extra)
  ) (stable_ocaml_versions @ extra_ocaml_versions)
  |> List.flatten |>
  (List.sort (fun (a,_,_) (b,_,_) -> compare a b))

let latest_dockerfile_matrix ?(opam_version=latest_opam_version) ?(extra=[]) ?pin () =
  List.map (fun distro ->
    distro,
    to_dockerfile ?pin ~opam_version ~ocaml_version:latest_ocaml_version ~distro ()
  ) (latest_stable_distros @ extra) |> 
  List.sort (fun (a,_) (b,_) -> compare a b)

let map_tag ?filter fn =
  List.filter
    (match filter with
      | None -> (fun _ -> true)
      | Some fn -> fn) (dockerfile_matrix ())
  |>
  List.map (fun (distro,ocaml_version,_) -> fn ~distro ~ocaml_version)

let map ?filter ?(org="ocaml/opam") fn =
  map_tag ?filter (fun ~distro ~ocaml_version ->
   let tag = opam_tag_of_distro distro ocaml_version in
   let base = from org ~tag in
   fn ~distro ~ocaml_version base)

open Printf

let run_command fmt =
  ksprintf (fun cmd ->
    eprintf "Exec: %s\n%!" cmd;
    match Sys.command cmd with
    | 0 -> ()
    | _ -> raise (Failure cmd)
  ) fmt

let write_to_file file s =
  eprintf "Open: %s\n%!" file;
  let fout = open_out file in
  output_string fout s;
  close_out fout

let write_dockerfile ~crunch file dfile =
  let dfile = if crunch then Dockerfile.crunch dfile else dfile in
  write_to_file file (string_of_t dfile)

let generate_dockerfile ?(crunch=true) output_dir d =
  printf "Generating: %s/Dockerfile\n" output_dir;
  run_command "mkdir -p %s" output_dir;
  write_dockerfile ~crunch (output_dir ^ "/Dockerfile") d

let generate_dockerfiles_in_directories ?(crunch=true) output_dir d =
  List.iter (fun (name, docker) ->
    printf "Generating: %s/%s/Dockerfile\n" output_dir name;
    run_command "mkdir -p %s/%s" output_dir name;
    write_dockerfile ~crunch (output_dir ^ "/" ^ name ^ "/Dockerfile") docker
  ) d

let generate_dockerfiles ?(crunch=true) output_dir d =
  List.iter (fun (name, docker) ->
     printf "Generating: %s/Dockerfile.%s\n" output_dir name;
     write_dockerfile ~crunch (output_dir ^ "/Dockerfile." ^ name) docker
  ) d

let generate_dockerfiles_in_git_branches ?readme ?(crunch=true) output_dir d =
  List.iter (fun (name, docker) ->
    printf "Switching to branch %s in %s\n%!" name output_dir;
    (match name with
     |"master" -> run_command "git -C \"%s\" checkout master" output_dir
     |name -> run_command "git -C \"%s\" checkout -q -B %s master" output_dir name);
    let file = output_dir ^ "/Dockerfile" in
    write_dockerfile ~crunch file docker;
    (match readme with
     | None -> ()
     | Some r ->
        write_to_file (sprintf "%s/README.md" output_dir) r;
        run_command "git -C \"%s\" add README.md" output_dir);
    run_command "git -C \"%s\" add Dockerfile" output_dir;
    run_command "git -C \"%s\" commit -q -m \"update %s Dockerfile\" -a || true" output_dir name
  ) d;
  run_command "git -C \"%s\" checkout -q master" output_dir
