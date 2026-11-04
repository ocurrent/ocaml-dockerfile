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

type t = [ `V2_1 | `V2_2 | `V2_3 | `V2_4 | `V2_5 | `V2_6 | `Dev ]

let all : t list = [ `V2_1; `V2_2; `V2_3; `V2_4; `V2_5; `V2_6; `Dev ]
let releases = List.filter (fun v -> v <> `Dev) all
let latest = List.nth releases (List.length releases - 1)

let to_string = function
  | `V2_1 -> "2.1"
  | `V2_2 -> "2.2"
  | `V2_3 -> "2.3"
  | `V2_4 -> "2.4"
  | `V2_5 -> "2.5"
  | `V2_6 -> "2.6"
  | `Dev -> "dev"

let of_string = function
  | "2.1" -> Ok `V2_1
  | "2.2" -> Ok `V2_2
  | "2.3" -> Ok `V2_3
  | "2.4" -> Ok `V2_4
  | "2.5" -> Ok `V2_5
  | "2.6" -> Ok `V2_6
  | "dev" -> Ok `Dev
  | s -> Error (`Msg (s ^ ": unknown opam version"))

let rank = function
  | `V2_1 -> 0
  | `V2_2 -> 1
  | `V2_3 -> 2
  | `V2_4 -> 3
  | `V2_5 -> 4
  | `V2_6 -> 5
  | `Dev -> max_int

let compare a b = Int.compare (rank a) (rank b)
let equal (a : t) (b : t) = a = b
let pp = Fmt.of_to_string to_string
let branch = function `Dev -> "master" | v -> to_string v
let binary v = "opam-" ^ to_string v
let sexp_of_t v = Sexplib0.Sexp.Atom (to_string v)

(* The JSON encoding deliberately matches what [@@deriving yojson] generates
   for a constant polymorphic variant constructor, i.e. ["V2_6"].  ocaml-ci
   and opam-repo-ci mix this value into their Current_cache key and value
   digests, so changing the shape would invalidate every cached job on
   deploy. *)
let constructor = function
  | `Dev -> "Dev"
  | v -> "V" ^ String.map (function '.' -> '_' | c -> c) (to_string v)

let to_yojson v = `List [ `String (constructor v) ]

let of_yojson = function
  | `List [ `String s ] -> (
      match List.find_opt (fun v -> constructor v = s) all with
      | Some v -> Ok v
      | None -> Error ("Opam_version.of_yojson: unknown constructor " ^ s))
  | _ -> Error "Opam_version.of_yojson: expected [\"<constructor>\"]"

let t_of_sexp sexp =
  match sexp with
  | Sexplib0.Sexp.Atom s -> (
      match of_string s with
      | Ok v -> v
      | Error (`Msg m) -> Sexplib0.Sexp_conv.of_sexp_error m sexp)
  | Sexplib0.Sexp.List _ ->
      Sexplib0.Sexp_conv.of_sexp_error "Opam_version.t_of_sexp: atom expected"
        sexp
