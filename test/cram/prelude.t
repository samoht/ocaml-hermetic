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
  > (library (name m) (libraries hermetic hermetic.unix))
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
  $ dune build --root . --display quiet --profile dev ./lib 2>&1 | sed 's/"//g; s/Hermetic__Refused\.//g' | grep -A1 -E '^(Alert|Error)'
  Alert ambient: Hermetic.Sys.file_exists
  Reads the file system by name: take Eio.Stdenv.fs or Eio.Stdenv.cwd (an Eio.Path) as an argument.
  --
  Error: This expression has type ambient
         This is not a function; it cannot be applied.
  $ rm lib/exists.ml
  $ put print 'let () = print_endline "x"'
  $ dune build --root . --display quiet --profile dev ./lib 2>&1 | sed 's/"//g; s/Hermetic__Refused\.//g' | grep -A1 '^Alert'
  Alert ambient: Hermetic.print_endline
  Writes the process's standard output: take Eio.Stdenv.stdout as an argument, or log with Logs or Eio.traceln.
  $ rm lib/print.ml

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

The standard input, output and error, which the code was not handed.

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
  $ put output_do_at_exit 'let () = do_at_exit ()'
  $ put output_format_set_output 'let capture b = Format.set_formatter_output_functions (Buffer.add_substring b) ignore'
  $ put output_format_set_out_channel 'let redirect oc = Format.set_formatter_out_channel oc'
  $ put output_format_set_max_boxes 'let () = Format.set_max_boxes 2'
  $ put output_format_set_ellipsis 'let () = Format.set_ellipsis_text "x"'
  $ put output_format_set_mark_tags 'let () = Format.set_mark_tags true'
  $ put output_format_set_geometry 'let () = Format.safe_set_geometry ~max_indent:2 ~margin:4'
  $ put output_format_get_margin 'let m = Format.get_margin ()'
  $ put output_format_over_max_boxes 'let b = Format.over_max_boxes ()'
  $ put output_runtime_warnings 'let () = Sys.enable_runtime_warnings true'

A child process, which Eio's process manager hands out, and what parses the
command line or ends the process by printing on the standard error. A domain
is in domain.t, since OCaml 4.14 has none.

  $ put proc_command 'let n = Sys.command "true"'
  $ put proc_arg 'let () = Arg.parse [] ignore ""'
  $ put proc_catch 'let run f = Printexc.catch f ()'

Entropy from the system, which would seed a generator.

  $ put random_self_init 'let () = Random.self_init ()'
  $ put random_state_self 'let s = Random.State.make_self_init ()'

Unix, which the prelude restates as it restates the standard library, in
hermetic.unix, which the library names: its types stay, and what reaches a
capability is refused (see unix.t).

  $ put unix_connect 'let connect fd addr = Unix.connect fd addr'

The libraries that reach the system past Eio's capabilities and that ship
apart from the compiler: Eio's backends, the clocks of mtime and ptime, the
entropy of bytesrw, the setup of Fmt's standard formatters, and the units of
Eio and its backends that reach a capability, or the standard error past the
executable's Eio.traceln. The prelude declares them empty, without depending
on them, so each of their names is unbound, whether the library is installed
or not.

  $ put past_eio_main 'let run = Eio_main.run'
  $ put past_eio_unix 'let () = Eio_unix.sleep 1.'
  $ put past_mtime_clock 'let now = Mtime_clock.now ()'
  $ put past_ptime_clock 'let now = Ptime_clock.now ()'
  $ put past_sysrandom 'let bytes n = Bytesrw_sysrandom.get_random n'
  $ put past_fmt_tty 'let () = Fmt_tty.setup_std_outputs ()'
  $ put past_eio_debug 'let say = Eio__core__Debug.default_traceln'
  $ put past_eio_cancel 'let root = Eio__core__Cancel.Fiber_context.make_root ()'
  $ put past_eio_unix_private 'let resolve = Eio_unix__Private.getaddrinfo'
  $ put past_eio_unix_fd 'let out = Eio_unix__Fd.stdout'
  $ put past_eio_unix_net 'let name = Eio_unix__Net.getnameinfo'
  $ put past_eio_unix_process 'let spawn = Eio_unix__Process.spawn_unix'
  $ put past_eio_unix_thread_pool 'let run = Eio_unix__Thread_pool.run_in_systhread'
  $ put past_eio_posix_low_level 'let fd = Eio_posix__Low_level.openat'
  $ put past_eio_linux_low_level 'let fd = Eio_linux__Low_level.openat'

