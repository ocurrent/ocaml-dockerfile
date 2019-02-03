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

type t = [ 
  | `Alpine of [ `V3_3 | `V3_4 | `V3_5 | `V3_6 | `V3_7 | `V3_8 | `V3_9 | `Latest ]
  | `CentOS of [ `V6 | `V7 | `Latest ]
  | `Debian of [ `V9 | `V8 | `V7 | `Stable | `Testing | `Unstable ]
  | `Fedora of [ `V21 | `V22 | `V23 | `V24 | `V25 | `V26 | `V27 | `V28 | `V29 | `Latest ]
  | `OracleLinux of [ `V7 | `Latest ]
  | `OpenSUSE of [ `V42_1 | `V42_2 | `V42_3 | `V15_0 | `Latest ]
  | `Ubuntu of [ `V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 | `V16_10 | `V17_04 | `V17_10 | `V18_04 | `V18_10 | `LTS | `Latest ]
] [@@deriving sexp] 
(** Supported Docker container distributions *)

val compare : t -> t -> int
(** [compare a b] is a lexical comparison function for {!t}. *)

val resolve_alias : t -> t
(** [resolve_alias t] will resolve [t] into a concrete version. This removes
   versions such as [Latest]. *)

val distros : t list
(** Enumeration of the supported Docker container distributions *)

val latest_distros : t list
(** Enumeration of the latest stable (ideally LTS) supported distributions. *)

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
  | `Zypper (** OpenSUSE Zypper *) ] [@@deriving sexp]
(** The package manager used by a distro. *)
  
val package_manager : t -> package_manager
(** [package_manager t] returns the type of package manager used
 by that distribution.  Many derived distributions (such as OracleLinux)
 share the same package manager from a base distribution (such as CentOS). *)

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

val base_distro_tag : t -> string * string
(** [base_distro_tag t] will return a tuple of a Docker Hub
 user/repository and tag for which the base image of a distribution
 can be found (e.g. [opensuse/leap],[15.0] which maps to [opensuse/leap:15.0]
 on the Docker Hub).  This base image is in turn can be used to generate opam
 and other OCaml tool Dockerfiles. *)

(** {2 CPU architectures} *)

val distro_arches : Ocaml_version.t -> t -> Ocaml_version.arch list
(** [distro_arches ov t] returns the list of architectures that
    distribution [t] is supported on for OCaml compiler version [ov] *)

val distro_supported_on : Ocaml_version.arch -> Ocaml_version.t -> t -> bool
(** [distro_supported_on arch ov distro] returns [true] if the
    combination of CPU [arch], compiler version [ov] is available
    on the distribution [distro]. *)

(** {2 Opam build infrastructure support} *)

val active_distros : Ocaml_version.arch -> t list
(** [active_distros arch] returns the list of currently supported
    distributions in the opam build infrastructure.  Distributions
    that are end-of-life upstream will rotate out of this list
    regularly. *)

val active_tier1_distros : Ocaml_version.arch -> t list
(** Tier 1 distributions are those supported for the full matrix
    of compiler versions in the opam build infrastructure. *)

val active_tier2_distros : Ocaml_version.arch -> t list
(** Tier 2 distributions are those supported for a limited set
    of compiler versions in the opam build infrastructure. *)

