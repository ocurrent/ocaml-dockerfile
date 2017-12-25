(*
 * Copyright (c) 2014-2016 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2014-2016 Docker Inc (for the documentation comments, which
 * have been adapted from https://docs.docker.com/reference/builder)
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

(** Linux distribution-specific Dockerfile utility functions *)

open Dockerfile

val run_sh : ('a, unit, string, t) format4 -> 'a
(** [run_sh fmt] will execute [/bin/sh -c "fmt"] after quoting [fmt]. *)

val run_as_user : string -> ('a, unit, string, t) format4 -> 'a
(** [run_as_user user fmt] will execute [sudo -u user /bin/sh -c "fmt"] after
    quoting [fmt]. *)

(** Rules for RPM-based distributions *)
module RPM : sig
  val update : t
  (** [update] will run [yum update -y] *)

  val install : ('a, unit, string, t) format4 -> 'a
  (** [install fmt] will run [yum install] on the supplied package list. *)

  val groupinstall : ('a, unit, string, t) format4 -> 'a
  (** [groupinstall fmt] will run [yum groupinstall] on the supplied package list. *)

  val add_user : ?uid:int -> ?gid:int -> ?sudo:bool -> string -> t
  (** [add_user username] will install a new user with name [username] and a locked
      password.  If [sudo] is true then root access with no password will also be
      configured.  The default value for [sudo] is [false]. *)

  val dev_packages : ?extra:string -> unit -> t
  (** [dev_packages ?extra ()] will install the base development tools and [sudo],
      [passwd] and [git].  Extra packages may also be optionally supplied via [extra]. *)

  val install_system_ocaml : t
  (** Install the system OCaml packages via Yum *)
end

(** Rules for Apt-based distributions *)
module Apt : sig
  val update : t
  (** [update] will run [apt-get update && apt-get upgrade] non-interactively. *)

  val install : ('a, unit, string, t) format4 -> 'a
  (** [install fmt] will [apt-get update && apt-get install] the packages specified by the [fmt] format string. *)

  val add_user : ?uid:int -> ?gid:int -> ?sudo:bool -> string -> t
  (** [add_user username] will install a new user with name [username] and a locked
      password.  If [sudo] is true then root access with no password will also be
      configured.  The default value for [sudo] is [false]. *)

  val dev_packages : ?extra:string -> unit -> t
  (** [dev_packages ?extra ()] will install the base development tools and [sudo],
      [passwd] and [git] and X11.  Extra packages may also be optionally supplied via [extra]. *)

  val install_system_ocaml : t
  (** Install the system OCaml packages via [apt-get] *)
end

(** Rules for Apk-based distributions such as Alpine Linux *)
module Apk : sig
  val update : t
  (** [update] will run [apk update && apk upgrade] non-interactively. *)

  val install : ('a, unit, string, t) format4 -> 'a
  (** [install fmt] will [apk add] the packages specified by the [fmt] format string. *)

  val dev_packages : ?extra:string -> unit -> t
  (** [dev_packages ?extra ()] will install the base alpine-sdk.
      Extra packages may also be optionally supplied via [extra]. *)

  val add_user : ?uid:int -> ?gid:int -> ?sudo:bool -> string -> t
  (** [add_user username] will install a new user with name [username] and a locked
      password.  If [sudo] is true then root access with no password will also be
      configured.  The default value for [sudo] is [false]. *)

  val install_system_ocaml : t
  (** Install the system OCaml packages via Apk *)
end

(** Rules for Zypper-based distributions such as OpenSUSE *)
module Zypper : sig
  val update : t
  (** [update] will run [zypper update] non-interactively. *)

  val install : ('a, unit, string, t) format4 -> 'a
  (** [install fmt] will [zypper update && zypper install] the packages specified by the [fmt] format string. *)

  val add_user : ?uid:int -> ?gid:int -> ?sudo:bool -> string -> t
  (** [add_user username] will install a new user with name [username] and a locked
      password.  If [sudo] is true then root access with no password will also be
      configured.  The default value for [sudo] is [false]. *)

  val dev_packages : ?extra:string -> unit -> t
  (** [dev_packages ?extra ()] will install the base development tools and [sudo],
      [passwd] and [git].  Extra packages may also be optionally supplied via [extra]. *)

  val install_system_ocaml : t
  (** Install the system OCaml packages via [zypper] *)
end

(** Rules for Git *)
module Git : sig
  val init : ?name:string -> ?email:string -> unit -> t
  (** Configure the git name and email variables to sensible defaults *)
end
