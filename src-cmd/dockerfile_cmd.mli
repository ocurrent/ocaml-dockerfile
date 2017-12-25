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

(** Command invocation library to help with Docker builds.

    This module primarily exposes utility functions to glue together
    Docker-based scripts for (e.g.) continuous integration systems
    like the ocaml-ci.  The interface is fairly domain-specific and
    does not expose all the functionality of the underlying tools.
    Feel free to contribute more functions if you need them. *)

type cmd_log = {
  command: string;
  stdout: string;
  success: bool;
  status: [ `Signaled of int | `Exited of int ]
} [@@deriving sexp]
(** Results of a command invocation *)

val run_log :
  ?ok_to_fail:bool ->
  ?env:Bos.OS.Env.t ->
  Fpath.t ->
  string -> Bos.Cmd.t -> (unit, [> Rresult.R.msg ]) result
(** [runlog log_dir name cmd] will run [cmd] with label [name] 
   and log the results in [<log_dir>/<name>.sxp]. *)

(** Docker command invocation *)
module Docker : sig
  val bin : Bos.Cmd.t

  val info : Bos.Cmd.t

  val exists : unit -> bool

  val build_cmd :
    ?squash:bool ->
    ?pull:bool ->
    ?cache:bool ->
    ?dockerfile:Fpath.t -> ?tag:string -> Fpath.t -> Bos.Cmd.t

  val volume_cmd : Bos.Cmd.t

  val push_cmd : string -> Bos.Cmd.t

  val build_id : Fpath.t -> (string, [> Rresult.R.msg ]) result

  val run_cmd :
    ?mounts:(string * string) list ->
    ?volumes:(string * string) list ->
    ?rm:bool -> string -> Bos.Cmd.t -> Bos.Cmd.t

  val manifest_push_cli :
    platforms:string list ->
    template:string -> target:string -> Bos.Cmd.t

  val manifest_push_file : Fpath.t -> Bos.Cmd.t
end

(** GNU Parallel command invocation *)
module Parallel : sig

  module Joblog : sig
    type t = {
      arg: string;
      seq: int;
      host: string;
      start_time: float;
      run_time: float;
      send: int;
      receive: int;
      exit_code: int;
      signal: int;
      command: string;
      build_logfiles: (string * string) option;
    } [@@deriving sexp]
  end
  type joblog = Joblog.t 
  type t = joblog list [@@deriving sexp]

  val run :
    ?mode:[< `Local
           | `Remote of [< `Controlmaster | `Ssh ] * string list
           > `Local ] ->
    ?delay:float -> ?jobs:int -> ?retries:int ->
    Fpath.t -> string -> Bos.Cmd.t ->
    string list -> (joblog list, [> Rresult.R.msg ]) result
 
end

(** Opam2 command invocation *)
module Opam : sig
  val bin : Bos.Cmd.t

  val opam_env :
    root:Fpath.t ->
    jobs:int -> (string Astring.String.map, [> Rresult.R.msg ]) result

end

(** {2 Utility functions} *)

val setup_logs : unit -> unit Cmdliner.Term.t 
(** [setup_logs ()] initialises a {!Logs} environment. *)

val iter : ('a -> (unit, 'b) result) -> 'a list -> (unit, 'b) result

val map : ('a -> ('b, 'c) result) -> 'a list -> ('b list, 'c) result


