(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

type kind = Ambient | Unsafe | Unreviewed
type refusal = { kind : kind; message : string }

type entry =
  | Value of refusal
  | Module of refusal
  | Retyped of { typ : string; impl : string; doc : string }
  | Keep of string

let kind_name = function
  | Ambient -> "ambient"
  | Unsafe -> "unsafe"
  | Unreviewed -> "unreviewed"

let ambient message = Value { kind = Ambient; message }
let unsafe message = Value { kind = Unsafe; message }
let unsafe_module message = Module { kind = Unsafe; message }

(* [words s] is the space-separated names in [s]. *)
let words s = List.filter (( <> ) "") (String.split_on_char ' ' s)

(* [each m names entry] refuses with [entry] each of the space-separated
   [names] of the module at path [m], or of [Stdlib] itself when [m] is
   empty. *)
let each m names entry =
  List.map (fun n -> ((if m = "" then n else m ^ "." ^ n), entry)) (words names)

(* {1 Forging: what escapes memory or type safety} *)

let no_check check m pairs =
  let path n = if m = "" then n else m ^ "." ^ n in
  List.map
    (fun (unsafe_name, safe) ->
      ( path unsafe_name,
        unsafe (Printf.sprintf "No %s check: use %s." check (path safe)) ))
    pairs

let accessors m =
  no_check "bounds" m [ ("unsafe_get", "get"); ("unsafe_set", "set") ]

let bytes m =
  no_check "bounds" m
    [
      ("unsafe_get", "get");
      ("unsafe_set", "set");
      ("unsafe_blit", "blit");
      ("unsafe_blit_string", "blit_string");
      ("unsafe_fill", "fill");
    ]
  @ [
      ( m ^ ".unsafe_to_string",
        unsafe
          (Printf.sprintf
             "Shares mutable bytes with a string: use %s.to_string." m) );
      ( m ^ ".unsafe_of_string",
        unsafe
          (Printf.sprintf
             "Shares a string with mutable bytes: use %s.of_string." m) );
      ( m ^ ".unsafe_escape",
        Keep "It returns its argument or a fresh copy, and forges nothing." );
    ]

let strings m =
  no_check "bounds" m [ ("unsafe_get", "get"); ("unsafe_blit", "blit") ]

let any_type = "Returns a value of any type: escapes the type system."

let marshalled =
  "Reads marshalled data, which can forge a value of any type: decode with a \
   typed codec."

let type_escapes =
  [
    ("Obj", unsafe_module "Escapes the type system.");
    ( "CamlinternalMod",
      unsafe_module
        "The runtime support of recursive modules: escapes the type system." );
    ( "CamlinternalOO",
      unsafe_module "The runtime support of objects: escapes the type system."
    );
    ("input_value", unsafe marshalled);
    ( "Dynarray.unsafe_to_iarray",
      unsafe
        "Shares a mutable array with an immutable one: use Iarray.of_array on \
         Dynarray.to_array." );
  ]
  @ each "Marshal" "from_bytes from_string from_channel" (unsafe marshalled)
  @ each "Lexing" "engine new_engine"
      (unsafe
         "Reads and writes past the bounds of the tables it is given: run the \
          lexer ocamllex generates outside the prelude.")
  @ each "Parsing" "peek_val yyparse" (unsafe any_type)

let unsafe_refusals =
  type_escapes
  @ no_check "bounds" "" [ ("unsafe_really_input", "really_input") ]
  @ no_check "range" "Char" [ ("unsafe_chr", "chr") ]
  @ no_check "range" "Uchar"
      [ ("unsafe_of_int", "of_int"); ("unsafe_to_char", "to_char") ]
  @ List.concat_map accessors
      [
        "Array";
        "Array.Floatarray";
        "ArrayLabels";
        "ArrayLabels.Floatarray";
        "Float.Array";
        "Float.ArrayLabels";
        "Bigarray.Array1";
        "Bigarray.Array2";
        "Bigarray.Array3";
      ]
  @ bytes "Bytes" @ bytes "BytesLabels" @ strings "String"
  @ strings "StringLabels"
  @ no_check "bounds" "Iarray" [ ("unsafe_get", "get") ]

(* {1 Ambient authority: what reaches an Eio capability without being handed
   it} *)

let fs = "take Eio.Stdenv.fs or Eio.Stdenv.cwd (an Eio.Path) as an argument"
let opens = "Opens a file by name: " ^ fs ^ ", or the file's contents."
let reads_fs = "Reads the file system by name: " ^ fs ^ "."
let writes_fs = "Writes the file system by name: " ^ fs ^ "."

let stdin =
  "Reads the process's standard input: take Eio.Stdenv.stdin or the bytes as \
   an argument."

let capability = function
  | "output" -> "Eio.Stdenv.stdout"
  | _ -> "Eio.Stdenv.stderr"

let writes channel =
  Printf.sprintf
    "Writes the process's standard %s: take %s as an argument, or log with \
     Logs or Eio.traceln."
    channel (capability channel)

let environment =
  [
    ( "Sys.getcwd",
      ambient
        "Reads the process's working directory: take Eio.Stdenv.cwd as an \
         argument." );
    ( "Sys.chdir",
      ambient
        "Changes the process's working directory: take Eio.Stdenv.cwd (an \
         Eio.Path) as an argument." );
  ]

let files =
  each "" "open_in open_in_bin open_in_gen open_out open_out_bin open_out_gen"
    (ambient opens)
  @ each "In_channel"
      "open_bin open_text open_gen with_open_bin with_open_text with_open_gen"
      (ambient opens)
  @ each "Out_channel"
      "open_bin open_text open_gen with_open_bin with_open_text with_open_gen"
      (ambient opens)
  @ each "Sys" "file_exists is_directory is_regular_file readdir"
      (ambient reads_fs)
  @ each "Sys" "remove rename mkdir rmdir" (ambient writes_fs)
  @ each "Filename" "temp_file open_temp_file temp_dir"
      (ambient
         "Creates a file in the process's temporary directory: take a \
          directory (an Eio.Path from Eio.Stdenv.fs or Eio.Stdenv.cwd) as an \
          argument.")
  @ each ""
      "Digest.file Digest.BLAKE128.file Digest.BLAKE256.file \
       Digest.BLAKE512.file Digest.MD5.file"
      (ambient
         ("Reads a file by name: " ^ fs
        ^ ", or digest the contents you are given."))
  @ each "Scanf.Scanning" "open_in open_in_bin from_file from_file_bin"
      (ambient opens)
  @ each "Arg" "read_arg read_arg0" (ambient reads_fs)
  @ each "Arg" "write_arg write_arg0" (ambient writes_fs)

let standard_input =
  each "" "stdin read_line read_int_opt read_int read_float_opt read_float"
    (ambient stdin)
  @ [
      ("In_channel.stdin", ambient stdin);
      ("Scanf.Scanning.stdin", ambient stdin);
      ( "Scanf.scanf",
        ambient
          "Reads the process's standard input: take Eio.Stdenv.stdin as an \
           argument, or use sscanf on a string you are given." );
      ( "Scanf.scanf_opt",
        ambient
          "Reads the process's standard input: take Eio.Stdenv.stdin as an \
           argument, or use sscanf_opt on a string you are given." );
    ]

(* A function of Format that prints to the standard formatter: its message
   names the [pp_] function that takes a formatter. *)
let std_formatter names =
  List.map
    (fun n ->
      ( "Format." ^ n,
        ambient
          (Printf.sprintf
             "Writes the process's standard output: take Eio.Stdenv.stdout as \
              an argument and use pp_%s on a formatter of it, or log with Logs \
              or Eio.traceln."
             n) ))
    (words names)

let standard_output =
  each ""
    "stdout print_char print_string print_bytes print_int print_float \
     print_endline print_newline flush_all"
    (ambient (writes "output"))
  @ each ""
      "stderr prerr_char prerr_string prerr_bytes prerr_int prerr_float \
       prerr_endline prerr_newline"
      (ambient (writes "error"))
  @ each "Out_channel" "stdout flush_all" (ambient (writes "output"))
  @ each "Out_channel" "stderr" (ambient (writes "error"))
  @ each "Printf" "printf lprintf" (ambient (writes "output"))
  @ each "Printf" "eprintf leprintf" (ambient (writes "error"))
  @ each "Format" "std_formatter get_std_formatter printf lprintf"
      (ambient (writes "output"))
  @ each "Format" "err_formatter get_err_formatter eprintf leprintf"
      (ambient (writes "error"))
  @ each "Printexc" "print default_uncaught_exception_handler"
      (ambient (writes "error"))
  @ each "Arg" "usage" (ambient (writes "error"))
  @ [
      ( "Sys.enable_runtime_warnings",
        ambient
          "Makes the runtime write warnings on the process's standard error: \
           leave the switch to the executable, which holds Eio.Stdenv.stderr."
      );
    ]
  @ std_formatter
      "open_box close_box open_hbox open_vbox open_hvbox open_hovbox \
       print_string print_substring print_bytes print_as print_substring_as \
       print_int print_float print_char print_bool print_space print_cut \
       print_break force_newline print_if_newline print_flush print_newline \
       open_tbox close_tbox set_tab print_tab print_tbreak open_stag \
       close_stag get_formatter_out_functions get_formatter_output_functions \
       get_formatter_stag_functions"

let the_process =
  [
    ( "Domain.spawn",
      ambient "Spawns a domain: take Eio.Stdenv.domain_mgr as an argument." );
    ( "Sys.command",
      ambient
        "Runs a shell command: take Eio.Stdenv.process_mgr as an argument." );
    ( "Printexc.catch",
      ambient
        "Prints the exception on the process's standard error and ends the \
         process: take Eio.Stdenv.stderr as an argument, or catch the \
         exception and return an outcome." );
  ]
  @ List.map
      (fun (parse, argv) ->
        ( "Arg." ^ parse,
          ambient
            (Printf.sprintf
               "Prints on the process's standard output or error and ends the \
                process: take Eio.Stdenv.stdout and Eio.Stdenv.stderr as \
                arguments, and use Arg.%s, which raises Arg.Help or Arg.Bad \
                instead."
               argv) ))
      [
        ("parse", "parse_argv");
        ("parse_dynamic", "parse_argv_dynamic");
        ("parse_expand", "parse_and_expand_argv_dynamic");
      ]

(* What would seed a hash table from the system's entropy, either because the
   [?random] argument says so or because [OCAMLRUNPARAM] holds [R]: every
   table the prelude makes is made with [~random:false]. *)
let no_random = "It is never seeded from the system's entropy."

(* A functor's result is restated from its signature, not its strengthened
   module type, so that an anonymous argument can be eliminated: its table
   type is the result's own [t]. *)
let seeded_tables m ~table =
  [
    ( m ^ ".create",
      Retyped
        {
          typ = "int -> " ^ table;
          impl = "fun n -> create ~random:false n";
          doc = "[create n] is an empty table of initial size [n]. " ^ no_random;
        } );
    ( m ^ ".of_seq",
      Retyped
        {
          typ = "(key * 'a) Stdlib.Seq.t -> " ^ table;
          impl = "fun s -> let t = create 16 in replace_seq t s; t";
          doc = "[of_seq s] is a table of the bindings of [s]. " ^ no_random;
        } );
  ]

let tables m =
  let t = "('a, 'b) {orig}.t" in
  [
    ( m ^ ".create",
      Retyped
        {
          typ = "int -> " ^ t;
          impl = "fun n -> create ~random:false n";
          doc = "[create n] is an empty table of initial size [n]. " ^ no_random;
        } );
    ( m ^ ".rebuild",
      Retyped
        {
          typ = t ^ " -> " ^ t;
          impl = "fun t -> rebuild ~random:false t";
          doc = "[rebuild t] is a copy of [t]. " ^ no_random;
        } );
    ( m ^ ".of_seq",
      Retyped
        {
          typ = "('a * 'b) Stdlib.Seq.t -> " ^ t;
          impl = "fun s -> let t = create 16 in replace_seq t s; t";
          doc = "[of_seq s] is a table of the bindings of [s]. " ^ no_random;
        } );
  ]
  @ seeded_tables (m ^ ".MakeSeeded") ~table:"'a t"

let entropy =
  "Seeds from the system's entropy: take Eio.Stdenv.secure_random or a seed as \
   an argument."

let randomness =
  [
    ("Random.State.make_self_init", ambient entropy);
    ("Random.self_init", ambient entropy);
  ]
  @ tables "Hashtbl"
  @ tables "MoreLabels.Hashtbl"
  @ seeded_tables "Ephemeron.K1.MakeSeeded" ~table:"'a t"
  @ seeded_tables "Ephemeron.K2.MakeSeeded" ~table:"'a t"
  @ seeded_tables "Ephemeron.Kn.MakeSeeded" ~table:"'a t"

(* {1 Unix: its types stay, what reaches a capability is refused} *)

let network = "Reaches the network: take Eio.Stdenv.net as an argument."
let clock = "Reads the clock: take Eio.Stdenv.clock as an argument."

let waits =
  "Waits on the clock: take Eio.Stdenv.clock as an argument and use \
   Eio.Time.sleep."

let timed_waits =
  "Waits with a timeout on the clock: take Eio.Stdenv.clock as an argument and \
   use Eio.Time.with_timeout."

let processes =
  "Runs or controls a process: take Eio.Stdenv.process_mgr as an argument."

(* Every value of the compiler's Unix, or UnixLabels, at [m] that reaches a
   capability by name or by address. The others are kept, by reviewed.ml
   or, for a name that says [unsafe], here. *)
let unix m =
  let large = m ^ ".LargeFile" in
  each m "unsafe_environment unsafe_getenv"
    (Keep "It reads the process environment, as getenv does.")
  @ each m "getcwd"
      (ambient
         "Reads the process's working directory: take Eio.Stdenv.cwd as an \
          argument.")
  @ each m "chdir"
      (ambient
         "Changes the process's working directory: take Eio.Stdenv.cwd (an \
          Eio.Path) as an argument.")
  @ each m "time gettimeofday" (ambient clock)
  @ each m "sleep sleepf alarm getitimer setitimer" (ambient waits)
  @ each m "select" (ambient timed_waits)
  @ each m "openfile opendir" (ambient opens)
  @ each m "access stat lstat readlink realpath" (ambient reads_fs)
  @ each m
      "chmod chown link mkdir mkfifo rename rmdir symlink truncate unlink \
       utimes"
      (ambient writes_fs)
  @ each m "chroot"
      (ambient ("Changes the process's root directory: " ^ fs ^ "."))
  @ each large "stat lstat" (ambient reads_fs)
  @ each large "truncate" (ambient writes_fs)
  @ each m
      "socket bind connect sendto sendto_substring open_connection \
       establish_server getaddrinfo getnameinfo gethostbyname gethostbyaddr \
       getprotobyname getprotobynumber getservbyname getservbyport"
      (ambient network)
  @ each m
      "create_process create_process_env execv execve execvp execvpe fork wait \
       waitpid system open_process open_process_in open_process_out \
       open_process_full open_process_args open_process_args_in \
       open_process_args_out open_process_args_full"
      (ambient processes)
  @ each m "kill"
      (ambient
         "Signals a process by its identifier: take Eio.Stdenv.process_mgr as \
          an argument and use Eio.Process.signal.")
  @ each m "stdin" (ambient stdin)
  @ each m "stdout" (ambient (writes "output"))
  @ each m "stderr" (ambient (writes "error"))
  @ [
      ( m ^ ".handle_unix_error",
        ambient
          "Prints the error on the process's standard error and ends the \
           process: take Eio.Stdenv.stderr as an argument, or catch Unix_error \
           and return an outcome." );
    ]

(* {1 Thread: its types and Event stay, what bypasses a capability is
   refused} *)

let threads =
  [
    ("Thread.delay", ambient waits);
    ( "Thread.wait_pid",
      ambient
        "Waits for a child process: take Eio.Stdenv.process_mgr as an argument \
         and use Eio.Process.await." );
  ]
  @ each "Thread" "select wait_timed_read wait_timed_write"
      (ambient timed_waits)
  @ [ ("Thread.default_uncaught_exception_handler", ambient (writes "error")) ]

(* [verbose] makes the runtime write on the process's standard error, so
   [Gc.set] leaves it as it is. *)
let gc =
  [
    ( "Gc.set",
      Retyped
        {
          typ = "{orig}.control -> unit";
          impl = "fun c -> set { c with verbose = (get ()).verbose }";
          doc =
            "[set c] is [Stdlib.Gc.set c] with [c.verbose] ignored: the \
             runtime's verbosity, which writes on the process's standard \
             error, stays as it is.";
        } );
  ]

let refusals =
  unsafe_refusals @ environment @ files @ standard_input @ standard_output @ gc
  @ the_process @ randomness @ unix "Unix" @ unix "UnixLabels" @ threads

(* Libraries that reach the system past Eio's capabilities, which the prelude
   declares empty, so that a name of theirs is unbound. *)
let backend =
  "Creates an Eio environment from nothing: take the capabilities as arguments \
   from the executable's Eio_main.run."

let shadowed =
  [
    ( "Runtime_events",
      "Writes and reads the runtime's events in a file it names: take \
       Eio.Stdenv.fs as an argument, and leave tracing to the executable." );
    ( "Dynlink",
      "Loads code from a file by name: take Eio.Stdenv.fs as an argument, and \
       leave loading code to the executable." );
    ( "Eio_unix",
      "Reaches the system past Eio's capabilities: take Eio.Stdenv.clock, \
       Eio.Stdenv.net, Eio.Stdenv.process_mgr or the capability you need as an \
       argument." );
    ("Eio_posix", backend);
    ("Eio_linux", backend);
    ("Eio_windows", backend);
    ("Eio_main", backend);
  ]

(* StdLabels refuses nothing of its own: it is restated because it aliases
   ArrayLabels and the other restated modules. *)
let aliases = [ "StdLabels" ]
let name = "Hermetic"

let doc =
  "The standard library, restated to make code take Eio's capabilities as \
   arguments.\n\n\
   In a file that opens [Hermetic], a use of a standard library, [Unix] or \
   [Thread] value is a type error when it reaches, without being handed it, \
   something Eio's env provides as a capability: the file system, a clock, the \
   network, the standard input, output or error, the system's entropy, a \
   domain or a child process. A value that can forge a capability, such as \
   [Obj.magic] or a [Marshal] reader, is refused too. Everything else stays. A \
   file opens the prelude on its first line:\n\n\
   {[\n\
   open! Hermetic\n\
   ]}\n\n\
   [Hermetic] restates the standard library, [Unix] and [Thread], and gives \
   each value it refuses one of three types: {!ambient} when it reaches an Eio \
   capability without being handed it, {!unsafe} when it can forge memory or a \
   value of any type, and {!unreviewed} when this version of hermetic has not \
   reviewed it. Each type is abstract and nothing in the prelude consumes it, \
   so a refused value can be named but not applied or used at its original \
   type: such a use is a type error, in every build profile. Passing it to a \
   polymorphic function such as [ignore] compiles and does nothing.\n\n\
   A refused value carries an alert named after its type, and the alert is its \
   documentation: the compiler prints it at each use, and its message says why \
   the value is refused and, when it can, the [Eio.Stdenv] capability to take \
   as an argument instead.\n\n\
   Every type of the standard library stays, so an interface, which does not \
   open the prelude, names the standard library's own types.\n\n\
   The prelude guards against accidents, not against an author trying to \
   cheat: {!Stdlib_original} is the standard library without refusals."

let unreviewed path =
  {
    kind = Unreviewed;
    message =
      Printf.sprintf
        "Not reviewed by this version of hermetic: %s is new in this compiler, \
         and is refused until hermetic reviews it."
        path;
  }

type reviewed = {
  modules : string list;
  kept : (string * string list) list;
  channels : string list;
}

let reviewed =
  {
    modules = Reviewed.modules;
    kept =
      List.fold_left
        (fun acc (path, _reason, names) ->
          let names = words names in
          match List.assoc_opt path acc with
          | Some old -> (path, old @ names) :: List.remove_assoc path acc
          | None -> (path, names) :: acc)
        [] Reviewed.kept;
    channels = List.map fst Reviewed.channels;
  }

let version_specific = Reviewed.version_specific
