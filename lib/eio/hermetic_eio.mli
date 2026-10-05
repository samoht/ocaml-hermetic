(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** The standard library for a library that does its I/O through Eio.

    A library compiled with

    {v (flags (:standard -open Hermetic_eio -alert @ambient)) v}

    is typed in an environment where every value of the standard library that
    reaches the file system, the process, its environment or a clock without a
    capability carries the [ambient] alert, which [-alert @ambient] makes a
    compile error naming the value and the Eio call to make instead. The
    standard library's mutexes, conditions and semaphores, which block the
    domain under every fiber, are refused as a whole. The rest stays, the parts
    an Eio program legitimately shares included: hash table iteration,
    {!Random}, {!Atomic}, {!Domain} and the standard formatters.

    The process environment stays refused, as in [Hermetic]: Eio has no
    capability for it, so a value read from it is taken as an input.

    The refusal follows the declaration, not the spelling, as in [Hermetic].
    What the alert cannot close, [hermetic-check --eio] closes over the compiled
    units: a unit compiled without [-open Hermetic_eio] or [-alert @ambient], an
    [[@alert]] attribute that makes [ambient] a warning again, a reference to a
    unit of the standard library by its own name, an [external] declaration, and
    an import of [Unix], [UnixLabels], [Thread] or [Event]. A library that is
    the sanctioned boundary between Eio and the system passes [--boundary],
    which allows the imports and the externals. *)

(** {1:stdlib The standard library} *)

(** The standard library, with its accesses past a capability refused. A path
    through [Stdlib], an [open Stdlib] and an [include Stdlib] reach this
    module, not the original. *)
