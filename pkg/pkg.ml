#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let () =
  Pkg.describe "dockerfile" @@ fun c ->
  Ok [ Pkg.mllib "src/dockerfile.mllib";
       Pkg.mllib "src/dockerfile_opam.mllib";
       Pkg.mllib "src/dockerfile_opam_cmdliner.mllib"
  ]
