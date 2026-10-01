A library compiled with -open Hermetic -alert @ambient is refused every value
of the standard library that reads or writes the world outside the program.
Each case below is one module of such a library, put in place by put; the build refuses each by the
name it reached, and a case refused for any other reason would print nothing
here.

  $ cat > dune-project <<EOF
  > (lang dune 3.21)
  > EOF
  $ mkdir lib ok
  $ cat > lib/dune <<EOF
  > (library (name m) (libraries hermetic)
  >  (flags (:standard -open Hermetic -alert @ambient)))
  > EOF
  $ put () { echo "$2" > "lib/$1.ml"; }
  $ refusals () {
  >   dune build --root . --display quiet ./lib 2>&1 | awk '
  >     /^File "lib\// { f = $2; gsub(/"|lib\/|\.ml|,/, "", f) }
  >     sub(/^Error \(alert ambient\): /, "") { print f ": " $0 }' | LC_ALL=C sort
  > }

The refusal names the value and says what to do instead.

  $ put getenv 'let home = Sys.getenv "HOME"'
  $ dune build --root . --display quiet ./lib 2>&1 | grep -A1 '^Error'
  Error (alert ambient): Hermetic.Sys.getenv
  Reads the process environment: take the value as an input.

The process environment and the process's own facts.

  $ put env_getenv_opt 'let home = Sys.getenv_opt "HOME"'
  $ put env_argv 'let argv = Sys.argv'
  $ put env_executable 'let exe = Sys.executable_name'
  $ put env_cwd 'let cwd = Sys.getcwd ()'
  $ put env_runtime 'let params = Sys.runtime_parameters ()'

The clock.

  $ put clock 'let t = Sys.time ()'

Randomness seeded from the system, and the generator the whole process
shares. A generic hash table is seeded from the system when OCAMLRUNPARAM
holds R, so what observes its order is refused.

  $ put random_self_init 'let () = Random.self_init ()'
  $ put random_int 'let n = Random.int 10'
  $ put random_state_self 'let s = Random.State.make_self_init ()'
  $ put table_iter 'let f t = Hashtbl.iter (fun _ _ -> ()) t'
  $ put table_fold 'let f t = Hashtbl.fold (fun k _ acc -> k :: acc) t []'
  $ put table_seq 'let f t = Hashtbl.to_seq_keys t'
  $ put table_seeded 'module T = Hashtbl.MakeSeeded'
  $ put table_randomize 'let () = Hashtbl.randomize ()'

Files and channels.

  $ put file_open_in 'let ic = open_in "f"'
  $ put file_in_channel 'let read path = In_channel.with_open_bin path In_channel.input_all'
  $ put file_out_channel 'let write path = Out_channel.with_open_bin path (fun oc -> Out_channel.output_string oc "x")'
  $ put file_exists 'let here = Sys.file_exists "f"'
  $ put file_readdir 'let names = Sys.readdir "."'
  $ put file_remove 'let () = Sys.remove "f"'
  $ put file_temp 'let p = Filename.temp_file "a" "b"'
  $ put file_digest 'let d = Digest.file "f"'
  $ put chan_stdin 'let c = stdin'
  $ put chan_stdout 'let c = stdout'
  $ put chan_print 'let () = print_string "x"'
  $ put chan_prerr 'let () = prerr_endline "x"'
  $ put chan_read_line 'let s = read_line ()'
  $ put chan_printf 'let () = Printf.printf "x"'
  $ put chan_format_printf 'let () = Format.printf "x"'
  $ put chan_std_formatter 'let ppf = Format.std_formatter'
  $ put chan_format_print 'let () = Format.print_string "x"'
  $ put chan_fmt_pr 'let () = Fmt.pr "x"'
  $ put chan_fmt_stdout 'let ppf = Fmt.stdout'
  $ put chan_scanf 'let n = Scanf.scanf "%d" Fun.id'

The process itself.

  $ put proc_exit 'let stop () = exit 1'
  $ put proc_at_exit 'let () = at_exit ignore'
  $ put proc_command 'let n = Sys.command "true"'
  $ put proc_signal 'let () = Sys.set_signal Sys.sigint Sys.Signal_ignore'
  $ put proc_arg 'let parse = Arg.parse'

