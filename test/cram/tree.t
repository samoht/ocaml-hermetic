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
Each finding is an error at a location, as the compiler writes one, so what
reads a build's output, an editor or a merge queue, names the file it lies in
and tells one finding from another.

  $ check
  File "uses/uses.ml", line 1, characters 0-0:
  Error: uses: compiled without -open Hermetic_eio
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
  File "ratchet", line 2, characters 0-0:
  Error: named-eio: hermetic, remove it from the ratchet
  File "ratchet", line 3, characters 0-0:
  Error: other: in the ratchet but not an Eio library of the tree
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
  File "plain-eio/plain_eio.ml", line 1, characters 0-0:
  Error: plain-eio: imports Unix, which reaches the system past an Eio capability
  4 Eio libraries: 2 hermetic, 1 in the ratchet
  exit 1

An adopted library's interface names the prelude's types, so a toplevel that
loads the library without the prelude's compiled interface sees them
abstract: under (implicit_transitive_deps false) an mdx stanza reaches only
the libraries it names. An mdx stanza naming an adopted library, by its public
or its local name, names hermetic.eio too.

  $ echo "(mdx (files README.md) (libraries named-eio fmt))" >> named-eio/dune
  $ echo "(mdx (files local.md) (libraries named_eio))" >> uses/dune
  $ echo "(mdx (files other.md) (libraries uses))" >> other/dune
  $ check --ratchet ratchet
  File "plain-eio/plain_eio.ml", line 1, characters 0-0:
  Error: plain-eio: imports Unix, which reaches the system past an Eio capability
  File "named-eio/dune", line 1, characters 0-0:
  Error: an mdx stanza names named-eio, which opens Hermetic_eio, and not hermetic.eio
  File "uses/dune", line 1, characters 0-0:
  Error: an mdx stanza names named_eio, which opens Hermetic_eio, and not hermetic.eio
  4 Eio libraries: 2 hermetic, 1 in the ratchet
  exit 1

Naming the prelude satisfies it.

  $ printf '(mdx (files README.md) (libraries named-eio hermetic.eio))\n' > named-eio/mdx.inc
  $ lib named-eio named-eio hermetic.eio "$adopt" <<EOF
  > let x = 1
  > EOF
  $ echo "(include mdx.inc)" >> named-eio/dune
  $ echo "(mdx (files local.md) (libraries named_eio hermetic.eio))" > uses/mdx.inc
  $ sed '/^(mdx/d' uses/dune > uses/dune.new && mv uses/dune.new uses/dune
  $ echo "(include mdx.inc)" >> uses/dune
  $ check --ratchet ratchet
  File "plain-eio/plain_eio.ml", line 1, characters 0-0:
  Error: plain-eio: imports Unix, which reaches the system past an Eio capability
  4 Eio libraries: 2 hermetic, 1 in the ratchet
  exit 1

A package's own runtest checks that package alone, so a merge queue that
tests the packages a change touches runs it. --scope judges the selected
libraries and the mdx stanzas of the directories the packages of one directory
own. A library of the ratchet outside the scope is another scope's. Whether a
library an mdx stanza names has adopted is read from the dune files of the
packages --reads names; the libraries no package of the tree provides are
listed with --outside, and a stanza naming any other library is refused, as a
rule written for an older tree.

  $ scoped () {
  >   check --ratchet ratchet --scope "$@"
  > }
  $ echo "(mdx (files named.md) (libraries named-eio fmt))" >> other/dune
  $ scoped other --reads named-eio,uses --outside fmt
  File "other/dune", line 1, characters 0-0:
  Error: an mdx stanza names named-eio, which opens Hermetic_eio, and not hermetic.eio
  0 Eio libraries: 0 hermetic, 0 in the ratchet
  exit 1
  $ scoped other --reads uses --outside fmt
  File "other/dune", line 1, characters 0-0:
  Error: an mdx stanza names named-eio, which the rule of its package does not read: regenerate the rules hermetic-tree --include prints
  0 Eio libraries: 0 hermetic, 0 in the ratchet
  exit 1
  $ scoped plain-eio
  File "plain-eio/plain_eio.ml", line 1, characters 0-0:
  Error: plain-eio: imports Unix, which reaches the system past an Eio capability
  1 Eio libraries: 0 hermetic, 0 in the ratchet
  exit 1
  $ scoped uses
  1 Eio libraries: 0 hermetic, 1 in the ratchet
  exit 0

