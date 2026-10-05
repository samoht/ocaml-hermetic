A library that does its I/O through Eio is compiled with -open Hermetic_eio
-alert @ambient. Its prelude keeps the standard library that Eio code uses and
refuses every file system, process, environment and clock access that bypasses
a capability, naming the Eio call to make instead. hermetic-check --eio refuses
what the prelude cannot see: a unit that imports Unix, UnixLabels, Thread or
Event. A library that is the sanctioned boundary passes
--boundary in its own stanza.

  $ cat > dune-project <<EOF
  > (lang dune 3.21)
  > EOF
  $ unit () {
  >   mkdir -p "$1"
  >   printf '(library (name %s) (libraries hermetic.eio %s) (flags (:standard %s)))\n' \
  >     "$1" "$2" "$3" > "$1/dune"
  >   cat > "$1/$1.ml"
  > }
  $ cmt () { echo "_build/default/$1/.$1.objs/byte/$1.cmt"; }
  $ check () {
  >   hermetic-check "$@"
  >   echo "exit $?"
  > }

A file system query past a capability is a compile error naming the Eio call
that replaces it.

  $ unit exists "" "-open Hermetic_eio -alert @ambient" <<EOF
  > let here = Sys.file_exists "state"
  > EOF
  $ dune build --root . --display quiet ./exists 2>&1 | grep -A1 '^Error'
  Error (alert ambient): Hermetic_eio.Sys.file_exists
  Reads the file system past a capability: use Eio.Path.kind ~follow:true.
  $ rm -r exists

What Eio code uses stays: the pure standard library, Hashtbl iteration, Atomic
and the standard formatters.

  $ unit good "" "-open Hermetic_eio -alert @ambient" <<EOF
  > let words = Hashtbl.fold (fun k _ acc -> k :: acc) (Hashtbl.create 1) []
  > let count = Atomic.make 0
  > let pp ppf () = Format.fprintf ppf "%d" (Atomic.get count)
  > EOF

A unit that imports Unix or the threads library reaches the system past Eio.
It builds, and the check refuses it; Thread's own signature imports Unix.

  $ unit unlink "unix" "-open Hermetic_eio -alert @ambient" <<EOF
  > let remove path = Unix.unlink path
  > EOF
  $ unit threaded "threads.posix" "-open Hermetic_eio -alert @ambient" <<EOF
  > let self () = Thread.id (Thread.self ())
  > EOF
  $ unit plain "hermetic" "-open Hermetic -alert @ambient" <<EOF
  > let x = 1
  > EOF
  $ dune build --root . --display quiet --profile release; echo "exit $?"
  exit 0
  $ check --eio $(cmt good)
  exit 0
  $ check --eio $(cmt unlink)
  unlink/unlink.ml: imports Unix, which reaches the system past an Eio capability
  exit 1
  $ check --eio $(cmt threaded)
  threaded/threaded.ml: imports Thread, which reaches the system past an Eio capability
  threaded/threaded.ml: imports Unix, which reaches the system past an Eio capability
  exit 1

--eio requires the Eio prelude, not Hermetic's.

  $ check --eio $(cmt plain)
  plain/plain.ml: compiled without -open Hermetic_eio
  exit 1

A sanctioned boundary may import Unix; it still needs the prelude.

  $ check --eio --boundary $(cmt unlink)
  exit 0
  $ check --eio --boundary $(cmt plain)
  plain/plain.ml: compiled without -open Hermetic_eio
  exit 1
  $ check --boundary $(cmt unlink)
  Usage: hermetic-check [--help] [--boundary] [--eio] [--open=MODULE]
         [OPTION]… CMT…
  hermetic-check: --boundary needs --eio
  exit 124
