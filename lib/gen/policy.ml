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
         "Reads and writes past the bounds of the tables it is given: run \
          the           lexer ocamllex generates, outside the prelude.")
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

(* {1 Ambient authority: what reaches the world without being handed in} *)

let fs = "take Eio.Stdenv.fs or Eio.Stdenv.cwd (an Eio.Path) as an argument"
let opens = "Opens a file by name: " ^ fs ^ ", or the file's contents."
let reads_fs = "Reads the file system by name: " ^ fs ^ "."
let writes_fs = "Writes the file system by name: " ^ fs ^ "."

(* A value that reads the host or the process's environment is refused. The
   runtime's own state is kept, even where OCAMLRUNPARAM sets it, since the
   program can set it too: Gc.get, Printexc.backtrace_status and
   Hashtbl.is_randomized. *)
let fact = "Reads a fact of the process: take the value as an argument."

let stdin =
  "Reads the process's standard input: take Eio.Stdenv.stdin or the bytes as \
   an argument."

let writes channel =
  "Writes the process's standard " ^ channel
  ^ ": log with Logs or Eio.traceln, or take an Eio sink or a formatter as an \
     argument."

let process = "the process is the caller's."
let signal = "Changes how the process handles a signal: " ^ process

let environment =
  [
    ( "Sys.getenv",
      ambient "Reads the process environment: take the value as an argument." );
    ( "Sys.getenv_opt",
      ambient "Reads the process environment: take the value as an argument." );
    ( "Sys.argv",
      ambient "Reads the process's command line: take the values as arguments."
    );
    ( "Sys.getcwd",
      ambient
        "Reads the process's working directory: take Eio.Stdenv.cwd as an \
         argument." );
    ( "Sys.chdir",
      ambient
        "Changes the process's working directory: take Eio.Stdenv.cwd (an \
         Eio.Path) as an argument." );
    ( "Sys.time",
      ambient
        "Reads the processor time the process has used: take the value as an \
         argument." );
  ]
  @ each "Sys"
      "executable_name runtime_executable runtime_parameters interactive"
      (ambient fact)
  @ [
      ( "Domain.recommended_domain_count",
        ambient
          "Reads a fact of the host, its number of processors: take the value \
           as an argument." );
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
         "Creates a file in the temporary directory: take a directory (an \
          Eio.Path) as an argument.")
  @ [
      ( "Filename.get_temp_dir_name",
        ambient "Reads TMPDIR: take a directory (an Eio.Path) as an argument."
      );
      ( "Filename.set_temp_dir_name",
        ambient
          "Sets a directory the whole process shares: take a directory (an \
           Eio.Path) as an argument." );
    ]
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
             "Writes the process's standard output: log with Logs or \
              Eio.traceln, or use pp_%s on a formatter you are given."
             n) ))
    (words names)

(* Library code does not write to the process's standard channels:
   diagnostics go through Logs or Eio.traceln, data through a sink it is
   handed. *)
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
    ( "exit",
      ambient "Ends the process: return an outcome and let the caller exit." );
    ( "at_exit",
      ambient
        "Registers an action on the process's exit: release it with \
         Eio.Switch.on_release on a switch you are given." );
    ("do_at_exit", ambient ("Runs the process's exit actions: " ^ process));
    ( "do_domain_local_at_exit",
      ambient ("The exit actions of the domain: " ^ process) );
    ( "Domain.at_exit",
      ambient
        "Registers an action on the domain's exit: release it with \
         Eio.Switch.on_release on a switch you are given." );
    ( "Domain.spawn",
      ambient "Spawns a domain: take Eio.Stdenv.domain_mgr as an argument." );
    ( "Sys.command",
      ambient
        "Runs a shell command: take Eio.Stdenv.process_mgr as an argument." );
    ("Sys.signal", ambient signal);
    ("Sys.set_signal", ambient signal);
    ( "Sys.catch_break",
      ambient ("Changes how the process handles an interrupt: " ^ process) );
    ( "Sys.poll_actions",
      ambient ("Runs the process's pending signal handlers: " ^ process) );
    ( "Printexc.catch",
      ambient
        ("Prints the exception and ends the process: catch it and return an \
          outcome; " ^ process) );
    ( "Printexc.set_uncaught_exception_handler",
      ambient ("Sets how the process ends on an exception: " ^ process) );
  ]
  @ each "Arg" "parse parse_dynamic parse_expand"
      (ambient
         "Parses the process's command line: take the arguments and use \
          parse_argv, or take the parsed values as arguments.")

