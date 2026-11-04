The prelude depends on nothing but the standard library: its restated Unix
and UnixLabels are the library hermetic.unix, which depends on unix, and its
restated Thread is hermetic.threads, which depends on threads. A program
that links every unit of hermetic, as -linkall does and as wasm_of_ocaml
does in its development profile, then needs neither unix nor threads.

  $ cat > dune-project <<EOF
  > (lang dune 3.0)
  > EOF
  $ mkdir all
  $ cat > all/dune <<EOF
  > (executable (name main) (modes byte exe) (libraries hermetic)
  >  (link_flags (-linkall)))
  > EOF
  $ printf 'open! Hermetic\nlet () = exit (List.length [ Sys.word_size ] - 1)\n' > all/main.ml
  $ dune build --root . --display quiet ./all/main.bc ./all/main.exe; echo "exit $?"
  exit 0
  $ ./_build/default/all/main.exe; echo "exit $?"
  exit 0

A library that uses Unix or Thread through the prelude names the sub-library
among its libraries, and the link order follows from the dependencies: a
program that names only that library links unix before the restated Unix.

  $ mkdir pid run
  $ echo '(library (name pid) (libraries hermetic hermetic.unix hermetic.threads))' > pid/dune
  $ cat > pid/pid.ml <<'EOF'
  > open! Hermetic
  > let positive () = Unix.getpid () > 0 && Thread.id (Thread.self ()) >= 0
  > EOF
  $ echo '(executable (name main) (libraries pid))' > run/dune
  $ echo 'let () = exit (if Pid.positive () then 0 else 1)' > run/main.ml
  $ dune build --root . --display quiet ./run/main.exe; echo "exit $?"
  exit 0
  $ ./_build/default/run/main.exe; echo "exit $?"
  exit 0

With the sub-library, a refused value of Unix or Thread is refused as the
standard library's are.

  $ mkdir refused
  $ echo '(library (name refused) (libraries hermetic hermetic.unix hermetic.threads))' > refused/dune
  $ printf 'open! Hermetic\nlet now = Unix.gettimeofday ()\n' > refused/now.ml
  $ printf 'open! Hermetic\nlet () = Thread.delay 1.\n' > refused/delay.ml
  $ dune build --root . --display quiet ./refused 2>&1 | grep -oE '^(Alert [a-z]+: [A-Za-z.]+|Error)' | sort
  Alert ambient: Hermetic.Thread.delay
  Alert ambient: Hermetic.Unix.gettimeofday
  Error
  Error

Without it, a file that opens the prelude does not fall back on the unix
library's Unix, even when the library names unix: Unix is the prelude's,
whose unit is missing, and the build fails. Compilers before 5.3 quote the
module names, which the sed removes.

  $ mkdir missing
  $ echo '(library (name missing) (libraries hermetic unix threads))' > missing/dune
  $ printf 'open! Hermetic\nlet pid () = Unix.getpid ()\n' > missing/pid.ml
  $ printf 'open! Hermetic\nlet self () = Thread.self ()\n' > missing/self.ml
  $ dune build --root . --display quiet ./missing 2>&1 | sed 's/"//g' | grep -oE 'Hermetic__[A-Za-z]+, which is missing' | sort
  Hermetic__Thread, which is missing
  Hermetic__Unix, which is missing
