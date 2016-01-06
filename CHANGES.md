1.2.0:
* Set Debian `apt-get` commands to `noninteractive`.
* Add support for Ubuntu 12.04 LTS and also bleeding edge 16.04.
* Add sexplib convertors for `Dockerfile.t`.
* Add `Dockerfile_distro` module to handle supported online distributions.
* Add `Dockerfile.label` to support Docker 1.6 metadata labels.
* Add `generate_dockerfiles_in_git_branches` to make it easier
  to use Docker Hub dynamic branch support to build all permutations.
* Correctly escape the `run_exec`, `entrypoint_exec` and `cmd_exec`
  JSON arrays so that the strings are quoted.
* Run `yum clean` after a Yum installation.
* Add support for Alpine Linux.
* Cleanup OPAM build directory to save container space after building from source.
* Remove support for OpenSUSE remotes, as it is no longer maintained.

1.1.1 (2015-03-11):
* Add a `?prefix` argument to `install_opam_from_source`

1.1.0 (2015-01-24):
* Add `Dockerfile_opam` and `Dockerfile_opam_cmdliner` modules with
  specific rules for managing OPAM installations with Dockerfiles.

1.0.0 (2014-12-30):
* Initial public release.
