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

type t
(** [t] is a list of Dockerfile lines *)

val sexp_of_t : t -> Sexplib.Sexp.t
(** [sexp_of_t t] converts a Dockerfile into a s-expression representation. *)

val t_of_sexp : Sexplib.Sexp.t -> t
(** [t_of_sexp s] converts the [s] s-expression representation into a {!t}. The
    s-expression should have been generated using {!sexp_of_t}. *)

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

type parser_directive = [ `Syntax of string | `Escape of char ]
[@@deriving sexp]

val parser_directive : parser_directive -> t
(** A parser directive. If used, needs to be the first line of the Dockerfile.
    @see <https://docs.docker.com/engine/reference/builder/#parser-directives>
    @see <https://docs.docker.com/build/buildkit/dockerfile-frontend/> *)

val buildkit_syntax : t
(** Convenience function, returns the {{!val-parser_directive}parser directive}
    describing the latest BuildKit syntax. *)

val comment : ('a, unit, string, t) format4 -> 'a
(** Adds a comment to the Dockerfile for documentation purposes *)

type heredoc
(** Build here-document values with {!val:heredoc}. *)

val heredoc :
  ?strip:bool ->
  ?word:string ->
  ?delimiter:string ->
  ('a, unit, string, heredoc) format4 ->
  'a
(** [heredoc ~word here_document] creates a {!type:heredoc} value with
    [here_document] as content and [word] () as opening delimiter. If [word] is
    quoted, then [delimiter] (unquoted [word]) needs to be specified. Quoting
    affects expansion in the here-document. Requires 1.4 {!val:buildkit_syntax}.

    @param strip Whether to strip leading tab characters. Defaults to false.
    @param word The opening delimiter, possibly quoted. Defaults to [EOF].
    @param delimiter
      The closing delimiter, unquoted. Defaults to the content of [word].

    @see <https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_07_04>
      POSIX 2.7.4 Here-Document
    @see <https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md#here-documents>
      BuildKit Here-Documents *)

val from : ?alias:string -> ?tag:string -> ?platform:string -> string -> t
(** The [from] instruction sets the base image for subsequent instructions.

    - A valid Dockerfile must have [from] as its first instruction. The image
      can be any valid image.
    - [from] must be the first non-comment instruction in the Dockerfile.
    - [from] can appear multiple times within a single Dockerfile in order to
      create multiple images. Multiple FROM commands will result in a
      multi-stage build, and the [?from] argument to the {!copy} and {!add}
      functions can move artefacts across stages.

    By default, the stages are not named, and you refer to them by their integer
    number, starting with 0 for the first [FROM] instruction. However, you can
    name your stages, by supplying an [?alias] argument. The alias can be
    supplied to the [?from] parameter to {!copy} or {!add} to refer to this
    particular stage by name.

    If no [tag] is supplied, [latest] is assumed. If the used tag does not
    exist, an error will be returned.

    The optional [platform] flag can be used to specify the platform of the
    image in case the [from] references a multi-platform image. For example,
    [linux/386] could be used. By default, the target platform of the build
    request is ued if this is not specified. *)

val maintainer : ('a, unit, string, t) format4 -> 'a
(** [maintainer] sets the author field of the generated images. *)

type mount
type network = [ `Default | `None | `Host ]
type security = [ `Insecure | `Sandbox ]
type device

val run :
  ?mounts:mount list ->
  ?network:network ->
  ?security:security ->
  ?device:device ->
  ('a, unit, string, t) format4 ->
  'a
(** [run ?mounts ?network ?security fmt] will execute any commands in a new
    layer on top of the current image and commit the results. The resulting
    committed image will be used for the next step in the Dockerfile. The string
    result of formatting [arg] will be passed as a [/bin/sh -c] invocation.

    @param mounts
      A list of filesystem mounts that the build can access. Requires
      {!val:buildkit_syntax} 1.2.

    @param network
      Control which networking environment the command is run in. Requires
      {!val:buildkit_syntax} 1.1. Requires BuildKit
      {{!val:parser_directive}syntax} 1.1.

    @param security
      Control which security mode the command is run in. Requires BuildKit
      {{!val:parser_directive}syntax} 1-labs.

    @param device
      Lets builds request CDI devices are available to the build step. See
      {!val-device}. *)

val run_exec :
  ?mounts:mount list ->
  ?network:network ->
  ?security:security ->
  ?device:device ->
  string list ->
  t
(** [run_exec ?mounts ?network ?security args] will execute any commands in a
    new layer on top of current image and commit the results. The resulting
    committed image will be used for the next step in the Dockerfile. The [cmd]
    form makes it possible to avoid shell string munging, and to run commands
    using a base image that does not contain [/bin/sh].

    @param mounts
      A list of filesystem mounts that the build can access. Requires
      {!val:buildkit_syntax} 1.2.

    @param network
      Control which networking environment the command is run in. Requires
      {!val:buildkit_syntax} 1.1.

    @param security
      Control which security mode the command is run in. Requires BuildKit
      {{!val:parser_directive}syntax} 1-labs.

    @param device
      Lets builds request CDI devices are available to the build step. See
      {!val-device}. *)

val run_heredoc :
  ?mounts:mount list ->
  ?network:network ->
  ?security:security ->
  ?device:device ->
  (heredoc * string option) list ->
  t
(** [run_heredoc ?mounts ?network ?security docs] will execute any commands in a
    new layer on top of the current image and commit the results. The resulting
    committed image will be used for the next step in the Dockerfile. The string
    result of formatting [arg] will be passed as a [/bin/sh -c] invocation.

    @param mounts
      A list of filesystem mounts that the build can access. Requires
      {!val:buildkit_syntax} 1.2.

    @param network
      Control which networking environment the command is run in. Requires
      {!val:buildkit_syntax} 1.1. Requires BuildKit
      {{!val:parser_directive}syntax} 1.1.

    @param security
      Control which security mode the command is run in. Requires BuildKit
      {{!val:parser_directive}syntax} 1-labs.

    @param device
      Lets builds request CDI devices are available to the build step. See
      {!val-device}. *)

val mount_bind :
  target:string ->
  ?source:string ->
  ?from:string ->
  ?readwrite:bool ->
  unit ->
  mount
(** [mount_bind ~target ?source ?from ?readwrite ()] Creates a bind mount for
    {!run}.

    Requires {!buildkit_syntax}.

    @param target
      the target of the mount inside the container. Usually a path, but for
      'podman' it can also contain SELinux flags like ',z' or ',Z'
    @param from a build stage to bind mount from (if absent: bind mount host)
    @param source
      path to mount. When [from] is absent this is relative to the build context
      on the host. When [source] is absent it defaults to root of [from].
    @param readwrite
      enables writing to the mount (default: read-only). The data written is not
      persisted, [source] always remains unchanged.

    @see <https://docs.docker.com/engine/ruference/builder/#run---mounttypebind>
      Docker --mount=type=bind reference *)

val mount_cache :
  ?id:string ->
  target:string ->
  ?readonly:bool ->
  ?sharing:[ `Locked | `Private | `Shared ] ->
  ?from:string ->
  ?source:string ->
  ?mode:int ->
  ?uid:int ->
  ?gid:int ->
  unit ->
  mount
(** [mount_cache ?id ~target ?readonly ?sharing ?from ?source ?mode ?uid ?gid
     ()] Creates a cache mount for {!run}.

    Requires {!buildkit_syntax}.

    @param id
      the cache id: all container builds with same cache id (even from other
      unrelated builds) will get the same writable directory mounted. Defaults
      to [target] when absent.
    @param target
      where to mount the cache inside the container. The [RUN] command needs to
      cope with a completely empty cache, and with files from the cache being
      deleted by the container runtime's GC in arbitrary order. E.g. a download
      cache would be suitable here, an entire git repository wouldn't. Also make
      sure that your RUN commands doesn't inadvertently wipe the cache (e.g. apt
      inside a container by default would).
    @param readonly whether the cache is read-only (by default it is writable)
    @param sharing
      how to share the cache between concurrent builds. The default is [`Shared]
      which doesn't use any locking.
    @param from the stage to use for the initial contents of the cache.
    @param source the initial contents of the cache, default is empty.
    @param mode file mode for cache directory
    @param uid UID of cache directory, default 0.
    @param gid GID of cache directory, default 0.

    @see <https://docs.docker.com/engine/reference/builder/#run---mounttypecache>
      Docker --mount=type=cache reference *)

val mount_tmpfs : target:string -> ?size:int -> unit -> mount
(** [mount_tmpfs ~target ?size ())] Creates a tmpfs mount for {!run}.

    Requires {!buildkit_syntax}.

    @param target mounts a [tmpfs] at [target]
    @param size maximum size of [tmpfs] (only supported by Docker)

    Note that the directory seems to be completely removed from the image, so
    once you start using [tmpfs] for a dir, it is recommended that all further
    [RUN] commands use it too to avoid ENOENT errors.

    @see <https://docs.docker.com/engine/reference/builder/#run---mounttypetmpfs>
      Docker --mount=type=tmpfs reference *)

val mount_secret :
  ?id:string ->
  ?target:string ->
  ?required:bool ->
  ?mode:int ->
  ?uid:int ->
  ?gid:int ->
  unit ->
  mount
(** [mount_secret ?id ?target ?required ?mode ?uid ?gid] Creates a secret mount
    for {!run}.

    Requires {!buildkit_syntax}.

    @see <https://docs.docker.com/engine/reference/builder/#run---mounttypesecret>
      Docker --mount=type=secret reference *)

val mount_ssh :
  ?id:string ->
  ?target:string ->
  ?required:bool ->
  ?mode:int ->
  ?uid:int ->
  ?gid:int ->
  unit ->
  mount
(** [mount_ssh ?id ?target ?required ?mode ?uid ?gid] Creates an ssh mount for
    {!run}.

    Requires {!buildkit_syntax}.

    Seems to be only supported by Docker at the moment.

    @see <https://docs.docker.com/engine/reference/builder/#run---mounttypessh>
      Docker --mount=type=ssh reference *)

val device : name:string -> ?required:bool -> unit -> device
(** Create a device for [RUN]. Lets builds request CDI devices are available to
    the build step. *)

val cmd : ('a, unit, string, t) format4 -> 'a
(** [cmd args] provides defaults for an executing container. These defaults can
    include an executable, or they can omit the executable, in which case you
    must specify an {!entrypoint} as well. The string result of formatting [arg]
    will be passed as a [/bin/sh -c] invocation.

    There can only be one [cmd] in a Dockerfile. If you list more than one then
    only the last [cmd] will take effect. *)

val cmd_exec : string list -> t
(** [cmd_exec args] provides defaults for an executing container. These defaults
    can include an executable, or they can omit the executable, in which case
    you must specify an {!entrypoint} as well. The first argument to the [args]
    list must be the full path to the executable.

    There can only be one [cmd] in a Dockerfile. If you list more than one then
    only the last [cmd] will take effect. *)

val expose_port : int -> t
(** [expose_port] informs Docker that the container will listen on the specified
    network port at runtime. *)

val expose_ports : int list -> t
(** [expose_ports] informs Docker that the container will listen on the
    specified network ports at runtime. *)

val arg : ?default:string -> string -> t
(** [arg ~default name] defines a variable that users can pass at build-time to
    the builder with the docker build command using the
    [--build-arg <varname>=<value>] flag. It can optionally include a default
    value. *)

val env : (string * string) list -> t
(** [env] sets the list of environment variables supplied with the (<key>,
    <value>) tuple. This value will be passed to all future {!run} instructions.
    This is functionally equivalent to prefixing a shell command with
    [<key>=<value>]. *)

val add :
  ?link:bool ->
  ?chown:string ->
  ?chmod:int ->
  ?from:string ->
  ?exclude:string list ->
  ?checksum:string ->
  ?keep_git_dir:bool ->
  ?unpack:bool ->
  src:string list ->
  dst:string ->
  unit ->
  t
(** [add ?link ?chown ?chmod ?from ~src ~dst ()] copies new files, directories
    or remote file URLs from [src] and adds them to the filesystem of the
    container at the [dst] path.

    Multiple [src] resource may be specified but if they are files or
    directories then they must be relative to the source directory that is being
    built (the context of the build).

    Each [src] may contain wildcards and matching will be done using Go's
    filepath.Match rules.

    All new files and directories are created with a UID and GID of 0. In the
    case where [src] is a remote file URL, the destination will have permissions
    of 600. If the remote file being retrieved has an HTTP Last-Modified header,
    the timestamp from that header will be used to set the mtime on the
    destination file. Then, like any other file processed during an ADD, mtime
    will be included in the determination of whether or not the file has changed
    and the cache should be updated.

    @param link
      Add files with enhanced semantics where your files remain independent on
      their own layer and don’t get invalidated when commands on previous layers
      are changed. Requires 1.4 {!val:buildkit_syntax}.

    @param chown
      Specify a given username, groupname, or UID/GID combination to request
      specific ownership of the copied content.

    @param chmod
      Specify permissions on the files. Only supported on Linux, with Dockerfile
      syntax 1.3.

    @param from
      Allows artefacts to be retrieved from multiple stages. It can either be an
      integer number (starting with 0 for the first {!from} stage, or a named
      stage (supplied via [?alias] to the {!from} command).

    @param checksum Verify a remote file checksum.

    @param keep_git_dir
      When cloning a Git repository, the flag adds the [.git] directory. This
      flag defaults to false.

    @param exclude
      The [--exclude] flag lets you specify a path expression for files to be
      excluded. The path expression follows the same format as [<src>],
      supporting wildcards and matching using Go's [filepath.Match] rules.

    @param unpack
      Control whether archives from a URL path are unpacked. The default is to
      detect unpack behavior based on the source path. *)

val copy :
  ?link:bool ->
  ?chown:string ->
  ?chmod:int ->
  ?from:string ->
  ?parents:bool ->
  ?exclude:string list ->
  src:string list ->
  dst:string ->
  unit ->
  t
(** [copy ?link ?chown ?from ~src ~dst ()] copies new files or directories from
    [src] and adds them to the filesystem of the container at the path [dst].
    See {!add} for more detailed documentation.

    @param link
      Copy files with enhanced semantics where your files remain independent on
      their own layer and don’t get invalidated when commands on previous layers
      are changed. Requires 1.4 {!val:buildkit_syntax}.

    @param chown
      Specify a given username, groupname, or UID/GID combination to request
      specific ownership of the copied content.

    @param chmod
      Specify permissions on the files. Only supported on Linux, with Dockerfile
      syntax 1.3.

    @param from
      Allows artefacts to be retrieved from multiple stages. It can either be an
      integer number (starting with 0 for the first {!from} stage, or a named
      stage (supplied via [?alias] to the {!from} command).

    @param parents
      The [--parents] flag preserves parent directories for [src] entries. This
      flag defaults to [false].

    @param exclude
      The [--exclude] flag lets you specify a path expression for files to be
      excluded. The path expression follows the same format as [<src>],
      supporting wildcards and matching using Go's [filepath.Match] rules. *)

val copy_heredoc :
  ?chown:string -> ?chmod:int -> src:heredoc list -> dst:string -> unit -> t
(** [copy_heredoc src dst] creates the file [dst] using the content of the
    here-documents [src]. Requires 1.4 {!val:buildkit_syntax}.

    @see <https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md#here-documents>
*)

val user : ('a, unit, string, t) format4 -> 'a
(** [user fmt] sets the user name or UID to use when running the image and for
    any {!run}, {!cmd}, {!entrypoint} commands that follow it in the Dockerfile.
*)

val workdir : ('a, unit, string, t) format4 -> 'a
(** [workdir fmt] sets the working directory for any {!run}, {!cmd} and
    {!entrypoint} instructions that follow it in the Dockerfile.

    It can be used multiple times in the one Dockerfile. If a relative path is
    provided, it will be relative to the path of the previous {!workdir}
    instruction. *)

val volume : ('a, unit, string, t) format4 -> 'a
(** [volume fmt] will create a mount point with the specified name and mark it
    as holding externally mounted volumes from native host or other containers.
    The value can be a JSON array or a plain string with multiple arguments that
    specify several mount points. *)

val volumes : string list -> t
(** [volumes mounts] will create mount points with the specified names in
    [mounts] and mark them as holding externally mounted volumes from native
    host or other containers. *)

val entrypoint : ('a, unit, string, t) format4 -> 'a
(** [entrypoint fmt] allows you to configure a container that will run as an
    executable. The [fmt] string will be executed using a [/bin/sh] subshell.

    The shell form prevents any {!cmd} or {!run} command line arguments from
    being used, but has the disadvantage that your {!entrypoint} will be started
    as a subcommand of [/bin/sh -c], which does not pass signals. This means
    that the executable will not be the container's PID 1 - and will not receive
    Unix signals - so your executable will not receive a SIGTERM from
    [docker stop <container>].

    To get around this limitation, use the {!entrypoint_exec} command to
    directly execute an argument list without a subshell. *)

val entrypoint_exec : string list -> t
(** [entrypoint fmt] allows you to configure a container that will run as an
    executable. You can use the exec form here to set fairly stable default
    commands and arguments and then use either {!cmd} or {!cmd_exec} to set
    additional defaults that are more likely to be changed by the user starting
    the Docker container. *)

val shell : string list -> t
(** [shell t] allows the default shell used for the shell form of commands to be
    overridden. The default shell on Linux is ["/bin/sh"; "-c"], and on Windows
    is ["cmd"; "/S"; "/C"]. The [shell] instruction can appear multiple times.
    Each [shell] instruction overrides all previous [shell] instructions, and
    affects all subsequent instructions. *)

val onbuild : t -> t
(** [onbuild t] adds to the image a trigger instruction [t] to be executed at a
    later time, when the image is used as the base for another build. The
    trigger will be executed in the context of the downstream build, as if it
    had been inserted immediately after the {!from} instruction in the
    downstream Dockerfile.

    Any build instruction can be registered as a trigger.

    This is useful if you are building an image which will be used as a base to
    build other images, for example an application build environment or a daemon
    which may be customized with user-specific configuration. *)

val label : (string * string) list -> t
(** [label l] adds metadata to an image via a list of key-value pairs. To
    include spaces within a label value, use quotes and backslashes as you would
    in command-line parsing. An image can have more than one label. To specify
    multiple labels, Docker recommends combining labels into a single label
    instruction where possible. Each label instruction produces a new layer
    which can result in an inefficient image if you use many labels.

    Labels are additive including [LABEL]s in [FROM] images. If Docker
    encounters a label/key that already exists, the new value overrides any
    previous labels with identical keys.

    To view an image’s labels, use the [docker inspect] command. *)

val healthcheck :
  ?interval:string ->
  ?timeout:string ->
  ?start_period:string ->
  ?start_interval:string ->
  ?retries:int ->
  ('a, unit, string, t) format4 ->
  'a
(** [healthcheck cmd] checks container health by running a command inside the
    container. See {!cmd} for additional details.

    @param interval
      The health check will first run [interval] seconds after the container is
      started, and then again [interval] seconds after each previous check
      completes.

    @param timeout
      If a single run of the check takes longer than [timeout] seconds then the
      check is considered to have failed.

    @param start_period
      provides initialization time for containers that need time to bootstrap.
      Probe failure during that period will not be counted towards the maximum
      number of retries. However, if a health check succeeds during the start
      period, the container is considered started and all consecutive failures
      will be counted towards the maximum number of retries.

    @param start_interval
      is the time between health checks during the start period.

    @param retries
      It takes [retries] consecutive failures of the health check for the
      container to be considered {i unhealthy}. *)

val healthcheck_exec :
  ?interval:string ->
  ?timeout:string ->
  ?start_period:string ->
  ?start_interval:string ->
  ?retries:int ->
  string list ->
  t
(** [healthcheck_exec cmd] checks container health by running a command inside
    the container. See {!cmd_exec} and {!healthcheck} for additional details. *)

val healthcheck_none : unit -> t
(** [healthcheck_none] disables any healthcheck inherited from the base image.
*)

val stopsignal : string -> t
(** [stopsignal signal] sets the system call signal that will be sent to the
    container to exit. *)

val crunch : t -> t
(** [crunch t] will reduce coincident {!run} commands into a single one that is
    chained using the shell [&&] operator. This reduces the number of layers
    required for a production image.

    @raise Invalid_argument
      if mounts or networks or security modes differ for each run command. *)

val layers : t -> int
(** [layers t] approximates the number of layers that would be produced by the
    Docker build of this Dockerfile. Each {!from}, {!run}, {!copy}, {!add}
    command produces a new layer. *)
