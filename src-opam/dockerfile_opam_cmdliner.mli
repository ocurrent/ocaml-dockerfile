(*
 * Copyright (c) 2015 Anil Madhavapeddy <anil@recoil.org>
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

(** Command-line helper functions for scripts using [Dockerfile_opam] *)

val cmd :
  name:string ->
  version:string ->
  summary:string ->
  manual:string ->
  default_dir:string ->
  generate:(opam_version:string -> output_dir:string -> 'a) -> 'a Cmdliner.Term.t * Cmdliner.Term.info
(** This generate a Cmdliner term with various defaults filled in for
    the manual page, and a default term that specifies an output
    directory. *)

val run : 'a Cmdliner.Term.t * Cmdliner.Term.info -> 'b
(** [run] executes the term that results from {!cmd} and returns with
    a non-zero exit code if there is an error. *)
