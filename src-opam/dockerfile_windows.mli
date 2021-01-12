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

val run_cmd : ('a, unit, string, t) format4 -> 'a
(** [run_cmd fmt] will execute [cmd /S /C fmt]. *)

val run_powershell : ('a, unit, string, t) format4 -> 'a
(** [run_powershell fmt] will execute [powershell -Command "fmt"]. *)

val install_vc_redist : ?version:string -> unit -> t
(** Install Microsoft Visual C++ Redistributable.
   @see <https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads> *)

val install_visual_studio_build_tools : ?version:string -> string list -> t
(** Install Visual Studio Build Tools components.
   @see <https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2019> *)

val cleanup : unit -> t
(** Cleanup caches. *)

(** Rules for Cygwin-based installation *)
module Cygwin : sig
  type cyg = {
      root : string; (** Cygwin root directory *)
      mirror : string; (** Cygwin mirror *)
    }

  val default : cyg
  (** The default Cygwin root and mirror. *)

  val setup : ?cyg:cyg -> unit -> t
  (** Setup Cygwin with CygSymPathy and msvs-tools, and no extra
     Cygwin packages.
     @see <https://github.com/dra27/cygsympathy/tree/script>
     @see <https://github.com/metastack/msvs-tools> *)

  val install : ?cyg:cyg -> ('a, unit, string, t) format4 -> 'a
  (** Install the supplied Cygwin package list. *)

  val update : ?cyg:cyg -> unit -> t
  (** Update Cygwin packages. *)

  val cygwin_packages : ?cyg:cyg -> ?extra:string -> unit -> t
  (** [cygwin_packages ?cyg ?extra ()] will install the base
     development tools for the OCaml Cygwin port. Extra packages may
     also be optionally supplied via [extra]. *)

  val mingw_packages : ?cyg:cyg -> ?extra:string -> unit -> t
  (** [mingw_packages ?cyg ?extra ()] will install the base development
     tools for the OCaml mingw port. Extra packages may also be
     optionally supplied via [extra]. *)

  val msvc_packages : ?cyg:cyg -> ?extra:string -> unit -> t
  (** [msvc_packages ?cyg ?extra ()] will install the base development
     tools for the OCaml MSVC port. Extra packages may also be
     optionally supplied via [extra]. *)

  val ocaml_for_windows_packages : ?cyg:cyg -> ?extra:string -> ?version:string -> unit -> t
  (** [ocaml_for_windows_packages ?cyg ?extra ()] will install OCaml
     for Windows and its required Cygwin packages. Extra packages may
     also be optionally supplied via [extra].
     @see <https://fdopen.github.io/opam-repository-mingw/> *)

  val run_sh : ?cyg:cyg -> ('a, unit, string, t) format4 -> 'a
  (** [run_sh ?cyg fmt] will execute in the Cygwin root
     [\bin\bash.exe --login -c "fmt"]. *)

  (** Rules for Git *)
  module Git : sig
    val init : ?cyg:cyg -> ?name:string -> ?email:string -> unit -> t
    (** Configure the git name and email variables to sensible defaults *)
  end
end

(** Rules for Winget-based installation *)
module Winget : sig
  val setup : ?version:string -> unit -> t
  (** Setup winget-cli. *)

  val install : ('a, unit, string, t) format4 -> 'a
  (** [install fmt] will install the supplied Winget package list. *)

  val dev_packages : ?extra:string list -> unit -> t
  (** [dev_packages ?extra ()] will install the base development
     tools and [git]. Extra packages may also be optionally supplied via
     [extra]. *)

  (** Rules for Git *)
  module Git : sig
    val init : ?name:string -> ?email:string -> unit -> t
    (** Configure the git name and email variables to sensible defaults *)
  end
end
