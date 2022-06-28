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
  [`From of string option] * [`Src of string list] * [`Dst of string] * [`Chown of string option]
  [@@deriving sexp]

type from = {
  image : string;
  tag: string option;
  alias: string option;
  platform: string option } [@@deriving sexp]

type parser_directive =
  [ `Syntax of string | `Escape of char ]
  [@@deriving sexp]

type heredoc = {
  here_document: string;
  word: string;
  delimiter: string;
  strip: bool } [@@deriving sexp]

type heredocs_to_dest =
  [`Chown of string option] * heredoc list * string
  [@@deriving sexp]

type line =
  [ `ParserDirective of parser_directive
  | `Comment of string
  | `From of from
  | `Maintainer of string
  | `Run of shell_or_exec
  | `Cmd of shell_or_exec
  | `Expose of int list
  | `Env of (string * string) list
  | `Add of sources_to_dest
  | `Copy of sources_to_dest
  | `Copy_heredoc of heredocs_to_dest
  | `Entrypoint of shell_or_exec
  | `Shell of string list
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


let string_of_shell_or_exec ~escape (t: shell_or_exec) =
  match t with
  | `Shell s -> s
  | `Shells [] -> ""
  | `Shells [s] -> s
  | `Shells l -> String.concat (" && "^(String.make 1 escape)^"\n  ") l
  | `Exec sl -> json_array_of_list sl


let string_of_env_list ~escape el =
  let quote v =
    let len = String.length v in
    let buf = Buffer.create len in
    let j = ref 0 in
    for i = 0 to len - 1 do
      if v.[i] = '"' || v.[i] = escape then begin
        if i - !j > 0 then Buffer.add_substring buf v !j (i - !j);
        Buffer.add_char buf escape;
        j := i
      end
    done;
    Buffer.add_substring buf v !j (len - !j);
    Buffer.contents buf
  in
  String.concat " " (List.map (fun (k, v) -> sprintf {|%s="%s"|} k (quote v)) el)


let optional name = function
  | None -> []
  | Some value -> [sprintf "%s=%s" name value]


let string_of_sources_to_dest (t: sources_to_dest) =
  let `From frm, `Src sl, `Dst d, `Chown chown = t in
  String.concat " " (
      optional "--chown" chown
      @ optional "--from" frm
      @ [json_array_of_list (sl @ [d])])

let string_of_label_list ls =
  List.map (fun (k, v) -> sprintf "%s=%S" k v) ls |> String.concat " "

let string_of_copy_heredoc (t: heredocs_to_dest) =
  let `Chown chown, heredocs, dst = t in
  let header, docs =
    List.fold_left (fun (header, docs) t ->
        (sprintf "<<%s%s" (if t.strip then "-" else "") t.word) :: header,
        sprintf "%s\n%s\n%s" docs t.here_document t.delimiter)
      ([], "") heredocs in
  String.concat " " (
      optional "--chown" chown
      @ (List.rev header)
      @ [dst])
  ^ docs

let rec string_of_line ~escape (t: line) =
  match t with
  | `ParserDirective (`Escape c) ->
     cmd "#" ("escape="^(String.make 1 c))
  | `ParserDirective (`Syntax str) -> cmd "#" ("syntax="^str)
  | `Comment c -> cmd "#" c
  | `From {image; tag; alias; platform} ->
      cmd "FROM" (String.concat "" [
        (match platform with None -> "" | Some p -> "--platform="^p^" ");
        image;
        (match tag with None -> "" | Some t -> ":"^t);
        (match alias with None -> "" | Some a -> " as " ^ a)])
  | `Maintainer m -> cmd "MAINTAINER" m
  | `Run c -> cmd "RUN" (string_of_shell_or_exec ~escape c)
  | `Cmd c -> cmd "CMD" (string_of_shell_or_exec ~escape c)
  | `Expose pl -> cmd "EXPOSE" (String.concat " " (List.map string_of_int pl))
  | `Env el -> cmd "ENV" (string_of_env_list ~escape el)
  | `Add c -> cmd "ADD" (string_of_sources_to_dest c)
  | `Copy c -> cmd "COPY" (string_of_sources_to_dest c)
  | `Copy_heredoc c -> cmd "COPY" (string_of_copy_heredoc c)
  | `User u -> cmd "USER" u
  | `Volume vl -> cmd "VOLUME" (json_array_of_list vl)
  | `Entrypoint el -> cmd "ENTRYPOINT" (string_of_shell_or_exec ~escape el)
  | `Shell sl -> cmd "SHELL" (json_array_of_list sl)
  | `Workdir wd -> cmd "WORKDIR" wd
  | `Onbuild t -> cmd "ONBUILD" (string_of_line ~escape t)
  | `Label ls -> cmd "LABEL" (string_of_label_list ls)


(* Function interface *)
let parser_directive pd : t = [`ParserDirective pd]

let heredoc ?(strip=false) ?(word="EOF") ?(delimiter=word) fmt =
  ksprintf (fun here_document -> { here_document; strip; word; delimiter; }) fmt

let from ?alias ?tag ?platform image =
  [`From { image; tag; alias; platform }]

let comment fmt = ksprintf (fun c -> [`Comment c]) fmt

let maintainer fmt = ksprintf (fun m -> [`Maintainer m]) fmt

let run fmt = ksprintf (fun b -> [`Run (`Shell b)]) fmt

let run_exec cmds : t = [`Run (`Exec cmds)]

let cmd fmt = ksprintf (fun b -> [`Cmd (`Shell b)]) fmt

let cmd_exec cmds : t = [`Cmd (`Exec cmds)]

let expose_port p : t = [`Expose [p]]

let expose_ports p : t = [`Expose p]

let env e : t = [`Env e]

let add ?chown ?from ~src ~dst () : t = [`Add (`From from, `Src src, `Dst dst, `Chown chown)]

let copy ?chown ?from ~src ~dst () : t = [`Copy (`From from, `Src src, `Dst dst, `Chown chown)]

let copy_heredoc ?chown ~src ~dst () : t = [`Copy_heredoc (`Chown chown, src, dst)]

let user fmt = ksprintf (fun u -> [`User u]) fmt

let onbuild t = List.map (fun l -> `Onbuild l) t

let volume fmt = ksprintf (fun v -> [`Volume [v]]) fmt

let volumes v : t = [`Volume v]

let label ls = [`Label ls]

let entrypoint fmt = ksprintf (fun e -> [`Entrypoint (`Shell e)]) fmt

let entrypoint_exec e : t = [`Entrypoint (`Exec e)]

let shell s : t = [`Shell s]

let workdir fmt = ksprintf (fun wd -> [`Workdir wd]) fmt

let string_of_t tl =
  let rec find_escape = function
    | `ParserDirective (`Escape c) :: _ -> c
    | `ParserDirective _ :: tl -> find_escape tl
    | _ -> '\\'
  in
  String.concat "\n" (List.map (string_of_line ~escape:(find_escape tl)) tl)

let pp ppf tl = Fmt.pf ppf "%s" (string_of_t tl)
