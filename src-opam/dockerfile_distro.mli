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

(** Run OPAM commands across a matrix of Docker containers.
    Each of these containers represents a different version of
    OCaml, OPAM and an OS distribution (such as Debian or Alpine).
  *)

(** {2 Known distributions and OCaml variants} *)

type t = [ 
  | `Alpine of [ `V3_3 | `V3_4 | `V3_5 | `V3_6 | `Latest ]
  | `CentOS of [ `V6 | `V7 | `Latest ]
  | `Debian of [ `V9 | `V8 | `V7 | `Stable | `Testing | `Unstable ]
  | `Fedora of [ `V21 | `V22 | `V23 | `V24 | `V25 | `V26 | `V27 | `Latest ]
  | `OracleLinux of [ `V7 | `Latest ]
  | `OpenSUSE of [ `V42_1 | `V42_2 | `V42_3 | `Latest ]
  | `Ubuntu of [ `V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 | `V16_10 | `V17_04 | `V17_10 | `LTS | `Latest ]
] [@@deriving sexp] 
(** Supported Docker container distributions *)

type arch = [
  | `X86_64
  | `Aarch64
] [@@deriving sexp]

val resolve_alias : t -> t

val distros : t list
(** Enumeration of the supported Docker container distributions *)

val distro_arches : t -> arch list
val distro_supported_on : arch -> t -> bool
val active_distros : t list
val inactive_distros : t list
val latest_distros : t list
(** Enumeration of the latest stable (ideally LTS) supported distributions. *)

val master_distro : t
(** The distribution that is the top-level alias for the [latest] tag
    in the [ocaml/opam] Docker Hub build. *)

val builtin_ocaml_of_distro : t -> string option
(** [builtin_ocaml_of_distro t] will return the OCaml version
  supplied with the distribution packaging, and [None] if there
  is no supported version. *)

val tag_of_distro : t -> string
(** Convert a distribution to a Docker Hub tag.  The full
  form of this is [ocaml/TAG] on the Docker Hub. *)

val distro_of_tag : string -> t option
(** [distro_of_tag s] parses [s] into a {!t} distribution, and
    [None] otherwise. *)

val latest_tag_of_distro : t -> string
(** [latest_tag_of_dsistro distro] will generate a Docker Hub
  tag that is a convenient short form for the latest stable
  release of a particular distribution.  This tag will be
  regularly rewritten to point to any new releases of the
  distribution. *)

val human_readable_string_of_distro : t -> string
(** [human_readable_string_of_distro t] returns a human readable
  version of the distribution tag, including version information. *)

val human_readable_short_string_of_distro : t -> string
(** [human_readable_short_string_of_distro t] returns a human readable
  short version of the distribution tag, excluding version information. *)

val compare : t -> t -> int
(** [compare a b] is a lexical comparison function for {!t}. *)
