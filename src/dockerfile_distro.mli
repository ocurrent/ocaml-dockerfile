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
  | `Alpine of [ `V3_3 | `V3_4 | `V3_5 | `Latest ]
  | `CentOS of [ `V6 | `V7 ]
  | `Debian of [ `V9 | `V8 | `V7 | `Stable | `Testing | `Unstable ]
  | `Fedora of [ `V21 | `V22 | `V23 | `V24 ]
  | `OracleLinux of [ `V7 ]
  | `OpenSUSE of [ `V42_1 | `V42_2 ]
  | `Ubuntu of [ `V12_04 | `V14_04 | `V15_04 | `V15_10 | `V16_04 | `V16_10 ]
] [@@deriving sexp] 
(** Supported Docker container distributions *)

val distros : t list
(** Enumeration of the supported Docker container distributions *)

val latest_stable_distros : t list
(** Enumeration of the latest stable (ideally LTS) supported distributions. *)

val master_distro : t
(** The distribution that is the top-level alias for the [latest] tag
    in the [ocaml/opam] Docker Hub build. *)

val stable_ocaml_versions : string list
(** Enumeration of released OCaml compiler versions. The latest patch
    branch of each release is picked. *)

val dev_ocaml_versions : string list
(** Enumerations of development OCaml compiler versions. *)

val all_ocaml_versions : string list
(** Enumeration of released OCaml compiler versions. In addition to the
    {!stable_ocaml_versions}, trunk builds for the latest releases may
    also be included. *)

val latest_ocaml_version : string
(** The latest stable OCaml release. *)

val opam_versions : string list
(** Enumeration of supported OPAM package manager versions. *)

val latest_opam_version : string
(** The latest stable OPAM release. *)

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

val opam_tag_of_distro : t -> string -> string
(** [opam_tag_of_distro distro ocaml_version] will generate
  a Docker Hub tag that maps to the container that matches
  the OS/OCaml combination.  They can be found by default in
  the [ocaml] organisation in Docker Hub. *)

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

(** {2 Dockerfile generation} *)

val to_dockerfile :
  ?pin:string ->
  ?opam_version:string ->
  ocaml_version:string ->
  distro:t -> unit -> Dockerfile.t
(** [to_dockerfile ?pin ~ocaml_version ~distro] generates
   a Dockerfile for [distro], with OPAM installed and the
   current switch pointing to [ocaml_version]. If [pin]
   is specified then an [opam pin add <pin>] will be added
   to the initialisation. *)

val dockerfile_matrix :
  ?opam_version:string -> 
  ?extra:t list ->
  ?extra_ocaml_versions:string list ->
  ?pin:string ->
  unit -> (t * string * Dockerfile.t) list
(** [dockerfile_matrix ?pin ()] contains the list of Docker tags
   and their associated Dockerfiles for all distributions.
   The user of the container can assume that OPAM is installed
   and initialised to the central remote, and that [opam depext]
   is available on that container. If [pin] is specified then an
   [opam pin add <pin>] will be added to the initialisation. *)

val latest_dockerfile_matrix :
  ?opam_version:string ->
  ?extra:t list -> 
  ?pin:string -> unit -> (t * Dockerfile.t) list
(** [latest_dockerfile_matrix] contains the list of Docker tags
   and Dockerfiles for the latest releases of distributions.
   These contain the latest stable version of the distribution,
   the most recently released version of OCaml, and the freshest
   version of OPAM supported on that distribution.

   The user of the container can assume that OPAM is installed
   and initialised to the central remote, and that [opam depext]
   is available on that container. If [pin] is specified then an
   [opam pin add <pin>] will be added to the initialisation. *)

(** {2 Dockerfile generators and iterators } *)

val map :
  ?filter:(t * string * Dockerfile.t -> bool)  ->
  ?org:string ->
  (distro:t -> ocaml_version:string -> Dockerfile.t -> 'a) ->
  'a list
(* [map ?org fn] will map all the supported Docker containers across [fn].
   [fn] will be passed the {!distro}, OCaml compiler version and a base
   Dockerfile that is based off a Docker Hub image from the [org] organisation
   (by default, this is [ocaml/opam]. *)

val map_tag :
  ?filter:(t * string * Dockerfile.t -> bool) ->
  (distro:t -> ocaml_version:string -> 'a) -> 'a list
(** [map_tag fn] executes [fn distro ocaml_version] with a tag suitable for use
   against the [ocaml/opam:TAG] Docker Hub. *)

val generate_dockerfile : ?crunch:bool -> string -> Dockerfile.t -> unit
(** [generate_dockerfile output_dir docker] will output Dockerfile inside
    the [output_dir] subdirectory.

    The [crunch] argument defaults to true and applies the {!Dockerfile.crunch}
    optimisation to reduce the number of layers; disable it if you really want
    more layers. *)

val generate_dockerfiles : ?crunch:bool -> string ->
  (string * Dockerfile.t) list -> unit
(** [generate_dockerfiles output_dir (name * docker)] will
    output a list of Dockerfiles inside the [output_dir/] subdirectory,
    with each Dockerfile named as [Dockerfile.<release>].

    The [crunch] argument defaults to true and applies the {!Dockerfile.crunch}
    optimisation to reduce the number of layers; disable it if you really want
    more layers. *)

val generate_dockerfiles_in_directories : ?crunch:bool -> string ->
  (string * Dockerfile.t) list -> unit
(** [generate_dockerfiles_in_directories output_dir (name * docker)] will
    output a list of Dockerfiles inside the [output_dir/name] subdirectory,
    with each directory containing the Dockerfile specified by [docker].

    The [crunch] argument defaults to true and applies the {!Dockerfile.crunch}
    optimisation to reduce the number of layers; disable it if you really want
    more layers. *)

val generate_dockerfiles_in_git_branches : ?readme:string -> ?crunch:bool ->
  string -> (string * Dockerfile.t) list -> unit
(** [generate_dockerfiles_in_git_branches output_dir (name * docker)] will
    output a set of git branches in the [output_dir] Git repository.
    Each branch will be named [name] and contain a single [docker] file.
    The contents of these branches will be reset, so this should be
    only be used on an [output_dir] that is a dedicated Git repository
    for this purpose.  If [readme] is specified, the contents will be
    written to [README.md] in that branch.

    The [crunch] argument defaults to true and applies the {!Dockerfile.crunch}
    optimisation to reduce the number of layers; disable it if you really want
    more layers. *)
