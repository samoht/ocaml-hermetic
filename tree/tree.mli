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

val adopted : Project_index.Library.t -> string list
(** [adopted l] is the names an [(mdx)] stanza may give [l], its dune name and
    its local name, when [l] names [hermetic.eio] among its libraries, and [[]]
    otherwise. *)

type finding = { file : string; line : int; text : string }
(** The type for one reason the tree is refused: the file it lies in, relative
    to the tree's root, the line, and what is wrong. *)

val pp_finding : finding Fmt.t
(** [pp_finding] formats a finding as the compiler formats an error, a
    [File "FILE", line LINE, characters 0-0:] line, then [Error: TEXT]. *)

val mdx :
  adopted:string list -> dune:string -> Dune.File.Mdx.t list -> finding list
(** [mdx ~adopted ~dune ms] is a finding in [dune] for each library of [adopted]
    that a stanza of [ms], the [(mdx)] stanzas of the dune file [dune], names
    without naming [hermetic.eio]. The adopted library's interface names the
    prelude's types, and a toplevel that loads it without the prelude's compiled
    interface sees them abstract. *)

type ratchet
(** The type for the libraries allowed to violate. *)

val ratchet_of_string : file:string -> string -> (ratchet, string) result
(** [ratchet_of_string ~file s] parses [s], the contents of [file], one library
    name per line; text after [#] and blank lines are ignored. *)

type verdict = {
  library : string;
  dune : string;
  boundary : bool;
  reports : Hermetic_check.report list;
}
(** The type for the verdict on one library: its name, its dune file relative to
    the tree's root, whether it is a boundary, and the reports on each of its
    compiled units. *)

val verdict :
  root:Fpath.t -> build:Fpath.t -> Project_index.Library.t -> verdict option
(** [verdict ~root ~build l] reads the [.cmt] files of [l], a library of the
    tree at [root], from the build directory [build]. It is [None] when [l] is
    {!Project_index.Library.gated} and was not built. *)

val judge : ratchet -> verdict list -> finding list * int * int
(** [judge r vs] is the findings refusing the tree, the number of hermetic
    libraries and the number of libraries in the ratchet. The findings are each
    finding of a violating library absent from [r], in the unit's source file,
    or the library's dune file when the unit names none; and each library of [r]
    that is hermetic or that is not among [vs], at its line of [r]. *)
