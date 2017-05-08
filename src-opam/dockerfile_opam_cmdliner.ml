(*
 * Copyright (c) 2015 Anil Madhavapeddy <anil@recoil.org>
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

open Cmdliner

let output_dir default =
  let doc = "Output directory for the Dockerfile to be written into." in
  Arg.(value & opt string default & info ["o"] ~docv:"DIR" ~doc)

let opam_version =
  let doc = "OPAM version to install." in
  Arg.(value & opt string Dockerfile_distro.latest_opam_version &
       info ["opam-version"] ~docv:"OPAM_VERSION" ~doc)

let cmd ~name ~version ~summary ~manual ~default_dir ~generate =
  let generate opam_version output_dir = generate ~opam_version ~output_dir in
  let doc = "Generate Dockerfiles for " ^ summary in
  let man = [
    `S "DESCRIPTION";
    `P ("$(tname) generates a set of Dockerfiles that " ^ manual);
    `P "The output directory for these files can be specified with the
        $(b,-o) option.";
    `S "BUGS";
    `P "Report them to via e-mail to <opam-devel@lists.ocaml.org>, or
        on the issue tracker at <https://github.com/avsm/ocaml-dockerfile/issues>";
    `S "SEE ALSO";
    `P "$(b,opam)(1), $(b,ocaml)(1)" ]
  in
  Term.(pure generate $ opam_version $ output_dir default_dir),
  Term.info name ~version ~doc ~man

let run cmd =
  match Term.eval cmd
  with `Error _ -> exit 1 | _ -> exit 0
