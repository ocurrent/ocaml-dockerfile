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
open Sexplib.Conv

type win10_release = [
  | `V1507 | `V1511 | `V1607 | `V1703 | `V1709 | `V1803 | `V1809
  | `V1903 | `V1909 | `V2004 | `V20H2 | `V21H1 | `V21H2
] [@@deriving sexp]

type win10_ltsc = [
  `Ltsc2015 | `Ltsc2016 | `Ltsc2019 | `Ltsc2022
] [@@deriving sexp]

type win10_lcu = [
  | `LCU
  | `LCU20220809
  | `LCU20220712
  | `LCU20220614
  | `LCU20220510
  | `LCU20220412
  | `LCU20220308
  | `LCU20220208
  | `LCU20220111
  | `LCU20211214
  | `LCU20211109
  | `LCU20211012
  | `LCU20210914
  | `LCU20210810
  | `LCU20210713
  | `LCU20210608
] [@@deriving sexp]

type win_all = [ win10_release | win10_ltsc ] [@@deriving sexp]

let win10_current_lcu = `LCU20220809

type win10_revision = win10_release * win10_lcu option [@@deriving sexp]

let win10_lcus : ('a * int * win10_release list) list = [

  `LCU20220809, 5016627, [`V21H2];
  `LCU20220809, 5016616, [`V20H2; `V21H1];
  `LCU20220809, 5016623, [`V1809];
  `LCU20220809, 5016622, [`V1607];
  `LCU20220809, 5016639, [`V1507];

  `LCU20220712, 5015827, [`V21H2];
  `LCU20220712, 5015807, [`V20H2; `V21H1];
  `LCU20220712, 5015811, [`V1809];
  `LCU20220712, 5015808, [`V1607];
  `LCU20220712, 5015832, [`V1507];

  `LCU20220614, 5014678, [`V21H2];
  `LCU20220614, 5014699, [`V20H2; `V21H1];
  `LCU20220614, 5014692, [`V1809];
  `LCU20220614, 5014702, [`V1607];
  `LCU20220614, 5014710, [`V1507];

  `LCU20220510, 5013944, [`V21H2];
  `LCU20220510, 5013942, [`V20H2; `V21H1];
  `LCU20220510, 5013945, [`V1909];
  `LCU20220510, 5013941, [`V1809];
  `LCU20220510, 5013952, [`V1607];
  `LCU20220510, 5013963, [`V1507];

  `LCU20220412, 5012604, [`V21H2];
  `LCU20220412, 5012599, [`V20H2; `V21H1];
  `LCU20220412, 5012591, [`V1909];
  `LCU20220412, 5012647, [`V1809];
  `LCU20220412, 5012596, [`V1607];
  `LCU20220412, 5012653, [`V1507];

  `LCU20220308, 5011497, [`V21H2];
  `LCU20220308, 5011487, [`V20H2; `V21H1];
  `LCU20220308, 5011485, [`V1909];
  `LCU20220308, 5011503, [`V1809];
  `LCU20220308, 5011495, [`V1607];
  `LCU20220308, 5011491, [`V1507];

  `LCU20220208, 5010354, [`V21H2];
  `LCU20220208, 5010342, [`V20H2; `V21H1];
  `LCU20220208, 5010345, [`V1909];
  `LCU20220208, 5010351, [`V1809];
  `LCU20220208, 5010359, [`V1607];
  `LCU20220208, 5010358, [`V1507];

  `LCU20220111, 5009555, [`V21H2];
  `LCU20220111, 5009543, [`V20H2; `V21H1];
  `LCU20220111, 5009545, [`V1909];
  `LCU20220111, 5009557, [`V1809];
  `LCU20220111, 5009546, [`V1607];
  `LCU20220111, 5009585, [`V1507];

  `LCU20211214, 5008223, [`V21H2];
  `LCU20211214, 5008212, [`V2004; `V20H2; `V21H1];
  `LCU20211214, 5008206, [`V1909];
  `LCU20211214, 5008218, [`V1809];
  `LCU20211214, 5008207, [`V1607];
  `LCU20211214, 5008230, [`V1507];

  `LCU20211109, 5007205, [`V21H2];
  `LCU20211109, 5007186, [`V2004; `V20H2; `V21H1];
  `LCU20211109, 5007189, [`V1909];
  `LCU20211109, 5007206, [`V1809];
  `LCU20211109, 5007192, [`V1607];
  `LCU20211109, 5007207, [`V1507];

  `LCU20211012, 5006699, [`V21H2];
  `LCU20211012, 5006670, [`V2004; `V20H2; `V21H1];
  `LCU20211012, 5006667, [`V1909];
  `LCU20211012, 5006672, [`V1809];
  `LCU20211012, 5006669, [`V1607];
  `LCU20211012, 5006675, [`V1507];
  `LCU20210914, 5005575, [`V21H2];
  `LCU20210914, 5005565, [`V2004; `V20H2; `V21H1];
  `LCU20210914, 5005566, [`V1909];
  `LCU20210914, 5005568, [`V1809];
  `LCU20210914, 5005573, [`V1607];
  `LCU20210914, 5005569, [`V1507];
  `LCU20210810, 5005039, [`V21H2];
  `LCU20210810, 5005033, [`V2004; `V20H2; `V21H1];
  `LCU20210810, 5005031, [`V1909];
  `LCU20210810, 5005030, [`V1809];
  `LCU20210810, 5005043, [`V1607];
  `LCU20210810, 5005040, [`V1507];
  `LCU20210713, 5004237, [`V2004; `V20H2; `V21H1];
  `LCU20210713, 5004245, [`V1909];
  `LCU20210713, 5004244, [`V1809];
  `LCU20210713, 5004238, [`V1607];
  `LCU20210713, 5004249, [`V1507];
  `LCU20210608, 5003637, [`V2004; `V20H2; `V21H1];
  `LCU20210608, 5003635, [`V1909];
  `LCU20210608, 5003646, [`V1809];
  `LCU20210608, 5003638, [`V1607];
  `LCU20210608, 5003687, [`V1507];
]

