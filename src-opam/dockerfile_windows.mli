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

val run_vc : arch:Ocaml_version.arch -> ('a, unit, string, t) format4 -> 'a
(** [run_vc ~arch fmt] will execute [run fmt] with Visual
   Compiler for [~arch] loaded in the environment. *)

val run_ocaml_env : string list -> ('a, unit, string, t) format4 -> 'a
(** [run_ocaml_env args fmt] will execute [fmt] in the evironment
   loaded by [ocaml-env exec] with [args]. *)

val install_vc_redist : ?vs_version:string -> unit -> t
(** Install Microsoft Visual C++ Redistributable.
   @see <https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads> *)

val install_visual_studio_build_tools : ?vs_version:string -> string list -> t
(** Install Visual Studio Build Tools components.
   @see <https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2019> *)

val ocaml_for_windows_package_exn :
  switch:Ocaml_version.t -> port:[`Mingw | `Msvc] -> arch:Ocaml_version.arch ->
  (string * string)
(** [ocaml_for_windows_variant ~port ~arch] returns the
   [(package_name, package_version)] of the OCaml compiler
   package in OCaml for Windows, if applicable. *)

val cleanup : unit -> t
(** Cleanup caches. *)

(** Rules for Cygwin-based installation *)
module Cygwin : sig
  type cyg = {
      root : string; (** Root installation directory *)
      site : string; (** Download site URL *)
      args : string list; (** List of arguments to give to Cygwin's
                             setup, except [--root] and [--site]. *)
    }

  val default : cyg
  (** The default Cygwin root, mirror, and arguments. *)

  val setup : ?cyg:cyg -> ?winsymlinks_native:bool -> ?extra:string list -> unit -> t
  (** Setup Cygwin with CygSymPathy and msvs-tools, and [extra] Cygwin
     packages. Sets the [CYGWIN=winsymlinks:native] environment
     variable by default.
     @see <https://github.com/metastack/cygsympathy>
     @see <https://github.com/metastack/msvs-tools> *)

  val install : ?cyg:cyg -> ('a, unit, string, t) format4 -> 'a
  (** Install the supplied Cygwin package list. The packages should be
     comma-separated. *)

  val update : ?cyg:cyg -> unit -> t
  (** Update Cygwin packages. *)

  val cygwin_packages : ?extra:string list -> ?flexdll_version:string -> unit
                        -> string list
  (** [cygwin_packages ?extra ()] will install the base development
     tools for the OCaml Cygwin port. Extra packages may also be
     optionally supplied via [extra]. *)

  val mingw_packages : ?extra:string list -> unit -> string list
  (** [mingw_packages ?extra ()] will install the base development
     tools for the OCaml mingw port. Extra packages may also be
     optionally supplied via [extra]. *)

  val msvc_packages : ?extra:string list -> unit -> string list
  (** [msvc_packages ?extra ()] will install the base development
     tools for the OCaml MSVC port. Extra packages may also be
     optionally supplied via [extra]. *)

  val ocaml_for_windows_packages : ?cyg:cyg -> ?extra:string list -> ?version:string -> unit
                                   -> string list * t
  (** [ocaml_for_windows_packages ?extra ()] returns the list of
     Cygwin packages dependencies, and the installation instructions.
     Extra packages may also be optionally supplied via [extra].
     @see <https://fdopen.github.io/opam-repository-mingw/> *)

  val run_sh : ?cyg:cyg -> ('a, unit, string, t) format4 -> 'a
  (** [run_sh ?cyg fmt] will execute in the Cygwin root
     [\bin\bash.exe --login -c "fmt"]. *)

  val run_sh_ocaml_env : ?cyg:cyg -> string list -> ('a, unit, string, t) format4 -> 'a
  (** [run_cmd_ocaml_env args fmt] will execute [fmt] in the evironment
     loaded by [ocaml-env cygwin exec] with [args]. *)

  (** Rules for Git *)
  module Git : sig
    val init : ?cyg:cyg -> ?name:string -> ?email:string -> unit -> t
    (** Configure the git name and email variables to sensible defaults *)
  end
end

(** Rules for winget installation.
    @see <https://docs.microsoft.com/en-us/windows/package-manager/winget>/ *)
module Winget : sig
  val is_supported : Dockerfile_distro.win10_release -> bool
  (** Winget 1.0.11692 discontinued support for versions older than
     Windows 10 1809. Older versions of Winget have bugs, don't use
     them. *)

  val build_from_source :
    ?arch:Ocaml_version.arch -> ?win10_revision:Dockerfile_distro.win10_lcu ->
    ?version:Dockerfile_distro.win10_release ->
    ?winget_version:string -> ?vs_version:string -> unit -> t
  (** Build winget from source (in a separate Docker image). The
     optional [winget_version] specifies a Git reference. *)

  val install_from_release :
    ?win10_revision:Dockerfile_distro.win10_lcu ->
    ?version:Dockerfile_distro.win10_release -> ?winget_version:string -> unit -> t
  (** Install winget from a released build (first in a separate Docker
     image). The optional [winget_version] specifies a Git tag. *)

  val setup : ?from:string -> unit -> t
  (** Setup winget, copied from the [from] Docker image. Disable
     winget telemetry. *)

  val install : string list -> t
  (** [install packages] will install the supplied winget package list. *)

  val dev_packages :
    ?version:Dockerfile_distro.win10_release ->
    ?extra:string list -> unit -> t
  (** [dev_packages ?version ?extra ()] will install the base development
     tools. Extra packages may also be optionally supplied via
     [extra]. Using [?version] may change the set of installed packages. *)

  (** Rules for Git *)
  module Git : sig
    val init : ?name:string -> ?email:string -> unit -> t
    (** Configure the git name and email variables to sensible defaults *)
  end
end
