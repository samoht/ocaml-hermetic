(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** What the prelude refuses, independent of the compiler's version.

    A path names a value or a module of the standard library from [Stdlib] down,
    without the [Stdlib] prefix: ["Sys.getenv"], ["Obj"],
    ["Float.Array.unsafe_get"], ["print_string"]. The values of a functor's
    result are named under the functor's path. The runtime support units, such
    as [CamlinternalOO], are named as top-level modules. A refusal whose path
    the installed compiler lacks is skipped, so that one table covers every
    supported version. *)

type kind =
  | Ambient  (** Reaches the world without being handed it. *)
  | Unsafe  (** Can forge memory or a value of any type. *)
  | Unreviewed  (** Not reviewed by this version of the policy. *)

val kind_name : kind -> string
(** [kind_name k] is the name of [k]'s type in the prelude, which is also the
    name of the alert its values carry: ["ambient"], ["unsafe"] or
    ["unreviewed"]. *)

type refusal = { kind : kind; message : string }
(** A refusal and the message its alert carries, which says why and, when it
    can, what to take as an argument instead. *)

type entry =
  | Value of refusal  (** The value at the path is refused. *)
  | Module of refusal
      (** Every value of the module at the path is refused, at any depth. *)
  | Retyped of { typ : string; impl : string; doc : string }
      (** The value at the path is restated with the type [typ] and the
          implementation [impl], an expression in which the value's name is the
          original. In [typ], [{orig}] stands for the path of the original
          module, a functor's application included. *)
  | Keep of string
      (** The value at the path is kept, for the reason given. It is needed only
          for a value whose name says [unsafe], which is refused as unreviewed
          otherwise. *)

val refusals : (string * entry) list
(** The refusals of the prelude. *)

val shadowed : (string * string) list
(** [shadowed] is each library that reaches the system past Eio's capabilities,
    such as [Unix], which the prelude declares empty, and the message of its
    [ambient] alert. *)

val name : string
(** The prelude's module name, ["Hermetic"]. *)

val doc : string
(** The odoc preamble of the prelude's interface. *)

val unreviewed : string -> refusal
(** [unreviewed path] is the refusal of the value or the module at [path], which
    the policy has not reviewed. *)

type reviewed = {
  modules : string list;
      (** The path of every module the policy has reviewed, at any depth. *)
  kept : (string * string list) list;
      (** The values each reviewed module keeps, by module path, [""] for the
          top level of [Stdlib]. *)
}
(** What the policy has reviewed. A value or a module that is neither refused
    nor reviewed is refused as {!Unreviewed}. *)

val reviewed : reviewed
(** The names reviewed on OCaml 5.3, 5.4 and 5.5. *)

val version_specific : string list
(** The paths of {!refusals} that some supported compiler lacks. Any other
    refusal path a compiler lacks is a mistake in the policy. *)
