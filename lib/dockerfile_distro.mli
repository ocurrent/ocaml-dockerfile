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
  | `Alpine of [ `V3_3 ]
  | `CentOS of [ `V6 | `V7 ]
  | `Debian of [ `Stable | `Testing | `Unstable ]
  | `Fedora of [ `V21 | `V22 | `V23 ]
  | `OracleLinux of [ `V7 ]
  | `Ubuntu of [ `V14_04 | `V15_04 | `V15_10 ]
] with sexp 
 
val distros : t list
(** All of the supported Docker container distributions *)

val ocaml_versions : bytes list
(** List of supported OCaml compiler versions. *)

val opam_versions : bytes list
(** List of supported OPAM package manager versions. *)

val tag_of_distro : t -> bytes
(** Convert a distribution to a Docker Hub tag.  The full
  form of this is [ocaml/TAG] on the Docker Hub. *)

(** {2 Dockerfile generation} *)

val to_dockerfile :
  ocaml_version:bytes ->
  distro:t -> Dockerfile.t
(** [to_dockerfile ~ocaml_version ~distro] generates
   a Dockerfile for [distro], with OPAM installed and the
   current switch pointing to [ocaml_version]. *)

val dockerfile_matrix : (t * bytes * Dockerfile.t) list
(** [dockerfile_matrix] contains the list of Docker tags
   and their associated Dockerfiles for all distributions.
   The user of the container can assume that OPAM is installed
   and initialised to the central remote, and that [opam depext]
   is available on that container. *)

(** {2 Dockerfile iterators and mappers} *)

val map : ?org:bytes -> (t -> Dockerfile.t -> Dockerfile.t) -> Dockerfile.t list
(* [map ?org fn] will map all the supported Docker containers across [fn].
   [fn] will be passed the {!distro} and a base Dockerfile that is based off
    a Docker Hub image from the [org] organisation (by default, this is
    [ocaml/opam]. *)

val map_tag : (t -> bytes -> 'a) -> 'a list
(** [map_tag fn] executes [fn distro tag] with a tag suitable for use
   against the [ocaml/opam:TAG] Docker Hub. *)

