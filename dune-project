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
  "A standard library prelude that makes code take Eio's capabilities as arguments")
 (tags (stdlib prelude capability))
 (description
  "In a file that opens Hermetic, a use of a standard library, Unix or Thread
value is a type error when it reaches, without being handed it, something
Eio's env provides as a capability: the file system, a clock, the network,
the standard input, output or error, the system's entropy, a domain or a
child process. Its alert names the Eio.Stdenv capability to take instead. A
value that can forge a capability, such as Obj.magic or a Marshal reader, is
refused too. Everything else stays.")
 (depends
  (ocaml (and (>= 5.3) (< 5.6)))
  (alcotest (and :with-test (>= 1.7.0)))
  (mdx (and :with-test (>= 2.3.0)))
  (ocamlfind :with-test)))
