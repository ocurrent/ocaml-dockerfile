1.2.0:
* Add `Dockerfile.label` to support Docker 1.6 metadata labels.
* Add `generate_dockerfiles_in_git_branches` to make it easier
  to use Docker Hub dynamic branch support to build all permutations.

1.1.1 (2015-03-11):
* Add a `?prefix` argument to `install_opam_from_source`

1.1.0 (2015-01-24):
* Add `Dockerfile_opam` and `Dockerfile_opam_cmdliner` modules with
  specific rules for managing OPAM installations with Dockerfiles.

1.0.0 (2014-12-30):
* Initial public release.
