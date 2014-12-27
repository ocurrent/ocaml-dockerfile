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

type shell_or_exec = [
  | `Shell of string
  | `Exec of string list
]

type sources_to_dest =
 [ `Src of string list ] * [ `Dst of string ]

type t = [
  | `Comment of string
  | `From of [ `Image of string | `Image_tag of string * string ]
  | `Maintainer of string
  | `Run of shell_or_exec
  | `Cmd of shell_or_exec
  | `Expose of int list
  | `Env of (string * string) list
  | `Add of sources_to_dest
  | `Copy of sources_to_dest
  | `Entrypoint of shell_or_exec
  | `Volume of string list
  | `User of string
  | `Workdir of string
  | `Onbuild of t
]

open Printf
let nl fmt = ksprintf (fun b -> b ^ "\n") fmt
let quote s = String.escaped s
let cmd c r = c ^ " " ^ r

let json_array_of_list sl =
  sprintf "[ %s ]" (String.concat ", " (List.map quote sl))

let string_of_shell_or_exec (t:shell_or_exec) =
  match t with
  | `Shell s -> s
  | `Exec sl -> json_array_of_list sl

let string_of_env_list =
  function
  | [(k,v)] -> sprintf "%s %s" k v
  | el -> String.concat " " (List.map (fun (k,v) -> sprintf "%s=%S" k v) el)

let string_of_sources_to_dest (t:sources_to_dest) =
  match t with
  | `Src sl, `Dst d -> String.concat " " (sl @ [d])

let rec string_of_t (t:t) = 
  match t with
  | `Comment c -> cmd "#"  c
  | `From (`Image i) -> cmd "FROM" i
  | `From (`Image_tag (i,t)) -> sprintf "FROM %s:%s" i t
  | `Maintainer m -> cmd "MAINTAINER" m
  | `Run c -> cmd "RUN" (string_of_shell_or_exec c)
  | `Cmd c -> cmd "CMD" (string_of_shell_or_exec c)
  | `Expose pl -> cmd "EXPOSE" (String.concat " " (List.map string_of_int pl))
  | `Env el -> cmd "ENV" (string_of_env_list el)
  | `Add c -> cmd "ADD" (string_of_sources_to_dest c)
  | `Copy c -> cmd "COPY" (string_of_sources_to_dest c)
  | `User u -> cmd "USER" u
  | `Onbuild t -> cmd "ONBUILD" (string_of_t t)
  | `Volume vl -> cmd "VOLUME" (json_array_of_list vl)
  | `Entrypoint el -> cmd "ENTRYPOINT" (string_of_shell_or_exec el)
  | `Workdir wd -> cmd "WORKDIR" wd

(* Function interface *)
let from ?tag img : t =
  match tag with
  | None -> `From (`Image img)
  | Some tag -> `From (`Image_tag (img, tag))

let comment c : t = `Comment c
let maintainer m : t = `Maintainer m
let run cmd : t = `Run (`Shell cmd)
let run_exec cmds : t = `Run (`Exec cmds)
let cmd cmd : t = `Cmd (`Shell cmd)
let cmd_exec cmds : t = `Cmd (`Exec cmds)
let expose_port p : t = `Expose [p]
let expose_ports p : t = `Expose p
let env e : t = `Env e
let add ~src ~dst : t = `Add (`Src src, `Dst dst)
let copy ~src ~dst : t = `Copy (`Src src, `Dst dst)
let user u : t = `User u
let onbuild t : t = `Onbuild t
let volume v : t = `Volume [v]
let volumes v : t = `Volume v
let entrypoint e : t = `Entrypoint (`Shell e)
let entrypoint_exec e : t = `Entrypoint (`Exec e)
let workdir wd : t = `Workdir wd

type file = t list
let string_of_file tl =
  String.concat "\n" (List.map string_of_t tl)
