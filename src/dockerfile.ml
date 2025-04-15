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
  [ `Shell of string | `Shells of string list | `Exec of string list ]
[@@deriving sexp]

type sources_to_dest =
  [ `From of string option ]
  * [ `Src of string list ]
  * [ `Dst of string ]
  * [ `Chown of string option ]
  * [ `Chmod of int option ]
  * [ `Link of bool option ]
  * [ `Checksum of string option ]
  * [ `Keep_git_dir of bool option ]
  * [ `Parents of bool option ]
  * [ `Exclude of string list option ]
[@@deriving sexp]

type from = {
  image : string;
  tag : string option;
  alias : string option;
  platform : string option;
}
[@@deriving sexp]

type parser_directive = [ `Syntax of string | `Escape of char ]
[@@deriving sexp]

type heredoc = {
  here_document : string;
  word : string;
  delimiter : string;
  strip : bool;
}
[@@deriving sexp]

type heredocs_to_dest =
  [ `Chown of string option ] * [ `Chmod of int option ] * heredoc list * string
[@@deriving sexp]

type mount_bind = {
  target : string;
  source : string option;
  from : string option;
  readwrite : bool option;
}
[@@deriving sexp]

type mount_cache = {
  id : string option;
  target : string;
  readonly : bool option;
  sharing : [ `Shared | `Private | `Locked ] option;
  from : string option;
  source : string option;
  mode : int option;
  uid : int option;
  gid : int option;
}
[@@deriving sexp]

type mount_tmpfs = { target : string; size : int option } [@@deriving sexp]

(* secret or ssh *)
type mount_file = {
  id : string option;
  target : string option;
  required : bool option;
  mode : int option;
  uid : int option;
  gid : int option;
}
[@@deriving sexp]

type mount = {
  typ :
    [ `Bind of mount_bind
    | `Cache of mount_cache
    | `Tmpfs of mount_tmpfs
    | `Secret of mount_file
    | `Ssh of mount_file ];
}
[@@deriving sexp]

type healthcheck_options = {
  interval : string option;
  timeout : string option;
  start_period : string option;
  start_interval : string option;
  retries : int option;
}
[@@deriving sexp]

type healthcheck = [ `Cmd of healthcheck_options * shell_or_exec | `None ]
[@@deriving sexp]

type network = [ `Default | `None | `Host ] [@@deriving sexp]
type security = [ `Insecure | `Sandbox ] [@@deriving sexp]

let escape_string ~char_to_escape ~escape v =
  let len = String.length v in
  let buf = Buffer.create len in
  let j = ref 0 in
  for i = 0 to len - 1 do
    if String.unsafe_get v i = char_to_escape || String.unsafe_get v i = escape
    then (
      if i - !j > 0 then Buffer.add_substring buf v !j (i - !j);
      Buffer.add_char buf escape;
      j := i)
  done;
  Buffer.add_substring buf v !j (len - !j);
  Buffer.contents buf

type line =
  [ `ParserDirective of parser_directive
  | `Comment of string
  | `From of from
  | `Maintainer of string
  | `Run of mount list * network option * security option * shell_or_exec
  | `Run_heredoc of
    mount list
    * network option
    * security option
    * (heredoc * string option) list
  | `Cmd of shell_or_exec
  | `Expose of int list
  | `Arg of string * string option
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
  | `Label of (string * string) list
  | `Healthcheck of healthcheck
  | `Stopsignal of string ]
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
  let merge m m' =
    if m = m' then m else invalid_arg "crunch: at least two mounts list differ."
  in
  let pack l =
    let rec aux acc = function
      | [] -> acc
      | `Run (m, n, s, `Shell a) :: `Run (m', n', s', `Shell b) :: tl ->
          if n <> n' then invalid_arg "crunch: at least two networks differ.";
          if s <> s' then invalid_arg "crunch: at least two securities differ.";
          aux (`Run (merge m m', n, s, `Shells [ a; b ]) :: acc) tl
      | `Run (m, n, s, `Shells a) :: `Run (m', n', s', `Shell b) :: tl ->
          if n <> n' then invalid_arg "crunch: at least two networks differ.";
          if s <> s' then invalid_arg "crunch: at least two securities differ.";
          aux (`Run (merge m m', n, s, `Shells (a @ [ b ])) :: acc) tl
      | `Run (m, n, s, `Shells a) :: `Run (m', n', s', `Shells b) :: tl ->
          if n <> n' then invalid_arg "crunch: at least two networks differ.";
          if s <> s' then invalid_arg "crunch: at least two securities differ.";
          aux (`Run (merge m m', n, s, `Shells (a @ b)) :: acc) tl
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