State the whole process shares.

  $ put shared_domain 'let spawn = Domain.spawn'
  $ put shared_mutex 'let m = Mutex.create ()'
  $ put shared_atomic 'let a = Atomic.make 0'
  $ put shared_gc 'let () = Gc.compact ()'
  $ put shared_weak 'let w = Weak.create 1'
  $ put shared_printer 'let () = Printexc.register_printer (fun _ -> None)'
  $ put shared_to_string 'let s = Printexc.to_string Exit'
  $ put shared_fmt_exn 'let s = Fmt.str "%a" Fmt.exn Exit'
  $ put shared_oo 'let id = Oo.id'

The escapes from the type system.

  $ put escape_obj 'let cast x = Obj.magic x'
  $ put escape_marshal 'let read s = Marshal.from_string s 0'
  $ put escape_internal 'let init = CamlinternalMod.init_mod'

The refusal follows the declaration, however the name is spelled: through
Stdlib, through a module alias, an open, an include, a functor argument, a
signature constraint, a first-class module, or a partial application. A unit
of the standard library named by its own name, Stdlib__Sys, is past the
prelude; check.t shows hermetic-check refusing it.

  $ put via_stdlib 'let home = Stdlib.Sys.getenv "HOME"'
  $ put via_alias 'module S = Sys let home = S.getenv "HOME"'
  $ put via_stdlib_alias 'module L = Stdlib let home = L.Sys.getenv "HOME"'
  $ put via_open 'open Stdlib let home = Sys.getenv "HOME"'
  $ put via_local_open 'let home = Stdlib.(Sys.getenv "HOME")'
  $ put via_include 'include Sys let home = getenv "HOME"'
  $ put via_functor 'module F (X : sig val getenv : string -> string end) = struct let home = X.getenv "HOME" end module M = F (Sys)'
  $ put via_constraint 'module S : sig val getenv : string -> string end = Sys'
  $ put via_first_class 'module type E = sig val getenv : string -> string end let m = (module Sys : E)'
  $ put via_partial 'let read = Sys.getenv'
  $ put via_qualified_value 'let () = Stdlib.print_string "x"'

  $ refusals
  chan_fmt_pr: Hermetic.Fmt.pr
  chan_fmt_stdout: Hermetic.Fmt.stdout
  chan_format_print: Hermetic.Format.print_string
  chan_format_printf: Hermetic.Format.printf
  chan_prerr: Hermetic.prerr_endline
  chan_print: Hermetic.print_string
  chan_printf: Hermetic.Printf.printf
  chan_read_line: Hermetic.read_line
  chan_scanf: Hermetic.Scanf.scanf
  chan_std_formatter: Hermetic.Format.std_formatter
  chan_stdin: Hermetic.stdin
  chan_stdout: Hermetic.stdout
  clock: Hermetic.Sys.time
  env_argv: Hermetic.Sys.argv
  env_cwd: Hermetic.Sys.getcwd
  env_executable: Hermetic.Sys.executable_name
  env_getenv_opt: Hermetic.Sys.getenv_opt
  env_runtime: Hermetic.Sys.runtime_parameters
  escape_internal: module Hermetic.CamlinternalMod
  escape_marshal: module Hermetic.Marshal
  escape_obj: module Hermetic.Obj
  file_digest: Hermetic.Digest.file
  file_exists: Hermetic.Sys.file_exists
  file_in_channel: Hermetic.In_channel.with_open_bin
  file_open_in: Hermetic.open_in
  file_out_channel: Hermetic.Out_channel.with_open_bin
  file_readdir: Hermetic.Sys.readdir
  file_remove: Hermetic.Sys.remove
  file_temp: Hermetic.Filename.temp_file
  getenv: Hermetic.Sys.getenv
  proc_arg: module Hermetic.Arg
  proc_at_exit: Hermetic.at_exit
  proc_command: Hermetic.Sys.command
  proc_exit: Hermetic.exit
  proc_signal: Hermetic.Sys.set_signal
  random_int: Hermetic.Random.int
  random_self_init: Hermetic.Random.self_init
  random_state_self: Hermetic.Random.State.make_self_init
  shared_atomic: module Hermetic.Atomic
  shared_domain: module Hermetic.Domain
  shared_fmt_exn: Hermetic.Fmt.exn
  shared_gc: module Hermetic.Gc
  shared_mutex: module Hermetic.Mutex
  shared_oo: module Hermetic.Oo
  shared_printer: Hermetic.Printexc.register_printer
  shared_to_string: Hermetic.Printexc.to_string
  shared_weak: module Hermetic.Weak
  table_fold: Hermetic.Hashtbl.fold
  table_iter: Hermetic.Hashtbl.iter
  table_randomize: Hermetic.Hashtbl.randomize
  table_seeded: module Hermetic.Hashtbl.MakeSeeded
  table_seq: Hermetic.Hashtbl.to_seq_keys
  via_alias: S.getenv
  via_constraint: getenv
  via_first_class: getenv
  via_functor: getenv
  via_include: getenv
  via_local_open: Hermetic.Stdlib.Sys.getenv
  via_open: Hermetic.Stdlib.Sys.getenv
  via_partial: Hermetic.Sys.getenv
  via_qualified_value: Hermetic.Stdlib.print_string
  via_stdlib: Hermetic.Stdlib.Sys.getenv
  via_stdlib_alias: L.Sys.getenv