Every other unit of those libraries is declared empty too, and so is the
module of aliases dune makes for each, which names each of its units by a
short name: the units of Eio_posix and Eio_main hold a ready-made file
system, clock, network, process manager, domain manager, entropy source or
a whole environment. Iomux, which Eio_posix polls with, waits on the clock
and makes a descriptor from an integer.

  $ put past_eio_unix_alias 'module Fd = Eio_unix__.Fd'
  $ put past_eio_posix_alias 'module L = Eio_posix__.Low_level'
  $ put past_eio_linux_alias 'module L = Eio_linux__.Low_level'
  $ put past_eio_windows_alias 'module L = Eio_windows__.Low_level'
  $ put past_eio_main_alias 'module B = Eio_main__.Posix_backend'
  $ put past_eio_core_alias 'module D = Eio__core__.Debug'
  $ put past_eio_main_backend 'let run = Eio_main__Posix_backend.run'
  $ put past_eio_posix_fs 'let fs = Eio_posix__Fs.fs'
  $ put past_eio_posix_time 'let clock = Eio_posix__Time.clock'
  $ put past_eio_posix_net 'let net = Eio_posix__Net.v'
  $ put past_eio_posix_process 'let mgr = Eio_posix__Process.mgr'
  $ put past_eio_posix_domain_mgr 'let mgr = Eio_posix__Domain_mgr.v'
  $ put past_eio_posix_flow 'let entropy = Eio_posix__Flow.secure_random'
  $ put past_eio_unix_pty 'let pty = Eio_unix__Pty.open_pty'
  $ put past_eio_unix_file 'let import = Eio_unix__File.import_rw'
  $ put past_eio_unix_fork_action 'let exec = Eio_unix__Fork_action.execve'
  $ put past_iomux 'let poll = Iomux.Poll.poll'
  $ put past_iomux_util 'let fd = Iomux__Util.unix_of_fd'

Uring, which Eio_linux submits its requests with, opens a file by name,
waits on the clock and makes and connects a socket, as Iomux reaches what
Eio_posix does.

  $ put past_uring 'let ring () : unit Uring.t = Uring.create ~queue_depth:4 ()'
  $ put past_uring_alias 'module H = Uring__.Heap'
  $ put past_uring_region 'let free = Uring__Region.free'

A unit that re-exports the standard library is Unsafe under
another name: Base's Import0 and Import, which Base__ names, and
Shadow_stdlib. Console_tty sets up the standard formatters, as Fmt_tty
does, and with Console__Recording, which Console__ names, opens the file
CONSOLE_CAST names.

  $ put past_base_import0 'let cast x : int = Base__Import0.Stdlib.Obj.magic x'
  $ put past_base_import 'module S = Base__Import.Stdlib'
  $ put past_base_alias 'module S = Base__.Import0.Stdlib'
  $ put past_shadow_stdlib 'let oc = Shadow_stdlib.open_out "f"'
  $ put past_console_tty 'let () = Console_tty.setup ()'
  $ put past_console_tty_alias 'module C = Console_tty__.Colour'
  $ put past_console_recording 'let start = Console__Recording.start'
  $ put past_console_alias 'module R = Console__.Recording'

A unit that hands out Obj.magic, or a fork of Format with its standard
formatter, is declared empty the same way: Base__Obj_local, Odoc's
Odoc_document__Compat, which includes Format, and ocamlformat's fork of
Format. So are the units of Eio's backends that Eio adds after 1.6.

  $ put past_base_obj_local 'let cast x : int = Base__Obj_local.magic x'
  $ put past_odoc_compat 'let () = Odoc_document__Compat.Format.printf "x"'
  $ put past_ocamlformat_format 'let () = Ocamlformat_format__Format_.printf "x"'
  $ put past_ocamlformat_format_main 'let () = Ocamlformat_format.Format_.printf "x"'
  $ put past_eio_unix_system_info 'let info = Eio_unix__System_info.get'
  $ put past_eio_windows_process 'let spawn = Eio_windows__Process.spawn'

