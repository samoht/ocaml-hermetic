hermetic-tree checks every Eio library of a source tree against hermetic.eio.
It selects a library by its public name, ending with -eio or .eio, or by its
dependency on eio, and reads the selection from the tree's dune files, so it
holds no package names. A ratchet file lists the libraries still allowed to
violate and may only shrink.

The workspace makes the ambient alert an error once, so a library adopts by
opening the prelude and naming it.

  $ cat > dune-workspace <<EOF
  > (lang dune 3.21)
  > (env (_ (flags (:standard -alert @ambient))))
  > EOF
  $ cat > dune-project <<EOF
  > (lang dune 3.21)
  > EOF
  $ pkg () {
  >   mkdir -p "$1"
  >   printf '(lang dune 3.21)\n(generate_opam_files)\n(package (name %s) (allow_empty) %s)\n' "$1" "$2" \
  >     > "$1/dune-project"
  > }
  $ lib () {
  >   printf '(library (name %s) (public_name %s) (libraries %s) %s)\n' \
  >     "$(echo "$2" | tr .- __)" "$2" "$3" "$4" > "$1/dune"
  >   cat > "$1/$(echo "$2" | tr .- __).ml"
  > }
  $ check () {
  >   hermetic-tree --root . --build _build/default --summary "$@"
  >   echo "exit $?"
  > }
  $ adopt="(flags (:standard -open Hermetic_eio))"

A stand-in for eio, which the selection reads by name only.

  $ pkg eio ""
  $ lib eio eio "" "" <<EOF
  > let run () = ()
  > EOF

named-eio adopts and is selected by its name; uses names eio among its
libraries and has not adopted; other neither does I/O through Eio nor
adopts, and is not selected.

  $ pkg named-eio ""
  $ lib named-eio named-eio hermetic.eio "$adopt" <<EOF
  > let x = 1
  > EOF
  $ pkg uses ""
  $ lib uses uses eio "" <<EOF
  > let run = Eio.run
  > EOF
  $ pkg other ""
  $ lib other other "" "" <<EOF
  > let y = 2
  > EOF

An adopted library that reads the file system past a capability does not
compile: the workspace's flag makes the alert an error.

  $ pkg ambient-eio ""
  $ lib ambient-eio ambient-eio hermetic.eio "$adopt" <<EOF
  > let here = Sys.file_exists "state"
  > EOF
  $ dune build --root . --display quiet ./ambient-eio 2>&1 | grep '^Error'
  Error (alert ambient): Hermetic_eio.Sys.file_exists
  $ rm -r ambient-eio

  $ dune build --root . --display quiet @check @default; echo "exit $?"
  exit 0

Without a ratchet, the unadopted Eio library is refused and the others pass.

  $ check
  uses: uses/uses.ml: compiled without -open Hermetic_eio
  2 Eio libraries: 1 hermetic, 0 in the ratchet
  exit 1

Listed in the ratchet, it passes.

  $ echo "uses  # not yet adopted" > ratchet
  $ check --ratchet ratchet
  2 Eio libraries: 1 hermetic, 1 in the ratchet
  exit 0

A listed library that is hermetic is refused, so the list only shrinks, and so
is a listed library the tree does not select.

  $ echo "named-eio" >> ratchet
  $ echo "other" >> ratchet
  $ check --ratchet ratchet
  named-eio: hermetic, remove it from the ratchet
  other: in the ratchet but not an Eio library of the tree
  2 Eio libraries: 1 hermetic, 3 in the ratchet
  exit 1

A line naming more than one library is a usage error.

  $ echo "uses other" > bad
  $ check --ratchet bad
  hermetic-tree: line 1: expected one library
  exit 124

A package whose dune-project carries the tag hermetic:eio-boundary is checked
as hermetic-check --eio --boundary: it may import Unix, and it still opens the
prelude.

  $ pkg bound "(tags (hermetic:eio-boundary))"
  $ lib bound bound "eio unix hermetic.eio" "$adopt" <<EOF
  > let pid () = Unix.getpid ()
  > EOF
  $ pkg plain-eio ""
  $ lib plain-eio plain-eio "unix hermetic.eio" "$adopt" <<EOF
  > let pid () = Unix.getpid ()
  > EOF
  $ dune build --root . --display quiet @check @default; echo "exit $?"
  exit 0
  $ echo "uses" > ratchet
  $ check --ratchet ratchet
  plain-eio: plain-eio/plain_eio.ml: imports Unix, which reaches the system past an Eio capability
  4 Eio libraries: 2 hermetic, 1 in the ratchet
  exit 1
