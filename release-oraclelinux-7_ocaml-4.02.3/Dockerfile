FROM ocaml/opam:oraclelinux-7_ocaml-4.02.3
RUN sudo -u opam sh -c "opam pin add -n dockerfile https://github.com/avsm/ocaml-dockerfile.git" && \
  sudo -u opam sh -c "opam update -u" && \
  sudo -u opam sh -c "opam depext -u dockerfile" && \
  sudo -u opam sh -c "opam install -y -j 2 -v dockerfile"