(*
 * Copyright (c) 2015-2016 Anil Madhavapeddy <anil@recoil.org>
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

(** Rules for generating Dockerfiles involving OPAM.

   These are deployed at {{:https://hub.docker.com/r/ocaml/opam2}ocaml/opam2}
   on the Docker Hub. The interfaces here may change as the production deployments
   there change, so please contact [anil@recoil.org] if you depend on these
   functions for your own infrastructure. *)

val run_as_opam : ('a, unit, string, Dockerfile.t) format4 -> 'a
(** [run_as_opam fmt] runs the command specified by the [fmt]
    format string as the [opam] user. *)

val install_opam_from_source :
  ?prefix:string -> ?install_wrappers:bool -> ?branch:string -> unit
  -> Dockerfile.t
(** Commands to install OPAM via a source code checkout from GitHub.
    The [branch] defaults to the [1.2] stable branch.
    The binaries are installed under [<prefix>/bin], defaulting to [/usr/local/bin].
    If [install_wrappers] is [true] then OPAM2 sandboxing scripts are installed (defaults to [false]). *)

val gen_opam2_distro :
  ?labels:(string * string) list -> Dockerfile_distro.t
  -> string * Dockerfile.t
(** [gen_opam2_distro d] will generate a Dockerfile for Linux distribution [d].
   @return a tuple of the Docker tag and the Dockerfile. *)

val opam2_mirror : string -> Dockerfile.t
(** [opam2_mirror hub_id] generates an opam2 mirror archive that stores the
  results of [opam admin make] in the container when built. This container
  is suitable to serve as an archive mirror using [cohttp-lwt-unix] *)

val all_ocaml_compilers :
  string -> Ocaml_version.arch -> Dockerfile_distro.t -> string * Dockerfile.t
(** [all_ocaml_compilers hub_id arch distro] will generate an opam2
  container that has all the recent OCaml compilers installed into a
  distribution [distro] on architecture [arch]. *)

val separate_ocaml_compilers :
  string -> Ocaml_version.arch -> Dockerfile_distro.t
  -> (string * Dockerfile.t) list
(** [separate_ocaml_compilers hub_id arch distro] will install a list of
  Dockerfiles that build individual OCaml compiler versions and their
  variants (e.g. flambda) in separate containers. *)

val bulk_build : string -> Dockerfile_distro.t -> Ocaml_version.t -> string -> (string * Dockerfile.t) list
(** [bulk_build hub_id distro ov rev] will setup a bulk build environment
  for OCaml version [ov] on distribution [distro] using the Git revision [rev]
  from opam-repository. *)

val multiarch_manifest : target:string -> platforms:(string * string) list -> string
(** [multiarch_manifest ~target ~platforms] will generate a manifest-tool compliant yaml file to
  build a [target] on the given multiarch [platforms]. *)
