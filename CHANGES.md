unreleased
----------

- Add Ubuntu 24.10. (@MisterDA, #222)

v8.2.2 2024-07-31 Rochester
---------------------------

- Added Opam 2.2 (@mtelvers, #215)
- Deprecate Ubuntu 23.10. (@mtelvers, #214)
- Deprecate Ubuntu 23.04. (@punchagan, #213)
- Deprecate Fedora 38. (@mtelvers, #211)
- Deprecate Debian 10. (@shonfeder, #210)
- Add Ubuntu 24.04. (@mtelvers, #205)
- Add Fedora 40, deprecate Fedora 37. (@mtelvers, #203)
- Refactored Windows builds (@mtelvers, #201)
- Add Fedora 39. (@MisterDA #200)
- Add Alpine 3.20, deprecate Alpine 3.18, 3.19. (@MisterDA #167, #197, #199, #207)
- Support formatting RUN heredocs. (@MisterDA #193 #195, reported by @kit-ty-kate)
- Turned off address space layout randomization on Windows 1809. (@mtelvers #196)
- Add Ubuntu 23.10. (@MisterDA #189)
- Deprecate Ubuntu 22.10 it is now EOL. (@tmcgilchrist #184).
- Support `--start-interval` in `HEALTCHECK` Dockerfile instruction.
  (@MisterDA #183)
- Support `--keep-git-dir` in `ADD` Dockerfile instruction. (@MisterDA #182)
- Add Debian 12 as main distribution. (@MisterDA #172)
- Deprecate Ubuntu 18.04 it is now EOL (@avsm).
- Deprecate Alpine 3.16 and 3.17, OracleLinux 7  and OpenSUSE 15.2 (@avsm)
- Add ARM64 builds to OpenSUSE (@mtelvers #178)
- Support `--checksum` argument in `ADD` Dockerfile instruction.
  (@MisterDA #175)
- Support `--chmod` argument in `COPY` and `ADD` Dockerfile
  instructions. (@MisterDA #174)
- Add OpenSUSE Leap 15.6 to Tier 2, deprecate 15.5 and 15.4. (@MisterDA #171, #208)
- Add OpenSUSE Tumbleweed to Tier 2. (@MisterDA #168 #169)
- Deprecate Fedora 36. (@MisterDA #170)
- Support opam new `--with-vendored-deps` configure option. (@MisterDA #165)
- Rework Windows images and update their dependencies. (@MisterDA #162)
  + Fix the origin of `Install.cmd` (avsm -> ocurrent);
  + Rename `Windows.Cygwin.install_from_release` to `install_cygwin`;
  + Rework Cygwin package list needed for opam and OCaml for Windows;
  + Remove msvs-tools from the mingw images;
  + Build opam with MSVS in the MSVS images. Explicitly set MSVS
    environment vars with msvs-detect.
  + Update to VC Redist 17 and MSVC 2022;
  + Track msvs-tools master;
  + Split MSVC build into multiple build steps;
  + Internal refactors.
- Add Ubuntu 23.04 and Fedora 38. (@mtelvers #164)
- Add newlines in some cases for better formatting.
  (@MisterDA #161, review by @benmandrew)
- Various LCU Updates. (@mtelvers #160 #166 #173 #179 #180 #185 #188)

v8.2.1 2023-04-07 Paris
-----------------------

- Correct sexp generation for dockerfile-opam.
  (@benmandrew #158, review by @MisterDA)
- Switch to root and back to opam user when installing OCaml external
  dependencies in the ocaml stage; fixes depext installation.
  (@MisterDA #146, #157)

v8.2.0 2023-03-23 Berlin
------------------------

- Install system packages required by OCaml in the ocaml stage,
  starting with OCaml 5.1 and libzstd.
  (@MisterDA #146, #149, review by @kit-ty-kate)
- Add OracleLinux 9. (@MisterDA #155)
- Optimize and fix Linux package install.
  (@MisterDA #147, #151, #153, #154, review by @kit-ty-kate)
- Switch to ocaml-opam/opam-repository-mingw#sunset for Windows images. (@MisterDA #152)
- Use DockerHub user risvc64/ubuntu. (@MisterDA, #150)
- Various LCU Updates (@mtelvers #156 #144 #136 #135)
- Support mounts, networks, and security parameters in RUN
  commands, add buildkit_syntax helper function.
  (@MisterDA, @edwintorok, #137, #139, review by @edwintorok)
- Build and install opam master from source in Windows images.
  (@MisterDA #140, #142, #143)
- Include the ocaml-beta-repository in the images. (@kit-ty-kate #132, review by @MisterDA)
- Add OpenSUSE 15.4, deprecate OpenSUSE 15.3. (@MisterDA #138)
- Update to bubblewrap 0.8.0. (@MisterDA #131 #148)
- Add Alpine 3.17 (3.16 is now tier 2 and 3.15 is deprecated). Remove
  libexecinfo-dev from the list of apk packages as it is no longer
  available. Its symbols are only used in OCaml's self tests.
  (@MisterDA #129, #130)
- Fix location of Debian exotic architecture images (@dra27 #134)
- Fix passing of --platform to all stages of the Dockerfiles (@dra27 #134)

v8.1.0 2022-11-17 Sydney
------------------------
- Add Fedora 36 and 37 and deprecate 34 and 35. (@MisterDA #125, #126)
- Add Ubuntu 22.10. (@MisterDA #124)
- Support STOPSIGNAL instruction. (@MisterDA #121, review by @avsm)
- Support HEALTHCHECK instruction. (@MisterDA #122, review by @avsm)
- Various LCU Updates, deprecate Windows 10 20H2
  (@mtelvers #128 #115 #109 #107)
- Update to bubblewrap 0.6.2 when building from source in a distro
  packaging an outdated version (@MisterDA #120)
- Add Alpine 3.16 (3.15 is now tier 2 and 3.14 is deprecated)
  (@raphael-proust #119)
- Refactor to be able to install Cygwin and OCaml for Windows in a
  separate multistage build image, then copy. Docker Engine 20.10.18
  for Windows is currently buggy and doesn't allow it.
  (@MisterDA #114)
- Support `ARG` Dockerfile instruction (@MisterDA #116 #117)
- Bump to OCaml 4.08 and remove dependencies on result and rresult (@MisterDA #106)
- Wrap libraries:
  + `Dockerfile_gen` from the `dockerfile-cmd` package becomes `Dockerfile_cmd.Gen`;
  + `Dockerfile_distro`, `Dockerfile_linux`, `Dockerfile_windows` from the
    `dockerfile_opam` package respectively become `Dockerfile_opam.Distro`,
    `Dockerfile_opam.Linux`, `Dockerfile_opam.Windows`. (@MisterDA #106, #113)
- Generate opam images using BuildKit 1.4 syntax for Dockerfiles. (@MisterDA #105)
- Support BuildKit 1.4 syntax of here-documents in `COPY` instructions. (@MisterDA #99)
- Support BuildKit 1.4 `--link` flag in `ADD` and `COPY` instructions. (@MisterDA #99)

v8.0.0 2022-07-27 Sydney
------------------------

- Deprecate Ubuntu 21.10 (@tmcgilchrist #104)
- Various LCU Updates (@mtelvers #103 #98 #95 #93 #91 #89 #83)
- Add IBM-Z Docker images for Ubuntu (@mtelvers #102)
- Added RISCV64 (@mtelvers #100)
- Ubuntu LTS and current release is 22.04 (@dra27 #97)
- When compiling opam, build OCaml once using `make compiler` on the master
  branch of opam and then share this compiler with the release branches.
  Simultaneously circumvents the `sigaltstack` problems with OCaml < 4.13 on new
  releases, improves the build time of opam and reduces the carbon footprint of
  the base image builder! (@dra27 #85)
- Only compile bubblewrap from sources if the OS either doesn't distribute it or
  it's too old (@dra27 #85)
- Add `Dockerfile_distro.bubblewrap_version` to return the version of bubblewrap
  package in a given release (@dra27 #85)
- Change types for aliasing of distributions. The return type of
  `Dockerfile_distro.resolve_alias` is guaranteed not to include an alias but
  may require coercing back to `Dockerfile_distro.t` in some code. Similarly
  affects uses of some of the Windows functions in `Dockerfile_distro`
  (@dra27 #85)
- Move CentOS 8 to deprecated and change CentOS latest to V7! (@kit-ty-kate #88)
- Add OCaml 5.00 support (@dra27 #84)
- Add Alpine 3.15 (3.14 is now tier 2 and 3.13 is deprecated) (@talex5)
- Switch all GitHub access from git:// to https:// in advance of insecure protocol
  sunset (@kit-ty-kate #73)
- Fix dependencies of dockerfile-cmd: result now correctly used (@dra27 #72)
- Add Fedora 35 and make the latest (@dra27 #71)
- Move Ubuntu 21.04 to deprecated (@dra27 #71)
- Add Ubuntu 22.04 (@dra27 #71)
- Add Alpine 3.14 and Ubuntu 21.10 (@avsm)
- Move Fedora 33 and OpenSUSE 15.2 to deprecated and Alpine 3.13 to Tier 2. (@avsm)
- Latest Fedora is now Fedora 34 (@avsm)
- Assume Windows x64 is an active distro even when it doesn't have the latest
  release (@dra27 #66; #68)
- Latest base distro is now Debian 11 (from Debian 10) (@kit-ty-kate #59)
- Ensure stray double-quotes don't end up in PATH on Windows images (@dra27 #62)
- Stop pinning binutils to 2.35 in Windows builds as that no longer works with
  GCC 11. (@dra27 #61)
- Introduce Windows 10 LTSC 2022 and Windows Server image (@MisterDA #63)
- Expose `Dockerfile_distro.win10_docker_base_image` and
  `Dockerfile_distro.win10_base_tag` to get the Windows container base
  image and tags. (@MisterDA #63)

v7.2.0 2021-07-28 Cambridge
---------------------------

- Add support for S390x architecture builds for Debian (@avsm)
- Add OpenSUSE 15.3 (#53 @avsm)
- Improve support for Windows 10 (#50 @MisterDA review by @dra27)
- Alpine 3.12 and Ubuntu 20.10 to deprecated, add Fedora 34 and Ubuntu 21.04 (@avsm)
- Deprecate Ubuntu 16.04 as it is now EOL (@kit-ty-kate #44)
- add `libexecinfo-dev` to Alpine dev packages as it is used
  by multicore OCaml (@avsm)
- retrieve cygsympathy script from upstream master (@dra27)
- Fixes to the Windows images, smaller images, fix bugs
  (@MisterDA)
- Introduce a Cygwin image, and move Windows Mingw and Windows Msvc at
  the distro level. (@MisterDA #42)
- Add edge and edgecommunity repositories to the Alpine image (@EwanMellor #48)
- Add support for Windows 10 Latest Cumulative Update docker image tags (@dra27 #56)

v7.1.0 2021-02-25 Cambridge
---------------------------

- Add ArchLinux support (@kit-ty-kate #23)
- Move Alpine 3.11 to deprecated (@kit-ty-kate #23).
- Add OracleLinux v8 (@kit-ty-kate #24)
- Add Ubuntu 20.10 and Fedora 33 (@avsm)
- Make Alpine 3.13 and Fedora 33 the latest versions.
- Update the latest versions of Ubuntu LTS to 20.04
  and CentOS to 8 and OracleLinux to 8 (@avsm)
- Activate Powertools for CentOS 8 (@kit-ty-kate #26)
- Build aarch64 images for Fedora 33 and higher as well (@avsm).
- Remove outdated bulk-build and archive functions from
  `Dockerfile_opam` (@avsm)
- Create a Tier 3 for distros for things we do not want
  to test in the opam repository (@avsm @kit-ty-kate)
- Add an `os_family` type (@MisterDA)
- Add support for parser directives (@MisterDA)
- Add Windows support (@MisterDA)

v7.0.0 2020-08-14 Cambridge
---------------------------

- Do not install `opam-installer` in images any more. This turns
  out to be a largely optional component as the opam binary
  installer doesn't include it either.  It will be made optional
  in the final opam 2.1 release. (@avsm)

- Build multiple versions of opam in the base images. This results
  in an `opam-2.0` and `opam-2.1` binary being installed, with
  a hardlink to `opam <- opam.2.0` so the defaults are unchanged.
  This allows upstream CI images to switch the hardlink to make
  it easier to test newer releases of opam, and also upgrades.

v6.6.1 2020-07-25 Cambridge
---------------------------

- Ensure debconf remains non-interactive (@avsm)
- Do not build ppc64le on Debian:9 as upstream has stopped
  providing images. Debian 10 ppc64le remains unchanged. (@avsm).

v6.6.0 2020-07-21 Cambridge
---------------------------

- Deprecate Ubuntu 19.10 (@talex5 #21)
- Add OpenSUSE 15.2 Leap (@avsm)
- Build Ubuntu ppc64le (@talex5 #21)
- Upgrade build files to dune 2.0 (@avsm)

v6.5.0 2020-06-29 Lockdown At Home
----------------------------------

- Add Fedora 32, Alpine 3.12 to the known distros (@avsm)
- Move Fedora 30 to deprecated, and Alpine 3.11 to Tier 2 (@avsm)
- Add i386 architecture build support (@avsm).
- Add a [Dockerfile.from ?platform] argument to specify multiarch
  image sources (@avsm)
- Add [Dockerfile.shell] to specify a custom shell to subsequent
  [run] commands (@avsm).
- Upgrade bubblewrap in containers to latest 0.4.1 (@avsm)
- Make the curl step fail if the download fails in bubblewrap
  installation (@talex5 #20)
- Switch aarch32 builds to use a Linux32 personality, so they
  can be built on 64-bit aarm64 hosts. (@avsm)

v6.4.0 2020-04-16 Lockdown At Home
----------------------------------

- Permute the order of Yum groupinstall/install to workaround
  a build issue in CentOS 8 under OverlayFS/Docker. (@avsm)
- Do not install `yum-ovl-plugin` workaround on CentOS 8. (@avsm)
- Add Fedora 31 and Ubuntu 19.10 (@XVilka @talex5)
- Add Alpine 3.11 and Ubuntu 20.04 (@avsm)
- Remove Ubuntu 19.04 from the supported distro list (@avsm).
- Add a `clone_opam_repo` optional argument to `gen_opam2_distro`
  to let the caller decide whether or not to have the git clone
  present in the container (@avsm @talex5).

v6.3.0 2019-08-11 Cambridge
---------------------------

- Add `?chown` option for `copy` and `add` Dockerfile
  functions (#12 @talex5)
- add beta repository for switches if there is a dev release
  in any of the compilers for that switch (@avsm).
- Demote Debian 9 to a Tier 2 now that Debian 10 is stable (@avsm).
- Create `opam` group on all Linux distributions (#11 @talex5)

v6.2.0 2019-06-25 Cambridge
---------------------------

- Add Fedora 30, Debian 10 (Buster), OpenSUSE 15.1 (Leap) and
  Alpine 3.10 to the distribution list (@avsm)
- Ensure Alpine 3.9 has an arm64 build (@avsm)
- Deprecate Ubuntu 14.04, Fedora 27/28 and Alpine 3.8 in favour of
  newer upstream versions (@avsm)

v6.1.1 2019-04-24 Cambridge
---------------------------

- Add support for Ubuntu 19.04 (Disco). (@avsm)
- Upgrade opam metadata to 2.0 format. (@avsm)

v6.1.0 2019-02-06 Cambridge
---------------------------

- Add support for Fedora 29 and OpenSUSE Leap 15.0 and Alpine 3.9.
- Demote some releases to Tier 2 from Tier 1.
- Add functions to calculate base distro tags in `Dockerfile_distro`.
- Install bzip2 and rsync on OpenSUSE distros.
- Add a `Dockerfile_opam.deprecated` container for being able to turn off older distros.
- Install `which` into OpenSUSE containers by default.
- Use `+trunk` suffix for dev versions of compiler.
- Remove unused GNU Parallel wrapper in `dockerfile_cmd`.

v6.0.0 2018-11-15 Cambridge
---------------------------

This release focuses on the opam 2.0 release and the resulting
containers built on ocaml/opam2 on the Docker Hub.

- set the `OPAMYES` variable to true by default in ocaml
  containers so they remain non-interactive.
- install rsync in RPM distros
- Install opam-depext in the containers by default
- fix opam2 alpine and centos installation by installing openssl
- add a dependency on `ppx_sexp_conv` for dockerfile-cmd
- add support for Aarch32 in distros
- install coreutils in Alpine since OCaml 4.08 needs GNU stat to compile
- add support for Ubuntu 18.10 and Alpine 3.8 releases.
- add xz to Alpine and Zypper distributions.
- `install_opam_from_source` requires an explicit branch rather
  than defaulting to master.
- update version of Bubblewrap in containers to 0.3.1.
- port build system from Jbuilder to Dune.

v5.1.0 2018-06-15 Cambridge
---------------------------

- Remove unnecessary cmdliner dep in dockerfile-opam
- Support Tier2 distros in bulk builds

v5.0.0 2018-06-07 Cambridge
---------------------------

- Install the Bubblewrap sandboxing tool in all distributions and
  remove the older wrappers for opam2 namespace usage.
- Ensure that X11 is available in the containers so that the
  OCaml Graphics module is available (#8 via @kit-ty-kate)
- Add concept of a "Tier 1" and "Tier 2" distro so that we can
  categorise them more easily for container generation.
- Add support for Alpine 3.7 and Ubuntu 18.04 and Fedora 28.
- Update Ubuntu LTS to 18.04.
- Deprecate Ubuntu 17.10 and 12.04 (now end-of-life).
- Alter the individual compiler containers to omit the patch version
  from the name. They will always have the latest patch version for CI.
- Allow distro selection to be filtered by OCaml version and architecture.
  This allows combinations like Ubuntu 18.04 (which breaks on earlier
  versions of OCaml due to the shift to PIE) to be expressed.
- Add missing OpenSUSE to the latest distros list.
- Add Ppc64le architecture.

v4.0.0 2017-12-25 Cambridge
---------------------------

Major API iteration to:

- switch to multistage container builds for smaller containers
- instead of separate `ocaml` and `opam` containers, just generate
  a single `opam` one which can optionally have the system compiler
  or a locally compiled one.
- explicitly support aliases for distributions, and allow older
  distributions to be marked as deprecated.

Other changes:
* Update OPAM 2 build mechanism to use `make cold`.
* Drop support for opam1 containers; use an older library version for those.
* Also mark OCaml 4.05.0 and 4.06.0 as a mainline release for opam2 as well.

v3.1.0 2017-07-14 Cambridge
---------------------------

* Mark OCaml 4.05.0 as a released stable version.
* Remove the Alpine 3.5 camlp4 hack as it has been fixed in a
  point release upstream.
* Add minimum constraint on sexplib in build rules (#6 reported by @smondet)
* Add support for Alpine 3.6 and Debian 10 (Buster).
* Bump the most recent Debian Stable to Debian 9.
* Bump the most recent Alpine to Alpine 3.6.
* Add OCaml 4.04.2 as the most recent compiler

v3.0.0 2017-06-14 Cambridge
---------------------------

* Add support for [multistage builds](https://docs.docker.com/engine/userguide/eng-image/multistage-build/)
  to the `from`, `add`, and `copy` commands.

There are also backwards incompatible changes to the package layout:

* Split up OPAM packages into `dockerfile` and `dockerfile-opam`.
  The latter contains the OPAM- and Linux-specific modules, with
  the core DSL in `dockerfile`.
* Port to [jbuilder](https://github.com/janestreet/jbuilder).

v2.2.3 2017-05-01 Cambridge
--------------------------

* Add OCaml 4.04.1 to the stable released set.
* Add Ubuntu 17.04 and Fedora 25 to the distribution list.
* Setup OPAM2 wrappers in containers. This will enforce Linux
  namespaces upon building and installing the packages, preventing
  them from doing network access when they shouldn't or writing files
  where they shouldn't (#1 from @AltGr).  These are not activated
  by default and are present in `/etc/opamrc.userns` in the relevant
  OPAM2 containers.

v2.2.2 2017-03-22 Cambridge
---------------------------

* Register 4.06.0 as a trunk compiler revision.
* Correctly install aspcud in all Alpine 3.5 containers.

v2.2.1 2017-02-22 Cambridge
---------------------------

* Bump latest stable OCaml to 4.04.0.
* Add OCaml 4.06.0dev into the build matrix.
* Support latest OPAM 2.0beta release.
* Bump the "latest" distro tags to Alpine 3.5 and OpenSUSE 42.2.

v2.2.0 2017-01-12 Cambridge
---------------------------

* Remove support for ARM variants from the default distribution
  list.  They will come back as explicitly supported multiarch
  targets, instead of the current qemu builds that are mixed up
  with x86_64 targets.
* Always install OPAM from source on Alpine until upstreaming
  is complete.
* Register 4.04 as a mainline compiler as well (fixes OPAM2).
* Add support for Alpine 3.5 and OpenSUSE 42.2, and promote
  the Alpine:latest images to Alpine 3.5.
* Do not install camlp4 by default in distributions.
* Refresh `aspcud` remote proxy with url-escaping fixes
  (via @OCamlPro-Henry in ocaml/opam#2809)
* Add Ubuntu 16.10 to the built-distros list.

v2.1.0 2016-11-07 Cambridge
---------------------------

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
* Add sexplib converters for `Dockerfile.t`.
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
