(lang dune 3.0)
(name dockerfile)

(generate_opam_files true)

(source (github ocurrent/ocaml-dockerfile))
(license "ISC")

(authors
 "Anil Madhavapeddy"
 "Anton Kochkov"
 "Antonin Décimo"
 "David Allsopp"
 "Ewan Mellor"
 "Kate Deplaix"
 "Louis Gesbert"
 "Mark Elvers"
 "Thomas Leonard"
 "Tim McGilchrist")

(maintainers
 "Anil Madhavapeddy <anil@recoil.org>"
 "Antonin Décimo <antonin@tarides.com>"
 "David Allsopp <david.allsopp@metastack.com>"
 "Kate <kit.ty.kate@disroot.org>"
 "Thomas Leonard <talex5@gmail.com>"
 "Tim McGilchrist <timmcgil@gmail.com>")

(package
 (name dockerfile)
 (synopsis "Dockerfile eDSL in OCaml")
 (description
"\| This library provides a typed OCaml interface to generating Dockerfiles
"\| programmatically without having to resort to lots of shell scripting and
"\| awk/sed-style assembly.
 )
 (depends
  (ocaml (>= "4.08"))
  (fmt (>= "0.8.7"))
  (ppx_sexp_conv (>= "v0.9.0"))
  sexplib)
 (conflicts
  (result (< 1.5))
  (rresult (< 0.7.0)))
 (documentation "https://ocurrent.github.io/ocaml-dockerfile/doc/dockerfile/")
 (tags ("org:mirage" "org:ocamllabs")))

(package
 (name dockerfile-cmd)
 (synopsis "Dockerfile eDSL -- generation support")
 (description
"\| This library provides a typed OCaml interface to generating Dockerfiles
"\| programmatically without having to resort to lots of shell scripting and
"\| awk/sed-style assembly.
"\|
"\| This sublibrary has support functions for generating arrays of Dockerfiles
"\| programmatically.
 )
 (depends
  (bos (>= 0.2))
  cmdliner
  (dockerfile-opam (= :version))
  (fmt (>= "0.8.7"))
  logs
  (ppx_sexp_conv (>= "v0.9.0"))
  sexplib)
 (conflicts
  (result (< 1.5))
  (rresult (< 0.7.0)))
 (documentation "https://ocurrent.github.io/ocaml-dockerfile/doc/dockerfile-cmd/")
 (tags ("org:mirage" "org:ocamllabs")))

(package
 (name dockerfile-opam)
 (synopsis "Dockerfile eDSL -- opam support")
 (description
"\| This library provides a typed OCaml interface to generating Dockerfiles
"\| programmatically without having to resort to lots of shell scripting and
"\| awk/sed-style assembly.
"\|
"\| The opam subpackage provides opam and Linux-specific distribution support
"\| for generating dockerfiles.
 )
 (depends
  astring
  (dockerfile (= :version))
  (fmt (>= "0.8.7"))
  (ocaml-version (>= "3.5.0"))
  (ppx_sexp_conv (>= "v0.9.0"))
  sexplib)
 (conflicts
  (result (< 1.5))
  (rresult (< 0.7.0)))
 (documentation "https://ocurrent.github.io/ocaml-dockerfile/doc/dockerfile-opam/")
 (tags ("org:mirage" "org:ocamllabs")))
