# hermetic

The OCaml standard library with the ambient world refused.

A protocol state machine, a codec or the model of a tool is meant to decide
from its inputs alone, so that the same inputs give the same outputs and a
test can replay any run. The build can refuse it Unix, Eio or a clock library
with dune's `forbidden_libraries`, but the standard library reads the world
outside the program too: `Sys.getenv`, `Sys.time`, `open_in`, `In_channel`,
`Random.self_init` and `exit` link with nothing extra. A model that calls
them builds and passes its tests, and a run then depends on the machine it ran
on.

`hermetic` makes those calls compile errors. Its `Hermetic` module restates
the standard library with every value that reaches the world without being
handed it marked by an `ambient` alert, and a library opens it before it is
typed:

<!-- $MDX skip -->
```
(library
 (name model)
 (libraries hermetic)
 (flags (:standard -open Hermetic -alert @ambient)))
```

<!-- $MDX skip -->
```
File "lib/machine.ml", line 3, characters 14-24:
3 | let home () = Sys.getenv "HOME"
                  ^^^^^^^^^^
Error (alert ambient): Hermetic.Sys.getenv
Reads the process environment: take the value as an input.
```

The `hermetic-check` command then reads the library's compiled units and
refuses what the prelude cannot see: a unit compiled without the two flags, an
attribute that makes the alert a warning again, a unit of the standard library
named by its own name, and an `external` declaration, which names a primitive
directly.

It needs OCaml 5.4 or later.

## Installation

<!-- $MDX skip -->
```sh
$ opam repo add samoht https://tangled.org/gazagnaire.org/opam-overlay.git
$ opam install hermetic
```

## What it refuses

