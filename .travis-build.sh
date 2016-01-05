#!/bin/sh -ex

cd /repo/__test
ocamlc -o travis_opam unix.cma yorick.mli yorick.ml travis_opam.ml
cd /repo
/repo/__test/travis_opam
