(lang dune 3.21)

(name hermetic)

(generate_opam_files true)

(implicit_transitive_deps false)

(license ISC)
(authors "Thomas Gazagnaire <thomas@gazagnaire.org>")
(maintainers "Thomas Gazagnaire <thomas@gazagnaire.org>")

(source (github samoht/ocaml-hermetic))

(package
 (name hermetic)
 (synopsis "A standard library prelude that refuses ambient authority")
 (tags (stdlib prelude capability))
 (description
  "In a file that opens Hermetic, a use of a standard library value that
reaches the world without being handed it is a type error. Such a file cannot
read the process environment, the clock or the file system through the
standard library, cannot read the standard input or write the standard
output, cannot spawn a process or a domain, and cannot end the process: the
values that do so get a type nothing consumes, and an alert names the
capability to take as an argument instead. So do the values of Unix that
reach the world. The libraries that reach the system past Eio's
capabilities, Eio_main among them, are refused by name, and so are the
values that can forge memory or a value of any type. A pure core is the case
where no capability is handed in. The prelude is generated from the
installed compiler's standard library, and a value a new compiler adds is
refused until it is reviewed. It guards against accidents, not against an
author trying to cheat, and it does not check dependencies")
 (depends
  (ocaml (and (>= 5.3) (< 5.6)))
  (alcotest (and :with-test (>= 1.7.0)))
  (ocamlfind :with-test)))