A refused value carries the alert, so the error names the value and says
what to pass in instead. A module refused as a whole is empty, and the three
mutable globals of the standard library (`Sys.argv`, `Sys.interactive` and the
domain's exit actions) are `()`, so that no use of them compiles even where
the alert is silenced. A channel, a formatter or a buffer the caller hands in
is an input: the functions that use one stay, and `Format.fprintf`,
`output_string oc` and `In_channel.input_all ic` compile.

- The process environment and the process's own facts: `Sys.getenv`,
  `Sys.argv`, `Sys.executable_name`, `Sys.getcwd`, `Sys.runtime_parameters`.
- The clock: `Sys.time`.
- Randomness: `Random.self_init`, `Random.State.make_self_init`, and every
  function of the generator the whole process shares (`Random.int` and the
  rest). A `Random.State.t` made with `Random.State.make` from a seed the
  caller passes stays.
- The order of a generic hash table, which `OCAMLRUNPARAM=R` seeds from the
  system: `Hashtbl.iter`, `fold`, `to_seq` and the rest of what observes it,
  `Hashtbl.randomize` and `Hashtbl.MakeSeeded`. Lookups stay, and so do the
  tables of `Hashtbl.Make`, which never randomise.
- The standard channels and the files: `stdin`, `stdout`, `stderr`,
  `print_*`, `prerr_*`, `read_*`, `open_in*`, `open_out*`, `flush_all`, the
  openers and standard channels of `In_channel` and `Out_channel`, the file
  functions of `Sys`, `Filename.temp_file`, `Digest.file`, `Printf.printf`,
  `Scanf.scanf` and the files of `Scanf.Scanning`, and the standard
  formatters of `Format` with every function that writes or sets them
  implicitly.
- The process: `exit`, `at_exit`, `Sys.command`, `Sys.signal`,
  `Sys.catch_break`, `Arg`, `Callback`.
- State the whole process shares: `Domain`, `Mutex`, `Condition`,
  `Semaphore`, `Atomic`, `Gc`, `Weak`, `Ephemeron`, `Oo`, and the printers
  and backtraces of `Printexc` (`Printexc.to_string_default` stays).
- The escapes from the type system: `Obj`, `Marshal`, `input_value`,
  `unsafe_really_input`, `CamlinternalMod`, `CamlinternalOO`.
- In `Fmt`: `Fmt.stdout`, `Fmt.stderr`, `Fmt.pr`, `Fmt.epr`, and `Fmt.exn`,
  which renders through the printers the process registered.

The refusal follows the declaration, not the spelling. `Stdlib.Sys.getenv`,
a module alias of `Sys`, `open Stdlib`, `include Sys`, a functor applied to
`Sys`, a signature constraint over it and a first-class module packing it are
all refused: each reaches the value through a declaration of `Hermetic`, and
the compiler checks the alert on a signature inclusion as it does on a use.
`Stdlib__Sys.getenv` names the standard library's own unit, which no prelude
can shadow without defining a module of that name; `hermetic-check` refuses
it.

## Checking the compiled units

<!-- $MDX skip -->
```
(rule
 (alias runtest)
 (deps (glob_files ../lib/.model.objs/byte/model__*.cmt))
 (action (run %{bin:hermetic-check} %{deps})))
```

`hermetic-check` reads each `.cmt` and prints one line per reason to refuse
the unit, then exits 1:

- the command line that compiled it does not open `Hermetic`, or a module
  given with `--open`;
- the `ambient` alert is not an error under its `-alert` options, which are
  replayed in order through the compiler's own parser, so a later
  `-alert -ambient` undoes an earlier `-alert @ambient`;
- an `[@alert "..."]` attribute, on the file, an item or an expression, under
  which the `ambient` alert stops being an error (`"-ambient"`, `"--ambient"`,
  `"-all"`); an attribute that keeps it an error, or one that declares an
  alert of the library's own, passes;
- it names a unit of the standard library by its own name, `Stdlib__Sys` or
  any other, in a value, an alias, an `open`, a functor argument or a
  first-class module;
- it declares an `external`, at any depth, with the primitive it names.

The first two do not apply to the alias module dune generates for a library of
several modules, which it compiles without the library's flags: a unit that
holds only `module X = Lib__X` aliases to units of its own library, each
checked by itself, has nothing in it to refuse. An alias to any other module
is refused as before, since it would hand that module to its users past the
prelude.

A library that also hides the ambient values of a dependency in a prelude of
its own opens that prelude after `Hermetic` and names it with `--open`, so
that dropping it from the stanza is refused too.

## Libraries that do their I/O through Eio

A library that talks to the system through Eio capabilities is not hermetic,
but it should reach the system only through the capabilities it is handed.
The `hermetic.eio` library holds the prelude for it, `Hermetic_eio`, opened the
same way:

<!-- $MDX skip -->
```
(library
 (name store)
 (libraries eio hermetic.eio)
 (flags (:standard -open Hermetic_eio -alert @ambient)))
```

It keeps the standard library an Eio program uses, hash table iteration,
`Random`, `Atomic`, `Domain` and the standard formatters included, and refuses
each access that bypasses a capability with a message naming the Eio call to
make instead:

- the file system: `open_in*`, `open_out*`, the openers of `In_channel` and
  `Out_channel`, the file functions of `Sys` (`file_exists`, `is_directory`,
  `readdir`, `remove`, `rename`, `mkdir`, `rmdir`), the temporary files of
  `Filename` and the digests of a file;
- the process: `exit`, `at_exit`, `Sys.command`, `Sys.signal`,
  `Sys.set_signal`, `Sys.catch_break`, `Sys.getcwd`, `Sys.chdir`, `Sys.argv`
  and `Sys.executable_name`;
- the clock: `Sys.time`;
- the process environment: `Sys.getenv` and `Sys.getenv_opt`, which no Eio
  capability holds, so the value is taken as an input, as under `Hermetic`;
- `Mutex`, `Condition` and `Semaphore`, which block the domain under every
  fiber, are refused as a whole.

`hermetic-check --eio` reads the units against that prelude and also refuses
a unit that imports `Unix`, `UnixLabels`, `Thread` or `Event`. The standard
library's `Mutex`, `Condition` and `Semaphore` are the prelude's to refuse:
Eio's own interfaces name `Mutex.t`, so every unit typed against Eio imports
them. The rule beside the library reads its units:

<!-- $MDX skip -->
```
(rule
 (alias runtest)
 (deps (glob_files .store.objs/byte/*.cmt))
 (action (run %{bin:hermetic-check} --eio %{deps})))
```

A library that is the boundary between Eio and the system, and so binds the
system calls Eio lacks, is checked with `--eio --boundary`, which allows those
imports and its `external` declarations.

## Every Eio library of a tree

In a tree of many projects, `-alert @ambient` belongs once in the env of the
`dune-workspace`, for every profile. A library then adopts the prelude with one
change to its stanza:

<!-- $MDX skip -->
```
 (libraries eio hermetic.eio)
 (flags (:standard -open Hermetic_eio))
```

The `hermetic-tree` command, of the `hermetic-tree` package, checks such a
tree. It indexes the source tree, selects each library whose public name ends
with `-eio` or `.eio` or that names `eio` among its libraries, and reads its
units as `hermetic-check --eio` does. A package whose `dune-project` carries
the tag `hermetic:eio-boundary` is checked as `--boundary`. An `mdx` stanza
that names an adopted library names `hermetic.eio` too, or its toplevel sees
the prelude's types abstract. A ratchet file lists the libraries still allowed
to violate, one library name per line, and the check refuses a listed library
that has become hermetic, so the list only shrinks.

Each package directory is checked in its own `runtest`, so that testing the
packages a change touches checks them, and nothing else is built.
`hermetic-tree --include --ratchet hermetic.ratchet` prints those rules, one
`(subdir DIR ...)` stanza for each package directory, for an `(include)` of
the root's dune file. Each depends on the compiled units of the directory's
selected libraries and on the dune files of the packages its `mdx` stanzas
read, and runs `hermetic-tree --scope DIR`. The root keeps one rule that
prints them again and fails on a difference, which `--auto-promote` takes, and
on a library of the ratchet the tree no longer selects:

<!-- $MDX skip -->
```
(include hermetic.inc)

(rule
 (deps (sandbox always) hermetic.ratchet (glob_files_rec dune)
  (glob_files_rec dune-project) (glob_files_rec *.opam) (glob_files_rec *.inc))
 (action
  (with-stdout-to hermetic.inc.gen
   (run %{bin:hermetic-tree} --include --ratchet hermetic.ratchet))))

(rule
 (alias runtest)
 (action (diff hermetic.inc hermetic.inc.gen)))
```

A library added to a package after the rules were printed has no compiled
unit in its rule's sandbox, and an `mdx` stanza that names a library its rule
does not read is refused the same way: both say to print the rules again. A
new package has no rule until they are.

## What it does not cover

A dependency is outside its reach. A function of another library that reads
the environment in its own code is refused only when that library is itself
compiled hermetic. A dependency's ambient values can be shadowed the same way,
by a module that restates it with the `ambient` alert, opened after
`Hermetic`, as the `probe.hermetic` library of the `probe` package does for
`Probe`. A top-level `ref` of the library's own is state the whole process shares,
and no name of the prelude can refuse it. An `OCAMLPARAM` in the environment
of the build can add compiler options the recorded command line does not
show.

## Licence

ISC. See [LICENSE.md](LICENSE.md).
