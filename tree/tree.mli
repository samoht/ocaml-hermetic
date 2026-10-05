(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** The Eio libraries of a source tree and their verdicts against the ratchet.
*)

val boundary_tag : string
(** [boundary_tag] is the tag a package's [dune-project] carries when its
    libraries are the sanctioned boundary between Eio and the system. *)

val selected : Project_index.Library.t -> bool
(** [selected l] is [true] when [l] is a library of the source tree, not
    vendored, that does its I/O through Eio: its public name ends with [-eio] or
    [.eio], or it names [eio] among its libraries. The library defining the
    prelude, [Hermetic_eio], is not. *)

type ratchet
(** The type for the libraries allowed to violate. *)

val ratchet_of_string : string -> (ratchet, string) result
(** [ratchet_of_string s] parses one library name per line; text after [#] and
    blank lines are ignored. *)

type verdict = {
  library : string;
  boundary : bool;
  reports : Hermetic_check.report list;
}
(** The type for the verdict on one library: its name, whether it is a boundary,
    and the reports on each of its compiled units. *)

val verdict :
  root:Fpath.t -> build:Fpath.t -> Project_index.Library.t -> verdict option
(** [verdict ~root ~build l] reads the [.cmt] files of [l], a library of the
    tree at [root], from the build directory [build]. It is [None] when [l] is
    {!Project_index.Library.gated} and was not built. *)

val judge : ratchet -> verdict list -> string list * int * int
(** [judge r vs] is the lines refusing the tree, the number of hermetic
    libraries and the number of libraries in the ratchet. The lines are each
    finding of a violating library absent from [r], each library of [r] that is
    hermetic, and each library of [r] that is not among [vs]. *)
