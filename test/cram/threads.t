The threads library's types reach nothing, so the prelude keeps them, as it
keeps Unix's: a signature can name Thread.t or Event.channel, and Event,
whose values work only on the channels they are handed, stays whole. The types are
the originals, so an interface that does not open the prelude names the same
types.

  $ cat > dune-project <<EOF
  > (lang dune 3.0)
  > EOF
  $ mkdir lib
  $ cat > lib/dune <<EOF
  > (library (name work) (libraries hermetic threads.posix))
  > EOF
  $ cat > lib/work.mli <<'EOF'
  > val me : unit -> Thread.t
  > val number : unit -> int
  > val handoff : int Event.channel -> int -> unit
  > val spawn : (unit -> unit) -> Thread.t
  > EOF
  $ cat > lib/work.ml <<'EOF'
  > open! Hermetic
  > let me () = Thread.self ()
  > let number () = Thread.id (me ())
  > let handoff c v = Event.sync (Event.send c v)
  > let spawn f = Thread.create f ()
  > EOF
  $ dune build --root . --display quiet ./lib; echo "exit $?"
  exit 0

A thread reaches no capability, so Thread.create stays. A sleep or a timed
wait on the process's clock, and a wait for a child process, are refused as
ambient, and each alert names the capability to take.

  $ mkdir refused
  $ echo '(library (name refused) (libraries hermetic))' > refused/dune
  $ printf 'open! Hermetic\nlet () = Thread.delay 1.\n' > refused/delay.ml
  $ printf 'open! Hermetic\nlet ready fds = Thread.select fds [] [] 1.\n' > refused/select.ml
  $ printf 'open! Hermetic\nlet readable fd = Thread.wait_timed_read fd 1.\n' > refused/timed_read.ml
  $ printf 'open! Hermetic\nlet writable fd = Thread.wait_timed_write fd 1.\n' > refused/timed_write.ml
  $ printf 'open! Hermetic\nlet reap pid = Thread.wait_pid pid\n' > refused/wait_pid.ml
  $ dune build --root . --display quiet ./refused 2>&1 | sed 's/"//g; s/Hermetic__Refused\.//g' | grep -A1 -E '^Alert' | grep -v '^--' | sort
  Alert ambient: Hermetic.Thread.delay
  Alert ambient: Hermetic.Thread.select
  Alert ambient: Hermetic.Thread.wait_pid
  Alert ambient: Hermetic.Thread.wait_timed_read
  Alert ambient: Hermetic.Thread.wait_timed_write
  Waits for a child process: take Eio.Stdenv.process_mgr as an argument and use Eio.Process.await.
  Waits on the clock: take Eio.Stdenv.clock as an argument and use Eio.Time.sleep.
  Waits with a timeout on the clock: take Eio.Stdenv.clock as an argument and use Eio.Time.with_timeout.
  Waits with a timeout on the clock: take Eio.Stdenv.clock as an argument and use Eio.Time.with_timeout.
  Waits with a timeout on the clock: take Eio.Stdenv.clock as an argument and use Eio.Time.with_timeout.
  $ dune build --root . --display quiet ./refused 2>&1 | sed 's/"//g; s/Hermetic__Refused\.//g' | grep -c '^Error: This expression has type ambient'
  5

Event refuses nothing, so the prelude does not declare it, and a library's
own module named Event stays its own under the open. A module of the
library named like one the prelude restates, Thread here, is shadowed by the
prelude's after the open, as a library's own Format would be; named again
through the unit dune gives it, it is the library's own.

  $ mkdir own
  $ echo '(library (name queue) (libraries hermetic))' > own/dune
  $ echo 'type t = Landed | Refused' > own/event.ml
  $ echo 'let start () = 1' > own/thread.ml
  $ printf 'open! Hermetic\nlet landed = Event.Landed\n' > own/log.ml
  $ dune build --root . --display quiet ./own; echo "exit $?"
  exit 0
  $ printf 'open! Hermetic\nlet started = Thread.start ()\n' > own/run.ml
  $ dune build --root . --display quiet ./own 2>&1 | grep -c '^Error'
  1
  $ printf 'open! Hermetic\nmodule Thread = Queue__Thread\nlet started = Thread.start ()\n' > own/run.ml
  $ dune build --root . --display quiet ./own; echo "exit $?"
  exit 0

A program that names only Thread's types links no code of the threads
library, which forces its own link, so the program does not name it among
its libraries: -I +threads finds the interfaces.

  $ mkdir types
  $ cat > types/dune <<EOF
  > (executable (name main) (modes byte) (libraries hermetic)
  >  (flags (:standard -I +threads -I +unix)))
  > EOF
  $ cat > types/main.ml <<'EOF'
  > open! Hermetic
  > let describe (_ : Thread.t) (_ : int Event.channel) = ()
  > let () = ignore describe
  > EOF
  $ dune build --root . --display quiet --profile release ./types/main.bc
  $ ocamlobjinfo _build/default/types/main.bc |
  >   sed -n 's/.*compilation unit .\([A-Za-z_]*\).*/\1/p' | grep -cE 'Thread|Event'
  0
  [1]
