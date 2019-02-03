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
  | `Alpine of [ `V3_3 | `V3_4 | `V3_5 | `V3_6 | `V3_7 | `V3_8 | `V3_9 | `Latest ]
  | `CentOS of [ `V6 | `V7 | `Latest ]
  | `Debian of [ `V9 | `V8 | `V7 | `Stable | `Testing | `Unstable ]
  | `Fedora of [ `V21 | `V22 | `V23 | `V24 | `V25 | `V26 | `V27 | `V28 | `V29 | `Latest ]
  | `OracleLinux of [ `V7 | `Latest ]
  | `OpenSUSE of [ `V42_1 | `V42_2 | `V42_3 | `V15_0 | `Latest ]
  | `Ubuntu of [ `V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 | `V16_10 | `V17_04 | `V17_10 | `V18_04 | `V18_10 | `LTS | `Latest ]
] [@@deriving sexp]

type status = [
  | `Deprecated
  | `Active of [ `Tier1 | `Tier2 ]
  | `Alias of t
] [@@deriving sexp]

let distros = [
  `Alpine `V3_3; `Alpine `V3_4; `Alpine `V3_5; `Alpine `V3_6; `Alpine `V3_7; `Alpine `V3_8; `Alpine `V3_9; `Alpine `Latest;
  `CentOS `V6; `CentOS `V7; `CentOS `Latest;
  `Debian `V9; `Debian `V8; `Debian `V7;
  `Debian `Stable; `Debian `Testing; `Debian `Unstable;
  `Fedora `V23; `Fedora `V24; `Fedora `V25; `Fedora `V26; `Fedora `V27; `Fedora `V28; `Fedora `V29; `Fedora `Latest;
  `OracleLinux `V7; `OracleLinux `Latest;
  `OpenSUSE `V42_1; `OpenSUSE `V42_2; `OpenSUSE `V42_3; `OpenSUSE `V15_0; `OpenSUSE `Latest;
  `Ubuntu `V12_04; `Ubuntu `V14_04; `Ubuntu `V15_04; `Ubuntu `V15_10;
  `Ubuntu `V16_04; `Ubuntu `V16_10; `Ubuntu `V17_04; `Ubuntu `V17_10; `Ubuntu `V18_04; `Ubuntu `V18_10;
  `Ubuntu `Latest; `Ubuntu `LTS ]
  
let distro_status (d:t) : status = match d with
  | `Alpine ( `V3_3 | `V3_4 | `V3_5 | `V3_6 | `V3_7) -> `Deprecated
  | `Alpine `V3_8 -> `Active `Tier2
  | `Alpine `V3_9 -> `Active `Tier1
  | `Alpine `Latest -> `Alias (`Alpine `V3_9)
  | `CentOS `V7 -> `Active `Tier2
  | `CentOS `V6 -> `Deprecated
  | `CentOS `Latest -> `Alias (`CentOS `V7)
  | `Debian `V7 -> `Deprecated
  | `Debian `V8  -> `Active `Tier2
  | `Debian `V9 -> `Active `Tier1
  | `Debian `Stable -> `Alias (`Debian `V9)
  | `Debian `Testing -> `Active `Tier2
  | `Debian `Unstable -> `Active `Tier2
  | `Fedora ( `V21 | `V22 | `V23 | `V24 | `V25 | `V26) -> `Deprecated
  | `Fedora (`V27|`V28|`V29) -> `Active `Tier2
  | `Fedora `Latest -> `Alias (`Fedora `V29)
  | `OracleLinux `V7 -> `Active `Tier2
  | `OracleLinux `Latest -> `Alias (`OracleLinux `V7)
  | `OpenSUSE `V42_1 | `OpenSUSE `V42_2 -> `Deprecated
  | `OpenSUSE (`V42_3|`V15_0) -> `Active `Tier2
  | `OpenSUSE `Latest -> `Alias (`OpenSUSE `V15_0)
  | `Ubuntu (`V14_04 |`V16_04 | `V18_04 | `V18_10 ) -> `Active `Tier2
  | `Ubuntu ( `V12_04 | `V15_04 | `V15_10 | `V16_10 | `V17_04 | `V17_10) -> `Deprecated
  | `Ubuntu `LTS -> `Alias (`Ubuntu `V18_04)
  | `Ubuntu `Latest -> `Alias (`Ubuntu `V18_10)

let latest_distros =
  [ `Alpine `Latest; `CentOS `Latest;
    `Debian `Stable; `OracleLinux `Latest; `OpenSUSE `Latest;
    `Fedora `Latest; `Ubuntu `Latest; `Ubuntu `LTS ]

let master_distro = `Debian `Stable

