(*
 * Copyright (c) 2016-2017 Anil Madhavapeddy <anil@recoil.org>
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
open Astring

type t = [ 
  | `Alpine of [ `V3_3 | `V3_4 | `V3_5 | `V3_6 | `Latest ]
  | `CentOS of [ `V6 | `V7 | `Latest ]
  | `Debian of [ `V9 | `V8 | `V7 | `Stable | `Testing | `Unstable ]
  | `Fedora of [ `V21 | `V22 | `V23 | `V24 | `V25 | `V26 | `V27 | `Latest ]
  | `OracleLinux of [ `V7 | `Latest ]
  | `OpenSUSE of [ `V42_1 | `V42_2 | `V42_3 | `Latest ]
  | `Ubuntu of [ `V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 | `V16_10 | `V17_04 | `V17_10 | `LTS | `Latest ]
] [@@deriving sexp]

type status = [
  | `Deprecated
  | `Active
  | `Alias of t
] [@@deriving sexp]

type arch = [
  | `X86_64
  | `Aarch64
] [@@deriving sexp]

let distros = [
  `Alpine `V3_3; `Alpine `V3_4; `Alpine `V3_5; `Alpine `V3_6; `Alpine `Latest;
  `CentOS `V6; `CentOS `V7; `CentOS `Latest;
  `Debian `V9; `Debian `V8; `Debian `V7;
  `Debian `Stable; `Debian `Testing; `Debian `Unstable;
  `Fedora `V23; `Fedora `V24; `Fedora `V25; `Fedora `V26; `Fedora `V27; `Fedora `Latest;
  `OracleLinux `V7; `OracleLinux `Latest;
  `OpenSUSE `V42_1; `OpenSUSE `V42_2; `OpenSUSE `V42_3; `OpenSUSE `Latest;
  `Ubuntu `V12_04; `Ubuntu `V14_04; `Ubuntu `V15_04; `Ubuntu `V15_10;
  `Ubuntu `V16_04; `Ubuntu `V16_10; `Ubuntu `V17_04; `Ubuntu `V17_10;
  `Ubuntu `Latest; `Ubuntu `LTS ]
  
let distro_status (d:t) : status = match d with
  | `Alpine ( `V3_3 | `V3_4 | `V3_5) -> `Deprecated
  | `Alpine `V3_6 -> `Active
  | `Alpine `Latest -> `Alias (`Alpine `V3_6)
  | `CentOS `V7 -> `Active
  | `CentOS `V6 -> `Deprecated
  | `CentOS `Latest -> `Alias (`CentOS `V7)
  | `Debian `V7 -> `Deprecated
  | `Debian ( `V8 | `V9 ) -> `Active
  | `Debian `Stable -> `Alias (`Debian `V9)
  | `Debian `Testing -> `Active
  | `Debian `Unstable -> `Active
  | `Fedora ( `V21 | `V22 | `V23 | `V24 ) -> `Deprecated
  | `Fedora (`V25 | `V26 | `V27 ) -> `Active
  | `Fedora `Latest -> `Alias (`Fedora `V26)
  | `OracleLinux `V7 -> `Active
  | `OracleLinux `Latest -> `Alias (`OracleLinux `V7)
  | `OpenSUSE `V42_1 | `OpenSUSE `V42_2 -> `Deprecated
  | `OpenSUSE `V42_3 -> `Active
  | `OpenSUSE `Latest -> `Alias (`OpenSUSE `V42_3)
  | `Ubuntu ( `V12_04 | `V14_04 | `V16_04 | `V17_10 ) -> `Active
  | `Ubuntu ( `V15_04 | `V15_10 | `V16_10 | `V17_04 ) -> `Deprecated
  | `Ubuntu `LTS -> `Alias (`Ubuntu `V16_04)
  | `Ubuntu `Latest -> `Alias (`Ubuntu `V17_10)

let latest_distros =
  [ `Alpine `Latest; `CentOS `Latest;
    `Debian `Stable; `OracleLinux `Latest;
    `Fedora `Latest; `Ubuntu `Latest; `Ubuntu `LTS ]

let master_distro = `Debian `Stable

let resolve_alias d =
  match distro_status d with
  | `Alias x -> x
  | _ -> d

let distro_arches (d:t) : arch list =
  match resolve_alias d with
  | `Debian (`V8 | `V9) -> [ `X86_64; `Aarch64 ]
  | `Alpine `V3_6 -> [ `X86_64; `Aarch64 ]
  | `Ubuntu (`V16_04 | `V17_04 | `V17_10) -> [ `X86_64; `Aarch64 ]
  | _ -> [ `X86_64 ]

