(*
 * Copyright (c) 2016-2018 Anil Madhavapeddy <anil@recoil.org>
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

(** Run Opam commands across a matrix of Docker containers.
    Each of these containers represents a different version of
    OCaml, Opam and an OS distribution (such as Debian or Alpine).
  *)

(** {2 Known distributions and OCaml variants} *)

type win10_release = [
  | `V1507 | `V1511 | `V1607
  | `V1703 | `V1709 | `V1803 | `V1809 | `V1903 | `V1909
  | `V2004 | `V20H2 | `V21H1 | `V21H2
] [@@deriving sexp]
(** All Windows 10 release versions. *)

type win10_ltsc = [
  `Ltsc2015 | `Ltsc2016 | `Ltsc2019 | `Ltsc2022
] [@@deriving sexp]
(** All Windows Long-Term Service Branch releases. LTSC versions are aliased to
    the semi-annual release they're based on. *)

type win_all = [ win10_release | win10_ltsc ] [@@deriving sexp]
(** All Windows 10/11 release versions and LTSC names *)

type win10_lcu = [
  | `LCU
  | `LCU20220913
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
(** Windows 10 Latest Cumulative Update. Out-of-band LCUs are not included
    as they aren't released with Docker images. [`LCU] always refers to the
    most recent LCU. *)