module Stdlib : sig
  include module type of struct
      include Stdlib
    end
    with module Condition := Stdlib.Condition
     and module Digest := Stdlib.Digest
     and module Filename := Stdlib.Filename
     and module In_channel := Stdlib.In_channel
     and module Mutex := Stdlib.Mutex
     and module Out_channel := Stdlib.Out_channel
     and module Semaphore := Stdlib.Semaphore
     and module Sys := Stdlib.Sys

  (** {2:files Files} *)

  val open_in : string -> in_channel
  [@@alert
    ambient
      "Opens a file past a capability: use Eio.Path.open_in or Eio.Path.load."]
  (** [open_in] opens a file for reading. *)

  val open_in_bin : string -> in_channel
  [@@alert
    ambient
      "Opens a file past a capability: use Eio.Path.open_in or Eio.Path.load."]
  (** [open_in_bin] opens a file for reading. *)

  val open_in_gen : open_flag list -> int -> string -> in_channel
  [@@alert
    ambient
      "Opens a file past a capability: use Eio.Path.open_in or Eio.Path.load."]
  (** [open_in_gen] opens a file for reading. *)

  val open_out : string -> out_channel
  [@@alert
    ambient
      "Opens a file past a capability: use Eio.Path.open_out or Eio.Path.save."]
  (** [open_out] opens a file for writing. *)

  val open_out_bin : string -> out_channel
  [@@alert
    ambient
      "Opens a file past a capability: use Eio.Path.open_out or Eio.Path.save."]
  (** [open_out_bin] opens a file for writing. *)

  val open_out_gen : open_flag list -> int -> string -> out_channel
  [@@alert
    ambient
      "Opens a file past a capability: use Eio.Path.open_out or Eio.Path.save."]
  (** [open_out_gen] opens a file for writing. *)

  (** {2:process The process} *)

  val exit : int -> 'a
  [@@alert
    ambient "Ends the process: return an outcome and let the executable exit."]
  (** [exit code] ends the process with [code]. *)

  val at_exit : (unit -> unit) -> unit
  [@@alert
    ambient
      "Registers an action on the process's exit: use Eio.Switch.on_release."]
  (** [at_exit f] runs [f] when the process exits. *)

  (** {2:sync Synchronisation that blocks the domain} *)

  module Condition : sig end
  [@@alert ambient "Blocks the domain under every fiber: use Eio.Condition."]

  module Mutex : sig end
  [@@alert ambient "Blocks the domain under every fiber: use Eio.Mutex."]

  module Semaphore : sig end
  [@@alert ambient "Blocks the domain under every fiber: use Eio.Semaphore."]

  (** {2:restated Modules with accesses past a capability} *)

  (** {!Stdlib.Sys}: its constants stay; its reads and writes of the file
      system, the process, its environment and the clock are refused. *)
  module Sys : sig
    include module type of struct
      include Stdlib.Sys

      let argv = () [@@warning "-32"]
    end

    val argv : unit
    [@@alert
      ambient "Reads the process's command line: take the values as inputs."]
    (** [argv] is [()]: the process's command line is refused, and its array is
        not exposed. *)

    val executable_name : string
    [@@alert
      ambient "Reads the process's executable path: take it as an input."]
    (** [executable_name] is the path of the process's executable. *)

    val file_exists : string -> bool
    [@@alert
      ambient
        "Reads the file system past a capability: use Eio.Path.kind \
         ~follow:true."]
    (** [file_exists path] is [true] when [path] names a file. *)

    val is_directory : string -> bool
    [@@alert
      ambient
        "Reads the file system past a capability: use Eio.Path.is_directory."]
    (** [is_directory path] is [true] when [path] names a directory. *)

    val is_regular_file : string -> bool
    [@@alert
      ambient "Reads the file system past a capability: use Eio.Path.is_file."]
    (** [is_regular_file path] is [true] when [path] names a regular file. *)

    val readdir : string -> string array
    [@@alert
      ambient "Reads the file system past a capability: use Eio.Path.read_dir."]
    (** [readdir path] is the names in the directory [path]. *)

    val remove : string -> unit
    [@@alert
      ambient "Writes the file system past a capability: use Eio.Path.unlink."]
    (** [remove path] deletes the file [path]. *)

    val rename : string -> string -> unit
    [@@alert
      ambient "Writes the file system past a capability: use Eio.Path.rename."]
    (** [rename src dst] moves the file [src] to [dst]. *)

    val mkdir : string -> int -> unit
    [@@alert
      ambient "Writes the file system past a capability: use Eio.Path.mkdir."]
    (** [mkdir path perm] creates the directory [path]. *)

    val rmdir : string -> unit
    [@@alert
      ambient "Writes the file system past a capability: use Eio.Path.rmdir."]
    (** [rmdir path] deletes the empty directory [path]. *)

    val getcwd : unit -> string
    [@@alert
      ambient
        "Reads the process's working directory: take a directory capability, \
         Eio.Stdenv.cwd."]
    (** [getcwd ()] is the process's working directory. *)

    val chdir : string -> unit
    [@@alert
      ambient
        "Changes the process's working directory: pass a directory capability \
         instead."]
    (** [chdir path] makes [path] the process's working directory. *)

    val getenv : string -> string
    [@@alert
      ambient "Reads the process environment: take the value as an input."]
    (** [getenv name] is the value of [name] in the process environment. *)

    val getenv_opt : string -> string option
    [@@alert
      ambient "Reads the process environment: take the value as an input."]
    (** [getenv_opt name] is the value of [name] in the process environment. *)

    val command : string -> int
    [@@alert ambient "Runs a process past a capability: use Eio.Process.run."]
    (** [command cmd] runs [cmd] in a shell and is its exit status. *)

    val time : unit -> float
    [@@alert
      ambient
        "Reads a clock past a capability: use Eio.Time.now or \
         Eio.Time.Mono.now."]
    (** [time ()] is the processor time the process has used. *)

    val signal : signal -> signal_behavior -> signal_behavior
    [@@alert
      ambient
        "Changes how the process handles a signal: use Eio_signal.install."]
    (** [signal s b] sets the process's handling of [s] to [b]. *)

    val set_signal : signal -> signal_behavior -> unit
    [@@alert
      ambient
        "Changes how the process handles a signal: use Eio_signal.install."]
    (** [set_signal s b] sets the process's handling of [s] to [b]. *)

    val catch_break : bool -> unit
    [@@alert
      ambient
        "Changes how the process handles an interrupt: use Eio_signal.install."]
    (** [catch_break on] turns an interrupt into {!Break}. *)
  end

  (** {!Stdlib.In_channel}: reading a channel the caller hands in stays; opening
      a file is refused. *)
  module In_channel : sig
    include module type of struct
      include Stdlib.In_channel
    end

    val open_bin : string -> t
    [@@alert
      ambient
        "Opens a file past a capability: use Eio.Path.with_open_in or \
         Eio.Path.load."]
    (** [open_bin] opens a file for reading. *)

    val open_text : string -> t
    [@@alert
      ambient
        "Opens a file past a capability: use Eio.Path.with_open_in or \
         Eio.Path.load."]
    (** [open_text] opens a file for reading. *)

    val open_gen : open_flag list -> int -> string -> t
    [@@alert
      ambient
        "Opens a file past a capability: use Eio.Path.with_open_in or \
         Eio.Path.load."]
    (** [open_gen] opens a file for reading. *)

    val with_open_bin : string -> (t -> 'a) -> 'a
    [@@alert
      ambient
        "Opens a file past a capability: use Eio.Path.with_open_in or \
         Eio.Path.load."]
    (** [with_open_bin] opens a file for reading. *)

    val with_open_text : string -> (t -> 'a) -> 'a
    [@@alert
      ambient
        "Opens a file past a capability: use Eio.Path.with_open_in or \
         Eio.Path.load."]
    (** [with_open_text] opens a file for reading. *)

    val with_open_gen : open_flag list -> int -> string -> (t -> 'a) -> 'a
    [@@alert
      ambient
        "Opens a file past a capability: use Eio.Path.with_open_in or \
         Eio.Path.load."]
    (** [with_open_gen] opens a file for reading. *)
  end

  (** {!Stdlib.Out_channel}: writing a channel the caller hands in stays;
      opening a file is refused. *)
  module Out_channel : sig
    include module type of struct
      include Stdlib.Out_channel
    end

    val open_bin : string -> t
    [@@alert
      ambient
        "Opens a file past a capability: use Eio.Path.with_open_out or \
         Eio.Path.save."]
    (** [open_bin] opens a file for writing. *)

    val open_text : string -> t
    [@@alert
      ambient
        "Opens a file past a capability: use Eio.Path.with_open_out or \
         Eio.Path.save."]
    (** [open_text] opens a file for writing. *)

    val open_gen : open_flag list -> int -> string -> t
    [@@alert
      ambient
        "Opens a file past a capability: use Eio.Path.with_open_out or \
         Eio.Path.save."]
    (** [open_gen] opens a file for writing. *)

    val with_open_bin : string -> (t -> 'a) -> 'a
    [@@alert
      ambient
        "Opens a file past a capability: use Eio.Path.with_open_out or \
         Eio.Path.save."]
    (** [with_open_bin] opens a file for writing. *)

    val with_open_text : string -> (t -> 'a) -> 'a
    [@@alert
      ambient
        "Opens a file past a capability: use Eio.Path.with_open_out or \
         Eio.Path.save."]
    (** [with_open_text] opens a file for writing. *)

    val with_open_gen : open_flag list -> int -> string -> (t -> 'a) -> 'a
    [@@alert
      ambient
        "Opens a file past a capability: use Eio.Path.with_open_out or \
         Eio.Path.save."]
    (** [with_open_gen] opens a file for writing. *)
  end

  (** {!Stdlib.Filename}: path arithmetic stays; temporary files are refused. *)
  module Filename : sig
    include module type of struct
      include Stdlib.Filename
    end

    val temp_file : ?temp_dir:string -> string -> string -> string
    [@@alert
      ambient
        "Creates a file past a capability: create it under a directory you are \
         given."]
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
        "Creates a file past a capability: create it under a directory you are \
         given."]
    (** [open_temp_file prefix suffix] creates and opens a fresh file in the
        temporary directory. *)

    val temp_dir : ?temp_dir:string -> ?perms:int -> string -> string -> string
    [@@alert
      ambient
        "Creates a file past a capability: create it under a directory you are \
         given."]
    (** [temp_dir prefix suffix] creates a fresh directory in the temporary
        directory. *)

    val get_temp_dir_name : unit -> string
    [@@alert ambient "Reads TMPDIR: take a directory capability as an input."]
    (** [get_temp_dir_name ()] is the temporary directory. *)

    val set_temp_dir_name : string -> unit
    [@@alert
      ambient
        "Sets state the whole process shares: pass a directory capability \
         instead."]
    (** [set_temp_dir_name dir] makes [dir] the temporary directory. *)
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
        "Reads a file past a capability: digest the bytes of Eio.Path.load."]
    (** [file path] is the digest of the file [path]. *)

    (** {!Stdlib.Digest.BLAKE128}, without the digest of a file. *)
    module BLAKE128 : sig
      include module type of struct
        include Stdlib.Digest.BLAKE128
      end

      val file : string -> t
      [@@alert
        ambient
          "Reads a file past a capability: digest the bytes of Eio.Path.load."]
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
          "Reads a file past a capability: digest the bytes of Eio.Path.load."]
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
          "Reads a file past a capability: digest the bytes of Eio.Path.load."]
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
          "Reads a file past a capability: digest the bytes of Eio.Path.load."]
      (** [file path] is the digest of the file [path]. *)
    end
  end
end

(** The standard library's types are not restated: an adopted library's
    interface names {!Stdlib.result} and the others under their own path, so a
    toplevel without this module's compiled interface still sees their
    definitions and prints their constructors unqualified. *)

include module type of struct
    include Stdlib
  end
  with type fpclass := Stdlib.fpclass
   and type in_channel := Stdlib.in_channel
   and type out_channel := Stdlib.out_channel
   and type open_flag := Stdlib.open_flag
   and type 'a ref := 'a Stdlib.ref
   and type ('a, 'b) result := ('a, 'b) Stdlib.result
   and type ('a, 'b, 'c, 'd, 'e, 'f) format6 :=
    ('a, 'b, 'c, 'd, 'e, 'f) Stdlib.format6
   and type ('a, 'b, 'c, 'd) format4 := ('a, 'b, 'c, 'd) Stdlib.format4
   and type ('a, 'b, 'c) format := ('a, 'b, 'c) Stdlib.format