let win10_lcu_to_kb : ((win10_lcu * win10_release), int option) Hashtbl.t =
  let t = Hashtbl.create 63 in
  let f (lcu, kb, vs) =
    let g v =
      if lcu = win10_current_lcu then
        Hashtbl.add t (`LCU, v) (Some kb);
      Hashtbl.add t (lcu, v) (Some kb)
    in
    List.iter g vs in
  List.iter f win10_lcus; t

let win10_kb_to_lcu =
  let t = Hashtbl.create 63 in
  let f (lcu, kb, vs) = List.iter (fun v -> Hashtbl.add t (kb, v) (Some lcu)) vs in
  List.iter f win10_lcus; t

let win10_lcu_kb_number v lcu =
  try Hashtbl.find win10_lcu_to_kb (lcu, v)
  with Not_found -> None

let win10_kb_number_to_lcu (v:win10_release) kb =
  match Hashtbl.find win10_kb_to_lcu (kb, v) with
  | lcu -> Some (v, lcu)
  | exception Not_found -> None

type distro = [
  | `Alpine of [ `V3_3 | `V3_4 | `V3_5 | `V3_6 | `V3_7 | `V3_8 | `V3_9 | `V3_10 | `V3_11 | `V3_12 | `V3_13 | `V3_14 | `V3_15 ]
  | `Archlinux of [ `Latest ]
  | `CentOS of [ `V6 | `V7 | `V8 ]
  | `Debian of [ `V11 | `V10 | `V9 | `V8 | `V7 | `Testing | `Unstable ]
  | `Fedora of [ `V21 | `V22 | `V23 | `V24 | `V25 | `V26 | `V27 | `V28 | `V29 | `V30 | `V31 | `V32 | `V33 | `V34 | `V35 ]
  | `OracleLinux of [ `V7 | `V8 ]
  | `OpenSUSE of [ `V42_1 | `V42_2 | `V42_3 | `V15_0 | `V15_1 | `V15_2 | `V15_3 ]
  | `Ubuntu of [ `V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 | `V16_10 | `V17_04 | `V17_10 | `V18_04 | `V18_10 | `V19_04 | `V19_10 | `V20_04 | `V20_10 | `V21_04 | `V21_10 | `V22_04 ]
  | `Cygwin of win10_release
  | `Windows of [`Mingw | `Msvc] * win10_release
] [@@deriving sexp]

type t = [
  | `Alpine of [ `V3_3 | `V3_4 | `V3_5 | `V3_6 | `V3_7 | `V3_8 | `V3_9 | `V3_10 | `V3_11 | `V3_12 | `V3_13 | `V3_14 | `V3_15 | `Latest ]
  | `Archlinux of [ `Latest ]
  | `CentOS of [ `V6 | `V7 | `V8 | `Latest ]
  | `Debian of [ `V11 | `V10 | `V9 | `V8 | `V7 | `Stable | `Testing | `Unstable ]
  | `Fedora of [ `V21 | `V22 | `V23 | `V24 | `V25 | `V26 | `V27 | `V28 | `V29 | `V30 | `V31 | `V32 | `V33 | `V34 | `V35 | `Latest ]
  | `OracleLinux of [ `V7 | `V8 | `Latest ]
  | `OpenSUSE of [ `V42_1 | `V42_2 | `V42_3 | `V15_0 | `V15_1 | `V15_2 | `V15_3 | `Latest ]
  | `Ubuntu of [ `V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 | `V16_10 | `V17_04 | `V17_10 | `V18_04 | `V18_10 | `V19_04 | `V19_10 | `V20_04 | `V20_10 | `V21_04 | `V21_10 | `V22_04 | `Latest | `LTS ]
  | `Cygwin of win_all
  | `Windows of [`Mingw | `Msvc] * win_all
] [@@deriving sexp]

type os_family = [ `Cygwin | `Linux | `Windows ] [@@deriving sexp]

let os_family_of_distro (t:t) : os_family =
  match t with
  | `Alpine _ | `Archlinux _ | `CentOS _ | `Debian _ | `Fedora _
    | `OracleLinux _ | `OpenSUSE _ | `Ubuntu _ -> `Linux
  | `Cygwin _ -> `Cygwin
  | `Windows _ -> `Windows

let os_family_to_string (os:os_family) =
  match os with
  | `Linux -> "linux"
  | `Windows -> "windows"
  | `Cygwin -> "cygwin"

let opam_repository (os:os_family) =
  match os with
  | `Cygwin | `Linux -> "https://github.com/ocaml/opam-repository.git"
  | `Windows -> "https://github.com/fdopen/opam-repository-mingw.git#opam2"

let personality os_family arch =
  match os_family with
  | `Linux when Ocaml_version.arch_is_32bit arch -> Some "/usr/bin/linux32"
  | _ -> None

type status = [
  | `Deprecated
  | `Active of [ `Tier1 | `Tier2 | `Tier3 ]
  | `Alias
  | `Not_available
] [@@deriving sexp]

let distros : t list = [
  `Alpine `V3_3; `Alpine `V3_4; `Alpine `V3_5; `Alpine `V3_6; `Alpine `V3_7; `Alpine `V3_8; `Alpine `V3_9; `Alpine `V3_10; `Alpine `V3_11; `Alpine `V3_12; `Alpine `V3_13; `Alpine `V3_14; `Alpine `V3_15; `Alpine `Latest;
  `Archlinux `Latest;
  `CentOS `V6; `CentOS `V7; `CentOS `V8; `CentOS `Latest;
  `Debian `V11; `Debian `V10; `Debian `V9; `Debian `V8; `Debian `V7;
  `Debian `Stable; `Debian `Testing; `Debian `Unstable;
  `Fedora `V23; `Fedora `V24; `Fedora `V25; `Fedora `V26; `Fedora `V27; `Fedora `V28; `Fedora `V29; `Fedora `V30; `Fedora `V31; `Fedora `V32; `Fedora `V33; `Fedora `V34; `Fedora `V35; `Fedora `Latest;
  `OracleLinux `V7; `OracleLinux `V8; `OracleLinux `Latest;
  `OpenSUSE `V42_1; `OpenSUSE `V42_2; `OpenSUSE `V42_3; `OpenSUSE `V15_0; `OpenSUSE `V15_1; `OpenSUSE `V15_2; `OpenSUSE `V15_3; `OpenSUSE `Latest;
  `Ubuntu `V12_04; `Ubuntu `V14_04; `Ubuntu `V15_04; `Ubuntu `V15_10;
  `Ubuntu `V16_04; `Ubuntu `V16_10; `Ubuntu `V17_04; `Ubuntu `V17_10; `Ubuntu `V18_04; `Ubuntu `V18_10; `Ubuntu `V19_04; `Ubuntu `V19_10; `Ubuntu `V20_04; `Ubuntu `V20_10; `Ubuntu `V21_04; `Ubuntu `V21_10; `Ubuntu `V22_04;
  `Ubuntu `Latest; `Ubuntu `LTS;
]
let distros =
  let win10_releases =
    [ `V1507; `Ltsc2015; `V1511; `V1607; `Ltsc2016; `V1703; `V1709; `V1809;
      `Ltsc2019; `V1903; `V1909; `V2004; `V20H2; `V21H1; `V21H2; `Ltsc2022 ] in
  List.fold_left (fun distros version ->
      `Cygwin version :: `Windows (`Mingw, version) :: `Windows (`Msvc, version) :: distros)
    distros win10_releases

type win10_release_status = [ `Deprecated | `Active ]

let resolve_ltsc v =
  match v with
  | `Ltsc2022 -> `V21H2
  | `Ltsc2019 -> `V1809
  | `Ltsc2016 -> `V1607
  | `Ltsc2015 -> `V1507
  | #win10_release as v -> v

(* https://en.wikipedia.org/wiki/Windows_10_version_history#Channels *)
let win10_release_status v : win10_release_status = match resolve_ltsc v with
  | `V1507 -> `Deprecated | `Ltsc2015 -> `Active
  | `V1511 -> `Deprecated
  | `V1607 -> `Deprecated | `Ltsc2016 -> `Active
  | `V1703
  | `V1709
  | `V1803
  | `V1809 -> `Deprecated | `Ltsc2019 -> `Active
  | `V1903
  | `V1909 -> `Deprecated
  | `V2004 -> `Deprecated
  | `V20H2
  | `V21H1 | `V21H2 | `Ltsc2022 -> `Active

let win10_latest_release = `V21H2

type win10_docker_base_image = [ `Windows | `ServerCore | `NanoServer ]

(* https://docs.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/base-image-lifecycle *)
let win10_docker_status (base : win10_docker_base_image) v : status =
  match base, v with
  | _, (`V20H2 | `V21H2) -> `Active `Tier3
  | _, `V2004
  | _, `V1909
  | _, `V1903 -> `Deprecated
  | `ServerCore, `V1809
  | `NanoServer, `V1809
  | `Windows, `V1809 -> `Active `Tier3
  | (`ServerCore | `NanoServer), `V1803
  | (`ServerCore | `NanoServer), `V1709 -> `Deprecated
  | `ServerCore, `V1607 -> `Active `Tier3
  | `NanoServer, `V1607 -> `Deprecated
  | _ -> `Not_available

let win10_latest_image = `V21H2

let resolve_alias (d:t) : distro =
  match d with
  | `Alpine `Latest -> `Alpine `V3_15
  | `CentOS `Latest -> `CentOS `V7
  | `Debian `Stable -> `Debian `V11
  | `Fedora `Latest -> `Fedora `V35
  | `OracleLinux `Latest -> `OracleLinux `V8
  | `OpenSUSE `Latest -> `OpenSUSE `V15_3
  | `Ubuntu `Latest -> `Ubuntu `V22_04
  | `Ubuntu `LTS -> `Ubuntu `V22_04
  | `Cygwin (#win10_ltsc as v) -> `Cygwin (resolve_ltsc v)
  | `Windows (cc, (#win10_ltsc as v)) -> `Windows (cc, resolve_ltsc v)
  | `Alpine (`V3_3 | `V3_4 | `V3_5 | `V3_6 | `V3_7 | `V3_8 | `V3_9 | `V3_10 | `V3_11 | `V3_12 | `V3_13 | `V3_14 | `V3_15)
  | `Archlinux `Latest
  | `CentOS (`V6 | `V7 | `V8)
  | `Debian (`V7 | `V8 | `V9 | `V10 | `V11 | `Testing | `Unstable)
  | `Fedora (`V21 | `V22 | `V23 | `V24 | `V25 | `V26 | `V27 | `V28 | `V29 | `V30 | `V31 | `V32 | `V33 | `V34 | `V35)
  | `OracleLinux (`V7 | `V8)
  | `OpenSUSE (`V42_1 | `V42_2 | `V42_3 | `V15_0 | `V15_1 | `V15_2 | `V15_3)
  | `Ubuntu (`V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 | `V16_10 | `V17_04 | `V17_10 | `V18_04 | `V18_10 | `V19_04 | `V19_10 | `V20_04 | `V20_10 | `V21_04 | `V21_10 | `V22_04)
  | `Cygwin (`V1507 | `V1511 | `V1607 | `V1703 | `V1709 | `V1803 | `V1809 | `V1903 | `V1909 | `V2004 | `V20H2 | `V21H1 | `V21H2)
  | `Windows (_, (`V1507 | `V1511 | `V1607 | `V1703 | `V1709 | `V1803 | `V1809 | `V1903 | `V1909 | `V2004 | `V20H2 | `V21H1 | `V21H2)) as d ->
      d

let distro_status (d:t) : status =
  let resolved = resolve_alias d in
  if (resolved : distro :> t) <> d then
    `Alias
  else
    match resolve_alias d with
    | `Alpine (`V3_3 | `V3_4 | `V3_5 | `V3_6 | `V3_7 | `V3_8 | `V3_9 | `V3_10 | `V3_11 | `V3_12 |`V3_13) -> `Deprecated
    | `Alpine `V3_14 -> `Active `Tier2
    | `Alpine `V3_15 -> `Active `Tier1
    | `Archlinux `Latest -> `Active `Tier3
    | `CentOS `V7 -> `Active `Tier3
    | `CentOS (`V6|`V8) -> `Deprecated
    | `Debian (`V7|`V8|`V9) -> `Deprecated
    | `Debian `V10 -> `Active `Tier2
    | `Debian `V11 -> `Active `Tier1
    | `Debian `Testing -> `Active `Tier3
    | `Debian `Unstable -> `Active `Tier3
    | `Fedora ( `V21 | `V22 | `V23 | `V24 | `V25 | `V26 | `V27 | `V28 | `V29 | `V30 | `V31 | `V32 | `V33) -> `Deprecated
    | `Fedora (`V34 | `V35) -> `Active `Tier2
    | `OracleLinux (`V7|`V8) -> `Active `Tier3
    | `OpenSUSE (`V42_1 | `V42_2 | `V42_3 | `V15_0 | `V15_1 | `V15_2) -> `Deprecated
    | `OpenSUSE `V15_3 -> `Active `Tier2
    | `Ubuntu (`V18_04) -> `Active `Tier3
    | `Ubuntu (`V20_04 | `V22_04) -> `Active `Tier2
    | `Ubuntu (`V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 | `V16_10 | `V17_04 | `V17_10 | `V18_10 | `V19_04 | `V19_10 | `V20_10 | `V21_04 | `V21_10) -> `Deprecated
    | `Cygwin v -> win10_docker_status `ServerCore v
    | `Windows (_, v) -> win10_docker_status `Windows v

let latest_distros =
  [ `Alpine `Latest; `Archlinux `Latest; `CentOS `Latest;
    `Debian `Stable; `OracleLinux `Latest; `OpenSUSE `Latest;
    `Fedora `Latest; `Ubuntu `Latest; `Ubuntu `LTS;
    (* Prefer win10_latest_image to win10_latest_release as
       latest_distro is used by docker-base-images to fetch tag
       aliases. *)
    `Cygwin win10_latest_image;
    `Windows (`Mingw, win10_latest_image);
    `Windows (`Msvc, win10_latest_image);
  ]

let master_distro = `Debian `Stable

module OV = Ocaml_version

let distro_arches ov (d:t) =
  match resolve_alias d, ov with
  | `Windows (`Msvc, _), ov when OV.major ov >= 5 -> []
  | (`CentOS (`V6|`V7)|`OracleLinux `V7), ov when OV.major ov >= 5 -> []
  | `Debian `V11, ov when OV.(compare Releases.v4_03_0 ov) = -1 -> [ `I386; `X86_64; `Aarch64; `Aarch32; `Ppc64le; `S390x ]
  | `Debian `V11, ov when OV.(compare Releases.v4_02_0 ov) = -1 -> [ `I386; `X86_64; `Aarch64; `Aarch32]
  | `Debian `V10, ov when OV.(compare Releases.v4_03_0 ov) = -1 -> [ `I386; `X86_64; `Aarch64; `Aarch32; `Ppc64le; `S390x ]
  | `Debian `V10, ov when OV.(compare Releases.v4_02_0 ov) = -1 -> [ `I386; `X86_64; `Aarch64; `Aarch32]
  | `Debian `V9, ov when OV.(compare Releases.v4_03_0 ov) = -1 -> [ `I386; `X86_64; `Aarch64; `Aarch32 ]
  | `Alpine (`V3_6 | `V3_7 | `V3_8 | `V3_9 | `V3_10 | `V3_11 | `V3_12 | `V3_13 | `V3_14 | `V3_15), ov when OV.(compare Releases.v4_05_0 ov) = -1 -> [ `X86_64; `Aarch64 ]
  | `Ubuntu `V18_04, ov when OV.(compare Releases.v4_05_0 ov) = -1  -> [ `X86_64; `Aarch64; `Ppc64le; `S390x ]
  | `Ubuntu (`V20_04|`V20_10|`V21_04|`V21_10|`V22_04), ov when OV.(compare Releases.v4_05_0 ov) = -1  ->
    let base = [ `X86_64; `Aarch64; `Ppc64le; `S390x ] in
    if OV.(compare Releases.v4_11_0 ov) <= 0 then
      `Riscv64 :: base
    else
      base
  | `Fedora (`V33|`V34|`V35), ov when OV.(compare Releases.v4_08_0 ov) = -1  -> [ `X86_64; `Aarch64 ]
  (* 2021-04-19: should be 4.03 but there's a linking failure until 4.06. *)
  | `Windows (`Msvc, _), ov when OV.(compare Releases.v4_06_0 ov) = 1 -> []
  | _ -> [ `X86_64 ]


let distro_supported_on a ov (d:t) =
  List.mem a (distro_arches ov d)

let distro_active_for arch (d:t) =
  match arch, d with
  | `X86_64, `Windows _ -> true
  | _ -> distro_supported_on arch OV.Releases.latest d

let active_distros arch =
  List.filter (fun d -> match distro_status d with `Active _ -> true | _ -> false ) distros |>
  List.filter (distro_active_for arch)

let active_tier1_distros arch =
  List.filter (fun d -> match distro_status d with `Active `Tier1 -> true | _ -> false ) distros |>
  List.filter (distro_active_for arch)

let active_tier2_distros arch =
  List.filter (fun d -> match distro_status d with `Active `Tier2 -> true | _ -> false ) distros |>
  List.filter (distro_active_for arch)

let active_tier3_distros arch =
  List.filter (fun d -> match distro_status d with `Active `Tier3 -> true | _ -> false ) distros |>
  List.filter (distro_active_for arch)

(* The distro-supplied version of OCaml *)
let builtin_ocaml_of_distro (d:t) : string option =
  match resolve_alias d with
  |`Debian `V7 -> Some "3.12.1"
  |`Debian `V8 -> Some "4.01.0"
  |`Debian `V9 -> Some "4.02.3"
  |`Debian `V10 -> Some "4.05.0"
  |`Debian `V11 -> Some "4.11.1"
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
  |`Ubuntu `V19_04 -> Some "4.05.0"
  |`Ubuntu `V19_10 -> Some "4.05.0"
  |`Ubuntu `V20_04 -> Some "4.08.1"
  |`Ubuntu `V20_10 -> Some "4.08.1"
  |`Ubuntu `V21_04 -> Some "4.11.1"
  |`Ubuntu `V21_10 -> Some "4.11.1"
  |`Ubuntu `V22_04 -> failwith "4.11.1; not yet confirmed"
  |`Alpine `V3_3 -> Some "4.02.3"
  |`Alpine `V3_4 -> Some "4.02.3"
  |`Alpine `V3_5 -> Some "4.04.0"
  |`Alpine `V3_6 -> Some "4.04.1"
  |`Alpine `V3_7 -> Some "4.04.2"
  |`Alpine `V3_8 -> Some "4.06.1"
  |`Alpine `V3_9 -> Some "4.06.1"
  |`Alpine `V3_10 -> Some "4.07.0"
  |`Alpine `V3_11 -> Some "4.08.1"
  |`Alpine `V3_12 -> Some "4.08.1"
  |`Alpine `V3_13 -> Some "4.08.1"
  |`Alpine `V3_14 -> Some "4.12.0"
  |`Alpine `V3_15 -> Some "4.13.1"
  |`Archlinux `Latest -> Some "4.11.1"
  |`Fedora `V21 -> Some "4.01.0"
  |`Fedora `V22 -> Some "4.02.0"
  |`Fedora `V23 -> Some "4.02.2"
  |`Fedora `V24 -> Some "4.02.3"
  |`Fedora `V25 -> Some "4.02.3"
  |`Fedora `V26 -> Some "4.04.0"
  |`Fedora `V27 -> Some "4.05.0"
  |`Fedora `V28 -> Some "4.06.0"
  |`Fedora `V29 -> Some "4.07.0"
  |`Fedora `V30 -> Some "4.07.0"
  |`Fedora `V31 -> Some "4.08.1"
  |`Fedora `V32 -> Some "4.10.0"
  |`Fedora `V33 -> Some "4.11.1"
  |`Fedora `V34 -> Some "4.11.1"
  |`Fedora `V35 -> Some "4.12.0"
  |`CentOS `V6 -> Some "3.11.2"
  |`CentOS `V7 -> Some "4.01.0"
  |`CentOS `V8 -> Some "4.07.0"
  |`OpenSUSE `V42_1 -> Some "4.02.3"
  |`OpenSUSE `V42_2 -> Some "4.03.0"
  |`OpenSUSE `V42_3 -> Some "4.03.0"
  |`OpenSUSE `V15_0 -> Some "4.05.0"
  |`OpenSUSE `V15_1 -> Some "4.05.0"
  |`OpenSUSE `V15_2 -> Some "4.05.0"
  |`OpenSUSE `V15_3 -> Some "4.05.0"
  |`OracleLinux `V7 -> Some "4.01.0"
  |`OracleLinux `V8 -> Some "4.07.0"
  |`Cygwin _ -> None
  |`Windows _ -> None
  |`Debian (`Testing | `Unstable) -> assert false

let win10_release_to_string = function
  | `V1507 -> "1507" | `Ltsc2015 -> "ltsc2015" | `V1511 -> "1511"
  | `V1607 -> "1607" | `Ltsc2016 -> "ltsc2016" | `V1703 -> "1703"
  | `V1709 -> "1709" | `V1803 -> "1803" | `V1809 -> "1809"
  | `Ltsc2019 -> "ltsc2019" | `V1903 -> "1903" | `V1909 -> "1909"
  | `V2004 -> "2004" | `V20H2 -> "20H2" | `V21H1 -> "21H1"
  | `Ltsc2022 -> "ltsc2022" | `V21H2 -> "21H2"

let win10_release_of_string v : win_all option =
  let v = match String.cut ~sep:"-KB" v with
  | Some (v, kb) -> if String.for_all Char.Ascii.is_digit kb then v else ""
  | None -> v
  in
  match v with
  | "1507" -> Some `V1507 | "ltsc2015" -> Some `Ltsc2015 | "1511" -> Some `V1511
  | "1607" -> Some `V1607 | "ltsc2016" -> Some `Ltsc2016 | "1703" -> Some `V1703
  | "1709" -> Some `V1709 | "1803" -> Some `V1803 | "1809" -> Some `V1809
  | "ltsc2019" -> Some `Ltsc2019 | "1903" -> Some `V1903 | "1909" -> Some `V1909
  | "2004" -> Some `V2004 | "20H2" -> Some `V20H2 | "21H1" -> Some `V21H1
  | "ltsc2022" -> Some `Ltsc2022
  | _ -> None

let rec win10_revision_to_string = function
| (v, None) -> win10_release_to_string v
| (v, Some `LCU) -> win10_revision_to_string (v, Some win10_current_lcu)
| (v, Some lcu) ->
    match win10_lcu_kb_number (resolve_ltsc v) lcu with
    | Some kb -> Printf.sprintf "%s-KB%d" (win10_release_to_string v) kb
    | None -> Fmt.invalid_arg "No KB for this Win10 %s revision" (win10_release_to_string v)

let win10_revision_of_string v =
  let v, lcu =
    match String.cut ~sep:"-KB" v with
    | Some (v, lcu) when String.for_all Char.Ascii.is_digit lcu ->
        (v, Some (int_of_string lcu))
    | _ ->
        (v, None)
  in
  match win10_release_of_string v with
  | None -> None
  | Some v ->
      let v = resolve_ltsc v in
      match lcu with
      | None -> Some (v, None)
      | Some lcu -> win10_kb_number_to_lcu v lcu

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
  |`Ubuntu `V19_04 -> "ubuntu-19.04"
  |`Ubuntu `V19_10 -> "ubuntu-19.10"
  |`Ubuntu `V20_04 -> "ubuntu-20.04"
  |`Ubuntu `V20_10 -> "ubuntu-20.10"
  |`Ubuntu `V21_04 -> "ubuntu-21.04"
  |`Ubuntu `V21_10 -> "ubuntu-21.10"
  |`Ubuntu `V22_04 -> "ubuntu-22.04"
  |`Ubuntu `Latest -> "ubuntu"
  |`Ubuntu `LTS -> "ubuntu-lts"
  |`Debian `Stable -> "debian-stable"
  |`Debian `Unstable -> "debian-unstable"
  |`Debian `Testing -> "debian-testing"
  |`Debian `V11 -> "debian-11"
  |`Debian `V10 -> "debian-10"
  |`Debian `V9 -> "debian-9"
  |`Debian `V8 -> "debian-8"
  |`Debian `V7 -> "debian-7"
  |`CentOS `V6 -> "centos-6"
  |`CentOS `V7 -> "centos-7"
  |`CentOS `V8 -> "centos-8"
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
  |`Fedora `V30 -> "fedora-30"
  |`Fedora `V31 -> "fedora-31"
  |`Fedora `V32 -> "fedora-32"
  |`Fedora `V33 -> "fedora-33"
  |`Fedora `V34 -> "fedora-34"
  |`Fedora `V35 -> "fedora-35"
  |`OracleLinux `V7 -> "oraclelinux-7"
  |`OracleLinux `V8 -> "oraclelinux-8"
  |`OracleLinux `Latest -> "oraclelinux"
  |`Alpine `V3_3 -> "alpine-3.3"
  |`Alpine `V3_4 -> "alpine-3.4"
  |`Alpine `V3_5 -> "alpine-3.5"
  |`Alpine `V3_6 -> "alpine-3.6"
  |`Alpine `V3_7 -> "alpine-3.7"
  |`Alpine `V3_8 -> "alpine-3.8"
  |`Alpine `V3_9 -> "alpine-3.9"
  |`Alpine `V3_10 -> "alpine-3.10"
  |`Alpine `V3_11 -> "alpine-3.11"
  |`Alpine `V3_12 -> "alpine-3.12"
  |`Alpine `V3_13 -> "alpine-3.13"
  |`Alpine `V3_14 -> "alpine-3.14"
  |`Alpine `V3_15 -> "alpine-3.15"
  |`Alpine `Latest -> "alpine"
  |`Archlinux `Latest -> "archlinux"
  |`OpenSUSE `V42_1 -> "opensuse-42.1"
  |`OpenSUSE `V42_2 -> "opensuse-42.2"
  |`OpenSUSE `V42_3 -> "opensuse-42.3"
  |`OpenSUSE `V15_0 -> "opensuse-15.0"
  |`OpenSUSE `V15_1 -> "opensuse-15.1"
  |`OpenSUSE `V15_2 -> "opensuse-15.2"
  |`OpenSUSE `V15_3 -> "opensuse-15.3"
  |`OpenSUSE `Latest -> "opensuse"
  |`Cygwin v -> "cygwin-" ^ (win10_release_to_string v)
  |`Windows (`Mingw, v) -> "windows-mingw-" ^ (win10_release_to_string v)
  |`Windows (`Msvc, v) -> "windows-msvc-" ^ (win10_release_to_string v)

let distro_of_tag x : t option =
  let win10_of_tag affix s f =
    let stop = String.length affix in
    match win10_release_of_string (String.(sub ~start:0 ~stop s |> Sub.to_string)) with
    | Some v -> Some (f v)
    | None -> None
  in
  match x with
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
  |"ubuntu-19.04" -> Some (`Ubuntu `V19_04)
  |"ubuntu-19.10" -> Some (`Ubuntu `V19_10)
  |"ubuntu-20.04" -> Some (`Ubuntu `V20_04)
  |"ubuntu-20.10" -> Some (`Ubuntu `V20_10)
  |"ubuntu-21.04" -> Some (`Ubuntu `V21_04)
  |"ubuntu-21.10" -> Some (`Ubuntu `V21_10)
  |"ubuntu-22.04" -> Some (`Ubuntu `V22_04)
  |"ubuntu" -> Some (`Ubuntu `Latest)
  |"ubuntu-lts" -> Some (`Ubuntu `LTS)
  |"debian-stable" -> Some (`Debian `Stable)
  |"debian-unstable" -> Some (`Debian `Unstable)
  |"debian-testing" -> Some (`Debian `Testing)
  |"debian-11" -> Some (`Debian `V11)
  |"debian-10" -> Some (`Debian `V10)
  |"debian-9" -> Some (`Debian `V9)
  |"debian-8" -> Some (`Debian `V8)
  |"debian-7" -> Some (`Debian `V7)
  |"centos-6" -> Some (`CentOS `V6)
  |"centos-7" -> Some (`CentOS `V7)
  |"centos-8" -> Some (`CentOS `V8)
  |"fedora-21" -> Some (`Fedora `V21)
  |"fedora-22" -> Some (`Fedora `V22)
  |"fedora-23" -> Some (`Fedora `V23)
  |"fedora-24" -> Some (`Fedora `V24)
  |"fedora-25" -> Some (`Fedora `V25)
  |"fedora-26" -> Some (`Fedora `V26)
  |"fedora-27" -> Some (`Fedora `V27)
  |"fedora-28" -> Some (`Fedora `V28)
  |"fedora-29" -> Some (`Fedora `V29)
  |"fedora-30" -> Some (`Fedora `V30)
  |"fedora-31" -> Some (`Fedora `V31)
  |"fedora-32" -> Some (`Fedora `V32)
  |"fedora-33" -> Some (`Fedora `V33)
  |"fedora-34" -> Some (`Fedora `V34)
  |"fedora-35" -> Some (`Fedora `V35)
  |"fedora" -> Some (`Fedora `Latest)
  |"oraclelinux-7" -> Some (`OracleLinux `V7)
  |"oraclelinux-8" -> Some (`OracleLinux `V8)
  |"oraclelinux" -> Some (`OracleLinux `Latest)
  |"alpine-3.3" -> Some (`Alpine `V3_3)
  |"alpine-3.4" -> Some (`Alpine `V3_4)
  |"alpine-3.5" -> Some (`Alpine `V3_5)
  |"alpine-3.6" -> Some (`Alpine `V3_6)
  |"alpine-3.7" -> Some (`Alpine `V3_7)
  |"alpine-3.8" -> Some (`Alpine `V3_8)
  |"alpine-3.9" -> Some (`Alpine `V3_9)
  |"alpine-3.10" -> Some (`Alpine `V3_10)
  |"alpine-3.11" -> Some (`Alpine `V3_11)
  |"alpine-3.12" -> Some (`Alpine `V3_12)
  |"alpine-3.13" -> Some (`Alpine `V3_13)
  |"alpine-3.14" -> Some (`Alpine `V3_14)
  |"alpine-3.15" -> Some (`Alpine `V3_15)
  |"alpine" -> Some (`Alpine `Latest)
  |"archlinux" -> Some (`Archlinux `Latest)
  |"opensuse-42.1" -> Some (`OpenSUSE `V42_1)
  |"opensuse-42.2" -> Some (`OpenSUSE `V42_2)
  |"opensuse-42.3" -> Some (`OpenSUSE `V42_3)
  |"opensuse-15.0" -> Some (`OpenSUSE `V15_0)
  |"opensuse-15.1" -> Some (`OpenSUSE `V15_1)
  |"opensuse-15.2" -> Some (`OpenSUSE `V15_2)
  |"opensuse-15.3" -> Some (`OpenSUSE `V15_3)
  |"opensuse" -> Some (`OpenSUSE `Latest)
  | s when String.is_prefix ~affix:"cygwin-" s ->
     win10_of_tag "cygwin-" s (fun v -> `Cygwin v)
  | s when String.is_prefix ~affix:"windows-mingw-" s ->
     win10_of_tag "windows-mingw-" s (fun v -> `Windows (`Mingw, v))
  | s when String.is_prefix ~affix:"windows-msvc-" s ->
     win10_of_tag "windows-msvc-" s (fun v -> `Windows (`Msvc, v))
  |_ -> None

let human_readable_string_of_distro (d:t) =
  if d = `Debian `Stable then
    "Debian Stable"
  else
    match resolve_alias d with
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
    |`Ubuntu `V19_04 -> "Ubuntu 19.04"
    |`Ubuntu `V19_10 -> "Ubuntu 19.10"
    |`Ubuntu `V20_04 -> "Ubuntu 20.04"
    |`Ubuntu `V20_10 -> "Ubuntu 20.10"
    |`Ubuntu `V21_04 -> "Ubuntu 21.04"
    |`Ubuntu `V21_10 -> "Ubuntu 21.10"
    |`Ubuntu `V22_04 -> "Ubuntu 22.04"
    |`Debian `Unstable -> "Debian Unstable"
    |`Debian `Testing -> "Debian Testing"
    |`Debian `V11 -> "Debian 11 (Bullseye)"
    |`Debian `V10 -> "Debian 10 (Buster)"
    |`Debian `V9 -> "Debian 9 (Stretch)"
    |`Debian `V8 -> "Debian 8 (Jessie)"
    |`Debian `V7 -> "Debian 7 (Wheezy)"
    |`CentOS `V6 -> "CentOS 6"
    |`CentOS `V7 -> "CentOS 7"
    |`CentOS `V8 -> "CentOS 8"
    |`Fedora `V21 -> "Fedora 21"
    |`Fedora `V22 -> "Fedora 22"
    |`Fedora `V23 -> "Fedora 23"
    |`Fedora `V24 -> "Fedora 24"
    |`Fedora `V25 -> "Fedora 25"
    |`Fedora `V26 -> "Fedora 26"
    |`Fedora `V27 -> "Fedora 27"
    |`Fedora `V28 -> "Fedora 28"
    |`Fedora `V29 -> "Fedora 29"
    |`Fedora `V30 -> "Fedora 30"
    |`Fedora `V31 -> "Fedora 31"
    |`Fedora `V32 -> "Fedora 32"
    |`Fedora `V33 -> "Fedora 33"
    |`Fedora `V34 -> "Fedora 34"
    |`Fedora `V35 -> "Fedora 35"
    |`OracleLinux `V7 -> "OracleLinux 7"
    |`OracleLinux `V8 -> "OracleLinux 8"
    |`Alpine `V3_3 -> "Alpine 3.3"
    |`Alpine `V3_4 -> "Alpine 3.4"
    |`Alpine `V3_5 -> "Alpine 3.5"
    |`Alpine `V3_6 -> "Alpine 3.6"
    |`Alpine `V3_7 -> "Alpine 3.7"
    |`Alpine `V3_8 -> "Alpine 3.8"
    |`Alpine `V3_9 -> "Alpine 3.9"
    |`Alpine `V3_10 -> "Alpine 3.10"
    |`Alpine `V3_11 -> "Alpine 3.11"
    |`Alpine `V3_12 -> "Alpine 3.12"
    |`Alpine `V3_13 -> "Alpine 3.13"
    |`Alpine `V3_14 -> "Alpine 3.14"
    |`Alpine `V3_15 -> "Alpine 3.15"
    |`Archlinux `Latest -> "Archlinux"
    |`OpenSUSE `V42_1 -> "OpenSUSE 42.1"
    |`OpenSUSE `V42_2 -> "OpenSUSE 42.2"
    |`OpenSUSE `V42_3 -> "OpenSUSE 42.3"
    |`OpenSUSE `V15_0 -> "OpenSUSE 15.0 (Leap)"
    |`OpenSUSE `V15_1 -> "OpenSUSE 15.1 (Leap)"
    |`OpenSUSE `V15_2 -> "OpenSUSE 15.2 (Leap)"
    |`OpenSUSE `V15_3 -> "OpenSUSE 15.3 (Leap)"
    |`Cygwin v -> "Cygwin " ^ (win10_release_to_string v)
    |`Windows (`Mingw, v) -> "Windows mingw " ^ (win10_release_to_string v)
    |`Windows (`Msvc, v) -> "Windows mingw " ^ (win10_release_to_string v)

let human_readable_short_string_of_distro (t:t) =
  match t with
  |`Ubuntu _ ->  "Ubuntu"
  |`Debian _ -> "Debian"
  |`CentOS _ -> "CentOS"
  |`Fedora _ -> "Fedora"
  |`OracleLinux _ -> "OracleLinux"
  |`Alpine _ -> "Alpine"
  |`Archlinux _ -> "Archlinux"
  |`OpenSUSE _ -> "OpenSUSE"
  |`Cygwin _ -> "Cygwin"
  |`Windows (`Mingw, _) -> "Windows mingw"
  |`Windows (`Msvc, _) -> "Windows mvsc"

let is_same_distro (d1:t) (d2:t) =
  match d1, d2 with
  | `Ubuntu _, `Ubuntu _ | `Debian _, `Debian _ | `CentOS _, `CentOS _
    | `Fedora _, `Fedora _ | `OracleLinux _, `OracleLinux _
    | `Alpine _, `Alpine _ | `Archlinux _, `Archlinux _
    | `OpenSUSE _, `OpenSUSE _ | `Cygwin _, `Cygwin _ -> true
  | `Windows (p1, _), `Windows (p2, _) when p1 = p2 -> true
  | _ -> false

(* The alias tag for the latest stable version of this distro *)
let latest_tag_of_distro (t:t) =
  let latest = List.find (is_same_distro t) latest_distros in
  tag_of_distro latest

type package_manager = [ `Apt | `Yum | `Apk | `Zypper | `Pacman | `Cygwin | `Windows ] [@@deriving sexp]

let package_manager (t:t) =
  match t with
  |`Ubuntu _ -> `Apt
  |`Debian _ -> `Apt
  |`CentOS _ -> `Yum
  |`Fedora _ -> `Yum
  |`OracleLinux _ -> `Yum
  |`Alpine _ -> `Apk
  |`Archlinux _ -> `Pacman
  |`OpenSUSE _ -> `Zypper
  |`Cygwin _ -> `Cygwin
  |`Windows _ -> `Windows

let rec bubblewrap_version (t:t) =
  match resolve_alias t with
  | `Ubuntu `V12_04 -> None
  | `Ubuntu `V14_04 -> None
  | `Ubuntu `V15_04 -> None
  | `Ubuntu `V15_10 -> None
  | `Ubuntu `V16_04 -> None
  | `Ubuntu `V16_10 -> None (* Not actually checked *)
  | `Ubuntu `V17_04 -> None (* Not actually checked *)
  | `Ubuntu `V17_10 -> None (* Not actually checked *)
  | `Ubuntu `V18_04 -> Some (0, 2, 1)
  | `Ubuntu `V18_10 -> Some (0, 2, 1) (* Not actually checked *)
  | `Ubuntu `V19_04 -> Some (0, 2, 1) (* Not actually checked *)
  | `Ubuntu `V19_10 -> Some (0, 2, 1) (* Not actually checked *)
  | `Ubuntu `V20_04 -> Some (0, 4, 0)
  | `Ubuntu `V20_10 -> Some (0, 4, 0) (* Not actually checked *)
  | `Ubuntu `V21_04 -> Some (0, 4, 1)
  | `Ubuntu `V21_10 -> Some (0, 4, 1)
  | `Ubuntu `V22_04 -> Some (0, 5, 0)
  | `Debian `V7 -> None (* Not actually checked *)
  | `Debian `V8 -> None (* Not actually checked *)
  | `Debian `V9 -> Some (0, 3, 1)
  | `Debian `V10 -> Some (0, 3, 1)
  | `Debian `V11 -> Some (0, 4, 1)
  | `Debian `Testing ->  Some (0, 5, 0)
  | `Debian `Unstable -> Some (0, 5, 0)
  | `CentOS `V6 -> None
  | `CentOS `V7 -> None
  | `CentOS `V8 -> Some (0, 4, 0)
  | `Fedora `V21 -> None (* Not actually checked *)
  | `Fedora `V22 -> None (* Not actually checked *)
  | `Fedora `V23 -> None (* Not actually checked *)
  | `Fedora `V24 -> None (* Not actually checked *)
  | `Fedora `V25 -> None (* Not actually checked *)
  | `Fedora `V26 -> Some (0, 2, 0)
  | `Fedora `V27 -> Some (0, 2, 1)
  | `Fedora `V28 -> Some (0, 3, 0)
  | `Fedora `V29 -> Some (0, 3, 1)
  | `Fedora `V30 -> Some (0, 3, 3)
  | `Fedora `V31 -> Some (0, 4, 1)
  | `Fedora `V32 -> Some (0, 4, 1)
  | `Fedora `V33 -> Some (0, 4, 1)
  | `Fedora `V34 -> Some (0, 4, 1)
  | `Fedora `V35 -> Some (0, 5, 0)
  | `OracleLinux (`V7|`V8 as v) -> bubblewrap_version (`CentOS v)
  | `Alpine `V3_3 -> None (* Not actually checked *)
  | `Alpine `V3_4 -> None (* Not actually checked *)
  | `Alpine `V3_5 -> None (* Not actually checked *)
  | `Alpine `V3_6 -> None (* Not actually checked *)
  | `Alpine `V3_7 -> None (* Not actually checked *)
  | `Alpine `V3_8 -> Some (0, 2, 0)
  | `Alpine `V3_9 -> Some (0, 3, 1)
  | `Alpine `V3_10 -> Some (0, 3, 3)
  | `Alpine `V3_11 -> Some (0, 4, 1)
  | `Alpine `V3_12 -> Some (0, 4, 1)
  | `Alpine `V3_13 -> Some (0, 4, 1)
  | `Alpine `V3_14 -> Some (0, 4, 1)
  | `Alpine `V3_15 -> Some (0, 5, 0)
  | `Archlinux `Latest -> Some (0, 5, 0)
  | `OpenSUSE `V42_1 -> None (* Not actually checked *)
  | `OpenSUSE `V42_2 -> None (* Not actually checked *)
  | `OpenSUSE `V42_3 -> None (* Not actually checked *)
  | `OpenSUSE `V15_0 -> Some (0, 2, 0)
  | `OpenSUSE `V15_1 -> Some (0, 3, 3)
  | `OpenSUSE `V15_2 -> Some (0, 4, 1)
  | `OpenSUSE `V15_3 -> Some (0, 4, 1)
  | `Cygwin _ -> None
  | `Windows _ -> None

let win10_base_tag ?win10_revision (base:win10_docker_base_image) v =
  let base, v = match base, resolve_ltsc v with
    | `NanoServer, _ -> "mcr.microsoft.com/windows/nanoserver", v
    | `ServerCore, _ -> "mcr.microsoft.com/windows/servercore", v
    | `Windows, `V21H2 -> "mcr.microsoft.com/windows/server", `Ltsc2022
    | `Windows, _ -> "mcr.microsoft.com/windows", v in
  base, win10_revision_to_string (v, win10_revision)

let base_distro_tag ?win10_revision ?(arch=`X86_64) d =
  match resolve_alias d with
  | `Alpine v -> begin
      let tag =
        match v with
        | `V3_3 -> "3.3"
        | `V3_4 -> "3.4"
        | `V3_5 -> "3.5"
        | `V3_6 -> "3.6"
        | `V3_7 -> "3.7"
        | `V3_8 -> "3.8"
        | `V3_9 -> "3.9"
        | `V3_10 -> "3.10"
        | `V3_11 -> "3.11"
        | `V3_12 -> "3.12"
        | `V3_13 -> "3.13"
        | `V3_14 -> "3.14"
        | `V3_15 -> "3.15"
      in
      match arch with
      | `I386 -> "i386/alpine", tag
      | _ -> "alpine", tag
    end
  | `Archlinux `Latest ->
      "archlinux", "latest"
  | `Debian v -> begin
      let tag =
        match v with
        | `V7 -> "7"
        | `V8 -> "8"
        | `V9 -> "9"
        | `V10 -> "10"
        | `V11 -> "11"
        | `Testing -> "testing"
        | `Unstable -> "unstable"
      in
      match arch with
      | `I386 -> "i386/debian", tag
      | `Aarch32 -> "arm32v7/debian", tag
      | _ -> "debian", tag
    end
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
        | `V19_04 -> "disco"
        | `V19_10 -> "eoan"
        | `V20_04 -> "focal"
        | `V20_10 -> "groovy"
        | `V21_04 -> "hirsute"
        | `V21_10 -> "impish"
        | `V22_04 -> "jammy"
      in
      "ubuntu", tag
  | `CentOS v ->
      let tag = match v with `V6 -> "6" | `V7 -> "7" | `V8 -> "8" in
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
        | `V29 -> "29"
        | `V30 -> "30"
        | `V31 -> "31"
        | `V32 -> "32"
        | `V33 -> "33"
        | `V34 -> "34"
        | `V35 -> "35"
      in
      "fedora", tag
  | `OracleLinux v ->
      let tag =
        match v with
        | `V7 -> "7"
        | `V8 -> "8" in
      "oraclelinux", tag
  | `OpenSUSE v ->
      let tag =
        match v with
        | `V42_1 -> "42.1"
        | `V42_2 -> "42.2"
        | `V42_3 -> "42.3"
        | `V15_0 -> "15.0"
        | `V15_1 -> "15.1"
        | `V15_2 -> "15.2"
        | `V15_3 -> "15.3"
      in
      "opensuse/leap", tag
  | `Cygwin v -> win10_base_tag ?win10_revision `ServerCore (v : win10_release :> [> win10_release])
  | `Windows (_, v) -> win10_base_tag ?win10_revision `Windows (v : win10_release :> [> win10_release])

let compare a b =
  String.compare (human_readable_string_of_distro a) (human_readable_string_of_distro b)
