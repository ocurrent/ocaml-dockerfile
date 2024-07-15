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

(** Distro selection for various OPAM combinations. *)

open Astring
open Sexplib.Conv

type distro =
  [ `Alpine of
    [ `V3_3
    | `V3_4
    | `V3_5
    | `V3_6
    | `V3_7
    | `V3_8
    | `V3_9
    | `V3_10
    | `V3_11
    | `V3_12
    | `V3_13
    | `V3_14
    | `V3_15
    | `V3_16
    | `V3_17
    | `V3_18
    | `V3_19
    | `V3_20 ]
  | `Archlinux of [ `Latest ]
  | `CentOS of [ `V6 | `V7 | `V8 ]
  | `Debian of [ `V12 | `V11 | `V10 | `V9 | `V8 | `V7 | `Testing | `Unstable ]
  | `Fedora of
    [ `V21
    | `V22
    | `V23
    | `V24
    | `V25
    | `V26
    | `V27
    | `V28
    | `V29
    | `V30
    | `V31
    | `V32
    | `V33
    | `V34
    | `V35
    | `V36
    | `V37
    | `V38
    | `V39
    | `V40 ]
  | `OracleLinux of [ `V7 | `V8 | `V9 ]
  | `OpenSUSE of
    [ `V42_1
    | `V42_2
    | `V42_3
    | `V15_0
    | `V15_1
    | `V15_2
    | `V15_3
    | `V15_4
    | `V15_5
    | `V15_6
    | `Tumbleweed ]
  | `Ubuntu of
    [ `V12_04
    | `V14_04
    | `V15_04
    | `V15_10
    | `V16_04
    | `V16_10
    | `V17_04
    | `V17_10
    | `V18_04
    | `V18_10
    | `V19_04
    | `V19_10
    | `V20_04
    | `V20_10
    | `V21_04
    | `V21_10
    | `V22_04
    | `V22_10
    | `V23_04
    | `V23_10
    | `V24_04 ]
  | `Cygwin of [ `Ltsc2016 | `Ltsc2019 | `Ltsc2022 ]
  | `Windows of [ `Mingw | `Msvc ] * [ `Ltsc2019 ]
  | `WindowsServer of [ `Mingw | `Msvc ] * [ `Ltsc2022 ] ]
[@@deriving sexp]

type t =
  [ `Alpine of
    [ `V3_3
    | `V3_4
    | `V3_5
    | `V3_6
    | `V3_7
    | `V3_8
    | `V3_9
    | `V3_10
    | `V3_11
    | `V3_12
    | `V3_13
    | `V3_14
    | `V3_15
    | `V3_16
    | `V3_17
    | `V3_18
    | `V3_19
    | `V3_20
    | `Latest ]
  | `Archlinux of [ `Latest ]
  | `CentOS of [ `V6 | `V7 | `V8 | `Latest ]
  | `Debian of
    [ `V12 | `V11 | `V10 | `V9 | `V8 | `V7 | `Stable | `Testing | `Unstable ]
  | `Fedora of
    [ `V21
    | `V22
    | `V23
    | `V24
    | `V25
    | `V26
    | `V27
    | `V28
    | `V29
    | `V30
    | `V31
    | `V32
    | `V33
    | `V34
    | `V35
    | `V36
    | `V37
    | `V38
    | `V39
    | `V40
    | `Latest ]
  | `OracleLinux of [ `V7 | `V8 | `V9 | `Latest ]
  | `OpenSUSE of
    [ `V42_1
    | `V42_2
    | `V42_3
    | `V15_0
    | `V15_1
    | `V15_2
    | `V15_3
    | `V15_4
    | `V15_5
    | `V15_6
    | `Tumbleweed
    | `Latest ]
  | `Ubuntu of
    [ `V12_04
    | `V14_04
    | `V15_04
    | `V15_10
    | `V16_04
    | `V16_10
    | `V17_04
    | `V17_10
    | `V18_04
    | `V18_10
    | `V19_04
    | `V19_10
    | `V20_04
    | `V20_10
    | `V21_04
    | `V21_10
    | `V22_04
    | `V22_10
    | `V23_04
    | `V23_10
    | `V24_04
    | `Latest
    | `LTS ]
  | `Cygwin of [ `Ltsc2016 | `Ltsc2019 | `Ltsc2022 | `Latest ]
  | `Windows of [ `Mingw | `Msvc ] * [ `Ltsc2019 | `Latest ]
  | `WindowsServer of [ `Mingw | `Msvc ] * [ `Ltsc2022 | `Latest ] ]
[@@deriving sexp]

type os_family = [ `Cygwin | `Linux | `Windows ] [@@deriving sexp]

let os_family_of_distro (t : t) : os_family =
  match t with
  | `Alpine _ | `Archlinux _ | `CentOS _ | `Debian _ | `Fedora _
  | `OracleLinux _ | `OpenSUSE _ | `Ubuntu _ ->
      `Linux
  | `Cygwin _ -> `Cygwin
  | `Windows _ -> `Windows
  | `WindowsServer _ -> `Windows

let os_family_to_string (os : os_family) =
  match os with
  | `Linux -> "linux"
  | `Windows -> "windows"
  | `Cygwin -> "cygwin"

let opam_repository (os : os_family) =
  match os with
  | `Cygwin | `Linux -> "https://github.com/ocaml/opam-repository.git"
  | `Windows -> "https://github.com/ocaml-opam/opam-repository-mingw.git#sunset"

let personality os_family arch =
  match os_family with
  | `Linux when Ocaml_version.arch_is_32bit arch -> Some "/usr/bin/linux32"
  | _ -> None

type status =
  [ `Deprecated
  | `Active of [ `Tier1 | `Tier2 | `Tier3 ]
  | `Alias
  | `Not_available ]
[@@deriving sexp]

let distros : t list =
  [
    `Alpine `V3_3;
    `Alpine `V3_4;
    `Alpine `V3_5;
    `Alpine `V3_6;
    `Alpine `V3_7;
    `Alpine `V3_8;
    `Alpine `V3_9;
    `Alpine `V3_10;
    `Alpine `V3_11;
    `Alpine `V3_12;
    `Alpine `V3_13;
    `Alpine `V3_14;
    `Alpine `V3_15;
    `Alpine `V3_16;
    `Alpine `V3_17;
    `Alpine `V3_18;
    `Alpine `V3_19;
    `Alpine `V3_20;
    `Alpine `Latest;
    `Archlinux `Latest;
    `CentOS `V6;
    `CentOS `V7;
    `CentOS `V8;
    `CentOS `Latest;
    `Debian `V12;
    `Debian `V11;
    `Debian `V10;
    `Debian `V9;
    `Debian `V8;
    `Debian `V7;
    `Debian `Stable;
    `Debian `Testing;
    `Debian `Unstable;
    `Fedora `V23;
    `Fedora `V24;
    `Fedora `V25;
    `Fedora `V26;
    `Fedora `V27;
    `Fedora `V28;
    `Fedora `V29;
    `Fedora `V30;
    `Fedora `V31;
    `Fedora `V32;
    `Fedora `V33;
    `Fedora `V34;
    `Fedora `V35;
    `Fedora `V36;
    `Fedora `V37;
    `Fedora `V38;
    `Fedora `V39;
    `Fedora `V40;
    `Fedora `Latest;
    `OracleLinux `V7;
    `OracleLinux `V8;
    `OracleLinux `V9;
    `OracleLinux `Latest;
    `OpenSUSE `V42_1;
    `OpenSUSE `V42_2;
    `OpenSUSE `V42_3;
    `OpenSUSE `V15_0;
    `OpenSUSE `V15_1;
    `OpenSUSE `V15_2;
    `OpenSUSE `V15_3;
    `OpenSUSE `V15_4;
    `OpenSUSE `V15_5;
    `OpenSUSE `V15_6;
    `OpenSUSE `Tumbleweed;
    `OpenSUSE `Latest;
    `Ubuntu `V12_04;
    `Ubuntu `V14_04;
    `Ubuntu `V15_04;
    `Ubuntu `V15_10;
    `Ubuntu `V16_04;
    `Ubuntu `V16_10;
    `Ubuntu `V17_04;
    `Ubuntu `V17_10;
    `Ubuntu `V18_04;
    `Ubuntu `V18_10;
    `Ubuntu `V19_04;
    `Ubuntu `V19_10;
    `Ubuntu `V20_04;
    `Ubuntu `V20_10;
    `Ubuntu `V21_04;
    `Ubuntu `V21_10;
    `Ubuntu `V22_04;
    `Ubuntu `V22_10;
    `Ubuntu `V23_04;
    `Ubuntu `V23_10;
    `Ubuntu `V24_04;
    `Ubuntu `Latest;
    `Ubuntu `LTS;
    `Cygwin `Ltsc2016;
    `Cygwin `Ltsc2019;
    `Cygwin `Ltsc2022;
    `Cygwin `Latest;
    `Windows (`Mingw, `Ltsc2019);
    `Windows (`Mingw, `Latest);
    `Windows (`Msvc, `Ltsc2019);
    `Windows (`Msvc, `Latest);
    `WindowsServer (`Mingw, `Ltsc2022);
    `WindowsServer (`Mingw, `Latest);
    `WindowsServer (`Msvc, `Ltsc2022);
    `WindowsServer (`Msvc, `Latest);
  ]

let resolve_alias (d : t) : distro =
  match d with
  | `Alpine `Latest -> `Alpine `V3_20
  | `CentOS `Latest -> `CentOS `V7
  | `Debian `Stable -> `Debian `V12
  | `Fedora `Latest -> `Fedora `V40
  | `OracleLinux `Latest -> `OracleLinux `V9
  | `OpenSUSE `Latest -> `OpenSUSE `V15_6
  | `Ubuntu `Latest -> `Ubuntu `V24_04
  | `Ubuntu `LTS -> `Ubuntu `V24_04
  | `Cygwin `Latest -> `Cygwin `Ltsc2022
  | `Windows (cc, `Latest) -> `Windows (cc, `Ltsc2019)
  | `WindowsServer (cc, `Latest) -> `WindowsServer (cc, `Ltsc2022)
  | ( `Alpine
        ( `V3_3 | `V3_4 | `V3_5 | `V3_6 | `V3_7 | `V3_8 | `V3_9 | `V3_10
        | `V3_11 | `V3_12 | `V3_13 | `V3_14 | `V3_15 | `V3_16 | `V3_17 | `V3_18
        | `V3_19 | `V3_20 )
    | `Archlinux `Latest
    | `CentOS (`V6 | `V7 | `V8)
    | `Debian (`V7 | `V8 | `V9 | `V10 | `V11 | `V12 | `Testing | `Unstable)
    | `Fedora
        ( `V21 | `V22 | `V23 | `V24 | `V25 | `V26 | `V27 | `V28 | `V29 | `V30
        | `V31 | `V32 | `V33 | `V34 | `V35 | `V36 | `V37 | `V38 | `V39 | `V40 )
    | `OracleLinux (`V7 | `V8 | `V9)
    | `OpenSUSE
        ( `V42_1 | `V42_2 | `V42_3 | `V15_0 | `V15_1 | `V15_2 | `V15_3 | `V15_4
        | `V15_5 | `V15_6 | `Tumbleweed )
    | `Ubuntu
        ( `V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 | `V16_10 | `V17_04
        | `V17_10 | `V18_04 | `V18_10 | `V19_04 | `V19_10 | `V20_04 | `V20_10
        | `V21_04 | `V21_10 | `V22_04 | `V22_10 | `V23_04 | `V23_10 | `V24_04 )
    | `Cygwin (`Ltsc2016 | `Ltsc2019 | `Ltsc2022)
    | `Windows (_, `Ltsc2019)
    | `WindowsServer (_, `Ltsc2022) ) as d ->
      d

let distro_status (d : t) : status =
  let resolved = resolve_alias d in
  if (resolved : distro :> t) <> d then `Alias
  else
    match resolve_alias d with
    | `Alpine
        ( `V3_3 | `V3_4 | `V3_5 | `V3_6 | `V3_7 | `V3_8 | `V3_9 | `V3_10
        | `V3_11 | `V3_12 | `V3_13 | `V3_14 | `V3_15 | `V3_16 | `V3_17 | `V3_18
        | `V3_19 ) ->
        `Deprecated
    | `Alpine `V3_20 -> `Active `Tier1
    | `Archlinux `Latest -> `Active `Tier3
    | `CentOS `V7 -> `Active `Tier3
    | `CentOS (`V6 | `V8) -> `Deprecated
    | `Debian (`V7 | `V8 | `V9 | `V10) -> `Deprecated
    | `Debian `V11 -> `Active `Tier2
    | `Debian `V12 -> `Active `Tier1
    | `Debian `Testing -> `Active `Tier3
    | `Debian `Unstable -> `Active `Tier3
    | `Fedora
        ( `V21 | `V22 | `V23 | `V24 | `V25 | `V26 | `V27 | `V28 | `V29 | `V30
        | `V31 | `V32 | `V33 | `V34 | `V35 | `V36 | `V37 | `V38 ) ->
        `Deprecated
    | `Fedora (`V39 | `V40) -> `Active `Tier2
    | `OracleLinux `V7 -> `Deprecated
    | `OracleLinux (`V8 | `V9) -> `Active `Tier3
    | `OpenSUSE
        ( `V42_1 | `V42_2 | `V42_3 | `V15_0 | `V15_1 | `V15_2 | `V15_3 | `V15_4
        | `V15_5 ) ->
        `Deprecated
    | `OpenSUSE `V15_6 -> `Active `Tier2
    | `OpenSUSE `Tumbleweed -> `Active `Tier2
    | `Ubuntu (`V20_04 | `V22_04 | `V24_04) -> `Active `Tier2
    | `Ubuntu
        ( `V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 | `V16_10 | `V17_04
        | `V17_10 | `V18_04 | `V18_10 | `V19_04 | `V19_10 | `V20_10 | `V21_04
        | `V21_10 | `V22_10 | `V23_04 | `V23_10 ) ->
        `Deprecated
    | `Cygwin (`Ltsc2016 | `Ltsc2019) -> `Deprecated
    | `Cygwin `Ltsc2022 -> `Active `Tier3
    | `Windows (_, `Ltsc2019) -> `Active `Tier3
    | `WindowsServer (_, `Ltsc2022) -> `Active `Tier3

let latest_distros =
  [
    `Alpine `Latest;
    `Archlinux `Latest;
    `CentOS `Latest;
    `Debian `Stable;
    `OracleLinux `Latest;
    `OpenSUSE `Latest;
    `OpenSUSE `Tumbleweed;
    `Fedora `Latest;
    `Ubuntu `Latest;
    `Ubuntu `LTS;
    `Cygwin `Latest;
    `Windows (`Mingw, `Latest);
    `Windows (`Msvc, `Latest);
    `WindowsServer (`Mingw, `Latest);
    `WindowsServer (`Msvc, `Latest);
  ]

let master_distro = `Debian `Stable

module OV = Ocaml_version

let distro_arches ov (d : t) =
  match (resolve_alias d, ov) with
  | (`CentOS (`V6 | `V7) | `OracleLinux `V7), ov when OV.major ov >= 5 -> []
  | `Debian (`V11 | `V12), ov when OV.(compare Releases.v4_03_0 ov) = -1 ->
      [ `I386; `X86_64; `Aarch64; `Aarch32; `Ppc64le; `S390x ]
  | `Debian (`V11 | `V12), ov when OV.(compare Releases.v4_02_0 ov) = -1 ->
      [ `I386; `X86_64; `Aarch64; `Aarch32 ]
  | `Debian `V10, ov when OV.(compare Releases.v4_03_0 ov) = -1 ->
      [ `I386; `X86_64; `Aarch64; `Aarch32 ]
  | `Debian `V10, ov when OV.(compare Releases.v4_02_0 ov) = -1 ->
      [ `I386; `X86_64; `Aarch64; `Aarch32 ]
  | `Debian `V9, ov when OV.(compare Releases.v4_03_0 ov) = -1 ->
      [ `I386; `X86_64; `Aarch64; `Aarch32 ]
  | ( `Alpine
        ( `V3_6 | `V3_7 | `V3_8 | `V3_9 | `V3_10 | `V3_11 | `V3_12 | `V3_13
        | `V3_14 | `V3_15 | `V3_16 | `V3_17 | `V3_18 | `V3_19 | `V3_20 ),
      ov )
    when OV.(compare Releases.v4_05_0 ov) = -1 ->
      [ `X86_64; `Aarch64 ]
  | `Ubuntu `V18_04, ov when OV.(compare Releases.v4_05_0 ov) = -1 ->
      [ `X86_64; `Aarch64; `Ppc64le; `S390x ]
  | ( `Ubuntu
        ( `V20_04 | `V20_10 | `V21_04 | `V21_10 | `V22_04 | `V22_10 | `V23_04
        | `V23_10 | `V24_04 ),
      ov )
    when OV.(compare Releases.v4_05_0 ov) = -1 ->
      let base = [ `X86_64; `Aarch64; `Ppc64le; `S390x ] in
      if OV.(compare Releases.v4_11_0 ov) <= 0 then `Riscv64 :: base else base
  | `Fedora (`V33 | `V34 | `V35 | `V36 | `V37 | `V38 | `V39 | `V40), ov
    when OV.(compare Releases.v4_08_0 ov) = -1 ->
      [ `X86_64; `Aarch64 ]
  | `OpenSUSE (`V15_4 | `V15_5 | `V15_6), ov
    when OV.(compare Releases.v4_02_0 ov) = -1 ->
      [ `X86_64; `Aarch64 ]
  (* OCaml for Windows doesn't package OCaml 5.0.
     TODO: remove when upstream opam gains OCaml packages on Windows. *)
  | (`Windows (`Mingw, _), ov | `WindowsServer (`Mingw, _), ov)
    when OV.major ov >= 5 ->
      []
  (* OCaml 5 doesn't support MSVC: https://github.com/ocaml/ocaml/pull/11835. *)
  | (`Windows (`Msvc, _), ov | `WindowsServer (`Msvc, _), ov)
    when OV.major ov >= 5 ->
      []
  (* 2021-04-19: should be 4.03 but there's a linking failure until 4.06. *)
  | (`Windows (`Msvc, _), ov | `WindowsServer (`Msvc, _), ov)
    when OV.(compare Releases.v4_06_0 ov) = 1 ->
      []
  | _ -> [ `X86_64 ]

let distro_supported_on a ov (d : t) = List.mem a (distro_arches ov d)

let distro_active_for arch (d : t) =
  match (arch, d) with
  | `X86_64, `Windows _ | `X86_64, `WindowsServer _ -> true
  | _ -> distro_supported_on arch OV.Releases.latest d

let active_distros arch =
  List.filter
    (fun d -> match distro_status d with `Active _ -> true | _ -> false)
    distros
  |> List.filter (distro_active_for arch)

let active_tier1_distros arch =
  List.filter
    (fun d -> match distro_status d with `Active `Tier1 -> true | _ -> false)
    distros
  |> List.filter (distro_active_for arch)

let active_tier2_distros arch =
  List.filter
    (fun d -> match distro_status d with `Active `Tier2 -> true | _ -> false)
    distros
  |> List.filter (distro_active_for arch)

let active_tier3_distros arch =
  List.filter
    (fun d -> match distro_status d with `Active `Tier3 -> true | _ -> false)
    distros
  |> List.filter (distro_active_for arch)

(* The distro-supplied version of OCaml *)
let builtin_ocaml_of_distro (d : t) : string option =
  match resolve_alias d with
  | `Debian `V7 -> Some "3.12.1"
  | `Debian `V8 -> Some "4.01.0"
  | `Debian `V9 -> Some "4.02.3"
  | `Debian `V10 -> Some "4.05.0"
  | `Debian `V11 -> Some "4.11.1"
  | `Debian `V12 -> Some "4.13.1"
  | `Ubuntu `V12_04 -> Some "3.12.1"
  | `Ubuntu `V14_04 -> Some "4.01.0"
  | `Ubuntu `V15_04 -> Some "4.01.0"
  | `Ubuntu `V15_10 -> Some "4.01.0"
  | `Ubuntu `V16_04 -> Some "4.02.3"
  | `Ubuntu `V16_10 -> Some "4.02.3"
  | `Ubuntu `V17_04 -> Some "4.02.3"
  | `Ubuntu `V17_10 -> Some "4.04.0"
  | `Ubuntu `V18_04 -> Some "4.05.0"
  | `Ubuntu `V18_10 -> Some "4.05.0"
  | `Ubuntu `V19_04 -> Some "4.05.0"
  | `Ubuntu `V19_10 -> Some "4.05.0"
  | `Ubuntu `V20_04 -> Some "4.08.1"
  | `Ubuntu `V20_10 -> Some "4.08.1"
  | `Ubuntu `V21_04 -> Some "4.11.1"
  | `Ubuntu `V21_10 -> Some "4.11.1"
  | `Ubuntu `V22_04 -> Some "4.13.1"
  | `Ubuntu `V22_10 -> Some "4.13.1"
  | `Ubuntu `V23_04 -> Some "4.13.1"
  | `Ubuntu `V23_10 -> Some "4.13.1"
  | `Ubuntu `V24_04 -> Some "4.14.1"
  | `Alpine `V3_3 -> Some "4.02.3"
  | `Alpine `V3_4 -> Some "4.02.3"
  | `Alpine `V3_5 -> Some "4.04.0"
  | `Alpine `V3_6 -> Some "4.04.1"
  | `Alpine `V3_7 -> Some "4.04.2"
  | `Alpine `V3_8 -> Some "4.06.1"
  | `Alpine `V3_9 -> Some "4.06.1"
  | `Alpine `V3_10 -> Some "4.07.0"
  | `Alpine `V3_11 -> Some "4.08.1"
  | `Alpine `V3_12 -> Some "4.08.1"
  | `Alpine `V3_13 -> Some "4.08.1"
  | `Alpine `V3_14 -> Some "4.12.0"
  | `Alpine `V3_15 -> Some "4.13.1"
  | `Alpine `V3_16 -> Some "4.14.0"
  | `Alpine `V3_17 -> Some "4.14.0"
  | `Alpine `V3_18 -> Some "4.14.1"
  | `Alpine `V3_19 -> Some "4.14.1"
  | `Alpine `V3_20 -> Some "4.14.2"
  | `Archlinux `Latest -> Some "5.1.0"
  | `Fedora `V21 -> Some "4.01.0"
  | `Fedora `V22 -> Some "4.02.0"
  | `Fedora `V23 -> Some "4.02.2"
  | `Fedora `V24 -> Some "4.02.3"
  | `Fedora `V25 -> Some "4.02.3"
  | `Fedora `V26 -> Some "4.04.0"
  | `Fedora `V27 -> Some "4.05.0"
  | `Fedora `V28 -> Some "4.06.0"
  | `Fedora `V29 -> Some "4.07.0"
  | `Fedora `V30 -> Some "4.07.0"
  | `Fedora `V31 -> Some "4.08.1"
  | `Fedora `V32 -> Some "4.10.0"
  | `Fedora `V33 -> Some "4.11.1"
  | `Fedora `V34 -> Some "4.11.1"
  | `Fedora `V35 -> Some "4.12.0"
  | `Fedora `V36 -> Some "4.13.1"
  | `Fedora `V37 -> Some "4.13.1"
  | `Fedora `V38 -> Some "4.14.0"
  | `Fedora `V39 -> Some "5.0.0"
  | `Fedora `V40 -> Some "5.1.1"
  | `CentOS `V6 -> Some "3.11.2"
  | `CentOS `V7 -> Some "4.01.0"
  | `CentOS `V8 -> Some "4.07.0"
  | `OpenSUSE `V42_1 -> Some "4.02.3"
  | `OpenSUSE `V42_2 -> Some "4.03.0"
  | `OpenSUSE `V42_3 -> Some "4.03.0"
  | `OpenSUSE `V15_0 -> Some "4.05.0"
  | `OpenSUSE `V15_1 -> Some "4.05.0"
  | `OpenSUSE `V15_2 -> Some "4.05.0"
  | `OpenSUSE `V15_3 -> Some "4.05.0"
  | `OpenSUSE `V15_4 -> Some "4.05.0"
  | `OpenSUSE `V15_5 -> Some "4.05.0"
  | `OpenSUSE `V15_6 -> Some "4.14.2"
  | `OpenSUSE `Tumbleweed -> Some "4.14.1"
  | `OracleLinux `V7 -> Some "4.01.0"
  | `OracleLinux `V8 -> Some "4.07.0"
  | `OracleLinux `V9 -> Some "4.11.1"
  | `Cygwin _ -> None
  | `Windows _ -> None
  | `WindowsServer _ -> None
  | `Debian (`Testing | `Unstable) -> assert false

(* The Docker tag for this distro *)
let tag_of_distro (d : t) =
  match d with
  | `Ubuntu `V12_04 -> "ubuntu-12.04"
  | `Ubuntu `V14_04 -> "ubuntu-14.04"
  | `Ubuntu `V15_04 -> "ubuntu-15.04"
  | `Ubuntu `V15_10 -> "ubuntu-15.10"
  | `Ubuntu `V16_04 -> "ubuntu-16.04"
  | `Ubuntu `V16_10 -> "ubuntu-16.10"
  | `Ubuntu `V17_04 -> "ubuntu-17.04"
  | `Ubuntu `V17_10 -> "ubuntu-17.10"
  | `Ubuntu `V18_04 -> "ubuntu-18.04"
  | `Ubuntu `V18_10 -> "ubuntu-18.10"
  | `Ubuntu `V19_04 -> "ubuntu-19.04"
  | `Ubuntu `V19_10 -> "ubuntu-19.10"
  | `Ubuntu `V20_04 -> "ubuntu-20.04"
  | `Ubuntu `V20_10 -> "ubuntu-20.10"
  | `Ubuntu `V21_04 -> "ubuntu-21.04"
  | `Ubuntu `V21_10 -> "ubuntu-21.10"
  | `Ubuntu `V22_04 -> "ubuntu-22.04"
  | `Ubuntu `V22_10 -> "ubuntu-22.10"
  | `Ubuntu `V23_04 -> "ubuntu-23.04"
  | `Ubuntu `V23_10 -> "ubuntu-23.10"
  | `Ubuntu `V24_04 -> "ubuntu-24.04"
  | `Ubuntu `Latest -> "ubuntu"
  | `Ubuntu `LTS -> "ubuntu-lts"
  | `Debian `Stable -> "debian-stable"
  | `Debian `Unstable -> "debian-unstable"
  | `Debian `Testing -> "debian-testing"
  | `Debian `V12 -> "debian-12"
  | `Debian `V11 -> "debian-11"
  | `Debian `V10 -> "debian-10"
  | `Debian `V9 -> "debian-9"
  | `Debian `V8 -> "debian-8"
  | `Debian `V7 -> "debian-7"
  | `CentOS `V6 -> "centos-6"
  | `CentOS `V7 -> "centos-7"
  | `CentOS `V8 -> "centos-8"
  | `CentOS `Latest -> "centos"
  | `Fedora `Latest -> "fedora"
  | `Fedora `V21 -> "fedora-21"
  | `Fedora `V22 -> "fedora-22"
  | `Fedora `V23 -> "fedora-23"
  | `Fedora `V24 -> "fedora-24"
  | `Fedora `V25 -> "fedora-25"
  | `Fedora `V26 -> "fedora-26"
  | `Fedora `V27 -> "fedora-27"
  | `Fedora `V28 -> "fedora-28"
  | `Fedora `V29 -> "fedora-29"
  | `Fedora `V30 -> "fedora-30"
  | `Fedora `V31 -> "fedora-31"
  | `Fedora `V32 -> "fedora-32"
  | `Fedora `V33 -> "fedora-33"
  | `Fedora `V34 -> "fedora-34"
  | `Fedora `V35 -> "fedora-35"
  | `Fedora `V36 -> "fedora-36"
  | `Fedora `V37 -> "fedora-37"
  | `Fedora `V38 -> "fedora-38"
  | `Fedora `V39 -> "fedora-39"
  | `Fedora `V40 -> "fedora-40"
  | `OracleLinux `V7 -> "oraclelinux-7"
  | `OracleLinux `V8 -> "oraclelinux-8"
  | `OracleLinux `V9 -> "oraclelinux-9"
  | `OracleLinux `Latest -> "oraclelinux"
  | `Alpine `V3_3 -> "alpine-3.3"
  | `Alpine `V3_4 -> "alpine-3.4"
  | `Alpine `V3_5 -> "alpine-3.5"
  | `Alpine `V3_6 -> "alpine-3.6"
  | `Alpine `V3_7 -> "alpine-3.7"
  | `Alpine `V3_8 -> "alpine-3.8"
  | `Alpine `V3_9 -> "alpine-3.9"
  | `Alpine `V3_10 -> "alpine-3.10"
  | `Alpine `V3_11 -> "alpine-3.11"
  | `Alpine `V3_12 -> "alpine-3.12"
  | `Alpine `V3_13 -> "alpine-3.13"
  | `Alpine `V3_14 -> "alpine-3.14"
  | `Alpine `V3_15 -> "alpine-3.15"
  | `Alpine `V3_16 -> "alpine-3.16"
  | `Alpine `V3_17 -> "alpine-3.17"
  | `Alpine `V3_18 -> "alpine-3.18"
  | `Alpine `V3_19 -> "alpine-3.19"
  | `Alpine `V3_20 -> "alpine-3.20"
  | `Alpine `Latest -> "alpine"
  | `Archlinux `Latest -> "archlinux"
  | `OpenSUSE `V42_1 -> "opensuse-42.1"
  | `OpenSUSE `V42_2 -> "opensuse-42.2"
  | `OpenSUSE `V42_3 -> "opensuse-42.3"
  | `OpenSUSE `V15_0 -> "opensuse-15.0"
  | `OpenSUSE `V15_1 -> "opensuse-15.1"
  | `OpenSUSE `V15_2 -> "opensuse-15.2"
  | `OpenSUSE `V15_3 -> "opensuse-15.3"
  | `OpenSUSE `V15_4 -> "opensuse-15.4"
  | `OpenSUSE `V15_5 -> "opensuse-15.5"
  | `OpenSUSE `V15_6 -> "opensuse-15.6"
  | `OpenSUSE `Tumbleweed -> "opensuse-tumbleweed"
  | `OpenSUSE `Latest -> "opensuse"
  | `Cygwin `Ltsc2016 -> "cygwin-2016"
  | `Cygwin `Ltsc2019 -> "cygwin-2019"
  | `Cygwin `Ltsc2022 -> "cygwin-2022"
  | `Cygwin `Latest -> "cygwin"
  | `Windows (`Mingw, `Ltsc2019) -> "windows-mingw-ltsc2019"
  | `Windows (`Mingw, `Latest) -> "windows-mingw"
  | `Windows (`Msvc, `Ltsc2019) -> "windows-msvc-ltsc2019"
  | `Windows (`Msvc, `Latest) -> "windows-msvc"
  | `WindowsServer (`Mingw, `Ltsc2022) -> "windows-server-mingw-ltsc2022"
  | `WindowsServer (`Mingw, `Latest) -> "windows-server-mingw"
  | `WindowsServer (`Msvc, `Ltsc2022) -> "windows-server-msvc-ltsc2022"
  | `WindowsServer (`Msvc, `Latest) -> "windows-server-msvc"

let distro_of_tag x : t option =
  match x with
  | "ubuntu-12.04" -> Some (`Ubuntu `V12_04)
  | "ubuntu-14.04" -> Some (`Ubuntu `V14_04)
  | "ubuntu-15.04" -> Some (`Ubuntu `V15_04)
  | "ubuntu-15.10" -> Some (`Ubuntu `V15_10)
  | "ubuntu-16.04" -> Some (`Ubuntu `V16_04)
  | "ubuntu-16.10" -> Some (`Ubuntu `V16_10)
  | "ubuntu-17.04" -> Some (`Ubuntu `V17_04)
  | "ubuntu-17.10" -> Some (`Ubuntu `V17_10)
  | "ubuntu-18.04" -> Some (`Ubuntu `V18_04)
  | "ubuntu-18.10" -> Some (`Ubuntu `V18_10)
  | "ubuntu-19.04" -> Some (`Ubuntu `V19_04)
  | "ubuntu-19.10" -> Some (`Ubuntu `V19_10)
  | "ubuntu-20.04" -> Some (`Ubuntu `V20_04)
  | "ubuntu-20.10" -> Some (`Ubuntu `V20_10)
  | "ubuntu-21.04" -> Some (`Ubuntu `V21_04)
  | "ubuntu-21.10" -> Some (`Ubuntu `V21_10)
  | "ubuntu-22.04" -> Some (`Ubuntu `V22_04)
  | "ubuntu-22.10" -> Some (`Ubuntu `V22_10)
  | "ubuntu-23.04" -> Some (`Ubuntu `V23_04)
  | "ubuntu-23.10" -> Some (`Ubuntu `V23_10)
  | "ubuntu-24.04" -> Some (`Ubuntu `V24_04)
  | "ubuntu" -> Some (`Ubuntu `Latest)
  | "ubuntu-lts" -> Some (`Ubuntu `LTS)
  | "debian-stable" -> Some (`Debian `Stable)
  | "debian-unstable" -> Some (`Debian `Unstable)
  | "debian-testing" -> Some (`Debian `Testing)
  | "debian-12" -> Some (`Debian `V12)
  | "debian-11" -> Some (`Debian `V11)
  | "debian-10" -> Some (`Debian `V10)
  | "debian-9" -> Some (`Debian `V9)
  | "debian-8" -> Some (`Debian `V8)
  | "debian-7" -> Some (`Debian `V7)
  | "centos-6" -> Some (`CentOS `V6)
  | "centos-7" -> Some (`CentOS `V7)
  | "centos-8" -> Some (`CentOS `V8)
  | "fedora-21" -> Some (`Fedora `V21)
  | "fedora-22" -> Some (`Fedora `V22)
  | "fedora-23" -> Some (`Fedora `V23)
  | "fedora-24" -> Some (`Fedora `V24)
  | "fedora-25" -> Some (`Fedora `V25)
  | "fedora-26" -> Some (`Fedora `V26)
  | "fedora-27" -> Some (`Fedora `V27)
  | "fedora-28" -> Some (`Fedora `V28)
  | "fedora-29" -> Some (`Fedora `V29)
  | "fedora-30" -> Some (`Fedora `V30)
  | "fedora-31" -> Some (`Fedora `V31)
  | "fedora-32" -> Some (`Fedora `V32)
  | "fedora-33" -> Some (`Fedora `V33)
  | "fedora-34" -> Some (`Fedora `V34)
  | "fedora-35" -> Some (`Fedora `V35)
  | "fedora-36" -> Some (`Fedora `V36)
  | "fedora-37" -> Some (`Fedora `V37)
  | "fedora-38" -> Some (`Fedora `V38)
  | "fedora-39" -> Some (`Fedora `V39)
  | "fedora-40" -> Some (`Fedora `V40)
  | "fedora" -> Some (`Fedora `Latest)
  | "oraclelinux-7" -> Some (`OracleLinux `V7)
  | "oraclelinux-8" -> Some (`OracleLinux `V8)
  | "oraclelinux-9" -> Some (`OracleLinux `V9)
  | "oraclelinux" -> Some (`OracleLinux `Latest)
  | "alpine-3.3" -> Some (`Alpine `V3_3)
  | "alpine-3.4" -> Some (`Alpine `V3_4)
  | "alpine-3.5" -> Some (`Alpine `V3_5)
  | "alpine-3.6" -> Some (`Alpine `V3_6)
  | "alpine-3.7" -> Some (`Alpine `V3_7)
  | "alpine-3.8" -> Some (`Alpine `V3_8)
  | "alpine-3.9" -> Some (`Alpine `V3_9)
  | "alpine-3.10" -> Some (`Alpine `V3_10)
  | "alpine-3.11" -> Some (`Alpine `V3_11)
  | "alpine-3.12" -> Some (`Alpine `V3_12)
  | "alpine-3.13" -> Some (`Alpine `V3_13)
  | "alpine-3.14" -> Some (`Alpine `V3_14)
  | "alpine-3.15" -> Some (`Alpine `V3_15)
  | "alpine-3.16" -> Some (`Alpine `V3_16)
  | "alpine-3.17" -> Some (`Alpine `V3_17)
  | "alpine-3.18" -> Some (`Alpine `V3_18)
  | "alpine-3.19" -> Some (`Alpine `V3_19)
  | "alpine-3.20" -> Some (`Alpine `V3_20)
  | "alpine" -> Some (`Alpine `Latest)
  | "archlinux" -> Some (`Archlinux `Latest)
  | "opensuse-42.1" -> Some (`OpenSUSE `V42_1)
  | "opensuse-42.2" -> Some (`OpenSUSE `V42_2)
  | "opensuse-42.3" -> Some (`OpenSUSE `V42_3)
  | "opensuse-15.0" -> Some (`OpenSUSE `V15_0)
  | "opensuse-15.1" -> Some (`OpenSUSE `V15_1)
  | "opensuse-15.2" -> Some (`OpenSUSE `V15_2)
  | "opensuse-15.3" -> Some (`OpenSUSE `V15_3)
  | "opensuse-15.4" -> Some (`OpenSUSE `V15_4)
  | "opensuse-15.5" -> Some (`OpenSUSE `V15_5)
  | "opensuse-15.6" -> Some (`OpenSUSE `V15_6)
  | "opensuse-tumbleweed" -> Some (`OpenSUSE `Tumbleweed)
  | "opensuse" -> Some (`OpenSUSE `Latest)
  | "cygwin-ltsc2016" -> Some (`Cygwin `Ltsc2016)
  | "cygwin-ltsc2019" -> Some (`Cygwin `Ltsc2019)
  | "cygwin-ltsc2022" -> Some (`Cygwin `Ltsc2022)
  | "cygwin" -> Some (`Cygwin `Latest)
  | "windows-mingw-ltsc2019" -> Some (`Windows (`Mingw, `Ltsc2019))
  | "windows-mingw" -> Some (`Windows (`Mingw, `Latest))
  | "windows-msvc-ltsc2019" -> Some (`Windows (`Msvc, `Ltsc2019))
  | "windows-msvc" -> Some (`Windows (`Msvc, `Latest))
  | "windows-server-mingw-ltsc2022" -> Some (`WindowsServer (`Mingw, `Ltsc2022))
  | "windows-server-mingw" -> Some (`WindowsServer (`Mingw, `Latest))
  | "windows-server-msvc-ltsc2022" -> Some (`WindowsServer (`Msvc, `Ltsc2022))
  | "windows-server-msvc" -> Some (`WindowsServer (`Msvc, `Latest))
  | _ -> None

let human_readable_string_of_distro (d : t) =
  if d = `Debian `Stable then "Debian Stable"
  else
    match resolve_alias d with
    | `Ubuntu `V12_04 -> "Ubuntu 12.04"
    | `Ubuntu `V14_04 -> "Ubuntu 14.04"
    | `Ubuntu `V15_04 -> "Ubuntu 15.04"
    | `Ubuntu `V15_10 -> "Ubuntu 15.10"
    | `Ubuntu `V16_04 -> "Ubuntu 16.04"
    | `Ubuntu `V16_10 -> "Ubuntu 16.10"
    | `Ubuntu `V17_04 -> "Ubuntu 17.04"
    | `Ubuntu `V17_10 -> "Ubuntu 17.10"
    | `Ubuntu `V18_04 -> "Ubuntu 18.04"
    | `Ubuntu `V18_10 -> "Ubuntu 18.10"
    | `Ubuntu `V19_04 -> "Ubuntu 19.04"
    | `Ubuntu `V19_10 -> "Ubuntu 19.10"
    | `Ubuntu `V20_04 -> "Ubuntu 20.04"
    | `Ubuntu `V20_10 -> "Ubuntu 20.10"
    | `Ubuntu `V21_04 -> "Ubuntu 21.04"
    | `Ubuntu `V21_10 -> "Ubuntu 21.10"
    | `Ubuntu `V22_04 -> "Ubuntu 22.04"
    | `Ubuntu `V22_10 -> "Ubuntu 22.10"
    | `Ubuntu `V23_04 -> "Ubuntu 23.04"
    | `Ubuntu `V23_10 -> "Ubuntu 23.10"
    | `Ubuntu `V24_04 -> "Ubuntu 24.04"
    | `Debian `Unstable -> "Debian Unstable"
    | `Debian `Testing -> "Debian Testing"
    | `Debian `V12 -> "Debian 12 (Bookworm)"
    | `Debian `V11 -> "Debian 11 (Bullseye)"
    | `Debian `V10 -> "Debian 10 (Buster)"
    | `Debian `V9 -> "Debian 9 (Stretch)"
    | `Debian `V8 -> "Debian 8 (Jessie)"
    | `Debian `V7 -> "Debian 7 (Wheezy)"
    | `CentOS `V6 -> "CentOS 6"
    | `CentOS `V7 -> "CentOS 7"
    | `CentOS `V8 -> "CentOS 8"
    | `Fedora `V21 -> "Fedora 21"
    | `Fedora `V22 -> "Fedora 22"
    | `Fedora `V23 -> "Fedora 23"
    | `Fedora `V24 -> "Fedora 24"
    | `Fedora `V25 -> "Fedora 25"
    | `Fedora `V26 -> "Fedora 26"
    | `Fedora `V27 -> "Fedora 27"
    | `Fedora `V28 -> "Fedora 28"
    | `Fedora `V29 -> "Fedora 29"
    | `Fedora `V30 -> "Fedora 30"
    | `Fedora `V31 -> "Fedora 31"
    | `Fedora `V32 -> "Fedora 32"
    | `Fedora `V33 -> "Fedora 33"
    | `Fedora `V34 -> "Fedora 34"
    | `Fedora `V35 -> "Fedora 35"
    | `Fedora `V36 -> "Fedora 36"
    | `Fedora `V37 -> "Fedora 37"
    | `Fedora `V38 -> "Fedora 38"
    | `Fedora `V39 -> "Fedora 39"
    | `Fedora `V40 -> "Fedora 40"
    | `OracleLinux `V7 -> "OracleLinux 7"
    | `OracleLinux `V8 -> "OracleLinux 8"
    | `OracleLinux `V9 -> "OracleLinux 9"
    | `Alpine `V3_3 -> "Alpine 3.3"
    | `Alpine `V3_4 -> "Alpine 3.4"
    | `Alpine `V3_5 -> "Alpine 3.5"
    | `Alpine `V3_6 -> "Alpine 3.6"
    | `Alpine `V3_7 -> "Alpine 3.7"
    | `Alpine `V3_8 -> "Alpine 3.8"
    | `Alpine `V3_9 -> "Alpine 3.9"
    | `Alpine `V3_10 -> "Alpine 3.10"
    | `Alpine `V3_11 -> "Alpine 3.11"
    | `Alpine `V3_12 -> "Alpine 3.12"
    | `Alpine `V3_13 -> "Alpine 3.13"
    | `Alpine `V3_14 -> "Alpine 3.14"
    | `Alpine `V3_15 -> "Alpine 3.15"
    | `Alpine `V3_16 -> "Alpine 3.16"
    | `Alpine `V3_17 -> "Alpine 3.17"
    | `Alpine `V3_18 -> "Alpine 3.18"
    | `Alpine `V3_19 -> "Alpine 3.19"
    | `Alpine `V3_20 -> "Alpine 3.20"
    | `Archlinux `Latest -> "Archlinux"
    | `OpenSUSE `V42_1 -> "OpenSUSE 42.1"
    | `OpenSUSE `V42_2 -> "OpenSUSE 42.2"
    | `OpenSUSE `V42_3 -> "OpenSUSE 42.3"
    | `OpenSUSE `V15_0 -> "OpenSUSE 15.0 (Leap)"
    | `OpenSUSE `V15_1 -> "OpenSUSE 15.1 (Leap)"
    | `OpenSUSE `V15_2 -> "OpenSUSE 15.2 (Leap)"
    | `OpenSUSE `V15_3 -> "OpenSUSE 15.3 (Leap)"
    | `OpenSUSE `V15_4 -> "OpenSUSE 15.4 (Leap)"
    | `OpenSUSE `V15_5 -> "OpenSUSE 15.5 (Leap)"
    | `OpenSUSE `V15_6 -> "OpenSUSE 15.6 (Leap)"
    | `OpenSUSE `Tumbleweed -> "OpenSUSE Tumbleweed"
    | `Cygwin `Ltsc2016 -> "Cygwin Ltsc2016"
    | `Cygwin `Ltsc2019 -> "Cygwin Ltsc2019"
    | `Cygwin `Ltsc2022 -> "Cygwin Ltsc2022"
    | `Windows (`Mingw, `Ltsc2019) -> "Windows Ltsc2019 mingw"
    | `Windows (`Msvc, `Ltsc2019) -> "Windows Ltsc2019 msvc"
    | `WindowsServer (`Mingw, `Ltsc2022) -> "Windows Server Ltsc2022 mingw"
    | `WindowsServer (`Msvc, `Ltsc2022) -> "Windows Server Ltsc2022 msvc"

let human_readable_short_string_of_distro (t : t) =
  match t with
  | `Ubuntu _ -> "Ubuntu"
  | `Debian _ -> "Debian"
  | `CentOS _ -> "CentOS"
  | `Fedora _ -> "Fedora"
  | `OracleLinux _ -> "OracleLinux"
  | `Alpine _ -> "Alpine"
  | `Archlinux _ -> "Archlinux"
  | `OpenSUSE _ -> "OpenSUSE"
  | `Cygwin _ -> "Cygwin"
  | `Windows (`Mingw, _) -> "Windows mingw"
  | `Windows (`Msvc, _) -> "Windows mvsc"
  | `WindowsServer (`Mingw, _) -> "Windows Server mingw"
  | `WindowsServer (`Msvc, _) -> "Windows Server mvsc"

let is_same_distro (d1 : t) (d2 : t) =
  match (d1, d2) with
  | `Ubuntu _, `Ubuntu _
  | `Debian _, `Debian _
  | `CentOS _, `CentOS _
  | `Fedora _, `Fedora _
  | `OracleLinux _, `OracleLinux _
  | `Alpine _, `Alpine _
  | `Archlinux _, `Archlinux _
  | `OpenSUSE _, `OpenSUSE _
  | `Cygwin _, `Cygwin _ ->
      true
  | `Windows (p1, _), `Windows (p2, _) when p1 = p2 -> true
  | `WindowsServer (p1, _), `WindowsServer (p2, _) when p1 = p2 -> true
  | _ -> false

(* The alias tag for the latest stable version of this distro *)
let latest_tag_of_distro (t : t) =
  let latest = List.find (is_same_distro t) latest_distros in
  tag_of_distro latest

type package_manager =
  [ `Apt | `Yum | `Apk | `Zypper | `Pacman | `Cygwin | `Windows ]
[@@deriving sexp]

let package_manager (t : t) =
  match t with
  | `Ubuntu _ -> `Apt
  | `Debian _ -> `Apt
  | `CentOS _ -> `Yum
  | `Fedora _ -> `Yum
  | `OracleLinux _ -> `Yum
  | `Alpine _ -> `Apk
  | `Archlinux _ -> `Pacman
  | `OpenSUSE _ -> `Zypper
  | `Cygwin _ -> `Cygwin
  | `Windows _ -> `Windows
  | `WindowsServer _ -> `Windows

let bubblewrap_version (t : t) =
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
  | `Ubuntu `V22_04 -> Some (0, 6, 1)
  | `Ubuntu `V22_10 -> Some (0, 6, 2)
  | `Ubuntu `V23_04 -> Some (0, 8, 0)
  | `Ubuntu `V23_10 -> Some (0, 8, 0)
  | `Ubuntu `V24_04 -> Some (0, 9, 0)
  | `Debian `V7 -> None (* Not actually checked *)
  | `Debian `V8 -> None (* Not actually checked *)
  | `Debian `V9 -> Some (0, 1, 7)
  | `Debian `V10 -> Some (0, 3, 1)
  | `Debian `V11 -> Some (0, 4, 1)
  | `Debian `V12 -> Some (0, 8, 0)
  | `Debian `Testing -> Some (0, 8, 0)
  | `Debian `Unstable -> Some (0, 8, 0)
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
  | `Fedora `V36 -> Some (0, 5, 0)
  | `Fedora `V37 -> Some (0, 5, 0)
  | `Fedora `V38 -> Some (0, 7, 0)
  | `Fedora `V39 -> Some (0, 8, 0)
  | `Fedora `V40 -> Some (0, 8, 0)
  | `OracleLinux `V7 -> None
  | `OracleLinux `V8 -> Some (0, 4, 0)
  | `OracleLinux `V9 -> Some (0, 4, 1)
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
  | `Alpine `V3_16 -> Some (0, 6, 2)
  | `Alpine `V3_17 -> Some (0, 7, 0)
  | `Alpine `V3_18 -> Some (0, 8, 0)
  | `Alpine `V3_19 -> Some (0, 8, 0)
  | `Alpine `V3_20 -> Some (0, 9, 0)
  | `Archlinux `Latest -> Some (0, 8, 0)
  | `OpenSUSE `V42_1 -> None (* Not actually checked *)
  | `OpenSUSE `V42_2 -> None (* Not actually checked *)
  | `OpenSUSE `V42_3 -> None (* Not actually checked *)
  | `OpenSUSE `V15_0 -> Some (0, 2, 0)
  | `OpenSUSE `V15_1 -> Some (0, 3, 3)
  | `OpenSUSE `V15_2 -> Some (0, 4, 1)
  | `OpenSUSE `V15_3 -> Some (0, 4, 1)
  | `OpenSUSE `V15_4 -> Some (0, 4, 1)
  | `OpenSUSE `V15_5 -> Some (0, 7, 0)
  | `OpenSUSE `V15_6 -> Some (0, 8, 0)
  | `OpenSUSE `Tumbleweed -> Some (0, 8, 0)
  | `Cygwin _ -> None
  | `Windows _ -> None
  | `WindowsServer _ -> None

let base_distro_tag ?(arch = `X86_64) d =
  match resolve_alias d with
  | `Alpine v -> (
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
        | `V3_16 -> "3.16"
        | `V3_17 -> "3.17"
        | `V3_18 -> "3.18"
        | `V3_19 -> "3.19"
        | `V3_20 -> "3.20"
      in
      match arch with `I386 -> ("i386/alpine", tag) | _ -> ("alpine", tag))
  | `Archlinux `Latest -> ("archlinux", "latest")
  | `Debian v -> (
      let tag =
        match v with
        | `V7 -> "7"
        | `V8 -> "8"
        | `V9 -> "9"
        | `V10 -> "10"
        | `V11 -> "11"
        | `V12 -> "12"
        | `Testing -> "testing"
        | `Unstable -> "unstable"
      in
      match (arch, v) with
      | `I386, `V7 -> ("i386/debian", tag)
      | `Aarch32, (`V7 | `V8) -> ("arm32v7/debian", tag)
      | `Ppc64le, (`V8 | `V9 | `V10) -> ("ppc64le/debian", tag)
      | `S390x, (`V8 | `V9 | `V10) -> ("s390x/debian", tag)
      | _ -> ("debian", tag))
  | `Ubuntu v -> (
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
        | `V22_10 -> "kinetic"
        | `V23_04 -> "lunar"
        | `V23_10 -> "mantic"
        | `V24_04 -> "noble"
      in
      match arch with
      | `Riscv64 -> ("ocurrent/opam-staging", tag_of_distro d ^ "-riscv64")
      | _ -> ("ubuntu", tag))
  | `CentOS v ->
      let tag = match v with `V6 -> "6" | `V7 -> "7" | `V8 -> "8" in
      ("centos", tag)
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
        | `V36 -> "36"
        | `V37 -> "37"
        | `V38 -> "38"
        | `V39 -> "39"
        | `V40 -> "40"
      in
      ("fedora", tag)
  | `OracleLinux v ->
      let tag = match v with `V7 -> "7" | `V8 -> "8" | `V9 -> "9" in
      ("oraclelinux", tag)
  | `OpenSUSE `Tumbleweed -> ("opensuse/tumbleweed", "latest")
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
        | `V15_4 -> "15.4"
        | `V15_5 -> "15.5"
        | `V15_6 -> "15.6"
        | `Tumbleweed -> assert false
      in
      ("opensuse/leap", tag)
  | `Cygwin v ->
      let tag =
        match v with
        | `Ltsc2016 -> "ltsc2016"
        | `Ltsc2019 -> "ltsc2019"
        | `Ltsc2022 -> "ltsc2022"
      in
      ("mcr.microsoft.com/windows/servercore", tag)
  | `Windows v ->
      let tag = match v with _, `Ltsc2019 -> "ltsc2019" in
      ("mcr.microsoft.com/windows", tag)
  | `WindowsServer v ->
      let tag = match v with _, `Ltsc2022 -> "ltsc2022" in
      ("mcr.microsoft.com/windows/server", tag)

let compare a b =
  String.compare
    (human_readable_string_of_distro a)
    (human_readable_string_of_distro b)
