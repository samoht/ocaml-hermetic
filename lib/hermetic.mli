(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** The standard library with the ambient world refused.

    A library compiled with

    {v (flags (:standard -open Hermetic -alert @ambient)) v}

    is typed in an environment where every value of the standard library that
    reaches the world outside the program without being handed it carries the
    [ambient] alert, which [-alert @ambient] makes a compile error naming the
    value and saying what to pass in instead. The world here is the process
    environment and command line, the clocks, the file system and the standard
    channels, the process itself (its exit, its signals, its exit actions),
    randomness seeded from the system or drawn from the generator the process
    shares, state the whole process shares (domains, atomics, the garbage
    collector, registered printers, the iteration order of a generic hash table)
    and the escapes from the type system. A channel, a formatter or a buffer the
    caller hands in is an input: the functions that use one stay.

    The refusal follows the declaration, not the spelling: [Sys.getenv],
    [Stdlib.Sys.getenv], a module alias of {!module-Sys}, an [open Stdlib], an
    [include Sys], a functor applied to {!module-Sys}, a signature constraint
    over it and a first-class module packing it all reach the value through a
    declaration of this module, and the compiler checks an alert on a signature
    inclusion as it does on a use. A module refused as a whole is empty here,
    and the three mutable globals of the standard library are [()], so that no
    use of them compiles even where the alert is silenced.

    What the alert cannot close, the [hermetic-check] command closes over the
    compiled units: a unit compiled without [-open Hermetic] or
    [-alert @ambient], an [[@alert]] attribute that makes [ambient] a warning
    again, a reference to a unit of the standard library by its own name
    ([Stdlib__Sys]), and an [external] declaration, which names a primitive
    directly. A dependency is outside this module's reach: a function of another
    library that reads the environment in its own code is refused only when that
    library is compiled hermetic too. {!Fmt}, whose printers every library here
    uses, is restated. *)

(** {1:stdlib The standard library} *)

(** The standard library, with its ambient values refused. A path through
    [Stdlib], an [open Stdlib] and an [include Stdlib] reach this module, not
    the original. *)
