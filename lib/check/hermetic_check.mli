(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Whether a compiled unit was compiled hermetic.

    A unit is read from its [.cmt] file, which records the compiler's command
    line and the typed tree. *)

type finding =
  | Not_opened of string
      (** [Not_opened m]: the command line does not open [m] with [-open]. *)
  | Not_fatal
      (** The [ambient] alert is not an error under the command line's [-alert]
          options, replayed in order by the compiler's own parser. *)
  | Silenced of { loc : Location.t; spec : string }
      (** An [[@alert spec]] attribute, at [loc], under which the [ambient]
          alert is no longer an error. *)
  | Stdlib_unit of { loc : Location.t; unit : string }
      (** A reference, at [loc], to [unit], a unit of the standard library named
          by its own name ([Stdlib__Sys]) rather than through the prelude. *)
  | External of { loc : Location.t; name : string; primitive : string }
      (** An [external] declaration of [name], at [loc], naming [primitive]. *)
  | Import of string
      (** [Import m]: the unit imports the compilation unit [m], one of the
          units refused to it. *)
  | Unreadable of string
      (** The file is not the [.cmt] of an implementation; the string says why.
      *)

type report = { name : string; findings : finding list }
(** The type for the verdict on one unit: the source file the unit was compiled
    from, or the path read when it names none, and what refuses it. *)

val unit :
  ?imports:string list ->
  ?externals:bool ->
  opens:string list ->
  string ->
  report
(** [unit ~opens path] is the verdict on the unit whose [.cmt] is [path]. Its
    findings are each module of [opens] the command line does not open, the
    [ambient] alert left non-fatal, each unit of [imports] (default [[]]) the
    unit imports, in alphabetical order, then each silencing attribute,
    reference to a standard library unit and, when [externals] is [true] (the
    default), [external] declaration of the typed tree, in source order. They
    are [[]] for a hermetic unit. *)

val pp_finding : finding Fmt.t
(** [pp_finding] prints a finding as one line naming what it refuses. *)

val past_eio : string list
(** [past_eio] is the units through which a library reaches the system past Eio:
    the Unix binding and the threads library. *)

val eio : ?boundary:bool -> string -> report
(** [eio path] is the verdict on a unit of a library that does its I/O through
    Eio: {!unit} with [Hermetic_eio] to open and {!past_eio} refused. With
    [~boundary:true] (default [false]) the library is a sanctioned boundary
    between Eio and the system, and its imports past Eio and its [external]
    declarations pass. *)
