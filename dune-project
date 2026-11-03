(lang dune 3.21)

(name hermetic)

(using mdx 0.4)

(generate_opam_files true)

(implicit_transitive_deps false)

(license ISC)
(authors "Thomas Gazagnaire <thomas@gazagnaire.org>")
(maintainers "Thomas Gazagnaire <thomas@gazagnaire.org>")

(source (github samoht/ocaml-hermetic))

(package
 (name hermetic)
 (synopsis
  "Enforce Eio's capabilities at compile time")
 (tags (stdlib prelude capability eio))
 (description
  "Hermetic is a prelude that restates OCaml's standard library. In a file
that opens it, a standard library, Unix or Thread value that reaches the file
system, a clock, the network, the standard streams, entropy, a domain or a
child process on its own is a type error, such as Sys.remove or Sys.command.
Its alert names the Eio.Stdenv capability to take instead. The unsafe
operations that could forge a capability, such as Obj.magic or a Marshal
reader, are refused too.")
 (depends
  (ocaml (and (>= 5.3) (< 5.6)))
  (alcotest (and :with-test (>= 1.7.0)))
  (mdx (and :with-test (>= 2.3.0)))
  (ocamlfind :with-test)))