A scope still refuses a library of the ratchet that has become hermetic, and
one its packages would install, by the first segment of its name, that the
tree no longer selects.

  $ echo "named-eio" >> ratchet
  $ echo "named-eio.gone" >> ratchet
  $ scoped named-eio
  File "ratchet", line 2, characters 0-0:
  Error: named-eio: hermetic, remove it from the ratchet
  File "ratchet", line 3, characters 0-0:
  Error: named-eio.gone: in the ratchet but not an Eio library of the tree
  1 Eio libraries: 1 hermetic, 2 in the ratchet
  exit 1
  $ echo "uses" > ratchet

A scope's rule names the compiled units of its package's libraries, so a
library added since the rules were written has none, ratchet or not.

  $ mkdir named-eio/extra
  $ lib named-eio/extra named-eio.extra "eio hermetic.eio" "$adopt" <<EOF
  > let z = 3
  > EOF
  $ echo "named-eio.extra" >> ratchet
  $ scoped named-eio
  File "named-eio/extra/dune", line 1, characters 0-0:
  Error: named-eio.extra: unreadable: no compiled units in named-eio/extra/.named_eio_extra.objs/byte: the rule of its package names none, regenerate the rules hermetic-tree --include prints
  2 Eio libraries: 1 hermetic, 1 in the ratchet
  exit 1
  $ rm -r named-eio/extra
  $ echo "uses" > ratchet

--include prints the rules for an (include) of the root's dune file, one in
each package directory's runtest, which depends on the compiled units of its
selected libraries and on the dune files of the packages its mdx stanzas read.
It refuses a library of the ratchet the tree no longer selects.

  $ hermetic-tree --root . --include --ratchet ratchet > hermetic.inc
  $ grep -c '^(subdir' hermetic.inc
  6
  $ sed -n -e '/^(subdir other/,/^$/p' -e '/^(subdir plain-eio/,/^$/p' hermetic.inc
  (subdir other
   (rule
    (alias runtest)
    (deps
     (sandbox always)
     ../ratchet
     ../dune
     ../dune-project
     (glob_files_rec dune)
     (glob_files_rec dune-project)
     (glob_files_rec *.opam)
     (glob_files_rec *.inc)
     (glob_files_rec ../named-eio/dune)
     (glob_files_rec ../named-eio/dune-project)
     (glob_files_rec ../named-eio/*.opam)
     (glob_files_rec ../named-eio/*.inc)
     (glob_files_rec ../uses/dune)
     (glob_files_rec ../uses/dune-project)
     (glob_files_rec ../uses/*.opam)
     (glob_files_rec ../uses/*.inc))
    (action
     (chdir
      %{workspace_root}
      (run %{bin:hermetic-tree} --scope other --ratchet ratchet --reads named-eio,uses --outside fmt)))))
  
  (subdir plain-eio
   (rule
    (alias runtest)
    (deps
     (sandbox always)
     ../ratchet
     ../dune
     ../dune-project
     (glob_files_rec dune)
     (glob_files_rec dune-project)
     (glob_files_rec *.opam)
     (glob_files_rec *.inc)
     (glob_files .plain_eio.objs/byte/*.cmt))
    (action
     (chdir
      %{workspace_root}
      (run %{bin:hermetic-tree} --scope plain-eio --ratchet ratchet)))))
  
  $ echo gone >> ratchet
  $ hermetic-tree --root . --include --ratchet ratchet > /dev/null
  File "ratchet", line 2, characters 0-0:
  Error: gone: in the ratchet but not an Eio library of the tree
  [1]
  $ echo "uses" > ratchet

With the rules included, building a package's runtest builds its libraries
and runs its check alone: plain-eio's is red on its violation, and named-eio's
is green. The scratch projects do not enable mdx, so their stanzas go first.

  $ for d in named-eio uses other; do
  >   grep -v mdx $d/dune > $d/dune.new && mv $d/dune.new $d/dune
  > done
  $ rm named-eio/mdx.inc uses/mdx.inc
  $ hermetic-tree --root . --include --ratchet ratchet > hermetic.inc
  $ echo "(include hermetic.inc)" > dune
  $ rm -r _build
  $ dune build --root . --display quiet @plain-eio/runtest 2>&1 | grep -E '^(File "plain|Error)'
  File "plain-eio/plain_eio.ml", line 1, characters 0-0:
  Error: plain-eio: imports Unix, which reaches the system past an Eio capability
  $ dune build --root . --display quiet @named-eio/runtest; echo "exit $?"
  exit 0
