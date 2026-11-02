# hermetic

A standard library prelude that refuses ambient authority.

With `Hermetic`, the only way to reach the world is through the capabilities
Eio's `env` hands you. A source file that opens the prelude cannot read the
process environment, the clock or the file system by name, cannot read the
standard input or write the standard output, cannot spawn a process or a
domain, and cannot end the process: the standard library values that do so
are refused at compile time, and their alerts name the `Eio.Stdenv`
capability to take as an argument instead. The libraries that reach the
system past Eio's capabilities, `Unix` and `Eio_main` among them, are refused
by name. A pure core, such as a protocol state machine or a codec, is the
case where no capability is handed in at all.

What this buys is that a library compiled under the prelude touches only what
it is handed, so a test can hand it an in-memory file system, a mock clock or
a recorded network, and a review can read its authority from its arguments.

`hermetic` also refuses what could forge what it was not handed: `Obj`, the
readers of `Marshal`, and the accessors that skip a bounds check.

## What it guards against

`hermetic` guards against accidents: an author who reaches for `Sys.getenv`
or `open_in` out of habit, or a refactoring that moves a call to the clock
into the wrong library. It does not guard against an author who is trying to
cheat. It is not a sandbox: the standard library without refusals is one
module away, as `Hermetic.Stdlib_original`, and an `external` declaration
names a primitive directly. It does not check dependencies either: a function
of another library that reads the environment in its own code is refused only
when that library is itself compiled under the prelude.

## Installation

<!-- $MDX skip -->
```sh
$ opam install hermetic
```

It supports OCaml 5.3, 5.4 and 5.5. It does not depend on Eio, nor on any
library it refuses: they are named in its messages only.

## Setup

Each source file of the library opens the prelude on its first line, with
`open!`, and the library names `hermetic` among its libraries:

<!-- $MDX skip -->
```
(library
 (name model)
 (libraries hermetic))
```

A refused value keeps its name but has one of three types: `Hermetic.ambient`
when it reaches the world without being handed it, `Hermetic.unsafe` when it
can forge memory or a value of any type, and `Hermetic.unreviewed` when this
version of `hermetic` has not reviewed it. Each type is abstract and nothing
in the prelude consumes it: a refused value cannot be applied or used at its
original type, so such a use is a type error, in every build profile. Passing
it to a polymorphic function such as `ignore` compiles and does nothing. The
value also carries an alert named after its type, which the compiler prints
beside the error to say why it is refused and, when it can, what to take as
an argument instead. This source file of the library:

<!-- $MDX skip -->
```
open! Hermetic

let home () = Sys.getenv "HOME"
```

does not build:

<!-- $MDX skip -->
```
File "lib/machine.ml", line 3, characters 14-24:
3 | let home () = Sys.getenv "HOME"
                  ^^^^^^^^^^
Alert ambient: Hermetic.Sys.getenv
Reads the process environment: take the value as an argument.

File "lib/machine.ml", line 3, characters 14-24:
3 | let home () = Sys.getenv "HOME"
                  ^^^^^^^^^^
Error: This expression has type ambient
       This is not a function; it cannot be applied.
```

Silencing the alert hides the message but not the error. A refused value can
still be named, with the alert as a warning, but not used.

The refusal follows the declaration, not the spelling: `Stdlib.Sys.getenv`,
`Stdlib__Sys.getenv`, a module alias of `Sys`, `open Stdlib` and
`include Sys` all reach the value the prelude declares, and a functor, a
signature constraint or a first-class module type that expects the original
`Sys` does not accept this one. `-unsafe` turns `a.(i)` into
`Array.unsafe_get`, which the prelude refuses, so a file that opens it cannot
be compiled with `-unsafe`.

Some details of this setup matter:

- The open is spelled `open!`. A plain `open` that leaves nothing used is
  warning 33, an error in dune's development profile up to
  `(lang dune 3.20)`, and one that shadows a name of the standard library is
  warning 44, which `-w +a` enables.
- Code above the open is outside the prelude, so the open is the first line.
  Nothing catches a file that forgets it: there is no checker.
- The interfaces do not open the prelude, so they name the standard library's
  own types, and a consumer of the library needs nothing of `hermetic` to use
  them. Give each source file an interface. A source file without one exports
  the types of its values: a type it infers is the standard library's, but a
  type, a constructor or a record field it names through a module the prelude
  restates, such as `Digest.t`, is the prelude's, and its consumer needs
  `hermetic` in its path. Such a file can also export a refused value it
  merely names, which then fails only in its consumer.