module Stdlib : sig
  include module type of struct
      include Stdlib

      let do_domain_local_at_exit = () [@@warning "-32"]
    end
    with module Arg := Stdlib.Arg
     and module Atomic := Stdlib.Atomic
     and module Callback := Stdlib.Callback
     and module Condition := Stdlib.Condition
     and module Digest := Stdlib.Digest
     and module Domain := Stdlib.Domain
     and module Ephemeron := Stdlib.Ephemeron
     and module Filename := Stdlib.Filename
     and module Format := Stdlib.Format
     and module Gc := Stdlib.Gc
     and module Hashtbl := Stdlib.Hashtbl
     and module In_channel := Stdlib.In_channel
     and module Marshal := Stdlib.Marshal
     and module MoreLabels := Stdlib.MoreLabels
     and module Mutex := Stdlib.Mutex
     and module Obj := Stdlib.Obj
     and module Oo := Stdlib.Oo
     and module Out_channel := Stdlib.Out_channel
     and module Parsing := Stdlib.Parsing
     and module Printexc := Stdlib.Printexc
     and module Printf := Stdlib.Printf
     and module Random := Stdlib.Random
     and module Scanf := Stdlib.Scanf
     and module Semaphore := Stdlib.Semaphore
     and module Sys := Stdlib.Sys
     and module Weak := Stdlib.Weak

  (** {2:channels The standard channels and files} *)

  val stdin : in_channel
  [@@alert
    ambient "Reads the process's standard input: take the bytes as an input."]
  (** [stdin] is the process's standard input. *)

  val stdout : out_channel
  [@@alert
    ambient
      "Writes the process's standard output: return the text and let the \
       caller print it."]
  (** [stdout] is the process's standard output. *)

  val stderr : out_channel
  [@@alert
    ambient
      "Writes the process's standard error: return the text and let the caller \
       print it."]
  (** [stderr] is the process's standard error. *)

  val print_char : char -> unit
  [@@alert
    ambient
      "Writes the process's standard output: return the text and let the \
       caller print it."]
  (** [print_char c] writes [c] on the standard output. *)

  val print_string : string -> unit
  [@@alert
    ambient
      "Writes the process's standard output: return the text and let the \
       caller print it."]
  (** [print_string s] writes [s] on the standard output. *)

  val print_bytes : bytes -> unit
  [@@alert
    ambient
      "Writes the process's standard output: return the text and let the \
       caller print it."]
  (** [print_bytes b] writes [b] on the standard output. *)

  val print_int : int -> unit
  [@@alert
    ambient
      "Writes the process's standard output: return the text and let the \
       caller print it."]
  (** [print_int n] writes [n] on the standard output. *)

  val print_float : float -> unit
  [@@alert
    ambient
      "Writes the process's standard output: return the text and let the \
       caller print it."]
  (** [print_float x] writes [x] on the standard output. *)

  val print_endline : string -> unit
  [@@alert
    ambient
      "Writes the process's standard output: return the text and let the \
       caller print it."]
  (** [print_endline s] writes [s] and a newline on the standard output. *)

  val print_newline : unit -> unit
  [@@alert
    ambient
      "Writes the process's standard output: return the text and let the \
       caller print it."]
  (** [print_newline ()] writes a newline on the standard output. *)

  val prerr_char : char -> unit
  [@@alert
    ambient
      "Writes the process's standard error: return the text and let the caller \
       print it."]
  (** [prerr_char c] writes [c] on the standard error. *)

  val prerr_string : string -> unit
  [@@alert
    ambient
      "Writes the process's standard error: return the text and let the caller \
       print it."]
  (** [prerr_string s] writes [s] on the standard error. *)

  val prerr_bytes : bytes -> unit
  [@@alert
    ambient
      "Writes the process's standard error: return the text and let the caller \
       print it."]
  (** [prerr_bytes b] writes [b] on the standard error. *)

  val prerr_int : int -> unit
  [@@alert
    ambient
      "Writes the process's standard error: return the text and let the caller \
       print it."]
  (** [prerr_int n] writes [n] on the standard error. *)

  val prerr_float : float -> unit
  [@@alert
    ambient
      "Writes the process's standard error: return the text and let the caller \
       print it."]
  (** [prerr_float x] writes [x] on the standard error. *)

  val prerr_endline : string -> unit
  [@@alert
    ambient
      "Writes the process's standard error: return the text and let the caller \
       print it."]
  (** [prerr_endline s] writes [s] and a newline on the standard error. *)

  val prerr_newline : unit -> unit
  [@@alert
    ambient
      "Writes the process's standard error: return the text and let the caller \
       print it."]
  (** [prerr_newline ()] writes a newline on the standard error. *)

  val read_line : unit -> string
  [@@alert
    ambient "Reads the process's standard input: take the bytes as an input."]
  (** [read_line ()] is the next line of the standard input. *)

  val read_int_opt : unit -> int option
  [@@alert
    ambient "Reads the process's standard input: take the bytes as an input."]
  (** [read_int_opt ()] is the integer on the next line of the standard input.
  *)

  val read_int : unit -> int
  [@@alert
    ambient "Reads the process's standard input: take the bytes as an input."]
  (** [read_int ()] is the integer on the next line of the standard input. *)

  val read_float_opt : unit -> float option
  [@@alert
    ambient "Reads the process's standard input: take the bytes as an input."]
  (** [read_float_opt ()] is the float on the next line of the standard input.
  *)

  val read_float : unit -> float
  [@@alert
    ambient "Reads the process's standard input: take the bytes as an input."]
  (** [read_float ()] is the float on the next line of the standard input. *)

  val open_out : string -> out_channel
  [@@alert
    ambient
      "Opens a file: the file system is the caller's, return the bytes instead."]
  (** [open_out path] is a channel writing the file [path]. *)

  val open_out_bin : string -> out_channel
  [@@alert
    ambient
      "Opens a file: the file system is the caller's, return the bytes instead."]
  (** [open_out_bin path] is a binary channel writing the file [path]. *)

  val open_out_gen : open_flag list -> int -> string -> out_channel
  [@@alert
    ambient
      "Opens a file: the file system is the caller's, return the bytes instead."]
  (** [open_out_gen flags perm path] is a channel writing the file [path]. *)

  val open_in : string -> in_channel
  [@@alert
    ambient
      "Opens a file: the file system is the caller's, take the bytes as an \
       input."]
  (** [open_in path] is a channel reading the file [path]. *)

  val open_in_bin : string -> in_channel
  [@@alert
    ambient
      "Opens a file: the file system is the caller's, take the bytes as an \
       input."]
  (** [open_in_bin path] is a binary channel reading the file [path]. *)

  val open_in_gen : open_flag list -> int -> string -> in_channel
  [@@alert
    ambient
      "Opens a file: the file system is the caller's, take the bytes as an \
       input."]
  (** [open_in_gen flags perm path] is a channel reading the file [path]. *)

  val flush_all : unit -> unit
  [@@alert
    ambient
      "Flushes every channel of the process: the channels are the caller's."]
  (** [flush_all ()] flushes every open output channel of the process. *)

  val input_value : in_channel -> 'a
  [@@alert ambient "Reads a value of any type: escapes the type system."]
  (** [input_value ic] is the next marshalled value of [ic], at any type. *)

  val unsafe_really_input : in_channel -> bytes -> int -> int -> unit
  [@@alert
    ambient "Writes bytes without a bounds check: escapes memory safety."]
  (** [unsafe_really_input] is [really_input] without its bounds check. *)

  (** {2:process The process} *)

  val exit : int -> 'a
  [@@alert
    ambient "Ends the process: return an outcome and let the caller exit."]
  (** [exit code] ends the process with [code]. *)

  val at_exit : (unit -> unit) -> unit
  [@@alert
    ambient
      "Registers an action on the process's exit: the process is the caller's."]
  (** [at_exit f] runs [f] when the process exits. *)

  val do_at_exit : unit -> unit
  [@@alert
    ambient "Runs the process's exit actions: the process is the caller's."]
  (** [do_at_exit ()] runs the actions registered with {!at_exit}. *)

  val do_domain_local_at_exit : unit
  [@@alert
    ambient "The exit actions of the domain: the process is the caller's."]
  (** [do_domain_local_at_exit] is [()]: the reference holding the domain's exit
      actions is refused, and not exposed. *)

  module Arg : sig end
  [@@alert
    ambient
      "Parses the process's command line and prints usage: take the parsed \
       values as inputs."]

  module Callback : sig end
  [@@alert
    ambient
      "Registers values for C code in a registry the whole process shares."]

  (** {2:shared State the whole process shares} *)

  module Atomic : sig end
  [@@alert
    ambient
      "Mutable state shared across domains: thread the value through the state \
       instead."]

  module Condition : sig end
  [@@alert ambient "Synchronises domains: concurrency is the caller's."]

  module Domain : sig end
  [@@alert
    ambient
      "Spawns domains and holds domain-local state: concurrency is the \
       caller's."]

  module Mutex : sig end
  [@@alert ambient "Synchronises domains: concurrency is the caller's."]

  module Semaphore : sig end
  [@@alert ambient "Synchronises domains: concurrency is the caller's."]

  module Gc : sig end
  [@@alert
    ambient
      "Reads and controls the garbage collector, whose timing no input decides."]

  module Weak : sig end
  [@@alert
    ambient
      "Holds values the garbage collector drops at a time no input decides."]

  module Ephemeron : sig end
  [@@alert
    ambient
      "Holds values the garbage collector drops at a time no input decides."]

  module Oo : sig end
  [@@alert ambient "Numbers objects from a counter the whole process shares."]

  (** {2:escapes Escapes from the type system} *)

  module Obj : sig end [@@alert ambient "Escapes the type system."]

  module Marshal : sig end
  [@@alert
    ambient "Reads and writes values of any type: escapes the type system."]

  (** {2:restated Modules with some ambient values} *)

  (** {!Stdlib.Sys}: its constants stay; its reads of the environment, the file
      system, the clock and the process are refused. *)
  module Sys : sig
    include module type of struct
      include Stdlib.Sys

      let argv = () [@@warning "-32"]
      let interactive = () [@@warning "-32"]
    end

    val argv : unit
    [@@alert
      ambient "Reads the process's command line: take the values as inputs."]
    (** [argv] is [()]: the process's command line is refused, and its array is
        not exposed. *)

    val interactive : unit
    [@@alert ambient "State the whole process shares."]
    (** [interactive] is [()]: the reference saying whether the process runs in
        the toplevel is refused, and not exposed. *)

    val executable_name : string
    [@@alert
      ambient "Reads the process's executable path: take it as an input."]
    (** [executable_name] is the path of the process's executable. *)

    val file_exists : string -> bool
    [@@alert ambient "Reads the file system: take what it holds as an input."]
    (** [file_exists path] is [true] when [path] names a file. *)

    val is_directory : string -> bool
    [@@alert ambient "Reads the file system: take what it holds as an input."]
    (** [is_directory path] is [true] when [path] names a directory. *)

    val is_regular_file : string -> bool
    [@@alert ambient "Reads the file system: take what it holds as an input."]
    (** [is_regular_file path] is [true] when [path] names a regular file. *)

    val remove : string -> unit
    [@@alert
      ambient
        "Writes the file system: return the change and let the caller make it."]
    (** [remove path] deletes the file [path]. *)

    val rename : string -> string -> unit
    [@@alert
      ambient
        "Writes the file system: return the change and let the caller make it."]
    (** [rename src dst] moves the file [src] to [dst]. *)

    val getenv : string -> string
    [@@alert
      ambient "Reads the process environment: take the value as an input."]
    (** [getenv name] is the value of [name] in the process environment. *)

    val getenv_opt : string -> string option
    [@@alert
      ambient "Reads the process environment: take the value as an input."]
    (** [getenv_opt name] is the value of [name] in the process environment. *)

    val command : string -> int
    [@@alert
      ambient
        "Runs a shell command: return the command and let the caller run it."]
    (** [command cmd] runs [cmd] in a shell and is its exit status. *)

    val time : unit -> float
    [@@alert ambient "Reads the processor clock: take the time as an input."]
    (** [time ()] is the processor time the process has used. *)

    val chdir : string -> unit
    [@@alert
      ambient
        "Changes the process's working directory: the process is the caller's."]
    (** [chdir path] makes [path] the process's working directory. *)

    val mkdir : string -> int -> unit
    [@@alert
      ambient
        "Writes the file system: return the change and let the caller make it."]
    (** [mkdir path perm] creates the directory [path]. *)

    val rmdir : string -> unit
    [@@alert
      ambient
        "Writes the file system: return the change and let the caller make it."]
    (** [rmdir path] deletes the empty directory [path]. *)

    val getcwd : unit -> string
    [@@alert
      ambient "Reads the process's working directory: take it as an input."]
    (** [getcwd ()] is the process's working directory. *)

    val readdir : string -> string array
    [@@alert ambient "Reads the file system: take what it holds as an input."]
    (** [readdir path] is the names in the directory [path]. *)

    val runtime_variant : unit -> string
    [@@alert
      ambient "Reads which runtime runs the process: take it as an input."]
    (** [runtime_variant ()] is the variant of the running runtime. *)

    val runtime_parameters : unit -> string
    [@@alert
      ambient
        "Reads the runtime's parameters, OCAMLRUNPARAM included: take them as \
         an input."]
    (** [runtime_parameters ()] is the runtime's parameters. *)

    val poll_actions : unit -> unit
    [@@alert
      ambient
        "Runs the process's pending signal handlers: the process is the \
         caller's."]
    (** [poll_actions ()] runs the process's pending signal handlers. *)

    val signal : signal -> signal_behavior -> signal_behavior
    [@@alert
      ambient
        "Changes how the process handles a signal: the process is the caller's."]
    (** [signal s b] sets the process's handling of [s] to [b]. *)

    val set_signal : signal -> signal_behavior -> unit
    [@@alert
      ambient
        "Changes how the process handles a signal: the process is the caller's."]
    (** [set_signal s b] sets the process's handling of [s] to [b]. *)

    val catch_break : bool -> unit
    [@@alert
      ambient
        "Changes how the process handles an interrupt: the process is the \
         caller's."]
    (** [catch_break on] turns an interrupt into {!Break}. *)

    val enable_runtime_warnings : bool -> unit
    [@@alert ambient "State the whole process shares."]
    (** [enable_runtime_warnings on] turns the runtime's warnings on. *)

    val runtime_warnings_enabled : unit -> bool
    [@@alert ambient "State the whole process shares."]
    (** [runtime_warnings_enabled ()] is whether the runtime warns. *)
  end

  (** {!Stdlib.Random}: the generator the process shares and the seeding from
      the system are refused. A {!Random.State.t} made with {!Random.State.make}
      from a seed the caller passes stays usable. *)
  module Random : sig
    include module type of struct
        include Stdlib.Random
      end
      with module State := Stdlib.Random.State

    (** {!Stdlib.Random.State}, without the seeding from the system. *)
    module State : sig
      include module type of struct
        include Stdlib.Random.State
      end

      val make_self_init : unit -> t
      [@@alert
        ambient
          "Seeds from the system's entropy: take the seed as an input and use \
           make."]
      (** [make_self_init ()] is a generator seeded from the system. *)
    end

    val init : int -> unit
    [@@alert
      ambient
        "Seeds the generator the whole process shares: use a Random.State.t \
         made from a seed."]
    (** [init seed] seeds the shared generator. *)

    val full_init : int array -> unit
    [@@alert
      ambient
        "Seeds the generator the whole process shares: use a Random.State.t \
         made from a seed."]
    (** [full_init seed] seeds the shared generator. *)

    val self_init : unit -> unit
    [@@alert
      ambient
        "Seeds from the system's entropy: take the seed as an input and use \
         Random.State.make."]
    (** [self_init ()] seeds the shared generator from the system. *)

    val bits : unit -> int
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [bits ()] is {!State.bits} on the shared generator. *)

    val int : int -> int
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [int bound] is {!State.int} on the shared generator. *)

    val full_int : int -> int
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [full_int bound] is {!State.full_int} on the shared generator. *)

    val int_in_range : min:int -> max:int -> int
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [int_in_range ~min ~max] is {!State.int_in_range} on the shared
        generator. *)

    val int32 : Int32.t -> Int32.t
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [int32 bound] is {!State.int32} on the shared generator. *)

    val int32_in_range : min:int32 -> max:int32 -> int32
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [int32_in_range ~min ~max] is {!State.int32_in_range} on the shared
        generator. *)

    val nativeint : Nativeint.t -> Nativeint.t
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [nativeint bound] is {!State.nativeint} on the shared generator. *)

    val nativeint_in_range : min:nativeint -> max:nativeint -> nativeint
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [nativeint_in_range ~min ~max] is {!State.nativeint_in_range} on the
        shared generator. *)

    val int64 : Int64.t -> Int64.t
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [int64 bound] is {!State.int64} on the shared generator. *)

    val int64_in_range : min:int64 -> max:int64 -> int64
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [int64_in_range ~min ~max] is {!State.int64_in_range} on the shared
        generator. *)

    val float : float -> float
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [float bound] is {!State.float} on the shared generator. *)

    val bool : unit -> bool
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [bool ()] is {!State.bool} on the shared generator. *)

    val bits32 : unit -> Int32.t
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [bits32 ()] is {!State.bits32} on the shared generator. *)

    val bits64 : unit -> Int64.t
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [bits64 ()] is {!State.bits64} on the shared generator. *)

    val nativebits : unit -> Nativeint.t
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [nativebits ()] is {!State.nativebits} on the shared generator. *)

    val get_state : unit -> State.t
    [@@alert
      ambient
        "Reads the generator the whole process shares: use a Random.State.t \
         made from a seed."]
    (** [get_state ()] is a copy of the shared generator. *)

    val set_state : State.t -> unit
    [@@alert
      ambient
        "Writes the generator the whole process shares: use a Random.State.t \
         made from a seed."]
    (** [set_state s] makes the shared generator a copy of [s]. *)

    val split : unit -> State.t
    [@@alert
      ambient
        "Draws from the generator the whole process shares: use a \
         Random.State.t made from a seed."]
    (** [split ()] is a generator split from the shared one. *)
  end

  (** {!Stdlib.Hashtbl}: a generic table is seeded from the system when
      [OCAMLRUNPARAM] holds [R], so what observes its order is refused, and so
      is {!Hashtbl.MakeSeeded}, whose tables take the same seed. Lookups stay,
      and so does every table of {!Hashtbl.Make}, which never randomises. *)
  module Hashtbl : sig
    include module type of struct
        include Stdlib.Hashtbl
      end
      with module MakeSeeded := Stdlib.Hashtbl.MakeSeeded

    module MakeSeeded : sig end
    [@@alert
      ambient
        "Tables seeded from the system when OCAMLRUNPARAM holds R: use \
         Hashtbl.Make or Map."]

    val iter : ('a -> 'b -> unit) -> ('a, 'b) t -> unit
    [@@alert
      ambient
        "Visits a generic table in an order OCAMLRUNPARAM=R randomises: use \
         Hashtbl.Make or Map."]
    (** [iter f t] applies [f] to each binding of [t], in bucket order. *)

    val filter_map_inplace : ('a -> 'b -> 'b option) -> ('a, 'b) t -> unit
    [@@alert
      ambient
        "Visits a generic table in an order OCAMLRUNPARAM=R randomises: use \
         Hashtbl.Make or Map."]
    (** [filter_map_inplace f t] maps the bindings of [t] in bucket order. *)

    val fold : ('a -> 'b -> 'acc -> 'acc) -> ('a, 'b) t -> 'acc -> 'acc
    [@@alert
      ambient
        "Visits a generic table in an order OCAMLRUNPARAM=R randomises: use \
         Hashtbl.Make or Map."]
    (** [fold f t acc] folds [f] over the bindings of [t], in bucket order. *)

    val stats : ('a, 'b) t -> statistics
    [@@alert
      ambient
        "Measures buckets OCAMLRUNPARAM=R randomises: use Hashtbl.Make or Map."]
    (** [stats t] is the bucket statistics of [t]. *)

    val to_seq : ('a, 'b) t -> ('a * 'b) Seq.t
    [@@alert
      ambient
        "Visits a generic table in an order OCAMLRUNPARAM=R randomises: use \
         Hashtbl.Make or Map."]
    (** [to_seq t] is the bindings of [t], in bucket order. *)

    val to_seq_keys : ('a, _) t -> 'a Seq.t
    [@@alert
      ambient
        "Visits a generic table in an order OCAMLRUNPARAM=R randomises: use \
         Hashtbl.Make or Map."]
    (** [to_seq_keys t] is the keys of [t], in bucket order. *)

    val to_seq_values : (_, 'b) t -> 'b Seq.t
    [@@alert
      ambient
        "Visits a generic table in an order OCAMLRUNPARAM=R randomises: use \
         Hashtbl.Make or Map."]
    (** [to_seq_values t] is the values of [t], in bucket order. *)

    val randomize : unit -> unit
    [@@alert
      ambient
        "Changes how every later table of the process is seeded: state the \
         whole process shares."]
    (** [randomize ()] seeds every later generic table from the system. *)

    val is_randomized : unit -> bool
    [@@alert
      ambient "Reads OCAMLRUNPARAM through state the whole process shares."]
    (** [is_randomized ()] is whether generic tables are seeded from the system.
    *)
  end

  (** {!Stdlib.MoreLabels}, whose [Hashtbl] is refused as {!Hashtbl} is. *)
  module MoreLabels : sig
    include module type of struct
        include Stdlib.MoreLabels
      end
      with module Hashtbl := Stdlib.MoreLabels.Hashtbl

    (** {!Stdlib.MoreLabels.Hashtbl}, refused as {!Hashtbl} is. *)
    module Hashtbl : sig
      include module type of struct
          include Stdlib.MoreLabels.Hashtbl
        end
        with module MakeSeeded := Stdlib.MoreLabels.Hashtbl.MakeSeeded

      module MakeSeeded : sig end
      [@@alert
        ambient
          "Tables seeded from the system when OCAMLRUNPARAM holds R: use \
           Hashtbl.Make or Map."]

      val iter : f:(key:'a -> data:'b -> unit) -> ('a, 'b) t -> unit
      [@@alert
        ambient
          "Visits a generic table in an order OCAMLRUNPARAM=R randomises: use \
           Hashtbl.Make or Map."]
      (** [iter ~f t] applies [f] to each binding of [t], in bucket order. *)

      val filter_map_inplace :
        f:(key:'a -> data:'b -> 'b option) -> ('a, 'b) t -> unit
      [@@alert
        ambient
          "Visits a generic table in an order OCAMLRUNPARAM=R randomises: use \
           Hashtbl.Make or Map."]
      (** [filter_map_inplace ~f t] maps the bindings of [t] in bucket order. *)

      val fold :
        f:(key:'a -> data:'b -> 'acc -> 'acc) -> ('a, 'b) t -> init:'acc -> 'acc
      [@@alert
        ambient
          "Visits a generic table in an order OCAMLRUNPARAM=R randomises: use \
           Hashtbl.Make or Map."]
      (** [fold ~f t ~init] folds [f] over the bindings of [t], in bucket order.
      *)

      val stats : ('a, 'b) t -> statistics
      [@@alert
        ambient
          "Measures buckets OCAMLRUNPARAM=R randomises: use Hashtbl.Make or \
           Map."]
      (** [stats t] is the bucket statistics of [t]. *)

      val to_seq : ('a, 'b) t -> ('a * 'b) Seq.t
      [@@alert
        ambient
          "Visits a generic table in an order OCAMLRUNPARAM=R randomises: use \
           Hashtbl.Make or Map."]
      (** [to_seq t] is the bindings of [t], in bucket order. *)

      val to_seq_keys : ('a, _) t -> 'a Seq.t
      [@@alert
        ambient
          "Visits a generic table in an order OCAMLRUNPARAM=R randomises: use \
           Hashtbl.Make or Map."]
      (** [to_seq_keys t] is the keys of [t], in bucket order. *)

      val to_seq_values : (_, 'b) t -> 'b Seq.t
      [@@alert
        ambient
          "Visits a generic table in an order OCAMLRUNPARAM=R randomises: use \
           Hashtbl.Make or Map."]
      (** [to_seq_values t] is the values of [t], in bucket order. *)

      val randomize : unit -> unit
      [@@alert
        ambient
          "Changes how every later table of the process is seeded: state the \
           whole process shares."]
      (** [randomize ()] seeds every later generic table from the system. *)

      val is_randomized : unit -> bool
      [@@alert
        ambient "Reads OCAMLRUNPARAM through state the whole process shares."]
      (** [is_randomized ()] is whether generic tables are seeded from the
          system. *)
    end
  end

  (** {!Stdlib.In_channel}: reading a channel the caller hands in stays; opening
      a file and the standard input are refused. *)
  module In_channel : sig
    include module type of struct
      include Stdlib.In_channel
    end

    val stdin : t
    [@@alert
      ambient "Reads the process's standard input: take the bytes as an input."]
    (** [stdin] is the process's standard input. *)

    val open_bin : string -> t
    [@@alert
      ambient
        "Opens a file: the file system is the caller's, take the bytes as an \
         input."]
    (** [open_bin path] is a binary channel reading the file [path]. *)

    val open_text : string -> t
    [@@alert
      ambient
        "Opens a file: the file system is the caller's, take the bytes as an \
         input."]
    (** [open_text path] is a text channel reading the file [path]. *)

    val open_gen : open_flag list -> int -> string -> t
    [@@alert
      ambient
        "Opens a file: the file system is the caller's, take the bytes as an \
         input."]
    (** [open_gen flags perm path] is a channel reading the file [path]. *)

    val with_open_bin : string -> (t -> 'a) -> 'a
    [@@alert
      ambient
        "Opens a file: the file system is the caller's, take the bytes as an \
         input."]
    (** [with_open_bin path f] applies [f] to a binary channel reading [path].
    *)

    val with_open_text : string -> (t -> 'a) -> 'a
    [@@alert
      ambient
        "Opens a file: the file system is the caller's, take the bytes as an \
         input."]
    (** [with_open_text path f] applies [f] to a text channel reading [path]. *)

    val with_open_gen : open_flag list -> int -> string -> (t -> 'a) -> 'a
    [@@alert
      ambient
        "Opens a file: the file system is the caller's, take the bytes as an \
         input."]
    (** [with_open_gen flags perm path f] applies [f] to a channel reading
        [path]. *)
  end

  (** {!Stdlib.Out_channel}: writing a channel the caller hands in stays;
      opening a file, the standard channels and flushing all of them are
      refused. *)
  module Out_channel : sig
    include module type of struct
      include Stdlib.Out_channel
    end

    val stdout : t
    [@@alert
      ambient
        "Writes the process's standard output: return the text and let the \
         caller print it."]
    (** [stdout] is the process's standard output. *)

    val stderr : t
    [@@alert
      ambient
        "Writes the process's standard error: return the text and let the \
         caller print it."]
    (** [stderr] is the process's standard error. *)

    val open_bin : string -> t
    [@@alert
      ambient
        "Opens a file: the file system is the caller's, return the bytes \
         instead."]
    (** [open_bin path] is a binary channel writing the file [path]. *)

    val open_text : string -> t
    [@@alert
      ambient
        "Opens a file: the file system is the caller's, return the bytes \
         instead."]
    (** [open_text path] is a text channel writing the file [path]. *)

    val open_gen : open_flag list -> int -> string -> t
    [@@alert
      ambient
        "Opens a file: the file system is the caller's, return the bytes \
         instead."]
    (** [open_gen flags perm path] is a channel writing the file [path]. *)

    val with_open_bin : string -> (t -> 'a) -> 'a
    [@@alert
      ambient
        "Opens a file: the file system is the caller's, return the bytes \
         instead."]
    (** [with_open_bin path f] applies [f] to a binary channel writing [path].
    *)

    val with_open_text : string -> (t -> 'a) -> 'a
    [@@alert
      ambient
        "Opens a file: the file system is the caller's, return the bytes \
         instead."]
    (** [with_open_text path f] applies [f] to a text channel writing [path]. *)

    val with_open_gen : open_flag list -> int -> string -> (t -> 'a) -> 'a
    [@@alert
      ambient
        "Opens a file: the file system is the caller's, return the bytes \
         instead."]
    (** [with_open_gen flags perm path f] applies [f] to a channel writing
        [path]. *)

    val flush_all : unit -> unit
    [@@alert
      ambient
        "Flushes every channel of the process: the channels are the caller's."]
    (** [flush_all ()] flushes every open output channel of the process. *)
  end

  (** {!Stdlib.Filename}: path arithmetic stays; temporary files are refused. *)
  module Filename : sig
    include module type of struct
      include Stdlib.Filename
    end

    val temp_file : ?temp_dir:string -> string -> string -> string
    [@@alert
      ambient
        "Creates a file and reads TMPDIR: the file system is the caller's."]
    (** [temp_file prefix suffix] creates a fresh file in the temporary
        directory. *)

    val open_temp_file :
      ?mode:open_flag list ->
      ?perms:int ->
      ?temp_dir:string ->
      string ->
      string ->
      string * out_channel
    [@@alert
      ambient
        "Creates a file and reads TMPDIR: the file system is the caller's."]
    (** [open_temp_file prefix suffix] creates and opens a fresh file in the
        temporary directory. *)

    val temp_dir : ?temp_dir:string -> ?perms:int -> string -> string -> string
    [@@alert
      ambient
        "Creates a directory and reads TMPDIR: the file system is the caller's."]
    (** [temp_dir prefix suffix] creates a fresh directory in the temporary
        directory. *)

    val get_temp_dir_name : unit -> string
    [@@alert ambient "Reads TMPDIR: take the directory as an input."]
    (** [get_temp_dir_name ()] is the temporary directory. *)

    val set_temp_dir_name : string -> unit
    [@@alert ambient "State the whole process shares."]
    (** [set_temp_dir_name dir] makes [dir] the temporary directory. *)
  end

  (** {!Stdlib.Printf}: formatting to a string, a buffer or a channel the caller
      hands in stays; printing to the standard channels is refused. *)
  module Printf : sig
    include module type of struct
      include Stdlib.Printf
    end

    val printf : ('a, out_channel, unit) format -> 'a
    [@@alert
      ambient
        "Writes the process's standard output: format with sprintf and let the \
         caller print."]
    (** [printf fmt] formats on the standard output. *)

    val eprintf : ('a, out_channel, unit) format -> 'a
    [@@alert
      ambient
        "Writes the process's standard error: format with sprintf and let the \
         caller print."]
    (** [eprintf fmt] formats on the standard error. *)
  end

  (** {!Stdlib.Format}: every function of a formatter the caller hands in stays,
      and so do [asprintf], [sprintf] and the formatters of a buffer. The
      standard formatters, their buffer and every function that writes or sets
      them implicitly are refused. *)
  module Format : sig
    include module type of struct
      include Stdlib.Format
    end

    val std_formatter : formatter
    [@@alert
      ambient "The process's standard output: take a formatter as an argument."]
    (** [std_formatter] writes the standard output. *)

    val get_std_formatter : unit -> formatter
    [@@alert
      ambient "The process's standard output: take a formatter as an argument."]
    (** [get_std_formatter ()] is the domain's formatter of the standard output.
    *)

    val err_formatter : formatter
    [@@alert
      ambient "The process's standard error: take a formatter as an argument."]
    (** [err_formatter] writes the standard error. *)

    val get_err_formatter : unit -> formatter
    [@@alert
      ambient "The process's standard error: take a formatter as an argument."]
    (** [get_err_formatter ()] is the domain's formatter of the standard error.
    *)

    val stdbuf : Buffer.t
    [@@alert ambient "A buffer the whole process shares: use asprintf."]
    (** [stdbuf] is the buffer of {!str_formatter}. *)

    val get_stdbuf : unit -> Buffer.t
    [@@alert ambient "A buffer the whole process shares: use asprintf."]
    (** [get_stdbuf ()] is the domain's buffer of {!get_str_formatter}. *)

    val str_formatter : formatter
    [@@alert ambient "A formatter the whole process shares: use asprintf."]
    (** [str_formatter] writes {!stdbuf}. *)

    val get_str_formatter : unit -> formatter
    [@@alert ambient "A formatter the whole process shares: use asprintf."]
    (** [get_str_formatter ()] is the domain's formatter of a shared buffer. *)

    val flush_str_formatter : unit -> string
    [@@alert ambient "A formatter the whole process shares: use asprintf."]
    (** [flush_str_formatter ()] is the contents of {!stdbuf}, which it empties.
    *)

    val printf : ('a, formatter, unit) format -> 'a
    [@@alert
      ambient
        "Writes the process's standard output: use fprintf on a formatter you \
         are given."]
    (** [printf fmt] is [fprintf] on the standard formatter. *)

    val eprintf : ('a, formatter, unit) format -> 'a
    [@@alert
      ambient
        "Writes the process's standard error: use fprintf on a formatter you \
         are given."]
    (** [eprintf fmt] is [fprintf] on the error formatter. *)

    val open_box : int -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_open_box on a formatter you are \
         given."]
    (** [open_box d] is [pp_open_box] on the standard formatter. *)

    val close_box : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_close_box on a formatter you \
         are given."]
    (** [close_box ()] is [pp_close_box] on the standard formatter. *)

    val open_hbox : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_open_hbox on a formatter you \
         are given."]
    (** [open_hbox ()] is [pp_open_hbox] on the standard formatter. *)

    val open_vbox : int -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_open_vbox on a formatter you \
         are given."]
    (** [open_vbox d] is [pp_open_vbox] on the standard formatter. *)

    val open_hvbox : int -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_open_hvbox on a formatter you \
         are given."]
    (** [open_hvbox d] is [pp_open_hvbox] on the standard formatter. *)

    val open_hovbox : int -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_open_hovbox on a formatter you \
         are given."]
    (** [open_hovbox d] is [pp_open_hovbox] on the standard formatter. *)

    val print_string : string -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_string on a formatter you \
         are given."]
    (** [print_string s] is [pp_print_string] on the standard formatter. *)

    val print_substring : pos:int -> len:int -> string -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_substring on a formatter \
         you are given."]
    (** [print_substring ~pos ~len s] is [pp_print_substring] on the standard
        formatter. *)

    val print_bytes : bytes -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_bytes on a formatter you \
         are given."]
    (** [print_bytes b] is [pp_print_bytes] on the standard formatter. *)

    val print_as : int -> string -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_as on a formatter you are \
         given."]
    (** [print_as n s] is [pp_print_as] on the standard formatter. *)

    val print_substring_as : pos:int -> len:int -> int -> string -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_substring_as on a \
         formatter you are given."]
    (** [print_substring_as ~pos ~len n s] is [pp_print_substring_as] on the
        standard formatter. *)

    val print_int : int -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_int on a formatter you \
         are given."]
    (** [print_int n] is [pp_print_int] on the standard formatter. *)

    val print_float : float -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_float on a formatter you \
         are given."]
    (** [print_float x] is [pp_print_float] on the standard formatter. *)

    val print_char : char -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_char on a formatter you \
         are given."]
    (** [print_char c] is [pp_print_char] on the standard formatter. *)

    val print_bool : bool -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_bool on a formatter you \
         are given."]
    (** [print_bool b] is [pp_print_bool] on the standard formatter. *)

    val print_space : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_space on a formatter you \
         are given."]
    (** [print_space ()] is [pp_print_space] on the standard formatter. *)

    val print_cut : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_cut on a formatter you \
         are given."]
    (** [print_cut ()] is [pp_print_cut] on the standard formatter. *)

    val print_break : int -> int -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_break on a formatter you \
         are given."]
    (** [print_break n o] is [pp_print_break] on the standard formatter. *)

    val force_newline : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_force_newline on a formatter \
         you are given."]
    (** [force_newline ()] is [pp_force_newline] on the standard formatter. *)

    val print_if_newline : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_if_newline on a formatter \
         you are given."]
    (** [print_if_newline ()] is [pp_print_if_newline] on the standard
        formatter. *)

    val print_flush : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_flush on a formatter you \
         are given."]
    (** [print_flush ()] is [pp_print_flush] on the standard formatter. *)

    val print_newline : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_newline on a formatter \
         you are given."]
    (** [print_newline ()] is [pp_print_newline] on the standard formatter. *)

    val set_margin : int -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_set_margin on a formatter you are \
         given."]
    (** [set_margin n] is [pp_set_margin] on the standard formatter. *)

    val get_margin : unit -> int
    [@@alert
      ambient
        "Reads the standard formatter: use pp_get_margin on a formatter you \
         are given."]
    (** [get_margin ()] is [pp_get_margin] on the standard formatter. *)

    val set_max_indent : int -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_set_max_indent on a formatter you \
         are given."]
    (** [set_max_indent n] is [pp_set_max_indent] on the standard formatter. *)

    val get_max_indent : unit -> int
    [@@alert
      ambient
        "Reads the standard formatter: use pp_get_max_indent on a formatter \
         you are given."]
    (** [get_max_indent ()] is [pp_get_max_indent] on the standard formatter. *)

    val set_geometry : max_indent:int -> margin:int -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_set_geometry on a formatter you \
         are given."]
    (** [set_geometry ~max_indent ~margin] is [pp_set_geometry] on the standard
        formatter. *)

    val safe_set_geometry : max_indent:int -> margin:int -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_safe_set_geometry on a formatter \
         you are given."]
    (** [safe_set_geometry ~max_indent ~margin] is [pp_safe_set_geometry] on the
        standard formatter. *)

    val update_geometry : (geometry -> geometry) -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_update_geometry on a formatter \
         you are given."]
    (** [update_geometry f] is [pp_update_geometry] on the standard formatter.
    *)

    val get_geometry : unit -> geometry
    [@@alert
      ambient
        "Reads the standard formatter: use pp_get_geometry on a formatter you \
         are given."]
    (** [get_geometry ()] is [pp_get_geometry] on the standard formatter. *)

    val set_max_boxes : int -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_set_max_boxes on a formatter you \
         are given."]
    (** [set_max_boxes n] is [pp_set_max_boxes] on the standard formatter. *)

    val get_max_boxes : unit -> int
    [@@alert
      ambient
        "Reads the standard formatter: use pp_get_max_boxes on a formatter you \
         are given."]
    (** [get_max_boxes ()] is [pp_get_max_boxes] on the standard formatter. *)

    val over_max_boxes : unit -> bool
    [@@alert
      ambient
        "Reads the standard formatter: use pp_over_max_boxes on a formatter \
         you are given."]
    (** [over_max_boxes ()] is [pp_over_max_boxes] on the standard formatter. *)

    val open_tbox : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_open_tbox on a formatter you \
         are given."]
    (** [open_tbox ()] is [pp_open_tbox] on the standard formatter. *)

    val close_tbox : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_close_tbox on a formatter you \
         are given."]
    (** [close_tbox ()] is [pp_close_tbox] on the standard formatter. *)

    val set_tab : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_set_tab on a formatter you are \
         given."]
    (** [set_tab ()] is [pp_set_tab] on the standard formatter. *)

    val print_tab : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_tab on a formatter you \
         are given."]
    (** [print_tab ()] is [pp_print_tab] on the standard formatter. *)

    val print_tbreak : int -> int -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_print_tbreak on a formatter you \
         are given."]
    (** [print_tbreak n o] is [pp_print_tbreak] on the standard formatter. *)

    val set_ellipsis_text : string -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_set_ellipsis_text on a formatter \
         you are given."]
    (** [set_ellipsis_text s] is [pp_set_ellipsis_text] on the standard
        formatter. *)

    val get_ellipsis_text : unit -> string
    [@@alert
      ambient
        "Reads the standard formatter: use pp_get_ellipsis_text on a formatter \
         you are given."]
    (** [get_ellipsis_text ()] is [pp_get_ellipsis_text] on the standard
        formatter. *)

    val open_stag : stag -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_open_stag on a formatter you \
         are given."]
    (** [open_stag t] is [pp_open_stag] on the standard formatter. *)

    val close_stag : unit -> unit
    [@@alert
      ambient
        "Writes the standard formatter: use pp_close_stag on a formatter you \
         are given."]
    (** [close_stag ()] is [pp_close_stag] on the standard formatter. *)

    val set_tags : bool -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_set_tags on a formatter you are \
         given."]
    (** [set_tags b] is [pp_set_tags] on the standard formatter. *)

    val set_print_tags : bool -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_set_print_tags on a formatter you \
         are given."]
    (** [set_print_tags b] is [pp_set_print_tags] on the standard formatter. *)

    val set_mark_tags : bool -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_set_mark_tags on a formatter you \
         are given."]
    (** [set_mark_tags b] is [pp_set_mark_tags] on the standard formatter. *)

    val get_print_tags : unit -> bool
    [@@alert
      ambient
        "Reads the standard formatter: use pp_get_print_tags on a formatter \
         you are given."]
    (** [get_print_tags ()] is [pp_get_print_tags] on the standard formatter. *)

    val get_mark_tags : unit -> bool
    [@@alert
      ambient
        "Reads the standard formatter: use pp_get_mark_tags on a formatter you \
         are given."]
    (** [get_mark_tags ()] is [pp_get_mark_tags] on the standard formatter. *)

    val set_formatter_out_channel : out_channel -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_set_formatter_out_channel on a \
         formatter you are given."]
    (** [set_formatter_out_channel oc] is [pp_set_formatter_out_channel] on the
        standard formatter. *)

    val set_formatter_output_functions :
      (string -> int -> int -> unit) -> (unit -> unit) -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_set_formatter_output_functions on \
         a formatter you are given."]
    (** [set_formatter_output_functions out flush] is
        [pp_set_formatter_output_functions] on the standard formatter. *)

    val get_formatter_output_functions :
      unit -> (string -> int -> int -> unit) * (unit -> unit)
    [@@alert
      ambient
        "Reads the standard formatter: use pp_get_formatter_output_functions \
         on a formatter you are given."]
    (** [get_formatter_output_functions ()] is
        [pp_get_formatter_output_functions] on the standard formatter. *)

    val set_formatter_out_functions : formatter_out_functions -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_set_formatter_out_functions on a \
         formatter you are given."]
    (** [set_formatter_out_functions fs] is [pp_set_formatter_out_functions] on
        the standard formatter. *)

    val get_formatter_out_functions : unit -> formatter_out_functions
    [@@alert
      ambient
        "Reads the standard formatter: use pp_get_formatter_out_functions on a \
         formatter you are given."]
    (** [get_formatter_out_functions ()] is [pp_get_formatter_out_functions] on
        the standard formatter. *)

    val set_formatter_stag_functions : formatter_stag_functions -> unit
    [@@alert
      ambient
        "Sets the standard formatter: use pp_set_formatter_stag_functions on a \
         formatter you are given."]
    (** [set_formatter_stag_functions fs] is [pp_set_formatter_stag_functions]
        on the standard formatter. *)

    val get_formatter_stag_functions : unit -> formatter_stag_functions
    [@@alert
      ambient
        "Reads the standard formatter: use pp_get_formatter_stag_functions on \
         a formatter you are given."]
    (** [get_formatter_stag_functions ()] is [pp_get_formatter_stag_functions]
        on the standard formatter. *)
  end

  (** {!Stdlib.Scanf}: scanning a string or an input the caller hands in stays;
      the standard input and opening a file are refused. *)
  module Scanf : sig
    include module type of struct
        include Stdlib.Scanf
      end
      with module Scanning := Stdlib.Scanf.Scanning

    (** {!Stdlib.Scanf.Scanning}, without the standard input and the files. *)
    module Scanning : sig
      include module type of struct
        include Stdlib.Scanf.Scanning
      end

      val stdin : in_channel
      [@@alert
        ambient
          "Reads the process's standard input: scan a string you are given."]
      (** [stdin] is the input of the standard input. *)

      val open_in : file_name -> in_channel
      [@@alert
        ambient
          "Opens a file: the file system is the caller's, scan a string you \
           are given."]
      (** [open_in path] is an input reading the file [path]. *)

      val open_in_bin : file_name -> in_channel
      [@@alert
        ambient
          "Opens a file: the file system is the caller's, scan a string you \
           are given."]
      (** [open_in_bin path] is an input reading the file [path] in binary mode.
      *)

      val from_file : file_name -> in_channel
      [@@alert
        ambient
          "Opens a file: the file system is the caller's, scan a string you \
           are given."]
      (** [from_file path] is an input reading the file [path]. *)

      val from_file_bin : string -> in_channel
      [@@alert
        ambient
          "Opens a file: the file system is the caller's, scan a string you \
           are given."]
      (** [from_file_bin path] is an input reading the file [path] in binary
          mode. *)
    end

    val scanf : ('a, 'b, 'c, 'd) scanner
    [@@alert
      ambient
        "Reads the process's standard input: use sscanf on a string you are \
         given."]
    (** [scanf fmt] is [bscanf] on the standard input. *)

    val scanf_opt : ('a, 'b, 'c, 'd) scanner_opt
    [@@alert
      ambient
        "Reads the process's standard input: use sscanf_opt on a string you \
         are given."]
    (** [scanf_opt fmt] is [bscanf_opt] on the standard input. *)
  end

  (** {!Stdlib.Printexc}: the printers the process registered, the backtraces
      and the handlers of uncaught exceptions are refused;
      {!Printexc.to_string_default} stays. *)
  module Printexc : sig
    include module type of struct
      include Stdlib.Printexc
    end

    val to_string : exn -> string
    [@@alert
      ambient
        "Renders through the printers the whole process registered: use \
         to_string_default."]
    (** [to_string e] is [e] rendered by the printers the process registered. *)

    val print : ('a -> 'b) -> 'a -> 'b
    [@@alert
      ambient
        "Writes the process's standard error: the process is the caller's."]
    (** [print f x] is [f x], printing on the standard error what it raises. *)

    val catch : ('a -> 'b) -> 'a -> 'b
    [@@alert
      ambient
        "Writes the process's standard error and ends the process: the process \
         is the caller's."]
    [@@alert deprecated "This function is no longer needed."]
    (** [catch f x] is [f x], ending the process on what it raises. *)

    val print_backtrace : out_channel -> unit
    [@@alert ambient "Reads the backtrace the whole process records."]
    (** [print_backtrace oc] writes the last recorded backtrace on [oc]. *)

    val get_backtrace : unit -> string
    [@@alert ambient "Reads the backtrace the whole process records."]
    (** [get_backtrace ()] is the last recorded backtrace. *)

    val record_backtrace : bool -> unit
    [@@alert ambient "State the whole process shares."]
    (** [record_backtrace on] turns the recording of backtraces on. *)

    val backtrace_status : unit -> bool
    [@@alert ambient "State the whole process shares."]
    (** [backtrace_status ()] is whether backtraces are recorded. *)

    val register_printer : (exn -> string option) -> unit
    [@@alert ambient "Registers a printer for the whole process."]
    (** [register_printer p] adds [p] to the process's exception printers. *)

    val use_printers : exn -> string option
    [@@alert
      ambient "Renders through the printers the whole process registered."]
    (** [use_printers e] is [e] rendered by the printers the process registered.
    *)

    val get_raw_backtrace : unit -> raw_backtrace
    [@@alert ambient "Reads the backtrace the whole process records."]
    (** [get_raw_backtrace ()] is the last recorded backtrace. *)

    val get_callstack : int -> raw_backtrace
    [@@alert ambient "Reads the process's call stack, which no input decides."]
    (** [get_callstack n] is the top [n] frames of the call stack. *)

    val default_uncaught_exception_handler : exn -> raw_backtrace -> unit
    [@@alert
      ambient
        "Writes the process's standard error: the process is the caller's."]
    (** [default_uncaught_exception_handler e bt] prints [e] and [bt] on the
        standard error. *)

    val set_uncaught_exception_handler : (exn -> raw_backtrace -> unit) -> unit
    [@@alert
      ambient
        "Sets the handler of the whole process: the process is the caller's."]
    (** [set_uncaught_exception_handler h] makes [h] the process's handler of
        uncaught exceptions. *)
  end

  (** {!Stdlib.Digest}: digests of strings, bytes and a channel the caller hands
      in stay; digests of a file are refused. *)
  module Digest : sig
    include module type of struct
        include Stdlib.Digest
      end
      with module BLAKE128 := Stdlib.Digest.BLAKE128
       and module BLAKE256 := Stdlib.Digest.BLAKE256
       and module BLAKE512 := Stdlib.Digest.BLAKE512
       and module MD5 := Stdlib.Digest.MD5

    val file : string -> t
    [@@alert
      ambient
        "Reads a file: the file system is the caller's, digest the bytes you \
         are given."]
    (** [file path] is the digest of the file [path]. *)

    (** {!Stdlib.Digest.BLAKE128}, without the digest of a file. *)
    module BLAKE128 : sig
      include module type of struct
        include Stdlib.Digest.BLAKE128
      end

      val file : string -> t
      [@@alert
        ambient
          "Reads a file: the file system is the caller's, digest the bytes you \
           are given."]
      (** [file path] is the digest of the file [path]. *)
    end

    (** {!Stdlib.Digest.BLAKE256}, without the digest of a file. *)
    module BLAKE256 : sig
      include module type of struct
        include Stdlib.Digest.BLAKE256
      end

      val file : string -> t
      [@@alert
        ambient
          "Reads a file: the file system is the caller's, digest the bytes you \
           are given."]
      (** [file path] is the digest of the file [path]. *)
    end

    (** {!Stdlib.Digest.BLAKE512}, without the digest of a file. *)
    module BLAKE512 : sig
      include module type of struct
        include Stdlib.Digest.BLAKE512
      end

      val file : string -> t
      [@@alert
        ambient
          "Reads a file: the file system is the caller's, digest the bytes you \
           are given."]
      (** [file path] is the digest of the file [path]. *)
    end

    (** {!Stdlib.Digest.MD5}, without the digest of a file. *)
    module MD5 : sig
      include module type of struct
        include Stdlib.Digest.MD5
      end

      val file : string -> t
      [@@alert
        ambient
          "Reads a file: the file system is the caller's, digest the bytes you \
           are given."]
      (** [file path] is the digest of the file [path]. *)
    end
  end

  (** {!Stdlib.Parsing}, without the trace on the standard error. *)
  module Parsing : sig
    include module type of struct
      include Stdlib.Parsing
    end

    val set_trace : bool -> bool
    [@@alert
      ambient
        "Writes the process's standard error, from state the whole process \
         shares."]
    (** [set_trace on] turns the parser's trace on the standard error on. *)
  end
end

include module type of struct
  include Stdlib
end

(** {1:internals The compiler's runtime support} *)

module CamlinternalMod : sig end
[@@alert
  ambient "The runtime support of recursive modules: escapes the type system."]

module CamlinternalOO : sig end
[@@alert ambient "The runtime support of objects: escapes the type system."]

(** {1:fmt Fmt} *)

(** {!Fmt}, whose printers to a formatter the caller hands in stay. The standard
    formatters and the exception printers, which render through the printers the
    process registered, are refused. *)
module Fmt : sig
  include module type of struct
    include Fmt
  end

  val stdout : Format.formatter
  [@@alert
    ambient "The process's standard output: take a formatter as an argument."]
  (** [stdout] is the formatter of the standard output. *)

  val stderr : Format.formatter
  [@@alert
    ambient "The process's standard error: take a formatter as an argument."]
  (** [stderr] is the formatter of the standard error. *)

  val pr : ('a, Format.formatter, unit) format -> 'a
  [@@alert
    ambient
      "Writes the process's standard output: use Fmt.pf on a formatter you are \
       given."]
  (** [pr fmt] is [pf stdout fmt]. *)

  val epr : ('a, Format.formatter, unit) format -> 'a
  [@@alert
    ambient
      "Writes the process's standard error: use Fmt.pf on a formatter you are \
       given."]
  (** [epr fmt] is [pf stderr fmt]. *)

  val exn : exn t
  [@@alert
    ambient
      "Renders through the printers the whole process registered: print the \
       error's own value."]
  (** [exn] prints an exception with the printers the process registered. *)

  val exn_backtrace : (exn * Printexc.raw_backtrace) t
  [@@alert
    ambient
      "Renders through the printers the whole process registered, with a \
       backtrace no input decides."]
  (** [exn_backtrace] prints an exception and a backtrace with the printers the
      process registered. *)
end
