1.6.0:
* Add a more modern Git in CentOS 6 to make it work with OPAM
  remote refs.

1.5.0:
* Add released OCaml 4.03.0 into the compiler list, and break up
  the exposed variables into a more manageable set of
  `stable_ocaml_versions` and `all_ocaml_versions`.
* Install `centos-release-xen` remote into CentOS6/7 by default
  so that depexts for `xen-devel` work.

1.4.0:
* `Dockerfile_distro.generate_dockerfiles` goes into the current
  directory instead with each Dockerfile suffixed with the release
  name.  There is a new `generate_dockerfiles_in_directories`
  for the old behaviour.
* Move slow ARM distribution out of the default distro list into
  `Dockerfile_distro.slow_distros`.
* Add optional `?pin` argument to `dockerfile_distro` generation
  to make it easier to customise version of packages installed.

1.3.0:
* Rearrange OCaml installation commands to be in `Dockerfile` instead
  of in `Dockerfile_opam` (which is now purely OPAM installation).
* Create a `~/.ssh` folder with the right permissions in all distros.
* Ensure rsync is installed in all the Debian-based containers.
* Correctly label the ARMv7 containers with the `arch=armv7` label.
* Use ppx to build instead of camlp4. Now depends on OCaml 4.02+.

1.2.1:
* Remove redundant `apk update` from Alpine definition.
* Switch default cloud solver to one dedicated to these images so
  they can updated in sync (the default cloud one is getting hit
  by many bulk build hits in parallel and cannot cope with the load).
* Add `distro_of_tag` and `generate_dockerfile` to `Dockerfile_distro`.
* Add `nano` to images to satisfy `opam pin` going interactive.
* Also include `4.03.0` flambda build.
* Add ARMv7hf Raspbian distro (Wheezy and Jessie).

1.2.0:
* Add `dev-repo` metadata to OPAM file.
* Add support for installing the cloud solver for platforms where aspcud is not available.
* Add CMD entrypoints for containers.
* Alpine: add `bash` in container (requested by @justincormack)
* Debian: correct non-interactive typos and add `dialog` in container
* Remove `onbuild` triggers from OPAM containers as it inhibits caching (suggestion via @talex5)
* Include specific Debian versions (v7,8,9) in addition to the stable/unstable streams.
* Add `Dockerfile.crunch` to reduce the number of layers by combining
  repeated `RUN` commands.
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
