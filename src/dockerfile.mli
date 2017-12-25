(*
 * Copyright (c) 2014 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2014 Docker Inc (for the documentation comments, which
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

(** Generate [Dockerfile] scripts for use with the Docker container manager *)

(** {2 Core combinators and serializers} *)

(** [t] is a list of Dockerfile lines *)
type t

val sexp_of_t : t -> Sexplib.Sexp.t
(** [sexp_of_t t] converts a Dockerfile into a s-expression representation. *)

val t_of_sexp : Sexplib.Sexp.t -> t
(** [t_of_sexp s] converts the [s] s-expression representation into a {!t}.
    The s-expression should have been generated using {!sexp_of_t}. *)

val string_of_t : t -> string
(** [string_of_t t] converts a {!t} into a Dockerfile format entry *)

val pp : t Fmt.t
(** [pp] is a formatter that outputs a {!t} in Dockerfile format. *)

val ( @@ ) : t -> t -> t
(** [a @@ b] concatenates two Dockerfile fragments into one. *)

val ( @@@ ) : t -> t list -> t
(** [a @@@ b] concatenates the [b] list of Dockerfile fragments onto [a]. *)

val empty : t
(** An empty set of instruction lines. *)

val maybe : ('a -> t) -> 'a option -> t
(** [maybe f v] returns {!empty} if the optional value [v] is [None], and
    otherwise applies [f] to the [Some] value in [v]. *)

(** {2 Dockerfile commands} *)

val comment : ('a, unit, string, t) format4 -> 'a
(** Adds a comment to the Dockerfile for documentation purposes *)

val from : ?alias:string -> ?tag:string -> string -> t
(** The [from] instruction sets the base image for subsequent instructions.

    - A valid Dockerfile must have [from] as its first instruction. The image
      can be any valid image.
    - [from] must be the first non-comment instruction in the Dockerfile.
    - [from] can appear multiple times within a single Dockerfile in order to
      create multiple images. Multiple FROM commands will result in a multi-stage
      build, and the [?from] argument to the {!copy} and {!add} functions
      can move artefacts across stages.

    By default, the stages are not named, and you refer to them by their
    integer number, starting with 0 for the first [FROM] instruction. However,
    you can name your stages, by supplying an [?alias] argument.  The alias
    can be supplied to the [?from] parameter to {!copy} or {!add} to refer
    to this particular stage by name.

    If no [tag] is supplied, [latest] is assumed. If the used tag does not
    exist, an error will be returned.
*)

val maintainer : ('a, unit, string, t) format4 -> 'a
(** [maintainer] sets the author field of the generated images. *)

val run : ('a, unit, string, t) format4 -> 'a
(** [run fmt] will execute any commands in a new layer on top of the current
  image and commit the results. The resulting committed image will be used
  for the next step in the Dockerfile.  The string result of formatting
  [arg] will be passed as a [/bin/sh -c] invocation. *)

val run_exec : string list -> t
(** [run_exec args] will execute any commands in a new layer on top of the current
  image and commit the results. The resulting committed image will be used
  for the next step in the Dockerfile.  The [args] form makes it possible
  to avoid shell string munging, and to run commands using a base image that
  does not contain [/bin/sh]. *)

val cmd : ('a, unit, string, t) format4 -> 'a
(** [cmd args] provides defaults for an executing container. These defaults
  can include an executable, or they can omit the executable, in which case
  you must specify an {!entrypoint} as well.  The string result of formatting
  [arg] will be passed as a [/bin/sh -c] invocation.

  There can only be one [cmd] in a Dockerfile. If you list more than one 
  then only the last [cmd] will take effect. *)

val cmd_exec : string list -> t
(** [cmd_exec args] provides defaults for an executing container. These defaults
  can include an executable, or they can omit the executable, in which case
  you must specify an {!entrypoint} as well.  The first argument to the [args]
  list must be the full path to the executable. 

  There can only be one [cmd] in a Dockerfile. If you list more than one 
  then only the last [cmd] will take effect. *)

val expose_port : int -> t
(** [expose_port] informs Docker that the container will listen on the specified
  network port at runtime. *)

val expose_ports : int list -> t
(** [expose_ports] informs Docker that the container will listen on the specified
  network ports at runtime. *)

val env : (string * string) list -> t
(** [env] sets the list of environment variables supplied with the
  (<key>, <value>) tuple. This value will be passed to all future {!run}
  instructions. This is functionally equivalent to prefixing a shell
  command with [<key>=<value>]. *)

val add : ?from:string -> src:string list -> dst:string -> unit -> t
(** [add ?from ~src ~dst ()] copies new files, directories or remote file URLs
  from [src] and adds them to the filesystem of the container at the
  [dst] path.

  Multiple [src] resource may be specified but if they are files or
  directories then they must be relative to the source directory that
  is being built (the context of the build).

  Each [src] may contain wildcards and matching will be done using
  Go's filepath.Match rules. 

  All new files and directories are created with a UID and GID of 0.
  In the case where [src] is a remote file URL, the destination will
  have permissions of 600. If the remote file being retrieved has an
  HTTP Last-Modified header, the timestamp from that header will be
  used to set the mtime on the destination file. Then, like any other
  file processed during an ADD, mtime will be included in the
  determination of whether or not the file has changed and the cache
  should be updated.

  The [?from] parameter allows artefacts to be retrieved from multiple
  {!commands}. It can either be an integer number (starting with 0 for the
  first {!from} command, or a named stage (supplied via [?alias] to the
  {!from} command). *)

val copy : ?from:string -> src:string list -> dst:string -> unit -> t
(** [copy ?from ~src ~dst ()] copies new files or directories from [src] and
  adds them to the filesystem of the container at the path [dst]. See
  {!add} for more detailed documentation. *)

val user : ('a, unit, string, t) format4 -> 'a
(** [user fmt] sets the user name or UID to use when running the image
  and for any {!run}, {!cmd}, {!entrypoint} commands that follow it in
  the Dockerfile.  *)

val workdir : ('a, unit, string, t) format4 -> 'a
(** [workdir fmt] sets the working directory for any {!run}, {!cmd}
  and {!entrypoint} instructions that follow it in the Dockerfile.

  It can be used multiple times in the one Dockerfile. If a relative
  path is provided, it will be relative to the path of the previous
  {!workdir} instruction. *)

val volume : ('a, unit, string, t) format4 -> 'a
(** [volume fmt] will create a mount point with the specified name
  and mark it as holding externally mounted volumes from native host
  or other containers. The value can be a JSON array or a plain string
  with multiple arguments that specify several mount points. *)

val volumes : string list -> t
(** [volumes mounts] will create mount points with the specified names
  in [mounts] and mark them as holding externally mounted volumes
  from native host or other containers. *)

val entrypoint : ('a, unit, string, t) format4 -> 'a
(** [entrypoint fmt] allows you to configure a container that will
  run as an executable.  The [fmt] string will be executed using
  a [/bin/sh] subshell.

  The shell form prevents any {!cmd} or {!run} command line arguments
  from being used, but has the disadvantage that your {!entrypoint}
  will be started as a subcommand of [/bin/sh -c], which does not pass
  signals. This means that the executable will not be the container's
  PID 1 - and will not receive Unix signals - so your executable will
  not receive a SIGTERM from [docker stop <container>].

  To get around this limitation, use the {!entrypoint_exec} command
  to directly execute an argument list without a subshell.
*)

val entrypoint_exec : string list -> t
(** [entrypoint fmt] allows you to configure a container that will
  run as an executable.  You can use the exec form here to set fairly
  stable default commands and arguments and then use either {!cmd} or
  {!cmd_exec} to set additional defaults that are more likely to be changed
  by the user starting the Docker container. *)

val onbuild : t -> t
(** [onbuild t] adds to the image a trigger instruction [t] to be
  executed at a later time, when the image is used as the base for
  another build. The trigger will be executed in the context of the
  downstream build, as if it had been inserted immediately after the
  {!from} instruction in the downstream Dockerfile.

  Any build instruction can be registered as a trigger.

  This is useful if you are building an image which will be used as a
  base to build other images, for example an application build environment
  or a daemon which may be customized with user-specific configuration. *)

val label : (string * string) list -> t
(** [label l] adds metadata to an image via a list of key-value pairs.
  To include spaces within a label value, use quotes and backslashes as
  you would in command-line parsing. An image can have more than one label.
  To specify multiple labels, Docker recommends combining labels into a
  single label instruction where possible. Each label instruction produces
  a new layer which can result in an inefficient image if you use many labels.

  Labels are additive including [LABEL]s in [FROM] images. If Docker
  encounters a label/key that already exists, the new value overrides any
  previous labels with identical keys.

  To view an image’s labels, use the [docker inspect] command. *)

val crunch : t -> t
(** [crunch t] will reduce coincident {!run} commands into a single
  one that is chained using the shell [&&] operator. This reduces the
  number of layers required for a production image. *)
