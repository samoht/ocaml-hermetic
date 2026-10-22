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

val adopted : Project_index.t -> string list
(** [adopted t] is the {!names} of the libraries of [t] that name [hermetic.eio]
    among their libraries. *)

val names : Project_index.t -> string list
(** [names t] is each name an [(mdx)] stanza may give a library of the source
    packages [t] read, vendored ones excepted: its dune name and its local name.
*)

val relative : root:Fpath.t -> Fpath.t -> Fpath.t
(** [relative ~root p] is [p] relative to [root], normalized, and [p] when it
    does not lie under [root]. *)

val owner : root:Fpath.t -> Project_index.t -> Fpath.t -> Fpath.t
(** [owner ~root t dir] is the directory, relative to [root], of the source
    packages that own [dir], as {!Project_index.packages_of_path} says, and [./]
    when none does. A package directory is the scope of one rule of {!rules}:
    the selected libraries and the [(mdx)] stanzas of the directories it owns.

    @raise Invalid_argument as {!Project_index.packages_of_path} does. *)

val source_dir : root:Fpath.t -> Project_index.Library.t -> Fpath.t
(** [source_dir ~root l] is the directory of [l]'s dune file, relative to
    [root]. *)

val objs : Project_index.Library.t -> Fpath.t
(** [objs l] is the directory of [l]'s compiled units, [.NAME.objs/byte],
    relative to its {!source_dir}. *)

type finding = { file : string; line : int; text : string }
(** The type for one reason the tree is refused: the file it lies in, relative
    to the tree's root, the line, and what is wrong. *)

val pp_finding : finding Fmt.t
(** [pp_finding] formats a finding as the compiler formats an error, a
    [File "FILE", line LINE, characters 0-0:] line, then [Error: TEXT]. *)

val mdx_names : Dune.File.Mdx.t list -> string list
(** [mdx_names ms] is the libraries the stanzas of [ms] name that do not name
    [hermetic.eio]: the ones {!mdx} judges. *)

val mdx_libraries : Dune.File.Mdx.t list -> string list
(** [mdx_libraries ms] is every library the stanzas of [ms] name but
    [hermetic.eio]: the ones a rule of {!rules} reads, so that a stanza that
    stops naming [hermetic.eio] is judged without writing the rules again. *)

val mdx :
  adopted:string list ->
  known:(string -> bool) ->
  dune:string ->
  Dune.File.Mdx.t list ->
  finding list
(** [mdx ~adopted ~known ~dune ms] is a finding in [dune] for each library of
    {!mdx_names}[ ms] that is among [adopted] or that is not [known]. The
    adopted library's interface names the prelude's types, and a toplevel that
    loads it without the prelude's compiled interface sees them abstract. A
    library the check does not know is one the rule of {!rules} for the stanza's
    package was not written for, which says to write the rules again. *)

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
  root:Fpath.t ->
  build:Fpath.t ->
  scoped:bool ->
  Project_index.Library.t ->
  verdict option
(** [verdict ~root ~build ~scoped l] reads the [.cmt] files of [l], a library of
    the tree at [root], from the build directory [build]. It is [None] when [l]
    is {!Project_index.Library.gated} and was not built. When [l] has no
    compiled unit, its one report is unreadable; with [scoped], the units come
    from the rule {!rules} wrote for [l]'s package, and the report says to write
    the rules again. *)

val stale : ratchet -> string list -> finding list
(** [stale r libs] is a finding at its line of [r] for each library of [r] that
    is not among [libs], the selected libraries of the tree. *)

val judge :
  owns:(string -> bool) -> ratchet -> verdict list -> finding list * int * int
(** [judge ~owns r vs] is the findings refusing the libraries of [vs], the
    number of hermetic libraries and the number of libraries of [r] it judged:
    those among [vs] and those [owns] says belong to the part of the tree [vs]
    covers. The findings are each finding of a violating library absent from
    [r], in the unit's source file, or the library's dune file when the unit
    names none; each unreadable unit of a library of [r]; each library of [r]
    that is hermetic, at its line of [r]; and {!stale} of the libraries of [r]
    it judged. A library of [r] that [owns] rejects and [vs] lacks is another
    part's. *)

type scope = {
  dir : Fpath.t;
  units : Fpath.t list;
  reads : Fpath.t list;
  outside : string list;
}
(** The type for what the rule of one package directory reads: [dir], relative
    to the tree's root; the directories of the compiled units of its selected
    libraries, relative to [dir]; the other package directories whose libraries
    its [(mdx)] stanzas name, relative to the root; and the names those stanzas
    give libraries no package of the tree provides. *)

val rules : ratchet:string option -> scope list -> string
(** [rules ~ratchet scopes] is a dune file for the tree's root that checks each
    scope in the runtest alias of its [dir], as
    [hermetic-tree --scope dir --reads ... --outside ...] with the ratchet file
    [ratchet], relative to the root. Each rule is a [(subdir dir ...)] stanza,
    sandboxed, that depends on the ratchet, the root's [dune] and
    [dune-project], the [dune], [dune-project], [.opam] and [.inc] files under
    [dir] and under each of [reads], which the index and the dune files'
    includes read, and the [.cmt] files of each of [units]. A selected library
    of [dir] that none of [units] names reads as having no compiled unit. No
    rule reads the whole tree, so that building one package's runtest loads the
    dune files of the packages it reads and no other. *)
