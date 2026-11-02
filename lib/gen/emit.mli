(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** The source of the prelude, from its plan.

    The prelude is a set of compilation units: the main one, which is a module
    of aliases, a unit for the types of refused values, and a unit for each
    top-level module the policy names, which is empty when the module stays as
    it is. A restated module the policy does not name goes to an overflow unit.
    A program then links only the units it uses. *)

val value_name : string -> string
(** [value_name v] is [v] as a declaration spells it: an operator, a keyword
    operator such as [mod] among them, in parentheses. *)

val units : string list
(** [units] is the top-level modules that have a unit of their own. *)

val files : Plan.prelude -> (string * string) list
(** [files plan] is each file of the prelude, by name, and its contents. *)

val file_names : string list
(** [file_names] is the name of every file {!files} returns, whatever the
    compiler. *)

val dune : gen:string -> string
(** [dune ~gen] is the dune rule that runs the generator [gen] and lists
    {!file_names} as its targets. *)
