(lang dune 3.21)

(name hermetic)

(generate_opam_files true)

(implicit_transitive_deps false)

(license ISC)
(authors "Thomas Gazagnaire <thomas@gazagnaire.org>")
(maintainers "Thomas Gazagnaire <thomas@gazagnaire.org>")

(source (tangled gazagnaire.org/ocaml-hermetic))

(package
 (name hermetic)
 (synopsis "The OCaml standard library with the ambient world refused")
 (tags (org:blacksun test))
 (description
  "A library whose decisions must be functions of their inputs (a protocol
state machine, a codec, the model of a tool) can still read the process
environment, the clock, the file system or a randomly seeded generator through
the standard library, which the build never notices. Hermetic is a prelude
opened before the library is typed. It restates the standard library with
every value that reads or writes the world outside the program marked by an
ambient alert, so that compiled with -alert @ambient such a use is a compile
error naming the value, through a qualified path, a module alias, a functor
argument or a signature constraint alike. The hermetic-check command reads the
library's compiled units and refuses one that was not compiled that way or that
declares an external primitive, which no prelude can shadow.")
 (depends
  (ocaml (>= 5.4))
  (cmdliner (>= 1.3.0))
  (fmt (>= 0.9))))
