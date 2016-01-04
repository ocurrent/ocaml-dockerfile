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

type line = [
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
  | `Onbuild of line
  | `Label of (string * string) list
]

type t = line list
let (@@) = (@)
let empty = []
let maybe f = function None -> empty | Some v -> f v

open Printf
let nl fmt = ksprintf (fun b -> b ^ "\n") fmt
let quote s = sprintf "%S" s
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

let string_of_label_list ls =
  let ls = List.map (fun (k,v) -> sprintf "%s=%S" k v) ls in
  match ls with
  | [] -> ""
  | ls -> sprintf "LABEL %s" (String.concat " " ls)

let rec string_of_line (t:line) = 
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
  | `Volume vl -> cmd "VOLUME" (json_array_of_list vl)
  | `Entrypoint el -> cmd "ENTRYPOINT" (string_of_shell_or_exec el)
  | `Workdir wd -> cmd "WORKDIR" wd
  | `Onbuild t -> cmd "ONBUILD" (string_of_line t)
  | `Label ls -> cmd "LABEL" (string_of_label_list ls)

(* Function interface *)
let from ?tag img =
  match tag with
  | None -> [ `From (`Image img) ]
  | Some tag -> [ `From (`Image_tag (img, tag)) ]

let comment fmt = ksprintf (fun c -> [ `Comment c ]) fmt
let maintainer fmt = ksprintf (fun m -> [ `Maintainer m ]) fmt
let run fmt = ksprintf (fun b -> [ `Run (`Shell b) ]) fmt
let run_exec cmds : t = [ `Run (`Exec cmds) ]
let cmd fmt = ksprintf (fun b -> [ `Cmd (`Shell b) ]) fmt
let cmd_exec cmds : t = [ `Cmd (`Exec cmds) ]
let expose_port p : t = [ `Expose [p] ]
let expose_ports p : t = [ `Expose p ]
let env e : t = [ `Env e ]
let add ~src ~dst : t = [ `Add (`Src src, `Dst dst) ]
let copy ~src ~dst : t = [ `Copy (`Src src, `Dst dst) ]
let user fmt = ksprintf (fun u -> [ `User u ]) fmt
let onbuild t = List.map (fun l -> `Onbuild l) t
let volume fmt = ksprintf (fun v -> [ `Volume [v] ]) fmt
let volumes v : t = [ `Volume v ]
let label ls = [ `Label ls ]
let entrypoint fmt = ksprintf (fun e -> [ `Entrypoint (`Shell e) ]) fmt
let entrypoint_exec e : t = [ `Entrypoint (`Exec e) ]
let workdir fmt = ksprintf (fun wd -> [ `Workdir wd ]) fmt

let string_of_t tl = String.concat "\n" (List.map string_of_line tl)


module Linux = struct

  let run_sh fmt = ksprintf (run "sh -c %S") fmt
  let run_as_user user fmt = ksprintf (run "sudo -u %s sh -c %S" user) fmt

  module Git = struct
    let init ?(name="Docker") ?(email="docker@example.com") () =
      run "git config --global user.email %S" "docker@example.com" @@
      run "git config --global user.name %S" "Docker CI"
  end

  let sudo_nopasswd = "ALL=(ALL:ALL) NOPASSWD:ALL"

  (** RPM rules *)
  module RPM = struct
    let install fmt = ksprintf (run "yum install -y %s") fmt
    let groupinstall fmt = ksprintf (run "yum groupinstall -y %s") fmt

    let add_user ?(sudo=false) username =
      let home = "/home/"^username in
      (match sudo with
       | false -> empty
       | true ->
         let sudofile = "/etc/sudoers.d/"^username in
         run "echo '%s %s' > %s" username sudo_nopasswd sudofile @@
         run "chmod 440 %s" sudofile @@
         run "chown root:root %s" sudofile @@
         run "sed -i.bak 's/^Defaults.*requiretty//g' /etc/sudoers") @@
      run "useradd -d %s -m -s /bin/bash %s" home username @@
      run "passwd -l %s" username @@
      run "chown -R %s:%s %s" username username home @@
      user "%s" username @@
      env ["HOME", home] @@
      workdir "%s" home

    let dev_packages ?extra () =
      install "sudo passwd git%s" (match extra with None -> "" | Some x -> " " ^ x) @@
      groupinstall "\"Development Tools\""
  end

  (** Debian rules *)
  module Apt = struct
    let update = run "apt-get -y update" @@ run "apt-get -y upgrade"
    let install fmt = ksprintf (run "apt-get -y install %s") fmt

    let dev_packages ?extra () =
      update @@
      install "sudo pkg-config git build-essential m4 software-properties-common aspcud unzip curl libx11-dev%s"
       (match extra with None -> "" | Some x -> " " ^ x)

    let add_user ?(sudo=false) username =
      let home = "/home/"^username in
      (match sudo with
       | false -> empty
       | true ->
         let sudofile = "/etc/sudoers.d/"^username in
         run "echo '%s %s' > %s" username sudo_nopasswd sudofile @@
         run "chmod 440 %s" sudofile @@
         run "chown root:root %s" sudofile) @@
      run "adduser --disabled-password --gecos '' %s" username @@
      run "passwd -l %s" username @@
      run "chown -R %s:%s %s" username username home @@
      user "%s" username @@
      env ["HOME", home] @@
      workdir "%s" home

  end

end