What stays is the pure standard library: the constants of Sys, a generator
built from a seed the caller passes, the tables of Hashtbl.Make and the
lookups of a generic one, formatting to a given formatter or a string, the
channels the caller hands in, and the language's own objects, recursive
modules and lazy values.

  $ cat > ok/dune <<EOF
  > (library (name ok) (libraries hermetic)
  >  (flags (:standard -open Hermetic -alert @ambient)))
  > EOF
  $ cat > ok/ok.ml <<EOF
  > let words = Sys.word_size + Sys.int_size + Sys.max_string_length
  > let os = (Sys.os_type, Sys.big_endian, Sys.opaque_identity 1)
  > let draw seed = Random.State.(int (make [| seed |]) 10)
  > module T = Hashtbl.Make (String)
  > let keys (t : int T.t) = T.fold (fun k _ acc -> k :: acc) t []
  > let seen = Hashtbl.create 1
  > let () = Hashtbl.replace seen "a" ()
  > let known = Hashtbl.mem seen "a"
  > let s = Printf.sprintf "%d" 1 ^ Format.asprintf "%a" Format.pp_print_int 1
  > let pp ppf x = Format.fprintf ppf "%d" x
  > let f = Fmt.str "%a" Fmt.int 1
  > let ext = Filename.extension "a.b"
  > let d = Digest.to_hex (Digest.string "x")
  > let e = Printexc.to_string_default Exit
  > class c = object method m = 1 end
  > let o = (new c)#m
  > module rec R : sig val x : int end = struct let x = 1 end
  > let l = Lazy.force (lazy 1)
  > let first ic = input_line ic
  > let all ic = In_channel.input_all ic
  > let say oc = Out_channel.output_string oc "x"; flush oc
  > EOF
  $ dune build --root . --display quiet ./ok; echo "exit $?"
  exit 0

A module refused as a whole is empty, and the mutable globals of the
standard library are (): an attribute that silences the alert, which
hermetic-check refuses, still leaves them unusable.

  $ mkdir silenced
  $ cat > silenced/dune <<EOF
  > (library (name silenced) (libraries hermetic)
  >  (flags (:standard -open Hermetic -alert @ambient)))
  > EOF
  $ cat > silenced/silenced.ml <<EOF
  > [@@@alert "-ambient"]
  > let first = Sys.argv.(0)
  > EOF
  $ dune build --root . --display quiet ./silenced 2>&1 | grep -A1 '^Error'
  Error: The value Sys.argv has type unit
         but an expression was expected of type 'a array
  $ cat > silenced/silenced.ml <<EOF
  > [@@@alert "-ambient"]
  > let cast x = Obj.magic x
  > EOF
  $ dune build --root . --display quiet ./silenced 2>&1 | grep '^Error'
  Error: Unbound value Obj.magic
