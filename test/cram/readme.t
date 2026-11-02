The README's setup and its refusal, as a user meets them: a library that
names hermetic, a source file that opens the prelude on its first line, and
the compiler's whole message for a refused value.

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
  > let home () = Sys.getenv "HOME"
  > EOF
  $ dune build --root . --display quiet ./lib 2>&1
  File "lib/machine.ml", line 3, characters 14-24:
  3 | let home () = Sys.getenv "HOME"
                    ^^^^^^^^^^
  Alert ambient: Hermetic.Sys.getenv
  Reads the process environment: take the value as an argument.
  
  File "lib/machine.ml", line 3, characters 14-24:
  3 | let home () = Sys.getenv "HOME"
                    ^^^^^^^^^^
  Error: This expression has type ambient
         This is not a function; it cannot be applied.
  [1]
