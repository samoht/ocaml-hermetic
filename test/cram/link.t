The prelude is a module of aliases, and each module it restates is a unit of
its own, so a program links only the units it uses. Here the same program is
built with and without the prelude; it uses List, which the prelude keeps,
and Sys, which it restates. The only units the prelude adds are the restated
Sys and the unit of the refused values' stubs; the prelude's own module,
which only aliases them, is not linked at all.

  $ cat > dune-project <<EOF
  > (lang dune 3.0)
  > EOF
  $ mkdir plain prelude
  $ echo '(executable (name main) (modes byte))' > plain/dune
  $ echo '(executable (name main) (modes byte) (libraries hermetic))' > prelude/dune
  $ echo 'let () = ignore (Sys.opaque_identity (List.length [ 1 ] + Sys.word_size))' > plain/main.ml
  $ printf 'open! Hermetic\n%s\n' "$(cat plain/main.ml)" > prelude/main.ml
  $ dune build --root . --display quiet --profile release ./plain/main.bc ./prelude/main.bc
  $ units () {
  >   ocamlobjinfo "_build/default/$1/main.bc" |
  >     sed -n 's/.*compilation unit .\([A-Za-z_]*\).*/\1/p' | grep -v Dune__exe | sort
  > }
  $ units plain > plain.units
  $ units prelude > prelude.units
  $ comm -13 plain.units prelude.units
  Hermetic__Refused
  Hermetic__Sys
