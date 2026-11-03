A domain, which Eio's domain manager hands out, and the domain's exit
functions, which flush the standard formatters, are refused. OCaml 4.14 has
neither, so this runs on OCaml 5.0 and later. Compilers word the error
differently, so only its alert is checked.

  $ cat > dune-project <<EOF
  > (lang dune 3.0)
  > EOF
  $ mkdir spawn at_exit
  $ echo '(library (name spawn) (libraries hermetic))' > spawn/dune
  $ echo '(library (name at_exit) (libraries hermetic))' > at_exit/dune
  $ printf 'open! Hermetic\nlet d = Domain.spawn ignore\n' > spawn/spawn.ml
  $ printf 'open! Hermetic\nlet () = !do_domain_local_at_exit ()\n' > at_exit/at_exit.ml
  $ dune build --root . --display quiet ./spawn 2>&1 | grep -oE '^(Alert .*|Error)'
  Alert ambient: Hermetic.Domain.spawn
  Error
  $ dune build --root . --display quiet ./at_exit 2>&1 | grep -oE '^(Alert .*|Error)'
  Alert ambient: Hermetic.do_domain_local_at_exit
  Error

What a domain reads of itself, its own exit functions and the processor's
count stay.

  $ mkdir kept
  $ echo '(library (name kept) (libraries hermetic))' > kept/dune
  $ cat > kept/kept.ml <<'EOF2'
  > open! Hermetic
  > let self () = Domain.self ()
  > let () = Domain.at_exit ignore
  > let n = Domain.recommended_domain_count ()
  > EOF2
  $ dune build --root . --display quiet --profile dev ./kept; echo "exit $?"
  exit 0
