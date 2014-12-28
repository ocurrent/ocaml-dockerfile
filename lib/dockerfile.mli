(*
 * Copyright (c) 2014 Anil Madhavapeddy <anil@recoil.org>
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

type t
type file = t list

val string_of_t : t -> string
val string_of_file : file -> string

val comment : ('a, unit, string, t) format4 -> 'a
val from : ?tag:string -> string -> t
val maintainer :  ('a, unit, string, t) format4 -> 'a
val run : ('a, unit, string, t) format4 -> 'a
val run_exec : string list -> t
val cmd : ('a, unit, string, t) format4 -> 'a
val cmd_exec : string list -> t
val expose_port : int -> t
val expose_ports : int list -> t
val env : (string * string) list -> t
val add : src:string list -> dst:string -> t
val copy : src:string list -> dst:string -> t
val user : ('a, unit, string, t) format4 -> 'a
val onbuild : t -> t
val volume :  ('a, unit, string, t) format4 -> 'a
val volumes : string list -> t
val entrypoint :  ('a, unit, string, t) format4 -> 'a
val entrypoint_exec : string list -> t
val workdir :  ('a, unit, string, t) format4 -> 'a

