(*
 * Copyright (c) 2020 Tarides - Antonin Décimo <antonin@tarides.com>
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

(** Windows specific Dockerfile utility functions *)

open Dockerfile

val cygarch : string
(** Cygwin architecture  *)

val cygroot : string
(** Cygwin root directory *)

val cygsetup : string
(** Path to Cygwin setup executable  *)

val cygcache : string
(** Path to Cygwin package cache  *)

val cygmirror : string
(** Cygwin package repository  *)

val run_sh : ('a, unit, string, t) format4 -> 'a
(** [run_sh fmt] will execute [C:\cygwin64\bin\bash.exe --login -c "fmt"] after quoting [fmt]. *)

val run_cmd : ('a, unit, string, t) format4 -> 'a
(** [run_cmd fmt] will execute [cmd /S /C fmt]. *)

val run_powershell : ('a, unit, string, t) format4 -> 'a
(** [run_powershell fmt] will execute [powershell -Command "fmt"]. *)

val install_cygsympathy_from_source : unit -> t
(** Install CygSymPathy  *)

val install_cygwin : unit -> t
(** Install Cygwin  *)

val install_ocaml_for_windows : ?version:string -> unit -> t
(** Install fdopen's OCaml for Windows  *)

val install_winget_cli : ?version:string -> unit -> t
(** Install winget-cli  *)

val install_vc_redist : ?version:string -> unit -> t
(** Install Microsoft vc_redist  *)

val install_visual_studio_compiler : ?version:string -> unit -> t
(** Install Microsoft Visual Studio Compiler  *)

val install_msvs_tools_from_source : ?version:string -> unit -> t
(** Install MSVS Tools  *)

(** Rules for Cygwin-based installation *)
module Cygwin : sig
  val update : t
  (** [update] will update Cygwin packages *)

  val install : ('a, unit, string, t) format4 -> 'a
  (** [install fmt] will install the supplied Cygwin package list. *)

  val dev_packages : ?extra:string -> unit -> t
  (** [dev_packages ?extra ()] will install the base development
     tools. Extra packages may also be optionally supplied via
     [extra]. *)

  val install_system_ocaml : t
  (** Install the system OCaml packages via Cygwin *)
end

(** Rules for Winget-based installation *)
module Winget : sig
  val install : ('a, unit, string, t) format4 -> 'a
  (** [install fmt] will install the supplied Winget package list. *)

  val dev_packages : ?extra:string list -> unit -> t
  (** [dev_packages ?extra ()] will install the base development
     tools and [git]. Extra packages may also be optionally supplied via
     [extra]. *)
end

(** Rules for Git *)
module Git : sig
  val init : ?name:string -> ?email:string -> unit -> t
  (** Configure the git name and email variables to sensible defaults *)
end