- A module that extends one of the standard library, with
  `include module type of String` in its interface and `include String` in
  its source file, includes the prelude's `String` in the source file, whose
  refused values do not match the interface. Include `Stdlib_original.String`
  there instead.
- The prelude is a module of aliases, and each module it restates is a unit
  of its own, so a program links only the units it uses.

## Escaping the prelude

`Hermetic.Stdlib_original` is `Stdlib` without refusals. Name it only for an
audited use, as in `Stdlib_original.Bytes.unsafe_get b i`: `grep
Stdlib_original` finds each one.

## Other ways to apply it

The prelude can be opened for every file of a library by a flag:

<!-- $MDX skip -->
```
(library
 (name model)
 (libraries hermetic)
 (flags (:standard -open Hermetic)))
```

The flag opens it in the interfaces too, so a type an interface names through
a module the prelude restates is the prelude's, and a consumer needs
`hermetic` in its path to use it. The open at the top of each source file
avoids this, and is the recommended setup.

A library can also ship without `hermetic` and be checked against the prelude
in another directory only. A library stanza there compiles a copy of every
source file of the library with the flag; `copy_files#` keeps the line
directives, so an error points at the original file. A library stanza
compiles each of its modules, where a test stanza would compile only those
its executable reaches:

<!-- $MDX skip -->
```
(copy_files# (files ../lib/*.ml))

(library
 (name model_hermetic)
 (libraries hermetic)
 (flags (:standard -open Hermetic)))
```

The code `ocamllex` generates calls `Lexing.engine`, and the code `ocamlyacc`
and `menhir` generate calls `Parsing.peek_val`, `Parsing.yyparse` or
`Obj.magic`: all of them can forge, and the prelude refuses them. Keep a
generated lexer or parser outside the prelude, in a library of its own, or
leave it out of the files a flag opens the prelude in.

## What it refuses

As `ambient`, what reaches the world without being handed it:

- the process environment and the process's own facts: `Sys.getenv`,
  `Sys.argv`, `Sys.executable_name`, `Sys.getcwd`, `Sys.chdir`,
  `Sys.runtime_parameters` and the rest;
- the processor time: `Sys.time`;
- the file system, reached by name: `open_in*`, `open_out*`, the openers of
  `In_channel` and `Out_channel`, the file functions of `Sys`, the temporary
  files of `Filename`, `Digest.file`, the files of `Scanf.Scanning`, and
  `Arg.read_arg` and `Arg.write_arg`;
- the standard input, which the code was not handed: `stdin`, `read_*`,
  `In_channel.stdin`, `Scanf.scanf` and `Scanf.Scanning.stdin`;
- the standard output and error: `stdout`, `stderr`, `print_*`, `prerr_*`,
  `flush_all`, `Out_channel.stdout` and `Out_channel.stderr`,
  `Printf.printf` and `Printf.eprintf`, the standard formatters of `Format`
  and every function that prints to them, `Printexc.print` and `Arg.usage`.
  Library code does not write to the process's standard channels:
  diagnostics go through Logs or Eio's `traceln`, which writes with the
  function the fiber's context holds, and data through a sink the code is
  handed;
- the process's lifecycle: `exit`, `at_exit`, `do_at_exit`, `Domain.at_exit`,
  `Domain.spawn`, `Sys.command`, the signals of `Sys`, `Printexc.catch` and
  `Printexc.set_uncaught_exception_handler`, and `Arg.parse` and the rest of
  what reads the command line;
- the system's entropy: `Random.self_init`, `Random.State.make_self_init`,
  `Hashtbl.randomize` and `Hashtbl.is_randomized`, and the `?random`
  argument of every `create` that has one (`Hashtbl`, `MoreLabels.Hashtbl`,
  their `MakeSeeded`, and the `MakeSeeded` of `Ephemeron`). Those are
  restated without it, and every table the prelude makes, `of_seq` and
  `rebuild` included, is made with `~random:false`, so that `OCAMLRUNPARAM=R`
  does not seed it either. Passing `~random` to one, even
  `~random:false`, is then a type error about an argument the function
  does not expect, and no alert explains it;
