FROM ocaml/opam:debian-9_ocaml-4.03.0_trunk
RUN sudo -u opam sh -c "opam pin add -n dockerfile https://github.com/avsm/ocaml-dockerfile.git" && \
  sudo -u opam sh -c "opam update -u" && \
  sudo -u opam sh -c "opam depext -u dockerfile" && \
  sudo -u opam sh -c "opam install -y -j 2 -v dockerfile"