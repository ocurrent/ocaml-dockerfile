#!/bin/sh -ex

# create env file
echo PACKAGE="$PACKAGE" > env.list
echo EXTRA_REMOTES="$EXTRA_REMOTES" >> env.list
echo PINS="$PINS" >> env.list
echo INSTALL="$INSTALL" >> env.list
echo DEPOPTS="$DEPOPTS" >> env.list
echo TESTS="$TESTS" >> env.list
echo REVDEPS="$REVDEPS" >> env.list
echo EXTRA_DEPS="$EXTRA_DEPS" >> env.list
echo PRE_INSTALL_HOOK="$PRE_INSTALL_HOOK" >> env.list
echo POST_INSTALL_HOOK="$POST_INSTALL_HOOK" >> env.list

OS=~/build/$TRAVIS_REPO_SLUG
chmod -R a+w $OS
docker run --env-file=env.list -v \
  $OS:/repo \
  ocaml/opam:${DISTRO}_ocaml-${OCAML_VERSION} \
  sh -c "cd /repo && travis-opam"