- the libraries that reach the system past Eio's capabilities: `Unix`,
  `UnixLabels`, `Thread`, `Event`, `Runtime_events`, `Dynlink`, `Eio_unix`,
  `Eio_posix`, `Eio_linux`, `Eio_windows` and `Eio_main`, which the prelude
  declares empty.

As `unsafe`, what can forge memory or a value of any type: `Obj`,
`CamlinternalMod`, `CamlinternalOO`, the readers of `Marshal` and
`input_value`, `Lexing.engine` and `Lexing.new_engine`, `Parsing.peek_val`
and `Parsing.yyparse`, and every accessor that skips the check its safe
version makes (the `unsafe_` functions of `Array`, `Bytes`, `String`,
`Bigarray`, `Char`, `Uchar`, `Float.Array`, `Iarray` and `Dynarray`, their
labelled versions, and `unsafe_really_input`).

`Arg.parse_argv` and `Arg.parse_argv_dynamic` are restated with `~current`
required, so that the position in the command line is handed in.

The complete list, one refusal per line, is
[test/refusals/hermetic.txt](test/refusals/hermetic.txt).

## What it keeps, and why

What works on what it is handed stays: a channel, a formatter, a buffer, a
table, `isatty` on a channel, the writers of `Marshal` and `output_value`.

State the whole process shares but that reaches no world stays too, since
the prelude's concern is authority, not determinism: the default generator of
`Random`, which OCaml 5 makes domain-local and seeds deterministically, and
`Random.State`; the iteration order of a hash table; registered printers and
backtraces; `Callback`, `Gc`, `Weak` and `Ephemeron`; the counters behind
`Oo.id`, `Type.Id.uid` and `Printexc.exn_slot_id`; call stacks; `Atomic`,
`Mutex`, `Condition`, `Semaphore`, `Lazy.Mutexed` and the domain-local state
of `Domain`; `Arg.current`; and the switches of `Sys`, `Parsing` and
`Printexc`.

## Eio code

A function that takes Eio's whole `env` holds all of its authority. Take the
narrowest capability that does the job instead: a directory, such as
`Eio.Stdenv.cwd` or one `Eio.Path.open_dir` returns, rather than
`Eio.Stdenv.fs`; a clock rather than the environment; a sink rather than
`Eio.Stdenv.stdout`. The executable, which calls `Eio_main.run` outside the
prelude, hands each library what it needs.

## Versions and compatibility

The prelude is generated when `hermetic` is built, from the installed
compiler's standard library and a policy that does not depend on the
compiler's version. The policy names every value and module it has reviewed,
at any depth. A value or a module a new compiler adds and the policy has not
reviewed is refused as `unreviewed`, and the modules above it are restated to
refuse it. A module whose contents the generator cannot open, such as a
generative functor, is removed and reported as unreviewed. The package's
upper bound on the compiler moves with each release, after a review. The test
suite runs the generator with `--strict` in the development profile, which
fails instead and lists the names to review. It also fails on a kept value
whose type hands out a channel, a formatter, or a record or a tuple of output
closures, as a result or to a callback, without taking one as an argument:
such a value can reach a standard channel, so it is refused, or reviewed as
making what it hands out from what it is handed, as `Format.formatter_of_buffer`
does.

Adding a refusal can break a library that builds today, so it is a breaking
change. Keeping a value the prelude refused, or widening the bound on the
compiler, is not.

## What it does not cover

A dependency is outside its reach, and so is a file that forgets the open. A
top-level `ref` of the library's own is state the whole process shares, and
no name of the prelude can refuse it. An `OCAMLPARAM` in the environment of
the build can add compiler options the build files do not show.

Some values carry an identity the process gives them: an object, the
constructor of a local exception, a type identifier, a channel and a closure.
`Hashtbl.hash` on such a value sees an address or a counter the whole process
shares, and so does `compare` on an object or an exception, so a library that
hashes or orders them depends on what ran before. The garbage collector's
timing shows through `==` on a lazy value once it has been forced.

`Bytes.create`, `Array.create_float`, `Float.Array.create` and the `create`
of each `Bigarray` module return memory the standard library leaves
uninitialised, whose contents depend on what the process did before; the
prelude keeps them as they are.

The limits of the process are not inputs either: how deep a recursion goes
before `Stack_overflow` depends on the stack the process was given, and an
allocation can fail. The constants of `Sys` (`os_type`, `word_size`,
`big_endian` and the rest) are the platform's, fixed when the program is
built.

## Licence

ISC. See [LICENSE.md](LICENSE.md).