module OV = Ocaml_version

let distro_supported_on (a:arch) (d:t) =
  List.mem a (distro_arches d)

let active_distros =
  List.filter (fun d -> distro_status d = `Active) distros

let inactive_distros =
  List.filter (fun d -> distro_status d = `Deprecated) distros

(* The distro-supplied version of OCaml *)
let builtin_ocaml_of_distro (d:t) : string option =
  match resolve_alias d with
  |`Debian `V7 -> Some "3.12.1"
  |`Debian `V8 -> Some "4.01.0"
  |`Debian `V9 -> Some "4.02.3"
  |`Ubuntu `V12_04 -> Some "3.12.1"
  |`Ubuntu `V14_04 -> Some "4.01.0"
  |`Ubuntu `V15_04 -> Some "4.01.0"
  |`Ubuntu `V15_10 -> Some "4.01.0"
  |`Ubuntu `V16_04 -> Some "4.02.3"
  |`Ubuntu `V16_10 -> Some "4.02.3"
  |`Ubuntu `V17_04 -> Some "4.02.3"
  |`Ubuntu `V17_10 -> Some "4.04.0"
  |`Alpine `V3_3 -> Some "4.02.3"
  |`Alpine `V3_4 -> Some "4.02.3"
  |`Alpine `V3_5 -> Some "4.04.0"
  |`Alpine `V3_6 -> Some "4.04.1"
  |`Fedora `V21 -> Some "4.01.0"
  |`Fedora `V22 -> Some "4.02.0"
  |`Fedora `V23 -> Some "4.02.2"
  |`Fedora `V24 -> Some "4.02.3"
  |`Fedora `V25 -> Some "4.02.3"
  |`Fedora `V26 -> Some "4.04.0"
  |`Fedora `V27 -> Some "4.05.0"
  |`CentOS `V6 -> Some "3.11.2"
  |`CentOS `V7 -> Some "4.01.0"
  |`OpenSUSE `V42_1 -> Some "4.02.3"
  |`OpenSUSE `V42_2 -> Some "4.03.0"
  |`OpenSUSE `V42_3 -> Some "4.03.0"
  |`OracleLinux `V7 -> None
  |`Alpine `Latest |`CentOS `Latest |`OracleLinux `Latest
  |`OpenSUSE `Latest |`Ubuntu `LTS | `Ubuntu `Latest
  |`Debian (`Testing | `Unstable | `Stable) |`Fedora `Latest -> assert false

(* The Docker tag for this distro *)
let tag_of_distro (d:t) = match d with
  |`Ubuntu `V12_04 -> "ubuntu-12.04"
  |`Ubuntu `V14_04 -> "ubuntu-14.04"
  |`Ubuntu `V15_04 -> "ubuntu-15.04"
  |`Ubuntu `V15_10 -> "ubuntu-15.10"
  |`Ubuntu `V16_04 -> "ubuntu-16.04"
  |`Ubuntu `V16_10 -> "ubuntu-16.10"
  |`Ubuntu `V17_04 -> "ubuntu-17.04"
  |`Ubuntu `V17_10 -> "ubuntu-17.10"
  |`Ubuntu `Latest -> "ubuntu"
  |`Ubuntu `LTS -> "ubuntu-lts"
  |`Debian `Stable -> "debian-stable"
  |`Debian `Unstable -> "debian-unstable"
  |`Debian `Testing -> "debian-testing"
  |`Debian `V9 -> "debian-9"
  |`Debian `V8 -> "debian-8"
  |`Debian `V7 -> "debian-7"
  |`CentOS `V6 -> "centos-6"
  |`CentOS `V7 -> "centos-7"
  |`CentOS `Latest -> "centos"
  |`Fedora `Latest -> "fedora"
  |`Fedora `V21 -> "fedora-21"
  |`Fedora `V22 -> "fedora-22"
  |`Fedora `V23 -> "fedora-23"
  |`Fedora `V24 -> "fedora-24"
  |`Fedora `V25 -> "fedora-25"
  |`Fedora `V26 -> "fedora-26"
  |`Fedora `V27 -> "fedora-27"
  |`OracleLinux `V7 -> "oraclelinux-7"
  |`OracleLinux `Latest -> "oraclelinux"
  |`Alpine `V3_3 -> "alpine-3.3"
  |`Alpine `V3_4 -> "alpine-3.4"
  |`Alpine `V3_5 -> "alpine-3.5"
  |`Alpine `V3_6 -> "alpine-3.6"
  |`Alpine `Latest -> "alpine"
  |`OpenSUSE `V42_1 -> "opensuse-42.1"
  |`OpenSUSE `V42_2 -> "opensuse-42.2"
  |`OpenSUSE `V42_3 -> "opensuse-42.3"
  |`OpenSUSE `Latest -> "opensuse"