val win10_current_lcu : win10_lcu
(** Current Windows 10 Latest Cumulative Update; value used when [`LCU] is
    specified. *)

type win10_revision = win10_release * win10_lcu option [@@deriving sexp]
(** A Windows 10 version optionally with an LCU. *)

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
(** Supported Docker container distributions distributions *)

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
(** Supported Docker container distributions *)

type os_family = [ `Cygwin | `Linux | `Windows ] [@@deriving sexp]
(** The operating system family a distro belongs to. *)

val os_family_of_distro : t -> os_family
(** [os_family_of_distro t] returns the OS family of the distro. *)

val os_family_to_string : os_family -> string
(** [os_family_to_string os] returns a string representing the OS
   family. *)

val opam_repository : os_family -> string
(** [opam_repository os_family] returns the git URL to the default
   Opam repository. *)

val personality : os_family -> Ocaml_version.arch -> string option
(** [personality os_family arch] returns the personality associated to
   the architecture, if [os_family] is [`Linux]. *)

val is_same_distro : t -> t -> bool
(** [is_same_distro d1 d2] returns whether [d1] is the same distro as
   [d2], regardless of their respective versions. *)

val compare : t -> t -> int
(** [compare a b] is a lexical comparison function for {!t}. *)

val resolve_alias : t -> distro
(** [resolve_alias t] will resolve [t] into a concrete version. This removes
   versions such as [Latest]. *)

val distros : t list
(** Enumeration of the supported Docker container distributions *)

val latest_distros : t list
(** Enumeration of the latest stable (ideally LTS) supported distributions. *)

val win10_latest_release : win10_release
(** Latest Windows 10 release. *)

val win10_latest_image : win10_release
(** Latest Windows 10 Docker image available. May differ from
   {!win10_latest_release} if the Docker repository hasn't been
   updated. *)

val master_distro : t
(** The distribution that is the top-level alias for the [latest] tag
    in the [ocaml/opam2] Docker Hub build. *)

val builtin_ocaml_of_distro : t -> string option
(** [builtin_ocaml_of_distro t] will return the OCaml version
  supplied with the distribution packaging, and [None] if there
  is no supported version. *)

val human_readable_string_of_distro : t -> string
(** [human_readable_string_of_distro t] returns a human readable
  version of the distribution tag, including version information. *)

val human_readable_short_string_of_distro : t -> string
(** [human_readable_short_string_of_distro t] returns a human readable
  short version of the distribution tag, excluding version information. *)

type package_manager = [
  | `Apk  (** Alpine Apk *)
  | `Apt  (** Debian Apt *)
  | `Yum  (** Fedora Yum *)
  | `Zypper (** OpenSUSE Zypper *)
  | `Pacman (** Archlinux Pacman *)
  | `Cygwin (** Cygwin package manager *)
  | `Windows (** Native Windows, WinGet, Cygwin  *)
] [@@deriving sexp]
(** The package manager used by a distro. *)

val package_manager : t -> package_manager
(** [package_manager t] returns the type of package manager used
 by that distribution.  Many derived distributions (such as OracleLinux)
 share the same package manager from a base distribution (such as CentOS). *)

val bubblewrap_version : t -> (int * int * int) option
(** [bubblewrap_version t] returns the version of bubblewrap available on that
 distribution. *)

(** {2 Docker Hub addresses} *)

val tag_of_distro : t -> string
(** [tag_of_distro t] convert a distribution [t] to a Docker Hub tag. *)

val distro_of_tag : string -> t option
(** [distro_of_tag s] parses [s] into a {!t} distribution, and
    [None] otherwise. *)

val latest_tag_of_distro : t -> string
(** [latest_tag_of_distro distro] will generate a Docker Hub
  tag that is a convenient short form for the latest stable
  release of a particular distribution.  This tag will be
  regularly rewritten to point to any new releases of the
  distribution. *)

type win10_docker_base_image = [
  | `NanoServer (** Windows Nano Server *)
  | `ServerCore (** Windows Server Core *)
  | `Windows    (** Windows Server "with Desktop Experience" *)
]
(** Windows containers base images.
    @see <https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/container-base-images> *)

val win10_base_tag : ?win10_revision:win10_lcu -> win10_docker_base_image -> win_all -> string * string
(** [win10_base_tag base_image release] will return a tuple of Windows
   container base image and tag for which the base image of a Windows
   base image can be found (e.g.
   [mcr.microsoft.com/windows/servercore],[ltsc2022] which maps to
   [mcr.microsoft.com/windows/servercore:ltsc2022] on the Microsoft
   Container Registry). *)

val base_distro_tag : ?win10_revision:win10_lcu -> ?arch:Ocaml_version.arch -> t -> string * string
(** [base_distro_tag ?arch t] will return a tuple of a Docker Hub
 user/repository and tag for which the base image of a distribution
 can be found (e.g. [opensuse/leap],[15.0] which maps to [opensuse/leap:15.0]
 on the Docker Hub).  This base image is in turn can be used to generate opam
 and other OCaml tool Dockerfiles. [arch] defaults to [x86_64] and can vary
 the base user/repository since some architecture are built elsewhere. *)

val win10_release_to_string : win10_release -> string
(** [win10_release_to_string update] converts a Windows 10 version name to
   string. *)

val win10_release_of_string : string -> win_all option
(** [win10_release_of_string] converts a Windows 10 version name as
   string to its internal representation. Ignores any KB number. *)

val win10_revision_to_string : win10_revision -> string

val win10_revision_of_string : string -> win10_revision option

(** {2 CPU architectures} *)

val distro_arches : Ocaml_version.t -> t -> Ocaml_version.arch list
(** [distro_arches ov t] returns the list of architectures that
    distribution [t] is supported on for OCaml compiler version [ov] *)

val distro_supported_on : Ocaml_version.arch -> Ocaml_version.t -> t -> bool
(** [distro_supported_on arch ov distro] returns [true] if the
    combination of CPU [arch], compiler version [ov] is available
    on the distribution [distro]. *)

(** {2 Opam build infrastructure support} *)

type win10_release_status = [ `Deprecated | `Active ]
(** Windows 10 release status. *)

val win10_release_status : win_all -> win10_release_status
(* [win10_release_status v channel] returns the Microsoft support
  status of the specified Windows 10 release.
  @see <https://en.wikipedia.org/wiki/Windows_10_version_history#Channels> *)

val active_distros : Ocaml_version.arch -> t list
(** [active_distros arch] returns the list of currently supported
    distributions in the opam build infrastructure.  Distributions
    that are end-of-life upstream will rotate out of this list
    regularly. *)

val active_tier1_distros : Ocaml_version.arch -> t list
(** Tier 1 distributions are those supported for the full matrix
    of compiler versions in the opam build infrastructure.
    The {{:https://github.com/ocurrent/docker-base-images}Docker base images}
    will compile a base image for every OCaml version, so this
    list should be added to sparingly. *)

val active_tier2_distros : Ocaml_version.arch -> t list
(** Tier 2 distributions are those supported for a limited set
    of compiler versions in the opam build infrastructure.  The
    distros in this list are also tested for packages in the
    opam repository. *)

val active_tier3_distros : Ocaml_version.arch -> t list
(** Tier 3 distributions are those supported for a limited set
    of compiler versions in the opam build infrastructure.  While
    these distros will have base images compiled for them, they
    are not widely tested. Distros maybe here as they are on the
    way to being deprecated, or new and still experimental. *)
