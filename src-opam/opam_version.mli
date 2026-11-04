(*
 * Copyright (c) 2026 Mark Elvers <mark.elvers@tunbury.org>
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

(** The opam versions installed in the
    {{:https://hub.docker.com/r/ocaml/opam} ocaml/opam} base images.

    Every image ships one binary per version, named [opam-<version>] (see
    {!binary}), so a CI that wants a particular opam can hard link the binary
    over [opam] and re-run [opam init --reinit]. This module is the single
    source of truth for which versions exist; downstream projects should use it
    rather than keep their own list.

    To add a new opam release: add the constructor, then add a case to
    {!to_string}, {!of_string} and the ordering, and append it to {!all}. *)

type t = [ `V2_1 | `V2_2 | `V2_3 | `V2_4 | `V2_5 | `V2_6 | `Dev ]
(** [`Dev] is the development build, installed as [opam-dev]. It is built from
    the newest tagged release on the opam repository, including alphas, betas
    and release candidates, rather than from the head of the [master] branch.
    Tracking tags gives each pre-release CI exposure as soon as it is tagged,
    while keeping the images stable between tags. *)

val all : t list
(** All versions, oldest first, with [`Dev] last. *)

val releases : t list
(** {!all} without [`Dev]. *)

val latest : t
(** The newest release, i.e. the last element of {!releases}. *)

val compare : t -> t -> int
(** Orders by release, with [`Dev] newer than every release. *)

val equal : t -> t -> bool
val pp : t Fmt.t

val to_string : t -> string
(** ["2.1"], ..., ["2.6"], ["dev"]. *)

val of_string : string -> (t, [ `Msg of string ]) result
(** Inverse of {!to_string}. *)

val branch : t -> string
(** The git branch in {{:https://github.com/ocaml/opam}ocaml/opam} that the
    version is built from: ["2.1"], ..., ["master"]. *)

val binary : t -> string
(** The name of the installed binary: ["opam-2.1"], ..., ["opam-dev"]. *)

val to_yojson : t -> [> `List of [> `String of string ] list ]
(** Encodes exactly as [[@@deriving yojson]] would for this polymorphic variant:
    a one-element list holding the constructor name, e.g. [["V2_6"]] or
    [["Dev"]]. The result unifies with [Yojson.Safe.t], so a record field of
    this type works with [ppx_deriving_yojson] without this library depending on
    yojson. The shape is part of the cache digests in ocaml-ci and opam-repo-ci,
    so it must not change. *)

val of_yojson : [> `List of [> `String of string ] list ] -> (t, string) result
(** Inverse of {!to_yojson}; any other JSON value is an [Error]. *)
