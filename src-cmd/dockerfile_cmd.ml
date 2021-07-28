(*
 * Copyright (c) 2017 Anil Madhavapeddy <anil@recoil.org>
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
open Rresult
open Bos
open Astring
open R.Infix
module OC = OS.Cmd

let rec iter fn l =
  match l with
  | hd::tl -> fn hd >>= fun () -> iter fn tl
  | [] -> Ok ()

let map fn l =
  List.map fn l |>
  List.fold_left (fun acc b ->
    match acc, b with
    | Ok acc, Ok v -> Ok (v :: acc)
    | Ok _acc, Error v -> Error v
    | Error _ as e, _ -> e
  ) (Ok [])  |> function
  | Ok v -> Ok (List.rev v)
  | e -> e

type cmd_log = {
  command: string;
  stdout: string;
  success: bool;
  status: [ `Signaled of int | `Exited of int ]
} [@@deriving sexp]

let run_log ?(ok_to_fail=true) ?env log_dir name cmd =
  let command = Cmd.to_string cmd in
  OS.Cmd.(run_out ?env ~err:err_run_out) cmd |>
  OS.Cmd.out_string >>= fun (stdout, (_,status)) ->
  let success = status = `Exited 0 in
  let cmd_log = { command; stdout; success; status } in
  let path = Fpath.(log_dir / (name ^ ".sxp")) in
  OS.File.write path (Sexplib.Sexp.to_string_hum (sexp_of_cmd_log cmd_log)) >>= fun () ->
  match status with
  |`Signaled n -> if ok_to_fail then Ok () else R.error_msg (Fmt.str "Signal %d" n)
  |`Exited 0 -> Ok ()
  |`Exited code -> if ok_to_fail then Ok () else R.error_msg (Fmt.str "Exit code %d" code)

(** Docker *)
module Docker = struct
  let bin = Cmd.(v "docker")
  let info = Cmd.(bin % "info")

  let exists () =
    OS.Cmd.run_out info |> OS.Cmd.out_string |> R.is_ok |>
    function
    | true -> Logs.info (fun l -> l "Docker is running"); true
    | false -> Logs.err (fun l -> l "Docker not running"); false

  let build_cmd ?(squash=false) ?(pull=true) ?(cache=true) ?dockerfile ?tag path =
    let open Cmd in
    let cache = if cache then empty else v "--no-cache" in
    let pull = if pull then v "--pull" else empty in
    let squash = if squash then v "--squash" else empty in
    let dfile = match dockerfile with None -> empty | Some d -> v "-f" % p d in
    let tag = match tag with None -> empty | Some t -> v "-t" % t in
    bin % "build" %% tag %% cache %% pull %% squash %% dfile  % p path

  let volume_cmd =
    Cmd.(bin % "volume")

  let push_cmd tag =
    Cmd.(bin % "push" % tag)

  (* Find the image id that we just built *)
  let build_id log =
    let rec find_id =
      function
      | hd::tl when String.is_prefix ~affix:"Successfully tagged " hd -> find_id tl
      | hd::_ when String.is_prefix ~affix:"Successfully built " hd -> begin
         match String.cut ~sep:"Successfully built " hd with
         | Some ("", id) -> R.ok id
         | Some _ -> R.error_msg "Unexpected internal error in build_id"
         | None -> R.error_msg "Malformed successfully built log"
      end
      | _hd::_tl -> R.error_msg "Unexpected lines at end of log"
      | [] -> R.error_msg "Unable to find container id in log" in
    OS.File.read_lines log >>= fun lines ->
    List.rev lines |> fun lines ->
    find_id lines

  let manifest_push_cli ~platforms ~template ~target =
    let platforms = String.concat ~sep:"," platforms in
    Cmd.(v "manifest-tool" % "push" % "from-args" % "--platforms" % platforms
         % "--template" % template % "--target" % target)

  let manifest_push_file file =
     Cmd.(v "manifest-tool" % "push" % "from-spec" % p file)

  let run_cmd ?(mounts=[]) ?(volumes=[]) ?(rm=true) img cmd =
    let rm = if rm then Cmd.(v "--rm") else Cmd.empty in
    let mounts = List.map (fun (src,dst) -> ["--mount"; Printf.sprintf "source=%s,destination=%s" src dst]) mounts |> List.flatten |> Cmd.of_list in
    let vols =
     List.map (fun (src,dst) -> ["-v"; Printf.sprintf "%s:%s" src dst]) volumes |> List.flatten |> Cmd.of_list in
    Cmd.(bin % "run" %% rm %% mounts %% vols % img %% cmd)
end

(** Opam *)
module Opam = struct
  let bin = Cmd.(v "opam")

  let opam_env ~root ~jobs =
    OS.Env.current () >>= fun env ->
    String.Map.add "OPAMROOT" (Cmd.p root) env |>
    String.Map.add "OPAMYES" "1" |>
    String.Map.add "OPAMJOBS" (string_of_int jobs) |> fun env ->
    R.return env
end

open Cmdliner
let setup_logs () =
  let setup_log style_renderer level =
    Fmt_tty.setup_std_outputs ?style_renderer ();
    Logs.set_level level;
    Logs.set_reporter (Logs_fmt.reporter ()) in
  let global_option_section = "COMMON OPTIONS" in
  Term.(const setup_log
    $ Fmt_cli.style_renderer ~docs:global_option_section ()
    $ Logs_cli.level ~docs:global_option_section ())