let string_of_shell_or_exec ~escape (t : shell_or_exec) =
  match t with
  | `Shell s -> s
  | `Shells [] -> ""
  | `Shells [ s ] -> s
  | `Shells l -> String.concat (" && " ^ String.make 1 escape ^ "\n  ") l
  | `Exec sl -> json_array_of_list sl

let quote_env_var = escape_string ~char_to_escape:'"'

let string_of_env_var ~escape (name, value) =
  sprintf {|%s="%s"|} name (quote_env_var ~escape value)

let string_of_env_list ~escape el =
  List.map (string_of_env_var ~escape) el |> String.concat " "

let string_of_arg ~escape = function
  | name, Some value -> string_of_env_var ~escape (name, value)
  | name, None -> name

let optional name = function
  | None -> []
  | Some value -> [ sprintf "%s=%s" name value ]

let optional_int name = function
  | None -> []
  | Some value -> [ sprintf "%s=%d" name value ]

let optional_int_octal name = function
  | None -> []
  | Some value -> [ sprintf "%s=%04o" name value ]

let optional_bool name = function
  | None -> []
  | Some value -> [ sprintf "%s=%b" name value ]

let optional_flag name = function
  | Some true -> [ name ]
  | Some false | None -> []

let optional_enum name string_of_val = function
  | None -> []
  | Some value -> [ sprintf "--%s=%s" name (string_of_val value) ]

let optional_list name string_of_val = function
  | None | Some [] -> []
  | Some list ->
      List.map (fun e -> sprintf "--%s=%s" name (string_of_val e)) list

let string_of_sources_to_dest (t : sources_to_dest) =
  let ( `From frm,
        `Src sl,
        `Dst d,
        `Chown chown,
        `Chmod chmod,
        `Link link,
        `Checksum checksum,
        `Keep_git_dir keep_git_dir,
        `Parents parents,
        `Exclude exclude ) =
    t
  in
  String.concat " "
    (optional_flag "--link" link
    @ optional "--chown" chown
    @ optional_int_octal "--chmod" chmod
    @ optional "--from" frm
    @ optional "--checksum" checksum
    @ optional_bool "--keep-git-dir" keep_git_dir
    @ optional_bool "--parents" parents
    @ optional_list "--exclude" Fun.id exclude
    @ [ json_array_of_list (sl @ [ d ]) ])

let string_of_label_list ls =
  List.map (fun (k, v) -> sprintf "%s=%S" k v) ls |> String.concat " "

let string_of_copy_heredoc (t : heredocs_to_dest) =
  let `Chown chown, `Chmod chmod, heredocs, dst = t in
  let header, docs =
    List.fold_left
      (fun (header, docs) t ->
        ( sprintf "<<%s%s" (if t.strip then "-" else "") t.word :: header,
          sprintf "%s\n%s\n%s" docs t.here_document t.delimiter ))
      ([], "") heredocs
  in
  String.concat " "
    (optional "--chown" chown
    @ optional_int_octal "--chmod" chmod
    @ List.rev header @ [ dst ])
  ^ docs

let string_of_mount { typ } =
  match typ with
  | `Bind { target; source; from; readwrite } ->
      String.concat ","
        ([ "--mount=type=bind" ]
        @ [ sprintf "target=%s" target ]
        @ optional "source" source @ optional "from" from
        @ optional_bool "readwrite" readwrite)
  | `Cache { id; target; readonly; sharing; from; source; mode; uid; gid } ->
      String.concat ","
        ([ "--mount=type=cache" ] @ optional "id" id
        @ [ sprintf "target=%s" target ]
        @ optional_bool "readonly" readonly
        @ (match sharing with
          | None -> []
          | Some `Shared -> [ "sharing=shared" ]
          | Some `Private -> [ "sharing=private" ]
          | Some `Locked -> [ "sharing=locked" ])
        @ optional "from" from @ optional "source" source
        @ optional_int_octal "mode" mode
        @ optional_int "uid" uid @ optional_int "gid" gid)
  | `Tmpfs { target; size } ->
      String.concat ","
        ([ "--mount=type=bind" ]
        @ [ sprintf "target=%s" target ]
        @ optional_int "size" size)
  | `Ssh m | `Secret m ->
      let typ =
        match typ with
        | `Ssh _ -> "ssh"
        | `Secret _ -> "secret"
        | _ -> assert false
      in
      let { id; target; required; mode; uid; gid } = m in
      String.concat ","
        ([ sprintf "--mount=type=%s" typ ]
        @ optional "id" id @ optional "target" target
        @ optional_bool "required" required
        @ optional_int_octal "mode" mode
        @ optional_int "uid" uid @ optional_int "gid" gid)

let string_of_run' ~escape mounts network security =
  let mounts =
    mounts |> List.map string_of_mount
    |> List.map (escape_string ~char_to_escape:' ' ~escape)
  in
  let network =
    optional_enum "network"
      (function `Default -> "default" | `None -> "none" | `Host -> "host")
      network
  in
  let security =
    optional_enum "security"
      (function `Insecure -> "insecure" | `Sandbox -> "sandbox")
      security
  in
  mounts @ network @ security