What can forge memory or a value of any type: the escapes from the type
system, and every accessor that skips the check its safe version makes.

  $ put unsafe_obj 'let cast x = Obj.magic x'
  $ put unsafe_marshal 'let read s : int = Marshal.from_string s 0'
  $ put unsafe_input_value 'let read ic : int = input_value ic'
  $ put unsafe_internal 'let shape = CamlinternalMod.init_mod ("f", 1, 1) (CamlinternalMod.Module [||])'
  $ put unsafe_internal_format 'let show fmt = CamlinternalFormat.string_of_fmt fmt'
  $ put unsafe_internal_format_basics 'let erase rel = CamlinternalFormatBasics.erase_rel rel'
  $ put unsafe_internal_lazy 'let force l : int = CamlinternalLazy.force_lazy_block l'
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
  output_do_at_exit: Hermetic.do_at_exit (ambient)
  output_flush: Hermetic.flush_all (ambient)
  output_format: Hermetic.Format.printf (ambient)
  output_format_get_margin: Hermetic.Format.get_margin (ambient)
  output_format_out_functions: Hermetic.Format.get_formatter_out_functions (ambient)
  output_format_output_functions: Hermetic.Format.get_formatter_output_functions (ambient)
  output_format_over_max_boxes: Hermetic.Format.over_max_boxes (ambient)
  output_format_print: Hermetic.Format.print_string (ambient)
  output_format_set_ellipsis: Hermetic.Format.set_ellipsis_text (ambient)
  output_format_set_geometry: Hermetic.Format.safe_set_geometry (ambient)
  output_format_set_mark_tags: Hermetic.Format.set_mark_tags (ambient)
  output_format_set_max_boxes: Hermetic.Format.set_max_boxes (ambient)
  output_format_set_out_channel: Hermetic.Format.set_formatter_out_channel (ambient)
  output_format_set_output: Hermetic.Format.set_formatter_output_functions (ambient)
  output_format_stag_functions: Hermetic.Format.get_formatter_stag_functions (ambient)
  output_prerr: Hermetic.prerr_endline (ambient)
  output_print: Hermetic.print_endline (ambient)
  output_printf: Hermetic.Printf.printf (ambient)
  output_runtime_warnings: Hermetic.Sys.enable_runtime_warnings (ambient)
  output_std_formatter: Hermetic.Format.std_formatter (ambient)
  output_stdout: Hermetic.stdout (ambient)
  past_base_alias: module Hermetic.Base__ (error)
  past_base_import: module Hermetic.Base__Import (error)
  past_base_import0: module Hermetic.Base__Import0 (error)
  past_base_obj_local: module Hermetic.Base__Obj_local (error)
  past_console_alias: module Hermetic.Console__ (error)
  past_console_recording: module Hermetic.Console__Recording (error)
  past_console_tty: module Hermetic.Console_tty (error)
  past_console_tty_alias: module Hermetic.Console_tty__ (error)
  past_eio_cancel: module Hermetic.Eio__core__Cancel (error)
  past_eio_core_alias: module Hermetic.Eio__core__ (error)
  past_eio_debug: module Hermetic.Eio__core__Debug (error)
  past_eio_linux_alias: module Hermetic.Eio_linux__ (error)
  past_eio_linux_low_level: module Hermetic.Eio_linux__Low_level (error)
  past_eio_main: module Hermetic.Eio_main (error)
  past_eio_main_alias: module Hermetic.Eio_main__ (error)
  past_eio_main_backend: module Hermetic.Eio_main__Posix_backend (error)
  past_eio_posix_alias: module Hermetic.Eio_posix__ (error)
  past_eio_posix_domain_mgr: module Hermetic.Eio_posix__Domain_mgr (error)
  past_eio_posix_flow: module Hermetic.Eio_posix__Flow (error)
  past_eio_posix_fs: module Hermetic.Eio_posix__Fs (error)
  past_eio_posix_low_level: module Hermetic.Eio_posix__Low_level (error)
  past_eio_posix_net: module Hermetic.Eio_posix__Net (error)
  past_eio_posix_process: module Hermetic.Eio_posix__Process (error)
  past_eio_posix_time: module Hermetic.Eio_posix__Time (error)
  past_eio_unix: module Hermetic.Eio_unix (error)
  past_eio_unix_alias: module Hermetic.Eio_unix__ (error)
  past_eio_unix_fd: module Hermetic.Eio_unix__Fd (error)
  past_eio_unix_file: module Hermetic.Eio_unix__File (error)
  past_eio_unix_fork_action: module Hermetic.Eio_unix__Fork_action (error)
  past_eio_unix_net: module Hermetic.Eio_unix__Net (error)
  past_eio_unix_private: module Hermetic.Eio_unix__Private (error)
  past_eio_unix_process: module Hermetic.Eio_unix__Process (error)
  past_eio_unix_pty: module Hermetic.Eio_unix__Pty (error)
  past_eio_unix_system_info: module Hermetic.Eio_unix__System_info (error)
  past_eio_unix_thread_pool: module Hermetic.Eio_unix__Thread_pool (error)
  past_eio_windows_alias: module Hermetic.Eio_windows__ (error)
  past_eio_windows_process: module Hermetic.Eio_windows__Process (error)
  past_fmt_tty: module Hermetic.Fmt_tty (error)
  past_iomux: module Hermetic.Iomux (error)
  past_iomux_util: module Hermetic.Iomux__Util (error)
  past_mtime_clock: module Hermetic.Mtime_clock (error)
  past_ocamlformat_format: module Hermetic.Ocamlformat_format__Format_ (error)
  past_ocamlformat_format_main: module Hermetic.Ocamlformat_format (error)
  past_odoc_compat: module Hermetic.Odoc_document__Compat (error)
  past_ptime_clock: module Hermetic.Ptime_clock (error)
  past_shadow_stdlib: module Hermetic.Shadow_stdlib (error)
  past_sysrandom: module Hermetic.Bytesrw_sysrandom (error)
  past_uring: module Hermetic.Uring (error)
  past_uring_alias: module Hermetic.Uring__ (error)
  past_uring_region: module Hermetic.Uring__Region (error)
  proc_arg: Hermetic.Arg.parse (ambient)
  proc_catch: Hermetic.Printexc.catch (ambient)
  proc_command: Hermetic.Sys.command (ambient)
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
  unsafe_internal_format: Hermetic.CamlinternalFormat.string_of_fmt (unsafe)
  unsafe_internal_format_basics: Hermetic.CamlinternalFormatBasics.erase_rel (unsafe)
  unsafe_internal_lazy: Hermetic.CamlinternalLazy.force_lazy_block (unsafe)
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
  $ dune build --root . --display quiet --profile dev ./lib 2>&1 | sed 's/"//g; s/Hermetic__Refused\.//g' | grep -E '^(Alert|Error)'
  Error: This expression has type ambient

