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

type t = [ 
  | `Alpine of [ `V3_3 ]
  | `CentOS of [ `V6 | `V7 ]
  | `Debian of [ `V9 | `V8 | `V7 | `Stable | `Testing | `Unstable ]
  | `Raspbian of [ `V8 | `V7 ]
  | `Fedora of [ `V21 | `V22 | `V23 ]
  | `OracleLinux of [ `V7 ]
  | `Ubuntu of [ `V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 ]
] [@@deriving sexp]

let distros = [ (`Ubuntu `V12_04); (`Ubuntu `V14_04); (`Ubuntu `V15_10); (`Ubuntu `V16_04);
                (`Debian `Stable); (`Debian `Testing); (`Debian `Unstable);
                (`Debian `V9); (`Debian `V8); (`Debian `V7);
                (`Fedora `V22); (`Fedora `V23);
                (`CentOS `V6); (`CentOS `V7);
                (`OracleLinux `V7);
                (`Alpine `V3_3) ]

let slow_distros = [
                (`Raspbian `V8); (`Raspbian `V7);
]

let latest_stable_distros = [
  (`Ubuntu `V14_04); (`Debian `Stable); (`Fedora `V23);
  (`CentOS `V7); (`OracleLinux `V7); (`Alpine `V3_3) ]

let master_distro = `Debian `Stable
let stable_ocaml_versions = [ "4.00.1"; "4.01.0"; "4.02.3"; "4.03.0"; "4.03.0+flambda" ]
let all_ocaml_versions = stable_ocaml_versions @ [ "4.03.0+trunk"; "4.03.0+trunk+flambda" ]
let latest_ocaml_version = "4.02.3"
let opam_versions = [ "1.2.2" ]
let latest_opam_version = "1.2.2"

(* The distro-supplied version of OCaml *)
let builtin_ocaml_of_distro = function
  |`Debian (`Stable |`V8) | `Raspbian `V8 -> Some "4.01.0"
  |`Debian `Testing -> Some "4.02.3"
  |`Debian (`Unstable | `V9) -> Some "4.02.3"
  |`Debian `V7 | `Raspbian `V7-> Some "3.12.1"
  |`Ubuntu `V12_04 -> Some "3.12.1"
  |`Ubuntu `V14_04 -> Some "4.01.0"
  |`Ubuntu `V15_04 -> Some "4.01.0"
  |`Ubuntu `V15_10 -> Some "4.01.0"
  |`Ubuntu `V16_04 -> Some "4.02.3"
  |`Alpine `V3_3 -> Some "4.02.3"
  |`Fedora `V21 -> Some "4.01.0"
  |`Fedora `V22 -> Some "4.02.0"
  |`Fedora `V23 -> Some "4.02.2"
  |`CentOS `V6 -> Some "3.11.2"
  |`CentOS `V7 -> Some "4.01.0"
  |`OracleLinux `V7 -> None

(* The Docker tag for this distro *)
let tag_of_distro = function
  |`Ubuntu `V12_04 -> "ubuntu-12.04"
  |`Ubuntu `V14_04 -> "ubuntu-14.04"
  |`Ubuntu `V15_04 -> "ubuntu-15.04"
  |`Ubuntu `V15_10 -> "ubuntu-15.10"
  |`Ubuntu `V16_04 -> "ubuntu-16.04"
  |`Debian `Stable -> "debian-stable"
  |`Debian `Unstable -> "debian-unstable"
  |`Debian `Testing -> "debian-testing"
  |`Debian `V9 -> "debian-9"
  |`Debian `V8 -> "debian-8"
  |`Debian `V7 -> "debian-7"
  |`Raspbian `V7 -> "raspbian-7"
  |`Raspbian `V8 -> "raspbian-8"
  |`CentOS `V6 -> "centos-6"
  |`CentOS `V7 -> "centos-7"
  |`Fedora `V21 -> "fedora-21"
  |`Fedora `V22 -> "fedora-22"
  |`Fedora `V23 -> "fedora-23"
  |`OracleLinux `V7 -> "oraclelinux-7"
  |`Alpine `V3_3 -> "alpine-3.3"

let distro_of_tag = function
  |"ubuntu-12.04" -> Some (`Ubuntu `V12_04)
  |"ubuntu-14.04" -> Some (`Ubuntu `V14_04)
  |"ubuntu-15.04" -> Some (`Ubuntu `V15_04)
  |"ubuntu-15.10" -> Some (`Ubuntu `V15_10)
  |"ubuntu-16.04" -> Some (`Ubuntu `V16_04)
  |"debian-stable" -> Some (`Debian `Stable)
  |"debian-unstable" -> Some (`Debian `Unstable)
  |"debian-testing" -> Some (`Debian `Testing)
  |"debian-9" -> Some (`Debian `V9)
  |"debian-8" -> Some (`Debian `V8)
  |"debian-7" -> Some (`Debian `V7)
  |"raspbian-8" -> Some (`Raspbian `V8)
  |"raspbian-7" -> Some (`Raspbian `V7)
  |"centos-6" -> Some (`CentOS `V6)
  |"centos-7" -> Some (`CentOS `V7)
  |"fedora-21" -> Some (`Fedora `V21)
  |"fedora-22" -> Some (`Fedora `V22)
  |"fedora-23" -> Some (`Fedora `V23)
  |"oraclelinux-7" -> Some (`OracleLinux `V7)
  |"alpine-3.3" -> Some (`Alpine `V3_3)
  |_ -> None

let human_readable_string_of_distro = function
  |`Ubuntu `V12_04 -> "Ubuntu 12.04"
  |`Ubuntu `V14_04 -> "Ubuntu 14.04"
  |`Ubuntu `V15_04 -> "Ubuntu 15.04"
  |`Ubuntu `V15_10 -> "Ubuntu 15.10"
  |`Ubuntu `V16_04 -> "Ubuntu 16.04"
  |`Debian `Stable -> "Debian Stable"
  |`Debian `Unstable -> "Debian Unstable"
  |`Debian `Testing -> "Debian Testing"
  |`Debian `V9 -> "Debian 9 (Stretch)"
  |`Debian `V8 -> "Debian 8 (Jessie)"
  |`Debian `V7 -> "Debian 7 (Wheezy)"
  |`Raspbian `V8 -> "Raspbian 8 (Jessie)"
  |`Raspbian `V7 -> "Raspbian 7 (Wheezy)"
  |`CentOS `V6 -> "CentOS 6"
  |`CentOS `V7 -> "CentOS 7"
  |`Fedora `V21 -> "Fedora 21"
  |`Fedora `V22 -> "Fedora 22"
  |`Fedora `V23 -> "Fedora 23"
  |`OracleLinux `V7 -> "OracleLinux 7"
  |`Alpine `V3_3 -> "Alpine 3.3"

let human_readable_short_string_of_distro (t:t) =
  match t with
  |`Ubuntu _ ->  "Ubuntu"
  |`Debian _ -> "Debian"
  |`Raspbian _ -> "Raspbian"
  |`CentOS _ -> "CentOS"
  |`Fedora _ -> "Fedora"
  |`OracleLinux _ -> "OracleLinux"
  |`Alpine _ -> "Alpine"

(* The alias tag for the latest stable version of this distro *)
let latest_tag_of_distro (t:t) =
  match t with
  |`Ubuntu _ ->  "ubuntu"
  |`Debian _ -> "debian"
  |`Raspbian _ -> "raspbian"
  |`CentOS _ -> "centos"
  |`Fedora _ -> "fedora"
  |`OracleLinux _ -> "oraclelinux"
  |`Alpine _ -> "alpine"

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
 
(* Apt based Dockerfile *)
let apt_opam ?pin ?opam_version ?compiler_version labels distro tag =
    let branch = opam_version in
    add_comment ?compiler_version tag @@
    header "ocaml/ocaml" tag @@
    label (("distro_style", "apt")::labels) @@
    Linux.Apt.install "aspcud" @@
    install_opam_from_source ?branch () @@
    Linux.Apt.add_user ~sudo:true "opam" @@
    Linux.Git.init () @@
    opam_init ?compiler_version () @@
    (match pin with Some x -> run_as_opam "opam pin add %s" x | None -> empty) @@
    run_as_opam "opam install -y depext travis-opam" @@
    entrypoint_exec ["opam";"config";"exec";"--"] @@
    cmd_exec ["bash"]

(* Yum RPM based Dockerfile *)
let yum_opam ?pin ?opam_version ?compiler_version labels distro tag =
    let branch = opam_version in
    add_comment ?compiler_version tag @@
    header "ocaml/ocaml" tag @@
    label (("distro_style", "yum")::labels) @@
    Linux.RPM.dev_packages ~extra:"which tar" () @@
    install_opam_from_source ~prefix:"/usr" ?branch () @@
    Dockerfile_opam.install_cloud_solver @@
    run "sed -i.bak '/LC_TIME LC_ALL LANGUAGE/aDefaults    env_keep += \"OPAMYES OPAMJOBS OPAMVERBOSE\"' /etc/sudoers" @@
    Linux.RPM.add_user ~sudo:true "opam" @@
    Linux.Git.init () @@
    opam_init ?compiler_version () @@
    (match pin with Some x -> run_as_opam "opam pin add %s" x | None -> empty) @@
    run_as_opam "opam install -y depext travis-opam" @@
    entrypoint_exec ["opam";"config";"exec";"--"] @@
    cmd_exec ["bash"]

(* Apk (alpine) Dockerfile *)
let apk_opam ?pin ?compiler_version labels tag =
    add_comment ?compiler_version tag @@
    header "ocaml/ocaml" tag @@
    label (("distro_style", "apk")::labels) @@
    Linux.Apk.install "opam rsync" @@
    Dockerfile_opam.install_cloud_solver @@
    Linux.Apk.add_user ~sudo:true "opam" @@
    Linux.Git.init () @@
    opam_init ?compiler_version () @@
    (match pin with Some x -> run_as_opam "opam pin add %s" x | None -> empty) @@
    run_as_opam "opam install -y depext travis-opam" @@
    entrypoint_exec ["opam";"config";"exec";"--"] @@
    cmd_exec ["sh"]

(* Construct a Dockerfile for a distro/ocaml combo, using the
   system OCaml if possible, or a custom OPAM switch otherwise *)
let to_dockerfile ?pin ~ocaml_version ~distro () =
  let labels = [
      "distro", (latest_tag_of_distro distro);
      "distro_long", (tag_of_distro distro);
      "arch", (match distro with |`Raspbian _ -> "armv7" |_ -> "x86_64");
      "ocaml_version", ocaml_version;
      "opam_version", latest_opam_version;
      "operatingsystem", "linux";
  ] in
  let tag = tag_of_distro distro in
  let compiler_version =
    match builtin_ocaml_of_distro distro with
    | Some v when v = ocaml_version -> None (* use builtin *)
    | None | Some _ (* when v <> ocaml_version *) -> Some ocaml_version
  in
  match distro with
  | `Ubuntu _ | `Debian _ | `Raspbian _ -> apt_opam ?pin ?compiler_version labels distro tag
  | `CentOS _ | `Fedora _ | `OracleLinux _ -> yum_opam ?pin ?compiler_version labels distro tag
  | `Alpine _ -> apk_opam ?pin ?compiler_version labels tag

(* Build up the matrix of Dockerfiles *)
let dockerfile_matrix ?pin () =
  List.map (fun opam_version ->
    List.map (fun ocaml_version ->
      List.map (fun distro ->
        distro,
        ocaml_version,
        to_dockerfile ?pin ~ocaml_version ~distro ()
      ) distros
    ) stable_ocaml_versions
  ) opam_versions |> List.flatten |> List.flatten |>
  (List.sort (fun (a,_,_) (b,_,_) -> compare a b))

let latest_dockerfile_matrix ?pin () =
  List.map (fun distro ->
    distro,
    to_dockerfile ?pin ~ocaml_version:latest_ocaml_version ~distro ()
  ) latest_stable_distros |> 
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
