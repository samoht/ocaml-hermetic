A library can ship without hermetic and be checked against the prelude in
another directory only. A library stanza there compiles a copy of every
source file of the library, with the prelude opened by a flag; copy_files#
keeps the line directives, so an error points at the original file. A library
stanza compiles each of its modules, where a test stanza would compile only
those its executable reaches.

  $ cat > dune-project <<EOF
  > (lang dune 3.0)
  > EOF
  $ mkdir lib check
  $ echo '(library (name core))' > lib/dune
  $ cat > lib/core.ml <<'EOF'
  > let decide x = x * 2
  > EOF
  $ cat > lib/load.ml <<'EOF'
  > let load () = open_in "model.bin"
  > EOF
  $ cat > check/dune <<EOF
  > (copy_files# (files ../lib/*.ml))
  > (library (name core_hermetic) (libraries hermetic)
  >  (flags (:standard -open Hermetic)))
  > EOF

The library itself builds, and the check refuses it, at the original file.

  $ dune build --root . --display quiet --profile dev ./lib; echo "exit $?"
  exit 0
  $ dune build --root . --display quiet --profile dev ./check 2>&1 | tr -d '"' | grep -E '^(File|Alert|Error)'
  File lib/load.ml, line 1, characters 14-21:
  Alert ambient: Hermetic.open_in
  File lib/load.ml, line 1, characters 14-21:
  Error: This expression has type ambient