The way out is Hermetic.Unsafe, the standard library without
refusals. A use of it is a visible exception, which a review can find with
grep.

  $ rm lib/*.ml
  $ put audited 'let here = Unsafe.Sys.file_exists "f" let c b = Unsafe.Bytes.unsafe_get b 0'
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
  > module T = Hashtbl.MakeSeeded (struct [@@@warning "-32"] type t = int let equal = Int.equal let seeded_hash _ x = x let hash = seeded_hash end)
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
  > let a = Atomic.make 0
  > let () = Gc.compact ()
  > let tuned = (Gc.get ()).space_overhead + Bool.to_int (Printexc.backtrace_status ())
  > let randomized = Hashtbl.is_randomized ()
  > let id o = Oo.id o
  > let line ic = In_channel.input_line ic
  > let parse argv = Arg.parse_argv argv [] ignore ""
  > let home = Sys.getenv_opt "HOME"
  > let program = Sys.argv.(0) ^ Sys.executable_name ^ Sys.runtime_parameters ()
  > let t = Sys.time ()
  > let stop () = exit 1
  > let () = at_exit ignore
  > let () = Sys.set_signal Sys.sigint Sys.Signal_ignore
  > let () = Hashtbl.randomize ()
  > class c = object method m = 1 end
  > let o = (new c)#m
  > module rec R : sig val x : int end = struct let x = 1 end
  > let l = Lazy.force (lazy 1)
  > let forced = match lazy 1 with lazy x -> x
  > let deferred = Lazy.from_fun (fun () -> 1)
  > let fmt () = format_of_string "%d" ^^ "%s"
  > let printed = Printf.sprintf (fmt ()) 1 "x" ^ Printf.sprintf "%a%t" (fun () -> string_of_int) 1 (fun () -> "")
  > let parsed = Scanf.sscanf "1 x" "%d %s" (fun n s -> (n, s))
  > let boxed = Format.asprintf "@[<v 2>%a@]%!" Format.pp_print_text "x"
  > let nested = Printf.sprintf "%{%d%}" "%d"
  > let reread () : (int -> unit, unit, unit) format = Scanf.format_from_string "%d" "%d"
  > let counter = Atomic.make 0
  > let () = Atomic.incr counter; ignore (Atomic.fetch_and_add counter 1)
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
  $ dune build --root . --display quiet --profile dev ./unsafe 2>&1 | sed 's/"//g; s/Hermetic__Refused\.//g' | grep -E '^(Alert|Error)'
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
  $ dune build --root old --no-print-directory --display quiet --profile dev ./lib 2>&1 | sed 's/"//g; s/Hermetic__Refused\.//g' | grep '^Error'
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
  $ dune build --root . --display quiet --profile release ./flag 2>&1 | sed 's/"//g; s/Hermetic__Refused\.//g' | grep -E '^(Alert|Error)'
  Alert ambient: Hermetic.Sys.file_exists
  Error: This expression has type ambient