let distro_of_tag x : t option = match x with
  |"ubuntu-12.04" -> Some (`Ubuntu `V12_04)
  |"ubuntu-14.04" -> Some (`Ubuntu `V14_04)
  |"ubuntu-15.04" -> Some (`Ubuntu `V15_04)
  |"ubuntu-15.10" -> Some (`Ubuntu `V15_10)
  |"ubuntu-16.04" -> Some (`Ubuntu `V16_04)
  |"ubuntu-16.10" -> Some (`Ubuntu `V16_10)
  |"ubuntu-17.04" -> Some (`Ubuntu `V17_04)
  |"ubuntu-17.10" -> Some (`Ubuntu `V17_10)
  |"ubuntu" -> Some (`Ubuntu `Latest)
  |"ubuntu-lts" -> Some (`Ubuntu `LTS)
  |"debian-stable" -> Some (`Debian `Stable)
  |"debian-unstable" -> Some (`Debian `Unstable)
  |"debian-testing" -> Some (`Debian `Testing)
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
  |"fedora-26" -> Some (`Fedora `V26)
  |"fedora-27" -> Some (`Fedora `V27)
  |"fedora" -> Some (`Fedora `Latest)
  |"oraclelinux-7" -> Some (`OracleLinux `V7)
  |"oraclelinux" -> Some (`OracleLinux `Latest)
  |"alpine-3.3" -> Some (`Alpine `V3_3)
  |"alpine-3.4" -> Some (`Alpine `V3_4)
  |"alpine-3.5" -> Some (`Alpine `V3_5)
  |"alpine-3.6" -> Some (`Alpine `V3_6)
  |"alpine" -> Some (`Alpine `Latest)
  |"opensuse-42.1" -> Some (`OpenSUSE `V42_1)
  |"opensuse-42.2" -> Some (`OpenSUSE `V42_2)
  |"opensuse-42.3" -> Some (`OpenSUSE `V42_3)
  |"opensuse" -> Some (`OpenSUSE `Latest)
  |_ -> None

let rec human_readable_string_of_distro (d:t) =
  let alias () = human_readable_string_of_distro (resolve_alias d) in
  match d with
  |`Ubuntu `V12_04 -> "Ubuntu 12.04"
  |`Ubuntu `V14_04 -> "Ubuntu 14.04"
  |`Ubuntu `V15_04 -> "Ubuntu 15.04"
  |`Ubuntu `V15_10 -> "Ubuntu 15.10"
  |`Ubuntu `V16_04 -> "Ubuntu 16.04"
  |`Ubuntu `V16_10 -> "Ubuntu 16.10"
  |`Ubuntu `V17_04 -> "Ubuntu 17.04"
  |`Ubuntu `V17_10 -> "Ubuntu 17.10"
  |`Debian `Stable -> "Debian Stable"
  |`Debian `Unstable -> "Debian Unstable"
  |`Debian `Testing -> "Debian Testing"
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
  |`Fedora `V26 -> "Fedora 26"
  |`Fedora `V27 -> "Fedora 27"
  |`OracleLinux `V7 -> "OracleLinux 7"
  |`Alpine `V3_3 -> "Alpine 3.3"
  |`Alpine `V3_4 -> "Alpine 3.4"
  |`Alpine `V3_5 -> "Alpine 3.5"
  |`Alpine `V3_6 -> "Alpine 3.6"
  |`OpenSUSE `V42_1 -> "OpenSUSE 42.1"
  |`OpenSUSE `V42_2 -> "OpenSUSE 42.2"
  |`OpenSUSE `V42_3 -> "OpenSUSE 42.3"
  |`Alpine `Latest | `Ubuntu `Latest | `Ubuntu `LTS | `CentOS `Latest | `Fedora `Latest
  |`OracleLinux `Latest | `OpenSUSE `Latest -> alias ()

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

let compare a b =
  String.compare (human_readable_string_of_distro a) (human_readable_string_of_distro b)
