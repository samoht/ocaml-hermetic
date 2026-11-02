(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** The names of the installed standard library, read from its compiled
    interfaces.

    Names are read: the values, the submodules and the functors of each module,
    and the names and arities of the types of [Stdlib] itself. The type of a
    value is read only to find the values that hand out a channel (see
    {!field-channels}), since the prelude restates a refused value with a type
    of its own. *)

type node =
  | Sig of item list  (** A signature, its items in declaration order. *)
  | Functor of { param : string; param_type : string; result : node }
      (** A functor of one named parameter. [param_type] is the path of the
          parameter's module type, as written in the standard library's
          interface. *)
  | Opaque of string
      (** A module type the reader does not open, and why: an abstract module
          type, a generative functor, a functor of an anonymous parameter or of
          a parameter that is not a named module type. *)

and item =
  | Value of string
  | Type of string * int  (** A type and its number of parameters. *)
  | Module_type of string
  | Class of string
  | Class_type of string  (** A class type that no class declares. *)
  | Module of string * module_
      (** A submodule, which is an alias of a top-level module or a module of
          its own. An alias of any other path is read as the module it names. *)

and module_ =
  | Alias of string  (** An alias of a top-level module, by its name. *)
  | Dotted of string * node
      (** An alias of a submodule of the standard library, by its path as
          {!Policy} spells it, and the module it names. *)
  | Node of node

type t = {
  types : (string * int) list;
      (** The types of [Stdlib] itself, each with its number of parameters. *)
  values : string list;  (** The values of [Stdlib] itself. *)
  modules : (string * node) list;
      (** The modules of [Stdlib], each followed to its unit, then the units of
          the standard library that [Stdlib] does not name ([CamlinternalOO] and
          the rest), in that order. *)
  in_stdlib : string list;
      (** The names in {!field-modules} that [Stdlib] names. *)
  channels : string list;
      (** The values, by their path as {!Policy} spells it, whose type hands out
          a channel, a formatter, or a record or a tuple of output closures (a
          closure whose result is [unit]), as a result or to a callback, and
          takes none as an argument. Such a value can reach a standard channel
          without being handed it. *)
}

val pp : Format.formatter -> t -> unit
(** [pp ppf t] prints the names of [t], one per line, each submodule's below it
    and indented. *)

val read : string -> t
(** [read dir] is the standard library whose compiled interfaces are in [dir].
*)

val mem : t -> string -> bool
(** [mem t path] is [true] when [t] has the value or the module at [path], as
    {!Policy} spells paths. *)
