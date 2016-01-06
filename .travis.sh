#!/bin/sh -ex

OS=~/build/$TRAVIS_REPO_SLUG
chmod -R a+w $OS
docker run -v \
  $OS:/repo \
  ocaml/opam:${DISTRO}_ocaml-${OCAML_VERSION} \
  sh -c "cd /repo && travis-opam"
