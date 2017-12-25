(*
 * Copyright (c) 2014-2016 Anil Madhavapeddy <anil@recoil.org>
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

open Sexplib.Conv

type shell_or_exec =
  [`Shell of string | `Shells of string list | `Exec of string list]
  [@@deriving sexp]

type sources_to_dest =
  [`From of string option] * [`Src of string list] * [`Dst of string]
  [@@deriving sexp]

type line =
  [ `Comment of string
  | `From of [ `Image of string * string option
             | `Image_tag of string * string * string option ]
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
  | `Onbuild of line
  | `Label of (string * string) list ]
  [@@deriving sexp]

type t = line list [@@deriving sexp]

let ( @@ ) = ( @ )

let ( @@@ ) = List.fold_left (fun a b -> a @@ b)

let empty = []

let maybe f = function None -> empty | Some v -> f v

open Printf

(* Multiple RUN lines will be compressed into a single one in
   order to reduce the number of layers used *)
let crunch l =
  let pack l =
    let rec aux acc = function
      | [] -> acc
      | (`Run `Shell a) :: (`Run `Shell b) :: tl ->
          aux (`Run (`Shells [a; b]) :: acc) tl
      | (`Run `Shells a) :: (`Run `Shell b) :: tl ->
          aux (`Run (`Shells (a @ [b])) :: acc) tl
      | (`Run `Shells a) :: (`Run `Shells b) :: tl ->
          aux (`Run (`Shells (a @ b)) :: acc) tl
      | hd :: tl -> aux (hd :: acc) tl
    in
    List.rev (aux [] l)
  in
  let rec fixp fn l =
    let a = fn l in
    if a = l then l else fixp fn a
  in
  fixp pack l


let quote s = sprintf "%S" s

let cmd c r = c ^ " " ^ r

let json_array_of_list sl =
  sprintf "[ %s ]" (String.concat ", " (List.map quote sl))


let string_of_shell_or_exec (t: shell_or_exec) =
  match t with
  | `Shell s -> s
  | `Shells [] -> ""
  | `Shells [s] -> s
  | `Shells l -> String.concat " && \\\n  " l
  | `Exec sl -> json_array_of_list sl


let string_of_env_list = function
  | [(k, v)] -> sprintf "%s %s" k v
  | el -> String.concat " " (List.map (fun (k, v) -> sprintf "%s=%S" k v) el)


let string_of_sources_to_dest (t: sources_to_dest) =
  match t with
  | `From None, `Src sl, `Dst d -> String.concat " " (sl @ [d])
  | `From Some frm, `Src sl, `Dst d ->
      sprintf "--from=%s %s" frm (String.concat " " (sl @ [d]))


let string_of_label_list ls =
  List.map (fun (k, v) -> sprintf "%s=%S" k v) ls |> String.concat " "


let rec string_of_line (t: line) =
  match t with
  | `Comment c -> cmd "#" c
  | `From `Image (i, None) -> cmd "FROM" i
  | `From `Image (i, Some alias) -> cmd "FROM" (i ^ " as " ^ alias)
  | `From `Image_tag (i, t, None) -> sprintf "FROM %s:%s" i t
  | `From `Image_tag (i, t, Some alias) -> sprintf "FROM %s:%s as %s" i t alias
  | `Maintainer m -> cmd "MAINTAINER" m
  | `Run c -> cmd "RUN" (string_of_shell_or_exec c)
  | `Cmd c -> cmd "CMD" (string_of_shell_or_exec c)
  | `Expose pl -> cmd "EXPOSE" (String.concat " " (List.map string_of_int pl))
  | `Env el -> cmd "ENV" (string_of_env_list el)
  | `Add c -> cmd "ADD" (string_of_sources_to_dest c)
  | `Copy c -> cmd "COPY" (string_of_sources_to_dest c)
  | `User u -> cmd "USER" u
  | `Volume vl -> cmd "VOLUME" (json_array_of_list vl)
  | `Entrypoint el -> cmd "ENTRYPOINT" (string_of_shell_or_exec el)
  | `Workdir wd -> cmd "WORKDIR" wd
  | `Onbuild t -> cmd "ONBUILD" (string_of_line t)
  | `Label ls -> cmd "LABEL" (string_of_label_list ls)


(* Function interface *)
let from ?alias ?tag img =
  match tag with
  | None -> [`From (`Image (img, alias))]
  | Some tag -> [`From (`Image_tag (img, tag, alias))]


let comment fmt = ksprintf (fun c -> [`Comment c]) fmt

let maintainer fmt = ksprintf (fun m -> [`Maintainer m]) fmt

let run fmt = ksprintf (fun b -> [`Run (`Shell b)]) fmt

let run_exec cmds : t = [`Run (`Exec cmds)]

let cmd fmt = ksprintf (fun b -> [`Cmd (`Shell b)]) fmt

let cmd_exec cmds : t = [`Cmd (`Exec cmds)]

let expose_port p : t = [`Expose [p]]

let expose_ports p : t = [`Expose p]

let env e : t = [`Env e]

let add ?from ~src ~dst () : t = [`Add (`From from, `Src src, `Dst dst)]

let copy ?from ~src ~dst () : t = [`Copy (`From from, `Src src, `Dst dst)]

let user fmt = ksprintf (fun u -> [`User u]) fmt

let onbuild t = List.map (fun l -> `Onbuild l) t

let volume fmt = ksprintf (fun v -> [`Volume [v]]) fmt

let volumes v : t = [`Volume v]

let label ls = [`Label ls]

let entrypoint fmt = ksprintf (fun e -> [`Entrypoint (`Shell e)]) fmt

let entrypoint_exec e : t = [`Entrypoint (`Exec e)]

let workdir fmt = ksprintf (fun wd -> [`Workdir wd]) fmt

let string_of_t tl = String.concat "\n" (List.map string_of_line tl)

let pp ppf tl = Fmt.pf ppf "%s" (string_of_t tl)
