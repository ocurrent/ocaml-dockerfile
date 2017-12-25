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

val generate_dockerfile : ?fname:string -> ?crunch:bool -> Fpath.t -> Dockerfile.t -> (unit, [> Rresult.R.msg ]) Result.result
(** [generate_dockerfile output_dir docker] will output Dockerfile inside
    the [output_dir] subdirectory.

    The [crunch] argument defaults to true and applies the {!Dockerfile.crunch}
    optimisation to reduce the number of layers; disable it if you really want
    more layers. *)

val generate_dockerfiles : ?crunch:bool -> Fpath.t ->
  (string * Dockerfile.t) list -> (unit, [> Rresult.R.msg ]) Result.result
(** [generate_dockerfiles output_dir (name * docker)] will
    output a list of Dockerfiles inside the [output_dir/] subdirectory,
    with each Dockerfile named as [Dockerfile.<release>].

    The [crunch] argument defaults to true and applies the {!Dockerfile.crunch}
    optimisation to reduce the number of layers; disable it if you really want
    more layers. *)

val generate_dockerfiles_in_directories : ?crunch:bool -> Fpath.t ->
  (string * Dockerfile.t) list -> (unit, [> Rresult.R.msg ]) Result.result
(** [generate_dockerfiles_in_directories output_dir (name * docker)] will
    output a list of Dockerfiles inside the [output_dir/name] subdirectory,
    with each directory containing the Dockerfile specified by [docker].

    The [crunch] argument defaults to true and applies the {!Dockerfile.crunch}
    optimisation to reduce the number of layers; disable it if you really want
    more layers. *)

val generate_dockerfiles_in_git_branches : ?readme:string -> ?crunch:bool ->
  Fpath.t -> (string * Dockerfile.t) list -> (unit, [> Rresult.R.msg ]) Result.result
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
