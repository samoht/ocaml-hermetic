The README's setup and its refusal, as a user meets them: a library that
names hermetic, a source file that opens the prelude on its first line, and
the compiler's whole message for a refused value. OCaml 5.3 quotes the type
in the error, as in "ambient", and later compilers do not. Compilers before
5.3 name it by its unit, as in Hermetic__Refused.ambient. The error line is
stripped of both, and of the blank line OCaml 5.1 and later print after the
alert, so that the message reads as the README shows it on every supported
compiler.

  $ cat > dune-project <<EOF
  > (lang dune 3.0)
  > EOF
  $ mkdir lib
  $ cat > lib/dune <<EOF
  > (library
  >  (name model)
  >  (libraries hermetic))
  > EOF
  $ cat > lib/machine.ml <<'EOF'
  > open! Hermetic
  > 
  > let load () = open_in "model.bin"
  > EOF
  $ dune build --root . --display quiet ./lib 2>&1 | sed '/^Error:/s/"//g; s/Hermetic__Refused\.//g; /^$/d'
  File "lib/machine.ml", line 3, characters 14-21:
  3 | let load () = open_in "model.bin"
                    ^^^^^^^
  Alert ambient: Hermetic.open_in
  Opens a file by name: take Eio.Stdenv.fs or Eio.Stdenv.cwd (an Eio.Path) as an argument, or the file's contents.
  File "lib/machine.ml", line 3, characters 14-21:
  3 | let load () = open_in "model.bin"
                    ^^^^^^^
  Error: This expression has type ambient
         This is not a function; it cannot be applied.
