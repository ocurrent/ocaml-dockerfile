* Always install OPAM from source on Alpine until upstreaming
  is complete.

v2.1.0 2016-11-07 Cambridge

* Update for OCaml 4.04 release. Now the "latest version"
  of the compiler is 4.03.0 since many packages do not yet
  compile for 4.04.
* Do not install `camlp4` in the base OPAM switch by default,
  as the dependencies in upstream OPAM work well enough to
  pull it in on-demand.

v2.0.0 2016-11-04 Cambridge
---------------------------

* Move `Dockerfile.Linux` to a separate `Dockerfile_linux`
  module, in preparation for `Dockerfile_windows` soon.
* Avoid using ppx annotations for sexp in the interface
  files, since this breaks ocamldoc.
* Add `Dockerfile.pp` for Format-style output.

v1.7.2
------

* Port to build using topkg and remove _oasis.
* Support `-safe-string` mode.
* Install `xz` into base Fedora and other RPM distros.
* Expose a `Linux.RPM.update` to force a Yum update.
* Install `openssl` as a dependency for OPAM2.

v1.7.1
------

* Support OPAM 2 better with explicit compiler selection.
* Correctly install ocamldoc in system OpenSUSE container.

v1.7.0
------

* *Multiarch:* Add Alpine 3.4 and Alpine/ARMHF 3.4 and
  deprecate Raspbian 7.
* Add OpenSUSE/Zypper support and add OpenSUSE 42.1 to the
  default distro build list.
* Add Ubuntu 16.10 to the distro list, and remove Ubuntu 15.10
  from default build list now that 16.10 LTS is available.
* Add Fedora 24 and make it the alias for Fedora stable. Also
  install `redhat-rpm-config` which is needed for pthreads.
* Add an `extra` arg the Dockerfile_distro matrix targets to
  add more distros to the mix, such as Raspbian.
* Support multiple OPAM versions in the matrix generation, 
  to make testing OPAM master easier.
* Always do an `rpm --rebuilddb` before a Yum invocation to
  deal with possible OverlayFS brokenness.
* Support `opam_version` to distro calls to build and install
  the latest version of OPAM2-dev.
* Add `xz` into Alpine containers so that untar of those works.
* Expose the development versions of OCaml compilers.

v1.6.0
------

* Add a more modern Git in CentOS 6 to make it work with OPAM
  remote refs.

v1.5.0
------

* Add released OCaml 4.03.0 into the compiler list, and break up
  the exposed variables into a more manageable set of
  `stable_ocaml_versions` and `all_ocaml_versions`.
* Install `centos-release-xen` remote into CentOS6/7 by default
  so that depexts for `xen-devel` work.

v1.4.0
------

* `Dockerfile_distro.generate_dockerfiles` goes into the current
  directory instead with each Dockerfile suffixed with the release
  name.  There is a new `generate_dockerfiles_in_directories`
  for the old behaviour.
* Move slow ARM distribution out of the default distro list into
  `Dockerfile_distro.slow_distros`.
* Add optional `?pin` argument to `dockerfile_distro` generation
  to make it easier to customise version of packages installed.

v1.3.0
------

* Rearrange OCaml installation commands to be in `Dockerfile` instead
  of in `Dockerfile_opam` (which is now purely OPAM installation).
* Create a `~/.ssh` folder with the right permissions in all distros.
* Ensure rsync is installed in all the Debian-based containers.
* Correctly label the ARMv7 containers with the `arch=armv7` label.
* Use ppx to build instead of camlp4. Now depends on OCaml 4.02+.

v1.2.1
------

* Remove redundant `apk update` from Alpine definition.
* Switch default cloud solver to one dedicated to these images so
  they can updated in sync (the default cloud one is getting hit
  by many bulk build hits in parallel and cannot cope with the load).
* Add `distro_of_tag` and `generate_dockerfile` to `Dockerfile_distro`.
* Add `nano` to images to satisfy `opam pin` going interactive.
* Also include `4.03.0` flambda build.
* Add ARMv7hf Raspbian distro (Wheezy and Jessie).

v1.2.0
------

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

v1.1.1 2015-03-11 Cambridge
---------------------------

* Add a `?prefix` argument to `install_opam_from_source`

v1.1.0 2015-01-24 Cambridge
---------------------------

* Add `Dockerfile_opam` and `Dockerfile_opam_cmdliner` modules with
  specific rules for managing OPAM installations with Dockerfiles.

v1.0.0 2014-12-30 Cambridge
---------------------------

* Initial public release.

