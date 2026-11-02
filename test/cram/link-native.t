The same holds for a native program, whose units nm lists.

  $ cat > dune-project <<EOF
  > (lang dune 3.0)
  > EOF
  $ mkdir plain prelude
  $ echo '(executable (name main))' > plain/dune
  $ echo '(executable (name main) (libraries hermetic))' > prelude/dune
  $ echo 'let () = ignore (Sys.opaque_identity (List.length [ 1 ] + Sys.word_size))' > plain/main.ml
  $ printf 'open! Hermetic\n%s\n' "$(cat plain/main.ml)" > prelude/main.ml
  $ dune build --root . --display quiet --profile release ./plain/main.exe ./prelude/main.exe
  $ units () {
  >   nm "_build/default/$1/main.exe" | grep -oE 'caml(Stdlib|Hermetic)[A-Za-z_]*.code_begin' |
  >     sed -E 's/[_.$]*code_begin$//; s/^caml//' | sort -u
  > }
  $ units plain > plain.units
  $ units prelude > prelude.units
  $ comm -13 plain.units prelude.units
  Hermetic__Refused
  Hermetic__Sys