let string_of_run ~escape mounts network security c =
  let params = string_of_run' ~escape mounts network security in
  let run = string_of_shell_or_exec ~escape c in
  String.concat " " (params @ [ run ])

let string_of_run_heredoc ~escape mounts network security c =
  let params = string_of_run' ~escape mounts network security in
  let escape_cmd = function
    | Some cmd -> " " ^ escape_string ~char_to_escape:'\n' ~escape cmd
    | None -> ""
  in
  let cmds, docs =
    List.fold_left
      (fun (cmds, docs) (t, cmd) ->
        let cmd = escape_cmd cmd in
        ( cmds @ [ sprintf "<<%s%s%s" (if t.strip then "-" else "") t.word cmd ],
          sprintf "%s\n%s\n%s" docs t.here_document t.delimiter ))
      ([], "") c
  in
  String.concat " " (params @ [ String.concat " && " cmds ]) ^ docs

let rec string_of_line ~escape (t : line) =
  match t with
  | `ParserDirective (`Escape c) -> cmd "#" ("escape=" ^ String.make 1 c)
  | `ParserDirective (`Syntax str) -> cmd "#" ("syntax=" ^ str)
  | `Comment c -> cmd "#" c
  | `From { image; tag; alias; platform } ->
      cmd "FROM"
        (String.concat ""
           [
             (match platform with
             | None -> ""
             | Some p -> "--platform=" ^ p ^ " ");
             image;
             (match tag with None -> "" | Some t -> ":" ^ t);
             (match alias with None -> "" | Some a -> " AS " ^ a);
           ])
  | `Maintainer m -> cmd "MAINTAINER" m
  | `Run (mounts, network, security, c) ->
      cmd "RUN" (string_of_run ~escape mounts network security c)
  | `Run_heredoc (mounts, network, security, c) ->
      cmd "RUN" (string_of_run_heredoc ~escape mounts network security c)
  | `Cmd c -> cmd "CMD" (string_of_shell_or_exec ~escape c)
  | `Expose pl -> cmd "EXPOSE" (String.concat " " (List.map string_of_int pl))
  | `Arg a -> cmd "ARG" (string_of_arg ~escape a)
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
  | `Stopsignal s -> cmd "STOPSIGNAL" s
  | `Healthcheck (`Cmd (opts, c)) ->
      cmd "HEALTHCHECK" (string_of_healthcheck ~escape opts c)
  | `Healthcheck `None -> "HEALTHCHECK NONE"

and string_of_healthcheck ~escape options c =
  String.concat " "
    (optional "--interval" options.interval
    @ optional "--timeout" options.timeout
    @ optional "--start-period" options.start_period
    @ optional "--start-interval" options.start_interval
    @ optional_int "--retries" options.retries)
  ^ sprintf " %c\n  %s" escape (string_of_line ~escape (`Cmd c))

(* Function interface *)
let parser_directive pd : t = [ `ParserDirective pd ]
let buildkit_syntax = parser_directive (`Syntax "docker/dockerfile:1")

let heredoc ?(strip = false) ?(word = "EOF") ?(delimiter = word) fmt =
  ksprintf (fun here_document -> { here_document; strip; word; delimiter }) fmt

let mount_bind ~target ?source ?from ?readwrite () =
  let m = { target; source; from; readwrite } in
  { typ = `Bind m }

let mount_cache ?id ~target ?readonly ?sharing ?from ?source ?mode ?uid ?gid ()
    =
  let m = { id; target; readonly; sharing; from; source; mode; uid; gid } in
  { typ = `Cache m }

let mount_tmpfs ~target ?size () =
  let m = { target; size } in
  { typ = `Tmpfs m }

let mount_secret ?id ?target ?required ?mode ?uid ?gid () =
  let m = { id; target; required; mode; uid; gid } in
  { typ = `Secret m }

let mount_ssh ?id ?target ?required ?mode ?uid ?gid () =
  let m = { id; target; required; mode; uid; gid } in
  { typ = `Ssh m }

let from ?alias ?tag ?platform image = [ `From { image; tag; alias; platform } ]
let comment fmt = ksprintf (fun c -> [ `Comment c ]) fmt
let maintainer fmt = ksprintf (fun m -> [ `Maintainer m ]) fmt

