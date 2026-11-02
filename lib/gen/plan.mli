(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** What the prelude restates, from the policy applied to the installed standard
    library.

    Every module of the standard library is reviewed, at any depth: a value or a
    submodule the policy neither refuses nor has reviewed is refused as
    {!Policy.Unreviewed}, and the modules above it are restated to refuse it. A
    module whose contents the reader cannot open (an abstract module type, a
    generative functor) is removed and reported as unreviewed, and so is a
    functor whose result has a submodule that must change. A class cannot be
    restated, so a module that has one and must be restated fails the
    generation. A value whose name says [unsafe] is kept only by an entry of the
    policy. *)

type restated =
  | Sig of { items : item list; names : names }
      (** A module restated as the original with the items below replaced.
          [names] are the original's own types, module types and submodules,
          which a values-only include of the original removes. *)
  | Whole of Policy.refusal * item list
      (** A module every value of which is refused, at any depth. *)
  | Functor of { params : (string * string) list; items : item list }
      (** A functor restated as the original, curried over [params] (name and
          module type), with the values [items] of its result replaced. *)
  | Gone  (** A top-level module removed: the prelude declares it empty. *)

and item =
  | Refused of string * Policy.refusal  (** A value restated as refused. *)
  | Retyped of { name : string; typ : string; impl : string; doc : string }
      (** A value restated with another type; see {!Policy.Retyped}. *)
  | Removed of string  (** A submodule removed. *)
  | Sub of string * restated  (** A submodule restated. *)
  | Rewired of string * string
      (** An alias of the standard library, such as [StdLabels.Array], restated
          as an alias of the prelude's own top-level module. *)

and names = {
  types : (string * int) list;
  module_types : string list;
  submodules : string list;
  class_types : bool;
      (** Whether the original declares a class type, which an include cannot
          remove. *)
}

type prelude = {
  values : item list;  (** The restated values of [Stdlib] itself. *)
  modules : (string * restated) list;
      (** The restated top-level modules, in the standard library's order. *)
  in_stdlib : string list;
      (** The names in {!field-modules} that [Stdlib] names, rather than runtime
          support units. *)
}

val v :
  ?refusals:(string * Policy.entry) list ->
  ?reviewed:Policy.reviewed ->
  Stdlib_tree.t ->
  prelude * string list
(** [v tree] is the plan of the prelude over [tree] and the paths it refused as
    unreviewed. [refusals] defaults to {!Policy.refusals} and [reviewed] to
    {!Policy.reviewed}.

    @raise Failure
      when a module that has a class must be restated, or when the policy
      refuses a module as a value or a value as a module. *)

val mistakes :
  ?refusals:(string * Policy.entry) list ->
  ?version_specific:string list ->
  Stdlib_tree.t ->
  string list
(** [mistakes tree] is the refusal paths that [tree] lacks and that no supported
    compiler is known to lack: a typo such as ["Sys.getevn"], which would
    otherwise refuse nothing and keep the real value. *)

val channels :
  ?refusals:(string * Policy.entry) list ->
  ?reviewed:Policy.reviewed ->
  Stdlib_tree.t ->
  string list
(** [channels tree] is the values of {!Stdlib_tree.field-channels} that the
    policy keeps and has not reviewed in {!Policy.field-channels}: each can
    reach a standard channel without being handed it, so it must be refused or
    reviewed. [refusals] defaults to {!Policy.refusals} and [reviewed] to
    {!Policy.reviewed}. *)
