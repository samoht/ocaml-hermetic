A source file opens Hermetic on its first line, with open!, and its library
names hermetic among its libraries. A value of the standard library that
reaches an Eio capability without being handed it then has the type ambient,
and one that can forge memory or a value of any type has the type unsafe.
Nothing consumes either type, and each refused value carries an alert named
after its type, whose message says why and what to take as an argument
instead. Each case below is one module of such a library that uses a refused
value. For each, refusals prints the value the alert names and the type the
build stopped on, or "(builds)" when the module compiles.

  $ cat > dune-project <<EOF
  > (lang dune 3.0)
  > EOF
  $ mkdir lib
  $ cat > lib/dune <<EOF
  > (library (name m) (libraries hermetic))
  > EOF
  $ put () { printf 'open! Hermetic\n%s\n' "$2" > "lib/$1.ml"; }
  $ refusals () {
  >   dune build --root . --display quiet --profile "$1" ./lib 2> build.log
  >   LC_ALL=C; for f in lib/*.ml; do
  >     awk -v n="$(basename "$f" .ml)" '
  >       /^File "/ { f = $2; gsub(/"|lib\/|\.ml|,/, "", f); err = 0 }
  >       /^Error/ { err = (f == n) }
  >       f == n && sub(/^Alert (ambient|unsafe|unreviewed): /, "") { a = $0 }
  >       f == n && /^Error/ { e = 1 }
  >       err && k == "" && match($0, /(ambient|unsafe|unreviewed)/) {
  >         k = substr($0, RSTART, RLENGTH) }
  >       END {
  >         r = (a == "" ? "no alert" : a)
  >         if (!e) r = r " (builds)"; else r = r " (" (k == "" ? "error" : k) ")"
  >         print n ": " r }
  >     ' build.log
  >   done
  > }

The alert names the value and says what to take instead; the build stops on
the value's type.

  $ put exists 'let here = Sys.file_exists "model.bin"'
  $ dune build --root . --display quiet --profile dev ./lib 2>&1 | tr -d '"' | grep -A1 -E '^(Alert|Error)'
  Alert ambient: Hermetic.Sys.file_exists
  Reads the file system by name: take Eio.Stdenv.fs or Eio.Stdenv.cwd (an Eio.Path) as an argument.
  --
  Error: This expression has type ambient
         This is not a function; it cannot be applied.
  $ rm lib/exists.ml

The file system, reached by name, and the current directory.

  $ put file_cwd 'let cwd = Sys.getcwd ()'
  $ put file_open_in 'let ic = open_in "f"'
  $ put file_in_channel 'let read path = In_channel.with_open_bin path In_channel.input_all'
  $ put file_out_channel 'let write path = Out_channel.with_open_bin path (fun oc -> Out_channel.output_string oc "x")'
  $ put file_exists 'let here = Sys.file_exists "f"'
  $ put file_readdir 'let names = Sys.readdir "."'
  $ put file_remove 'let () = Sys.remove "f"'
  $ put file_temp 'let p = Filename.temp_file "a" "b"'
  $ put file_digest 'let d = Digest.file "f"'
  $ put file_scanning 'let ib = Scanf.Scanning.open_in "f"'
  $ put file_arg 'let args = Arg.read_arg "f"'

The standard input, which the code was not handed, and the standard output
and error, which library code does not write to: diagnostics go through Logs,
data through a sink the code is handed.

  $ put input_stdin 'let c = input_line stdin'
  $ put input_read_line 'let s = read_line ()'
  $ put input_in_channel 'let s = In_channel.input_all In_channel.stdin'
  $ put input_scanf 'let n = Scanf.scanf "%d" Fun.id'
  $ put output_print 'let () = print_endline "x"'
  $ put output_stdout 'let () = output_string stdout "x"'
  $ put output_prerr 'let () = prerr_endline "x"'
  $ put output_printf 'let () = Printf.printf "x"'
  $ put output_format 'let () = Format.printf "x"'
  $ put output_std_formatter 'let () = Format.fprintf Format.std_formatter "x"'
  $ put output_format_print 'let () = Format.print_string "x"'
  $ put output_format_out_functions 'let () = let o = Format.get_formatter_out_functions () in o.out_string "x" 0 1'
  $ put output_format_output_functions 'let () = let out, _ = Format.get_formatter_output_functions () in out "x" 0 1'
  $ put output_format_stag_functions 'let () = let f = Format.get_formatter_stag_functions () in f.print_open_stag (Format.String_tag "x")'
  $ put output_flush 'let () = flush_all ()'
  $ put output_runtime_warnings 'let () = Sys.enable_runtime_warnings true'

A child process and a domain, which Eio's process and domain managers hand
out, and what parses the command line or ends the process by printing on the
standard error.

  $ put proc_command 'let n = Sys.command "true"'
  $ put proc_spawn 'let d = Domain.spawn ignore'
  $ put proc_arg 'let () = Arg.parse [] ignore ""'
  $ put proc_catch 'let run f = Printexc.catch f ()'

Entropy from the system, which would seed a generator.

  $ put random_self_init 'let () = Random.self_init ()'
  $ put random_state_self 'let s = Random.State.make_self_init ()'

Unix, which the prelude restates as it restates the standard library: its
types stay, and what reaches a capability is refused (see unix.t).

  $ put unix_connect 'let connect fd addr = Unix.connect fd addr'

The libraries that reach the system past Eio's capabilities and that ship
apart from the compiler: the prelude declares them empty, without depending
on them, so each of their names is unbound.

  $ put past_eio_main 'let run = Eio_main.run'
  $ put past_eio_unix 'let () = Eio_unix.sleep 1.'

What can forge memory or a value of any type: the escapes from the type
system, and every accessor that skips the check its safe version makes.

  $ put unsafe_obj 'let cast x = Obj.magic x'
  $ put unsafe_marshal 'let read s : int = Marshal.from_string s 0'
  $ put unsafe_input_value 'let read ic : int = input_value ic'
  $ put unsafe_internal 'let shape = CamlinternalMod.init_mod ("f", 1, 1) (CamlinternalMod.Module [||])'
  $ put unsafe_parsing 'let v : int = Parsing.peek_val (Obj.magic 0) 0'
  $ put unsafe_lexing 'let state lexbuf = Lexing.engine (Obj.magic 0) 0 lexbuf'
  $ put unsafe_bytes_get 'let c b = Bytes.unsafe_get b 0'
  $ put unsafe_bytes_string 'let s b = Bytes.unsafe_to_string b'
  $ put unsafe_string_get 'let c s = String.unsafe_get s 0'
  $ put unsafe_array_get 'let x a = Array.unsafe_get a 0'
  $ put unsafe_float_array 'let x a = Float.Array.unsafe_get a 0'
  $ put unsafe_floatarray 'let () = ArrayLabels.Floatarray.unsafe_set (Float.Array.make 1 0.) 0 1.'
  $ put unsafe_char 'let c = Char.unsafe_chr 300'
  $ put unsafe_uchar 'let u = Uchar.unsafe_of_int (-1)'
  $ put unsafe_bigarray 'let x a = Bigarray.Array1.unsafe_get a 0'
  $ put unsafe_stdlabels 'let x a = StdLabels.Array.unsafe_get a 0'

The refusal follows the declaration, however the name is spelled: through
Stdlib, a module alias, an open, an include, a unit of the standard library
named by its own name (Stdlib__Sys), a functor argument, a signature
constraint or a first-class module.

  $ put via_stdlib 'let here = Stdlib.Sys.file_exists "f"'
  $ put via_alias 'module S = Sys let here = S.file_exists "f"'
  $ put via_stdlib_alias 'module L = Stdlib let here = L.Sys.file_exists "f"'
  $ put via_open 'open Stdlib let here = Sys.file_exists "f"'
  $ put via_local_open 'let here = Stdlib.(Sys.file_exists "f")'
  $ put via_include 'include Sys let here = file_exists "f"'
  $ put via_unit 'let here = Stdlib__Sys.file_exists "f"'
  $ put via_functor 'module F (X : sig val file_exists : string -> bool end) = struct let here = X.file_exists "f" end module M = F (Sys)'
  $ put via_constraint 'module S : sig val file_exists : string -> bool end = Sys'
  $ put via_first_class 'module type E = sig val file_exists : string -> bool end let m = (module Sys : E)'
  $ put via_qualified_value 'let s = Stdlib.read_line ()'

A refused value can be named, with the alert as a warning, but not used.

  $ put named 'let exists = Sys.file_exists'

A refusal is a type error, so the build fails the same way in the release
profile as in the development one.

  $ refusals dev > dev.out
  $ refusals release > release.out
  $ cat dev.out
  file_arg: Hermetic.Arg.read_arg (ambient)
  file_cwd: Hermetic.Sys.getcwd (ambient)
  file_digest: Hermetic.Digest.file (ambient)
  file_exists: Hermetic.Sys.file_exists (ambient)
  file_in_channel: Hermetic.In_channel.with_open_bin (ambient)
  file_open_in: Hermetic.open_in (ambient)
  file_out_channel: Hermetic.Out_channel.with_open_bin (ambient)
  file_readdir: Hermetic.Sys.readdir (ambient)
  file_remove: Hermetic.Sys.remove (ambient)
  file_scanning: Hermetic.Scanf.Scanning.open_in (ambient)
  file_temp: Hermetic.Filename.temp_file (ambient)
  input_in_channel: Hermetic.In_channel.stdin (ambient)
  input_read_line: Hermetic.read_line (ambient)
  input_scanf: Hermetic.Scanf.scanf (ambient)
  input_stdin: Hermetic.stdin (ambient)
  named: Hermetic.Sys.file_exists (builds)
  output_flush: Hermetic.flush_all (ambient)
  output_format: Hermetic.Format.printf (ambient)
  output_format_out_functions: Hermetic.Format.get_formatter_out_functions (ambient)
  output_format_output_functions: Hermetic.Format.get_formatter_output_functions (ambient)
  output_format_print: Hermetic.Format.print_string (ambient)
  output_format_stag_functions: Hermetic.Format.get_formatter_stag_functions (ambient)
  output_prerr: Hermetic.prerr_endline (ambient)
  output_print: Hermetic.print_endline (ambient)
  output_printf: Hermetic.Printf.printf (ambient)
  output_runtime_warnings: Hermetic.Sys.enable_runtime_warnings (ambient)
  output_std_formatter: Hermetic.Format.std_formatter (ambient)
  output_stdout: Hermetic.stdout (ambient)
  past_eio_main: module Hermetic.Eio_main (error)
  past_eio_unix: module Hermetic.Eio_unix (error)
  proc_arg: Hermetic.Arg.parse (ambient)
  proc_catch: Hermetic.Printexc.catch (ambient)
  proc_command: Hermetic.Sys.command (ambient)
  proc_spawn: Hermetic.Domain.spawn (ambient)
  random_self_init: Hermetic.Random.self_init (ambient)
  random_state_self: Hermetic.Random.State.make_self_init (ambient)
  unix_connect: Hermetic.Unix.connect (ambient)
  unsafe_array_get: Hermetic.Array.unsafe_get (unsafe)
  unsafe_bigarray: Hermetic.Bigarray.Array1.unsafe_get (unsafe)
  unsafe_bytes_get: Hermetic.Bytes.unsafe_get (unsafe)
  unsafe_bytes_string: Hermetic.Bytes.unsafe_to_string (unsafe)
  unsafe_char: Hermetic.Char.unsafe_chr (unsafe)
  unsafe_float_array: Hermetic.Float.Array.unsafe_get (unsafe)
  unsafe_floatarray: Hermetic.ArrayLabels.Floatarray.unsafe_set (unsafe)
  unsafe_input_value: Hermetic.input_value (unsafe)
  unsafe_internal: Hermetic.CamlinternalMod.init_mod (unsafe)
  unsafe_lexing: Hermetic.Lexing.engine (unsafe)
  unsafe_marshal: Hermetic.Marshal.from_string (unsafe)
  unsafe_obj: Hermetic.Obj.magic (unsafe)
  unsafe_parsing: Hermetic.Parsing.peek_val (unsafe)
  unsafe_stdlabels: Hermetic.StdLabels.Array.unsafe_get (unsafe)
  unsafe_string_get: Hermetic.String.unsafe_get (unsafe)
  unsafe_uchar: Hermetic.Uchar.unsafe_of_int (unsafe)
  via_alias: S.file_exists (ambient)
  via_constraint: file_exists (ambient)
  via_first_class: file_exists (ambient)
  via_functor: file_exists (ambient)
  via_include: file_exists (ambient)
  via_local_open: Hermetic.Stdlib.Sys.file_exists (ambient)
  via_open: Hermetic.Stdlib.Sys.file_exists (ambient)
  via_qualified_value: Hermetic.Stdlib.read_line (ambient)
  via_stdlib: Hermetic.Stdlib.Sys.file_exists (ambient)
  via_stdlib_alias: L.Sys.file_exists (ambient)
  via_unit: Hermetic.Stdlib__Sys.file_exists (ambient)
  $ diff dev.out release.out && echo same in release
  same in release

Silencing the alert hides the message, not the refusal: the value keeps its
type.

  $ rm lib/*.ml
  $ put silenced 'let here = (Sys.file_exists [@alert "-ambient"]) "f"'
  $ dune build --root . --display quiet --profile dev ./lib 2>&1 | tr -d '"' | grep -E '^(Alert|Error)'
  Error: This expression has type ambient

The way out is Hermetic.Stdlib_original, the standard library without
refusals. A use of it is a visible exception, which a review can find with
grep.

  $ rm lib/*.ml
  $ put audited 'let here = Stdlib_original.Sys.file_exists "f" let c b = Stdlib_original.Bytes.unsafe_get b 0'
  $ dune build --root . --display quiet --profile dev ./lib; echo "exit $?"
  exit 0
  $ rm lib/*.ml
  $ put unsafe 'let c b = Bytes.unsafe_get b 0'
  $ dune build --root . --display quiet --profile dev ./lib 2>&1 | grep -A1 '^Alert'
  Alert unsafe: Hermetic.Bytes.unsafe_get
  No bounds check: use Bytes.get.

What stays is everything that reaches no Eio capability: what works on what
it is handed; the process environment, the command line, the process's facts,
the processor time it has used, its exit and its signals; and the state the
whole process shares: the default generator, which is domain-local and seeded
deterministically, the order of a hash table, the garbage collector,
registered printers, backtraces, the process's counters and synchronisation.

  $ rm lib/*.ml
  $ cat > lib/ok.ml <<'EOF'
  > open! Hermetic
  > let words = Sys.word_size + Sys.int_size + Sys.max_string_length
  > let os = (Sys.os_type, Sys.big_endian, Sys.opaque_identity 1)
  > let draw seed = Random.State.(int (make [| seed |]) 10)
  > let seen = Hashtbl.create 1
  > let () = Hashtbl.replace seen "a" ()
  > let keys t = Hashtbl.fold (fun k _ acc -> k :: acc) t []
  > module T = Hashtbl.MakeSeeded (struct type t = int let equal = Int.equal let seeded_hash _ x = x end)
  > let s = Printf.sprintf "%d" 1 ^ Format.asprintf "%a" Format.pp_print_int 1
  > let pp ppf x = Format.fprintf ppf "%d" x
  > let roll () = Random.int 6
  > let () = Printexc.register_printer (fun _ -> None); Printexc.record_backtrace true
  > let () = Callback.register "f" ignore
  > let _ = Parsing.set_trace false
  > let ext = Filename.extension "a.b"
  > let d = Digest.to_hex (Digest.string "x")
  > let e = Printexc.to_string Exit
  > let get a = a.(0) + Array.get a 0
  > let c = "x".[0] = Bytes.get (Bytes.make 1 'x') 0
  > let m = Mutex.create ()
  > let a = Atomic.make 0
  > let self () = Domain.self ()
  > let () = Gc.compact ()
  > let tuned = (Gc.get ()).space_overhead + Bool.to_int (Printexc.backtrace_status ())
  > let randomized = Hashtbl.is_randomized ()
  > let id o = Oo.id o
  > let terminal ic = In_channel.isatty ic
  > let parse argv = Arg.parse_argv argv [] ignore ""
  > let home = Sys.getenv_opt "HOME"
  > let program = Sys.argv.(0) ^ Sys.executable_name ^ Sys.runtime_parameters ()
  > let t = Sys.time ()
  > let stop () = exit 1
  > let () = at_exit ignore; Domain.at_exit ignore
  > let () = Sys.set_signal Sys.sigint Sys.Signal_ignore
  > let n = Domain.recommended_domain_count ()
  > let () = Hashtbl.randomize ()
  > class c = object method m = 1 end
  > let o = (new c)#m
  > module rec R : sig val x : int end = struct let x = 1 end
  > let l = Lazy.force (lazy 1)
  > let first ic = input_line ic
  > let all ic = In_channel.input_all ic
  > let write oc = Out_channel.output_string oc "x"; flush oc
  > let marshal x = Marshal.to_string x []
  > EOF
  $ dune build --root . --display quiet --profile dev ./lib; echo "exit $?"
  exit 0

Gc.set stays, but leaves the runtime's verbosity as it is: a verbose garbage
collector would write on the standard error.

  $ mkdir verbose
  $ echo '(executable (name main) (libraries hermetic))' > verbose/dune
  $ cat > verbose/main.ml <<'EOF'
  > open! Hermetic
  > let () = Gc.set { (Gc.get ()) with verbose = 0x01 }; Gc.full_major ()
  > let () = exit (Gc.get ()).verbose
  > EOF
  $ dune build --root . --display quiet --profile dev ./verbose/main.exe
  $ ./_build/default/verbose/main.exe; echo "exit $?"
  exit 0

-unsafe compiles a.(i) to Array.unsafe_get, which the prelude refuses, so a
file that opens it and indexes an array cannot be compiled with -unsafe; one
that indexes nothing can.

  $ mkdir unsafe
  $ cat > unsafe/dune <<EOF
  > (library (name u) (libraries hermetic) (flags (:standard -unsafe)))
  > EOF
  $ printf 'open! Hermetic\nlet first a = a.(0)\n' > unsafe/u.ml
  $ dune build --root . --display quiet --profile dev ./unsafe 2>&1 | tr -d '"' | grep -E '^(Alert|Error)'
  Alert unsafe: Hermetic.Array.unsafe_get
  Error: This expression has type unsafe
  $ printf 'open! Hermetic\nlet first l = List.hd l\n' > unsafe/u.ml
  $ dune build --root . --display quiet --profile dev ./unsafe; echo "exit $?"
  exit 0

Code above the open is outside the prelude, so the open is the first line. No
check catches a file that forgets it.

  $ mkdir above
  $ echo '(library (name above) (libraries hermetic))' > above/dune
  $ printf 'let here = Sys.file_exists "f"\nopen! Hermetic\nlet n = List.length []\n' > above/above.ml
  $ dune build --root . --display quiet --profile dev ./above; echo "exit $?"
  exit 0

The open is spelled open!. A plain open that leaves nothing used is warning
33, an error in dune's development profile up to (lang dune 3.20), and one
that shadows a name of the standard library is warning 44, which -w +a
enables. open! is neither.

  $ mkdir -p old/lib
  $ echo '(lang dune 3.0)' > old/dune-project
  $ echo '(library (name constant) (libraries hermetic))' > old/lib/dune
  $ printf 'open Hermetic\nlet answer = 42\n' > old/lib/constant.ml
  $ dune build --root old --no-print-directory --display quiet --profile dev ./lib 2>&1 | tr -d '"' | grep '^Error'
  Error (warning 33 [unused-open]): unused open Hermetic.
  $ printf 'open! Hermetic\nlet answer = 42\n' > old/lib/constant.ml
  $ dune build --root old --no-print-directory --display quiet --profile dev ./lib; echo "exit $?"
  exit 0
  $ mkdir strict
  $ echo '(library (name strict) (libraries hermetic) (flags (:standard -w +a-70)))' > strict/dune
  $ printf 'open Hermetic\nlet n = Sys.word_size\n' > strict/strict.ml
  $ dune build --root . --display quiet --profile dev ./strict 2>&1 | grep -o '^Warning 44 [^:]*' | sort -u
  Warning 44 [open-shadow-identifier]
  $ printf 'open! Hermetic\nlet n = Sys.word_size\n' > strict/strict.ml
  $ dune build --root . --display quiet --profile dev ./strict; echo "exit $?"
  exit 0

The prelude can also be opened by a flag, for every file of a library at once.
The flag opens it in the interfaces too, so their types are the prelude's
paths (see stdlib-types.t); the open at the top of each source file keeps them
the standard library's own.

  $ mkdir flag
  $ cat > flag/dune <<EOF
  > (library (name flagged) (libraries hermetic)
  >  (flags (:standard -open Hermetic)))
  > EOF
  $ echo 'let here = Sys.file_exists "f"' > flag/flagged.ml
  $ dune build --root . --display quiet --profile release ./flag 2>&1 | tr -d '"' | grep -E '^(Alert|Error)'
  Alert ambient: Hermetic.Sys.file_exists
  Error: This expression has type Hermetic__Refused.ambient