let run ?(mounts = []) ?network ?security fmt =
  ksprintf (fun b -> [ `Run (mounts, network, security, `Shell b) ]) fmt

let run_exec ?(mounts = []) ?network ?security cmds : t =
  [ `Run (mounts, network, security, `Exec cmds) ]

let run_heredoc ?(mounts = []) ?network ?security docs : t =
  [ `Run_heredoc (mounts, network, security, docs) ]

let cmd fmt = ksprintf (fun b -> [ `Cmd (`Shell b) ]) fmt
let cmd_exec cmds : t = [ `Cmd (`Exec cmds) ]
let expose_port p : t = [ `Expose [ p ] ]
let expose_ports p : t = [ `Expose p ]
let arg ?default a : t = [ `Arg (a, default) ]
let env e : t = [ `Env e ]

let add ?link ?chown ?chmod ?from ?exclude ?checksum ?keep_git_dir ~src ~dst ()
    : t =
  [
    `Add
      ( `From from,
        `Src src,
        `Dst dst,
        `Chown chown,
        `Chmod chmod,
        `Link link,
        `Checksum checksum,
        `Keep_git_dir keep_git_dir,
        `Parents None,
        `Exclude exclude );
  ]

let copy ?link ?chown ?chmod ?from ?parents ?exclude ~src ~dst () : t =
  [
    `Copy
      ( `From from,
        `Src src,
        `Dst dst,
        `Chown chown,
        `Chmod chmod,
        `Link link,
        `Checksum None,
        `Keep_git_dir None,
        `Parents parents,
        `Exclude exclude );
  ]

let copy_heredoc ?chown ?chmod ~src ~dst () : t =
  [ `Copy_heredoc (`Chown chown, `Chmod chmod, src, dst) ]

let user fmt = ksprintf (fun u -> [ `User u ]) fmt
let onbuild t = List.map (fun l -> `Onbuild l) t
let volume fmt = ksprintf (fun v -> [ `Volume [ v ] ]) fmt
let volumes v : t = [ `Volume v ]
let label ls = [ `Label ls ]
let entrypoint fmt = ksprintf (fun e -> [ `Entrypoint (`Shell e) ]) fmt
let entrypoint_exec e : t = [ `Entrypoint (`Exec e) ]
let shell s : t = [ `Shell s ]
let workdir fmt = ksprintf (fun wd -> [ `Workdir wd ]) fmt
let stopsignal s = [ `Stopsignal s ]

let healthcheck ?interval ?timeout ?start_period ?start_interval ?retries fmt =
  let opts = { interval; timeout; start_period; start_interval; retries } in
  ksprintf (fun b -> [ `Healthcheck (`Cmd (opts, `Shell b)) ]) fmt

let healthcheck_exec ?interval ?timeout ?start_period ?start_interval ?retries
    cmds : t =
  let opts = { interval; timeout; start_period; start_interval; retries } in
  [ `Healthcheck (`Cmd (opts, `Exec cmds)) ]

let healthcheck_none () : t = [ `Healthcheck `None ]

let string_of_t tl =
  let rec find_escape = function
    | `ParserDirective (`Escape c) :: _ -> c
    | `ParserDirective _ :: tl -> find_escape tl
    | _ -> '\\'
  in
  let escape = find_escape tl in
  let buf = Buffer.create 4096 in
  let is_parser_directive = function `ParserDirective _ -> true | _ -> false
  and is_arg = function `Arg _ -> true | _ -> false in
  let space l =
    Buffer.add_string buf (string_of_line ~escape l);
    Buffer.add_string buf "\n\n"
  and print l =
    Buffer.add_string buf (string_of_line ~escape l);
    Buffer.add_char buf '\n'
  in
  let rec outside = function
    | (`ParserDirective _ as l1) :: l2 :: tl when not (is_parser_directive l2)
      ->
        space l1;
        outside (l2 :: tl)
    | (`Arg _ as l1) :: l2 :: tl when not (is_arg l2) ->
        space l1;
        outside (l2 :: tl)
    | (`From _ as l) :: tl ->
        print l;
        inside tl
    | l :: tl ->
        print l;
        outside tl
    | [] -> ()
  and inside = function
    | (`Comment _ as l1) :: (`From _ as l2) :: tl ->
        Buffer.add_string buf "\n";
        print l1;
        inside (l2 :: tl)
    | l1 :: (`From _ as l2) :: tl ->
        space l1;
        inside (l2 :: tl)
    | l :: tl ->
        print l;
        inside tl
    | [] -> ()
  in
  outside tl;
  Buffer.contents buf

let pp ppf tl = Fmt.pf ppf "%s" (string_of_t tl)
