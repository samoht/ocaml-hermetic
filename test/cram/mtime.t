A library that depends on mtime names its types and its pure values, but not
its clock: Mtime_clock reads the monotonic clock, which Eio's env provides as
Eio.Stdenv.mono_clock, so the prelude declares it empty.

  $ cat > dune-project <<EOF
  > (lang dune 3.0)
  > EOF
  $ mkdir lib
  $ cat > lib/dune <<EOF
  > (library (name timing) (libraries hermetic mtime mtime.clock))
  > EOF
  $ cat > lib/timing.ml <<'EOF'
  > open! Hermetic
  > let ns (s : Mtime.Span.t) = Mtime.Span.to_uint64_ns s
  > let since (t : Mtime.t) (u : Mtime.t) = Mtime.span t u
  > EOF
  $ dune build --root . --display quiet ./lib; echo "exit $?"
  exit 0
  $ cat > lib/now.ml <<'EOF'
  > open! Hermetic
  > let now () = Mtime_clock.now ()
  > EOF
  $ dune build --root . --display quiet ./lib 2>&1 | sed 's/"//g; s/Hermetic__Refused\.//g' | grep -A1 -E '^(Alert|Error)'
  Alert ambient: module Hermetic.Mtime_clock
  Reads the monotonic clock: take Eio.Stdenv.mono_clock (an Eio.Time.Mono) as an argument.
  --
  Error: Unbound value Mtime_clock.now