(* [parse_argv] and [parse_argv_dynamic] take the position in the command
   line as an argument, rather than defaulting to [Arg.current]. *)
let command_line =
  let args = "string array -> " in
  let rest = "{orig}.anon_fun -> {orig}.usage_msg -> unit" in
  let specs = "({orig}.key * {orig}.spec * {orig}.doc) list" in
  [
    ( "Arg.parse_argv",
      Retyped
        {
          typ = "current:int ref -> " ^ args ^ specs ^ " -> " ^ rest;
          impl = "fun ~current -> parse_argv ~current";
          doc =
            "[parse_argv ~current args specs anon usage] is \
             [Stdlib.Arg.parse_argv] with [~current] required.";
        } );
    ( "Arg.parse_argv_dynamic",
      Retyped
        {
          typ = "current:int ref -> " ^ args ^ specs ^ " ref -> " ^ rest;
          impl = "fun ~current -> parse_argv_dynamic ~current";
          doc =
            "[parse_argv_dynamic ~current args specs anon usage] is \
             [Stdlib.Arg.parse_argv_dynamic] with [~current] required.";
        } );
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
    ( m ^ ".randomize",
      ambient ("Seeds every later table from the system's entropy: " ^ process)
    );
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

(* {1 Unix: its types stay, what reaches the world is refused} *)

let descriptor =
  "Performs I/O on a file descriptor: take an Eio flow, or the bytes, as an \
   argument."

let network = "Reaches the network: take Eio.Stdenv.net as an argument."
let clock = "Reads the clock: take Eio.Stdenv.clock as an argument."

let waits =
  "Waits on the clock: take Eio.Stdenv.clock as an argument and use \
   Eio.Time.sleep."

let processes =
  "Runs or controls a process: take Eio.Stdenv.process_mgr as an argument."

let host = "Reads a fact of the host: take the value as an argument."

(* Every value of the compiler's Unix, or UnixLabels, at [m], except the
   pure ones, which reviewed.ml keeps: the conversions of addresses and of
   errors, [gmtime], and the conversions between a channel and its
   descriptor. *)
let unix m =
  let large = m ^ ".LargeFile" in
  each m "environment getenv unsafe_environment unsafe_getenv"
    (ambient "Reads the process environment: take the value as an argument.")
  @ each m "putenv unsetenv"
      (ambient
         "Changes the process environment: take the value as an argument, and \
          hand the environment to the process you spawn.")
  @ each m
      "getpid getppid getuid geteuid getgid getegid getgroups getlogin umask \
       nice setuid setgid setgroups initgroups setsid chroot"
      (ambient fact)
  @ each m "getcwd"
      (ambient
         "Reads the process's working directory: take Eio.Stdenv.cwd as an \
          argument.")
  @ each m "chdir"
      (ambient
         "Changes the process's working directory: take Eio.Stdenv.cwd (an \
          Eio.Path) as an argument.")
  @ each m "gethostname getpwnam getpwuid getgrgid getgrnam has_symlink"
      (ambient host)
  @ each m "localtime mktime"
      (ambient
         "Reads the host's time zone: take the value as an argument, or use \
          gmtime.")
  @ each m "time gettimeofday times" (ambient clock)
  @ each m "sleep sleepf alarm getitimer setitimer" (ambient waits)
  @ each m "openfile opendir" (ambient opens)
  @ each m "access stat lstat readlink realpath" (ambient reads_fs)
  @ each m
      "chmod chown link mkdir mkfifo rename rmdir symlink truncate unlink \
       utimes"
      (ambient writes_fs)
  @ each large "stat lstat" (ambient reads_fs)
  @ each large "truncate" (ambient writes_fs)
  @ each m
      "close read write single_write write_substring single_write_substring \
       read_bigarray write_bigarray single_write_bigarray lseek ftruncate \
       fstat fchmod fchown fsync dup dup2 pipe set_nonblock clear_nonblock \
       set_close_on_exec clear_close_on_exec lockf select isatty map_file \
       readdir rewinddir closedir tcgetattr tcsetattr tcsendbreak tcdrain \
       tcflush tcflow"
      (ambient descriptor)
  @ each large "lseek ftruncate fstat" (ambient descriptor)
  @ each m
      "socket socketpair accept bind connect listen shutdown getsockname \
       getpeername recv recvfrom send send_substring sendto sendto_substring \
       getsockopt setsockopt getsockopt_int setsockopt_int getsockopt_optint \
       setsockopt_optint getsockopt_float setsockopt_float getsockopt_error \
       open_connection shutdown_connection establish_server getaddrinfo \
       getnameinfo gethostbyname gethostbyaddr getprotobyname getprotobynumber \
       getservbyname getservbyport"
      (ambient network)
  @ each m
      "create_process create_process_env execv execve execvp execvpe fork wait \
       waitpid system open_process open_process_in open_process_out \
       open_process_full open_process_args open_process_args_in \
       open_process_args_out open_process_args_full close_process \
       close_process_in close_process_out close_process_full process_pid \
       process_in_pid process_out_pid process_full_pid"
      (ambient processes)
  @ each m "kill sigprocmask sigpending sigsuspend sigwait pause"
      (ambient signal)
  @ each m "stdin" (ambient stdin)
  @ each m "stdout" (ambient (writes "output"))
  @ each m "stderr" (ambient (writes "error"))
  @ [
      ( m ^ "._exit",
        ambient "Ends the process: return an outcome and let the caller exit."
      );
      ( m ^ ".handle_unix_error",
        ambient
          "Prints the error on the process's standard error and ends the \
           process: catch Unix_error and return an outcome." );
    ]

let refusals =
  unsafe_refusals @ environment @ files @ standard_input @ standard_output
  @ the_process @ command_line @ randomness @ unix "Unix" @ unix "UnixLabels"

(* Libraries that reach the system past Eio's capabilities, which the prelude
   declares empty, so that a name of theirs is unbound. *)
let past =
  "Reaches the system past Eio's capabilities: take the Eio.Stdenv capability \
   you need as an argument."

let shadowed =
  List.map
    (fun m -> (m, past))
    [
      "Thread";
      "Event";
      "Runtime_events";
      "Dynlink";
      "Eio_unix";
      "Eio_posix";
      "Eio_linux";
      "Eio_windows";
    ]
  @ [
      ( "Eio_main",
        "Creates an Eio environment from nothing: take the capabilities as \
         arguments from the executable's Eio_main.run." );
    ]

let name = "Hermetic"

let doc =
  "The standard library, restated to refuse ambient authority.\n\n\
   With [Hermetic], the only way to reach the world is through the \
   capabilities Eio's [env] hands you: a value of the standard library that \
   reaches the world without being handed it has the type {!ambient}, a value \
   that can forge memory or a value of any type has the type {!unsafe}, and a \
   value that this version of the prelude has not reviewed has the type \
   {!unreviewed}. A file adopts it with\n\n\
   {[\n\
   open! Hermetic\n\
   ]}\n\n\
   on its first line. The three types are abstract and nothing in the prelude \
   consumes them: a refused value can be named, but it cannot be applied or \
   used at its original type, so such a use is a type error, in every build \
   profile. Each refused value also carries an alert named after its type, \
   whose message says why it is refused and, when it can, what to take as an \
   argument instead.\n\n\
   Library code does not write to the process's standard channels: diagnostics \
   go through Logs or Eio's traceln, data through a sink the code is handed. \
   Every type of the standard library stays, so an interface, which does not \
   open the prelude, names the standard library's own types."

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