let resolve_alias d =
  match distro_status d with
  | `Alias x -> x
  | _ -> d

module OV = Ocaml_version

let distro_arches ov (d:t) =
  match resolve_alias d, ov with
  | `Debian `V9, ov when OV.(compare Releases.v4_05_0 ov) = -1 -> [ `X86_64; `Aarch64; `Ppc64le; `Aarch32 ]
  | `Alpine (`V3_6 | `V3_7 | `V3_8), ov when OV.(compare Releases.v4_05_0 ov) = -1 -> [ `X86_64; `Aarch64 ]
  | `Ubuntu (`V16_04|`V18_04|`V17_10|`V18_10), ov when OV.(compare Releases.v4_05_0 ov) = -1  -> [ `X86_64; `Aarch64 ]
  | _ -> [ `X86_64 ]


let distro_supported_on a ov (d:t) =
  List.mem a (distro_arches ov d)

let active_distros arch =
  List.filter (fun d -> match distro_status d with `Active _ -> true | _ -> false ) distros |>
  List.filter (distro_supported_on arch OV.Releases.latest)

let active_tier1_distros arch =
  List.filter (fun d -> match distro_status d with `Active `Tier1 -> true | _ -> false ) distros |>
  List.filter (distro_supported_on arch OV.Releases.latest)

let active_tier2_distros arch =
  List.filter (fun d -> match distro_status d with `Active `Tier2 -> true | _ -> false ) distros |>
  List.filter (distro_supported_on arch OV.Releases.latest)

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
  |`Ubuntu `V18_04 -> Some "4.05.0"
  |`Ubuntu `V18_10 -> Some "4.05.0"
  |`Alpine `V3_3 -> Some "4.02.3"
  |`Alpine `V3_4 -> Some "4.02.3"
  |`Alpine `V3_5 -> Some "4.04.0"
  |`Alpine `V3_6 -> Some "4.04.1"
  |`Alpine `V3_7 -> Some "4.04.2"
  |`Alpine `V3_8 -> Some "4.06.1"
  |`Alpine `V3_9 -> Some "4.06.1"
  |`Fedora `V21 -> Some "4.01.0"
  |`Fedora `V22 -> Some "4.02.0"
  |`Fedora `V23 -> Some "4.02.2"
  |`Fedora `V24 -> Some "4.02.3"
  |`Fedora `V25 -> Some "4.02.3"
  |`Fedora `V26 -> Some "4.04.0"
  |`Fedora `V27 -> Some "4.05.0"
  |`Fedora `V28 -> Some "4.06.0"
  |`Fedora `V29 -> Some "4.07.0"
  |`CentOS `V6 -> Some "3.11.2"
  |`CentOS `V7 -> Some "4.01.0"
  |`OpenSUSE `V42_1 -> Some "4.02.3"
  |`OpenSUSE `V42_2 -> Some "4.03.0"
  |`OpenSUSE `V42_3 -> Some "4.03.0"
  |`OpenSUSE `V15_0 -> Some "4.05.0"
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
  |`Ubuntu `V18_04 -> "ubuntu-18.04"
  |`Ubuntu `V18_10 -> "ubuntu-18.10"
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
  |`Fedora `V28 -> "fedora-28"
  |`Fedora `V29 -> "fedora-29"
  |`OracleLinux `V7 -> "oraclelinux-7"
  |`OracleLinux `Latest -> "oraclelinux"
  |`Alpine `V3_3 -> "alpine-3.3"
  |`Alpine `V3_4 -> "alpine-3.4"
  |`Alpine `V3_5 -> "alpine-3.5"
  |`Alpine `V3_6 -> "alpine-3.6"
  |`Alpine `V3_7 -> "alpine-3.7"
  |`Alpine `V3_8 -> "alpine-3.8"
  |`Alpine `V3_9 -> "alpine-3.9"
  |`Alpine `Latest -> "alpine"
  |`OpenSUSE `V42_1 -> "opensuse-42.1"
  |`OpenSUSE `V42_2 -> "opensuse-42.2"
  |`OpenSUSE `V42_3 -> "opensuse-42.3"
  |`OpenSUSE `V15_0 -> "opensuse-15.0"
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
  |"ubuntu-18.04" -> Some (`Ubuntu `V18_04)
  |"ubuntu-18.10" -> Some (`Ubuntu `V18_10)
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
  |"fedora-28" -> Some (`Fedora `V28)
  |"fedora-29" -> Some (`Fedora `V29)
  |"fedora" -> Some (`Fedora `Latest)
  |"oraclelinux-7" -> Some (`OracleLinux `V7)
  |"oraclelinux" -> Some (`OracleLinux `Latest)
  |"alpine-3.3" -> Some (`Alpine `V3_3)
  |"alpine-3.4" -> Some (`Alpine `V3_4)
  |"alpine-3.5" -> Some (`Alpine `V3_5)
  |"alpine-3.6" -> Some (`Alpine `V3_6)
  |"alpine-3.7" -> Some (`Alpine `V3_7)
  |"alpine-3.8" -> Some (`Alpine `V3_8)
  |"alpine-3.9" -> Some (`Alpine `V3_9)
  |"alpine" -> Some (`Alpine `Latest)
  |"opensuse-42.1" -> Some (`OpenSUSE `V42_1)
  |"opensuse-42.2" -> Some (`OpenSUSE `V42_2)
  |"opensuse-42.3" -> Some (`OpenSUSE `V42_3)
  |"opensuse-15.0" -> Some (`OpenSUSE `V15_0)
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
  |`Ubuntu `V18_04 -> "Ubuntu 18.04"
  |`Ubuntu `V18_10 -> "Ubuntu 18.10"
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
  |`Fedora `V28 -> "Fedora 28"
  |`Fedora `V29 -> "Fedora 29"
  |`OracleLinux `V7 -> "OracleLinux 7"
  |`Alpine `V3_3 -> "Alpine 3.3"
  |`Alpine `V3_4 -> "Alpine 3.4"
  |`Alpine `V3_5 -> "Alpine 3.5"
  |`Alpine `V3_6 -> "Alpine 3.6"
  |`Alpine `V3_7 -> "Alpine 3.7"
  |`Alpine `V3_8 -> "Alpine 3.8"
  |`Alpine `V3_9 -> "Alpine 3.9"
  |`OpenSUSE `V42_1 -> "OpenSUSE 42.1"
  |`OpenSUSE `V42_2 -> "OpenSUSE 42.2"
  |`OpenSUSE `V42_3 -> "OpenSUSE 42.3"
  |`OpenSUSE `V15_0 -> "OpenSUSE 15.0 (Leap)"
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

type package_manager = [ `Apt | `Yum | `Apk | `Zypper ] [@@deriving sexp]

let package_manager (t:t) =
  match t with
  |`Ubuntu _ -> `Apt
  |`Debian _ -> `Apt
  |`CentOS _ -> `Yum
  |`Fedora _ -> `Yum
  |`OracleLinux _ -> `Yum
  |`Alpine _ -> `Apk
  |`OpenSUSE _ -> `Zypper

let base_distro_tag d =
  match resolve_alias d with
  | `Alpine v ->
        let tag =
          match v with
          | `V3_3 -> "3.3"
          | `V3_4 -> "3.4"
          | `V3_5 -> "3.5"
          | `V3_6 -> "3.6"
          | `V3_7 -> "3.7"
          | `V3_8 -> "3.8"
          | `V3_9 -> "3.9"
          | `Latest -> assert false
        in
        "alpine", tag
   | `Debian v ->
        let tag =
          match v with
          | `V7 -> "7"
          | `V8 -> "8"
          | `V9 -> "9"
          | `Testing -> "testing"
          | `Unstable -> "unstable"
          | `Stable -> assert false
        in
        "debian",tag
    | `Ubuntu v ->
        let tag =
          match v with
          | `V12_04 -> "precise"
          | `V14_04 -> "trusty"
          | `V15_04 -> "vivid"
          | `V15_10 -> "wily"
          | `V16_04 -> "xenial"
          | `V16_10 -> "yakkety"
          | `V17_04 -> "zesty"
          | `V17_10 -> "artful"
          | `V18_04 -> "bionic"
          | `V18_10 -> "cosmic"
          | `Latest | `LTS -> assert false
        in
        "ubuntu", tag
    | `CentOS v ->
        let tag = match v with `V6 -> "6" | `V7 -> "7" | _ -> assert false in
        "centos", tag
    | `Fedora v ->
        let tag =
          match v with
          | `V21 -> "21"
          | `V22 -> "22"
          | `V23 -> "23"
          | `V24 -> "24"
          | `V25 -> "25"
          | `V26 -> "26"
          | `V27 -> "27"
          | `V28 -> "28"
          | `V29 -> "28"
          | `Latest -> assert false
        in
        "fedora", tag
    | `OracleLinux v ->
        let tag = match v with `V7 -> "7" | _ -> assert false in
        "oraclelinux", tag
    | `OpenSUSE v ->
        let tag =
          match v with
          | `V42_1 -> "42.1"
          | `V42_2 -> "42.2"
          | `V42_3 -> "42.3"
          | `V15_0 -> "15.0"
          | `Latest -> assert false
        in
        "opensuse/leap", tag

let compare a b =
  String.compare (human_readable_string_of_distro a) (human_readable_string_of_distro b)
