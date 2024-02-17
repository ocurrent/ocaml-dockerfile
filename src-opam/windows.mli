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

(** Windows specific Dockerfile utility functions. *)

open Dockerfile

val run_cmd : ('a, unit, string, t) format4 -> 'a
(** [run_cmd fmt] will execute [cmd /S /C fmt]. *)

val run_powershell :
  ?escape:(string -> string) -> ('a, unit, string, t) format4 -> 'a
(** [run_powershell fmt] will execute [powershell -Command "fmt"].

      @param escape (defaults to {!Fun.id}) allows to escape [fmt]
        because the calling shell (usually [cmd]) might interpret
        unwanted things in [fmt]. This might help embedding readable
        powershell code. *)

val run_vc : arch:Ocaml_version.arch -> ('a, unit, string, t) format4 -> 'a
(** [run_vc ~arch fmt] will execute [run fmt] with Visual
    Compiler for [~arch] loaded in the environment. *)

val run_ocaml_env : string list -> ('a, unit, string, t) format4 -> 'a
(** [run_ocaml_env args fmt] will execute [fmt] in the environment
    loaded by [ocaml-env exec] with [args]. *)

val sanitize_reg_path : unit -> t
[@@ocaml.doc
  {|[sanitize_reg_path ()] adds the command necessary to remove a trailing
    backslash from the [PATH] value stored in the registry and must be called
    before any further manipulation of this variable is done in the Dockerfile.
    The following error is raised if [PATH] isn't sanitized.

    {v
/usr/bin/bash: -c: line 0: unexpected EOF while looking for matching `"'
/usr/bin/bash: -c: line 1: syntax error: unexpected end of file
    v} |}]

val install_vc_redist :
  ?vs_version:string -> ?arch:Ocaml_version.arch -> unit -> t
(** Install Microsoft Visual C++ Redistributable.
    @see <https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads> *)

val install_visual_studio_build_tools : ?vs_version:string -> string list -> t
(** Install Visual Studio Build Tools components.

    @see <https://learn.microsoft.com/en-us/visualstudio/install/build-tools-container?view=vs-2022>
    @see <https://learn.microsoft.com/en-us/visualstudio/install/build-tools-container-issues?view=vs-2022>
    @see <https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2022> *)

val ocaml_for_windows_package_exn :
  switch:Ocaml_version.t ->
  port:[ `Mingw | `Msvc ] ->
  arch:Ocaml_version.arch ->
  string * string
(** [ocaml_for_windows_variant ~port ~arch] returns the
    [(package_name, package_version)] of the OCaml compiler
    package in OCaml for Windows, if applicable. *)

val remove_system_attribute : ?recurse:bool -> string -> t
(** Remove the system attribute on a path. Might be useful to copy
    data across images when building Docker images. *)

val header :
  alias:string ->
  distro:Distro.t ->
  t
(** A Dockerfile header for multi-staged builds. *)

(** Rules for Cygwin-based installation. *)
module Cygwin : sig
  type cyg = {
    root : string;  (** Root installation directory *)
    site : string;  (** Download site URL *)
    args : string list;
  }
  (** List of arguments to give to Cygwin's setup, except [--root] and [--site]. *)

  val default : cyg
  (** The default Cygwin root, mirror, and arguments. *)

  val install_cygwin :
    ?cyg:cyg ->
    ?msvs_tools:bool ->
    ?aslr_off:bool ->
    ?extra:string list ->
    unit ->
    Dockerfile.t
  (** Install Cygwin with CygSymPathy and optionally msvs-tools,
      and [extra] Cygwin packages (first in a separate Docker image).
      Sets the [CYGWIN=winsymlinks:native] environment variable.
      @see <https://github.com/metastack/cygsympathy>
      @see <https://github.com/metastack/msvs-tools> *)

  val setup : ?cyg:cyg -> ?from:string -> unit -> t
  (** Setup Cygwin workdir, optionally copied from the [from] Docker image. *)

  val install : ?cyg:cyg -> string list -> Dockerfile.t
  (** Install the supplied Cygwin package list. The packages should be
      comma-separated. *)

  val update : ?cyg:cyg -> unit -> t
  (** Update Cygwin packages. *)

  val cygwin_packages : ?flexdll_version:string -> unit -> string list
  (** [cygwin_packages ?extra ()] is the list of the base development
      tools for the OCaml Cygwin port. *)

  val mingw_packages : string list
  (** [mingw_packages] is the list of base development tools for the
      Caml mingw port. *)

  val msvc_packages : string list
  (** [msvc_packages] is the list of base development tools for the
      Caml MSVC port. *)

  val install_ocaml_for_windows :
    ?cyg:cyg -> ?version:string -> unit -> string list * t
  (** [install_ocaml_for_windows ()] returns the list of Cygwin
      packages dependencies, and the installation instructions for
      OCaml for Windows.
      @see <https://fdopen.github.io/opam-repository-mingw/> *)

  val run_sh : ?cyg:cyg -> ('a, unit, string, t) format4 -> 'a
  (** [run_sh ?cyg fmt] will execute in the Cygwin root
      [\bin\bash.exe --login -c "fmt"]. *)

  val run_sh_ocaml_env :
    ?cyg:cyg -> string list -> ('a, unit, string, t) format4 -> 'a
  (** [run_cmd_ocaml_env args fmt] will execute [fmt] in the environment
      loaded by [ocaml-env cygwin exec] with [args]. *)

  (** Rules for Git. *)
  module Git : sig
    val init :
      ?cyg:cyg ->
      ?name:string ->
      ?email:string ->
      ?repos:string list ->
      unit ->
      t
    (** Configure the git name and email variables to sensible defaults.

        @param repos A list of paths to Git repos to mark as safe
          directories. Defaults to the default location of the
          opam-repository. *)
  end
end

(** Rules for winget installation.
    @see <https://docs.microsoft.com/en-us/windows/package-manager/winget> *)
module Winget : sig
  val install_from_release : ?winget_version:string -> unit -> t
  (** Install winget from a released build (first in a separate Docker
      image). The optional [winget_version] specifies a Git tag. *)

  val setup : ?from:string -> unit -> t
  (** Setup winget, optionally copied from the [from] Docker image. Disable
      winget telemetry. *)

  val install : string list -> t
  (** [install packages] will install the supplied winget package list. *)

  val dev_packages : distro:Distro.t -> ?extra:string list -> unit -> t
  (** [dev_packages distro ?extra ()] will install the base development
      tools. Extra packages may also be optionally supplied via [extra]. *)

  (** Rules for Git. *)
  module Git : sig
    val init : ?name:string -> ?email:string -> ?repos:string list -> unit -> t
    (** Configure the git name and email variables to sensible defaults.

        @param repos A list of paths to Git repos to mark as safe
          directories. Defaults to the default location of the
          opam-repository. *)
  end
end
