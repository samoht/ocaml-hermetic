# hermetic

A standard library prelude that makes code take Eio's capabilities as
arguments.

In a file that opens `Hermetic`, a use of a standard library, `Unix` or
`Thread` value is a type error when it reaches, without being handed it,
something Eio's env provides as a capability: the file system, a clock, the
network, the standard input, output or error, the system's entropy, a domain
or a child process. Its alert names the `Eio.Stdenv` capability to take
instead. A value that can forge a capability, such as `Obj.magic` or a
`Marshal` reader, is refused too. Everything else stays.

The libraries that reach the system past Eio's capabilities, `Eio_main`,
`Eio_unix` and the clocks of mtime and ptime among them, are refused by name.
A pure core, such as a protocol state machine or a codec, is the case where
no capability is handed in at all.

What this buys is that a library compiled under the prelude reaches Eio's
capabilities through the standard library only with what it is handed, so a
test can hand it an in-memory file system, a mock clock or a recorded
network, and a review can read that authority from its arguments. It is not
a sandbox: see [What it guards against](#what-it-guards-against).

Eio's [design note on capabilities](https://github.com/ocaml-multicore/eio#design-note-capabilities)
states the gap this fills: "Since OCaml is not a capability language, code
can ignore Eio and use the non-capability APIs directly." `hermetic` is
capability hygiene relative to Eio's env: it refuses what reaches something
that env provides, and nothing else. It is not an object-capability subset
of OCaml: mutable globals stay, and so do the process environment, the
command line and the signals, which Eio's env does not provide (see
[What it does not cover](#what-it-does-not-cover)).

## What it guards against

`hermetic` guards against accidents: an author who reaches for `open_in`
or `print_endline` out of habit, or a refactoring that moves a call to the
clock into the wrong library. It does not guard against an author who is trying to
cheat. It is not a sandbox: the standard library without refusals is one
module away, as `Hermetic.Stdlib_original`, and an `external` declaration
names a primitive directly. It does not check dependencies either: a function
of another library that opens a file in its own code is refused only when
that library is itself compiled under the prelude (see
[What it does not cover](#what-it-does-not-cover)).

## Installation

<!-- $MDX skip -->
```sh
$ opam install hermetic
```

It supports OCaml 5.3, 5.4 and 5.5. It does not depend on Eio, nor on any
library it refuses: they are named in its messages only. Its `Unix` and its
`Thread` are compiled against the interfaces of the compiler's unix and
threads libraries, without depending on them (see
[Unix and threads](#unix-and-threads)).

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
when it reaches an Eio capability without being handed it, `Hermetic.unsafe` when it
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

let load () = open_in "model.bin"
```

does not build:

<!-- $MDX skip -->
```
File "lib/machine.ml", line 3, characters 14-21:
3 | let load () = open_in "model.bin"
                  ^^^^^^^
Alert ambient: Hermetic.open_in
Opens a file by name: take Eio.Stdenv.fs or Eio.Stdenv.cwd (an Eio.Path) as an argument, or the file's contents.

File "lib/machine.ml", line 3, characters 14-21:
3 | let load () = open_in "model.bin"
                  ^^^^^^^
Error: This expression has type ambient
       This is not a function; it cannot be applied.
```

Silencing the alert hides the message but not the error. A refused value can
still be named, with the alert as a warning, but not used.

The refusal follows the declaration, not the spelling:
`Stdlib.Sys.file_exists`, `Stdlib__Sys.file_exists`, a module alias of `Sys`, `open Stdlib` and
`include Sys` all reach the value the prelude declares, and a functor, a
signature constraint or a first-class module type that expects the original
`Sys` does not accept this one. `-unsafe` turns `a.(i)` into
`Array.unsafe_get`, `s.[i]` into `String.unsafe_get` and `b.{i}` into the
`unsafe_get` of `Bigarray`, which the prelude refuses, so a file that opens
it and indexes an array, a string or a bigarray cannot be compiled with
`-unsafe`; a file that does not index one compiles.

Some details of this setup matter:

- The open is spelled `open!`. A plain `open` that leaves nothing used is
  warning 33, an error in dune's development profile up to
  `(lang dune 3.20)`, and one that shadows a name of the standard library is
  warning 44, which `-w +a` enables. `open!` silences both, but not warning
  66: under `-w +a`, an `open!` that leaves nothing used is still reported.
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
- A module of the library named like a top-level module the prelude
  declares is shadowed by the prelude's after the open, and cannot be named
  by its own name. Those modules are `Arg`, `Array`, `ArrayLabels`,
  `Bigarray`, `Bytes`, `BytesLabels`, `CamlinternalFormat`,
  `CamlinternalFormatBasics`, `CamlinternalLazy`, `CamlinternalMod`,
  `CamlinternalOO`, `Char`, `Digest`, `Domain`, `Dynarray`, `Ephemeron`,
  `Filename`, `Float`, `Format`, `Gc`, `Hashtbl`, `Iarray`, `In_channel`,
  `Lexing`, `Marshal`, `MoreLabels`, `Obj`, `Out_channel`, `Parsing`,
  `Printexc`, `Printf`, `Random`, `Scanf`, `StdLabels`, `Stdlib`,
  `Stdlib_original`, `String`, `StringLabels`, `Sys`, `Thread`, `Uchar`,
  `Unix`, `UnixLabels` and the
  `Stdlib__` units, those a compiler lacks aside, and the libraries the
  prelude declares empty (see [What it refuses](#what-it-refuses)). Rename
  the module, or name it again after the open through the unit dune gives
  it: in a library `model`, `module Format = Model__Format`.
- A module that extends one of the standard library, with
  `include module type of String` in its interface and `include String` in
  its source file, includes the prelude's `String` in the source file, whose
  refused values do not match the interface. Include `Stdlib_original.String`
  there instead.
- The result of `Hashtbl.MakeSeeded`, and of the `MakeSeeded` of
  `MoreLabels.Hashtbl` and of `Ephemeron`, no longer matches the standard
  library's `SeededS`: its `create` has no `?random`. A signature constraint
  that names `Hashtbl.SeededS` rejects it; constrain it with the signature
  the functor returns instead, or apply the functor of
  `Stdlib_original.Hashtbl`.
- The prelude is a module of aliases, and each module it restates is a unit
  of its own, so a program links only the units it uses. A module that only
  a compiler newer than this version of `hermetic` has shares the unit
  `Hermetic__Unreviewed` with the others of its kind until it is reviewed.

## Escaping the prelude

`Hermetic.Stdlib_original` is `Stdlib` without refusals. Name it only for an
audited use, as in `Stdlib_original.Bytes.unsafe_get b i`. `grep
Stdlib_original` finds each line that names it, but not the uses of an alias:
after `module S = Stdlib_original`, a use of `S` does not name it.

A library that re-exports the standard library is `Stdlib_original` under
another name, which `grep Stdlib_original` does not find. The prelude
declares empty those it knows: Base's `Base__Import0` and `Base__Import`,
whose `Stdlib` is the standard library whole, `Base__`, which names them,
and `Shadow_stdlib`. `Base` itself re-exports many of the values the
prelude refuses, among them `Base.Obj`, `Base.Marshal`, `Base.Filename` and
`Base.open_out`, with only a `deprecated` alert, and the prelude cannot
declare it empty (see [What it does not cover](#what-it-does-not-cover)).

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

As `ambient`, what reaches an Eio capability without being handed it:

- the file system, reached by name, and the current directory: `open_in*`,
  `open_out*`, the openers of `In_channel` and `Out_channel`, the file
  functions of `Sys`, `Sys.getcwd` and `Sys.chdir`, the temporary files of
  `Filename`, `Digest.file`, the files of `Scanf.Scanning`, and
  `Arg.read_arg` and `Arg.write_arg`;
- the standard input: `stdin`, `read_*`, `In_channel.stdin`, `Scanf.scanf`
  and `Scanf.Scanning.stdin`;
- the standard output and error: `stdout`, `stderr`, `print_*`, `prerr_*`,
  `flush_all`, `do_at_exit`, which flushes them and runs every `at_exit`
  function early, `Out_channel.stdout` and `Out_channel.stderr`,
  `Printf.printf` and `Printf.eprintf`, the standard formatters of `Format`,
  every function that prints to them, and every function that changes or
  reads the standard formatter's state, which the executable prints with,
  such as `Format.set_formatter_output_functions`, `Format.set_margin` and
  `Format.get_margin`, `Printexc.print`,
  `Printexc.catch`, `Thread.default_uncaught_exception_handler`,
  `Arg.usage`, `Arg.parse` and its two siblings, which print the usage and
  end the process, and `Sys.enable_runtime_warnings`, which makes the
  runtime write on the standard error. `Gc.set` is restated to leave the
  runtime's verbosity as it is, for the same reason;
- a domain and a child process: `Domain.spawn` and `Sys.command`;
- the system's entropy: `Random.self_init`, `Random.State.make_self_init`,
  and the `?random` argument of every `create` that has one (`Hashtbl`,
  `MoreLabels.Hashtbl`, their `MakeSeeded`, and the `MakeSeeded` of
  `Ephemeron`). Those are restated without it, and every table the prelude
  makes, `of_seq` and `rebuild` included, is made with `~random:false`, so
  that `OCAMLRUNPARAM=R` does not seed it either. Passing `~random` to one,
  even `~random:false`, is then a type error about an argument the function
  does not expect, and no alert explains it;
- the values of `Unix` and `UnixLabels` that reach a capability by name or
  by address: files and directories by name, the current directory, the
  clock and the waits on it, the network by address or by name, the
  processes they spawn, wait for or signal, and the standard descriptors;
  and those that make a descriptor the code was not handed, or that turn
  one into a way to the network or the clock: `socket`, `socketpair`,
  `pipe`, `listen` and `setsockopt_float`;
- `Thread.delay`, `Thread.select`, `Thread.wait_timed_read` and
  `Thread.wait_timed_write`, which wait on the clock, and `Thread.wait_pid`,
  which waits for a child process;
- the libraries, and the units of libraries, that reach the system past
  Eio's capabilities, which the prelude declares empty: `Runtime_events`,
  `Dynlink`; `Eio_unix`, `Eio_posix`, `Eio_linux`, `Eio_windows`,
  `Eio_main` and `Iomux`, which `Eio_posix` polls with, each with every unit
  of its library, such as `Eio_posix__Fs`, and the module of aliases dune
  makes for it, such as `Eio_unix__`, which names each unit by a short name;
  the clocks `Mtime_clock` and `Ptime_clock`; `Bytesrw_sysrandom`, which
  reads the system's entropy; `Fmt_tty`, which sets up the standard output
  and error, and `Console_tty`, which does the same and records them in the
  file `CONSOLE_CAST` names, with `Console__Recording`, which opens that
  file, and the modules of aliases that name them, `Console_tty__` and
  `Console__`; the units that re-export the standard library without
  refusals (see [Escaping the prelude](#escaping-the-prelude)); and the
  units of Eio's core that reach the standard error past
  the executable's `Eio.traceln`, `Eio__core__Debug` and
  `Eio__core__Cancel`, with `Eio__core__`, which names them. The units are
  those of Eio 1.6 and of the iomux it builds with. Their types are refused
  with them, only because `hermetic` depends on none of them and so cannot
  restate them. A name is declared whether its library is installed or not.
  Only the clock of mtime is refused: a library that depends on mtime still
  names `Mtime.t` and `Mtime.Span`.

Each alert names the `Eio.Stdenv` capability to take instead: a write on the
standard output, for instance, names `Eio.Stdenv.stdout`, or Logs and
`Eio.traceln` to log with.

As `unsafe`, what can forge memory or a value of any type: `Obj`,
`CamlinternalMod`, `CamlinternalOO`, and, for parity with them, the other
runtime support the compiler's output calls, `CamlinternalFormat`,
`CamlinternalFormatBasics` and `CamlinternalLazy` (the compiler finds them
through its own environment, so format strings and lazy values still
compile under the prelude), the readers of `Marshal` and
`input_value`, `Lexing.engine` and `Lexing.new_engine`, `Parsing.peek_val`
and `Parsing.yyparse`, and every accessor that skips the check its safe
version makes (the `unsafe_` functions of `Array`, `Bytes`, `String`,
`Bigarray`, `Char`, `Uchar`, `Float.Array`, `Iarray` and `Dynarray`, their
labelled versions, and `unsafe_really_input`). `Bytes.unsafe_escape` and
`BytesLabels.unsafe_escape` are kept: they return their argument or a fresh
copy, and forge nothing.

The complete list, one refusal per line, is
[test/refusals/hermetic.txt](test/refusals/hermetic.txt).

## What it keeps

What works on what it is handed stays: a channel, a formatter, a buffer, a
table, `isatty` on a channel, the writers of `Marshal` and `output_value`.

Everything else stays too, however surprising, since it reaches no
capability Eio's env provides: the process environment (`Sys.getenv`), the
command line (`Sys.argv`), `exit` and `at_exit`, the signals, the processor
time, the facts of the process, its user and its host, I/O on a descriptor,
a socket or a process the code was handed, and `Thread.create`.

## Unix and threads

The prelude restates `Unix` and `UnixLabels` as it restates the standard
library. Every type stays, equal to the original with its constructors and
fields, so a signature can name `Unix.file_descr`, `Unix.sockaddr` or
`Unix.EADDRINUSE`, and so does the exception `Unix_error`, so a source file
can match on it. A value that reaches a capability by name or by address is
refused as `ambient`: `openfile`, `stat` and the other functions that take a
path, `getcwd` and `chdir`, `time`, `gettimeofday`, `sleep`, the timers and
`select`, `bind`, `connect`, `sendto`, `open_connection`,
`establish_server` and the name resolvers, the functions that spawn a
process, wait for one or signal one, and `stdin`, `stdout` and `stderr`. So
is a value that makes a descriptor the code was not handed: `socket`,
`socketpair` and `pipe`. A fresh socket reaches the network, since `listen`
on a socket that is not bound binds it to a port on every interface, and
the times `fstat` reads of a fresh socket or pipe are the clock's. `listen`
is refused for the same reason, and `setsockopt_float`, whose only options,
`SO_RCVTIMEO` and `SO_SNDTIMEO`, make a receive or a send a timed wait on
the clock. The rest stays: I/O on a descriptor, a socket or a process the
code was handed, `accept` on a listening socket it was handed,
the environment, the facts of the process, its user and its
host, the time zone, the signal masks and `_exit`, and the pure values, such
as the conversions of internet addresses. A value a newer compiler adds is
refused as `unreviewed` until it is reviewed.

It restates the threads library's `Thread` too: every type stays, so a
signature can name `Thread.t`, and so do the values that act only on the
thread they are given or the current one (`self`, `id`, `join`, `yield` and
the rest), and `Thread.create`. `Thread.delay`, `Thread.select` and the
timed waits are refused, since they wait on the clock, and so is
`Thread.wait_pid`, which waits for a child process. `Event` refuses nothing, since its values
work only on the channels they are handed, so the prelude does not declare
it, and a library's own module named `Event` stays its own.

The unix and threads libraries force their own link: a program that names
one among its libraries links all of it, and the standard library modules it
uses, whether it uses a value of it or not. So `hermetic` depends on
neither. A program that uses a value of `Unix` or `Thread`, or matches on
`Unix_error`, names `unix` or `threads` among its libraries, as it would
without the prelude. A file that names only their types needs the
interfaces they are declared in, but none of their code:
`(flags (:standard -I +unix -I +threads))` finds them without linking
anything. Without that, OCaml 5 finds them itself and prints the
`ocaml_deprecated_auto_include` alert.

## Eio code

A function that takes Eio's whole `env` holds all of its authority. Take the
narrowest capability that does the job instead: a directory, such as
`Eio.Stdenv.cwd` or one `Eio.Path.open_dir` returns, rather than
`Eio.Stdenv.fs`; a clock rather than the environment; a sink rather than
`Eio.Stdenv.stdout`. The executable, which calls `Eio_main.run` outside the
prelude, hands each library what it needs.

## Diagnostics

`Eio.traceln` is the one diagnostic channel the prelude sanctions: where it
writes is the executable's choice, which binds the `traceln` key of
`Eio.Stdenv.debug` with `Eio.Fiber.with_binding`, and the standard error
when it binds nothing. It also writes on the standard error, whatever the
executable binds, where that binding is out of reach: outside an Eio
scheduler, in a system thread, and inside a nested `Eio_mock.Backend.run`,
whose fibers start from an empty context.

## Versions and compatibility

The prelude is generated when `hermetic` is built, from the installed
compiler's standard library and a policy that does not depend on the
compiler's version. The policy names every value and module it has reviewed,
at any depth. A value or a module a new compiler adds and the policy has not
reviewed is refused as `unreviewed`, and the modules above it are restated to
refuse it. So is a unit of the compiler's library directory that `Stdlib` does
not name and the policy has not reviewed, beside `CamlinternalOO` and
`Std_exit`. A module whose contents the generator cannot open, such as a
generative functor, is removed and reported as unreviewed. A class cannot be
restated, so a class a new compiler adds to a module the prelude must restate
fails the generator: `hermetic` does not build on that compiler until the
policy reviews the class. The package's
upper bound on the compiler moves with each release, after a review. The test
suite runs the generator with `--strict` in the development profile, which
fails instead and lists the names to review. It also fails on a kept value
whose type hands out a channel, a formatter, or a record or a tuple of output
closures, as a result or to a callback, without taking one as an argument:
such a value can reach a standard channel, so it is refused, or reviewed as
making what it hands out from what it is handed, as
`Format.formatter_of_buffer` does. Otherwise the check compares names, not
types or behaviour: a reviewed value whose type or behaviour a new compiler
changes passes it, so the review of a new compiler reads its changes too.

Adding a refusal can break a library that builds today, so it is a breaking
change. Keeping a value the prelude refused, or widening the bound on the
compiler, is not.

## What it does not cover

The prelude restates the compiler's libraries only. The values of other
libraries reach capabilities in their own code, and a file under the
prelude that calls one reaches them too. Those known so far, each with what
to use instead:

- `Fmt.pr`, `Fmt.epr`, `Fmt.stdout` and `Fmt.stderr`: `Fmt.pf` on a
  formatter the code is handed;
- `Cstruct.hexdump`: `Cstruct.hexdump_pp`;
- `Logs_fmt.reporter ()` and `Logs.format_reporter ()`, whose formatters
  default to the standard output and error: a library logs with `Logs.msg`
  and leaves `Logs.set_reporter` to the executable;
- cmdliner's `Arg.file`, `Arg.dir` and `Arg.non_dir_file`, which read the
  file system, and `Cmd.eval` and its siblings, whose formatters default to
  the standard output and error: `Cmd.eval_value ~help ~err`;
- Yojson's readers and writers by file name, such as `from_file` and
  `to_file`: read the contents through an `Eio.Path` and use `from_string`;
- `Base`'s re-exports of the standard library, such as `Base.Obj.magic`,
  `Base.open_out`, `Base.print_endline` and `Base.Marshal`, which carry only
  a `deprecated` alert, `Base.Random.self_init` and
  `Base.Random.State.make_self_init`, which read the system's entropy, and
  `Base.Exn.handle_uncaught`, which prints on the standard error: Base's own
  modules and the prelude's;
- Stdio's `stdout`, `stderr`, `print_*` and readers and writers by file
  name: take the channel or an `Eio.Path`;
- console-eio's `Console_eio.run` without `~ppf`, and `Console_eio.print`
  and `Console_eio.with_output` outside a run, which write on the standard
  error, and `Console_eio.run`, which records in the file `CONSOLE_CAST`
  names: pass `~ppf`, and leave the recording to the executable;
- `Eio.Private.Debug.default_traceln`, which writes on the standard error:
  `Eio.traceln`; and `Eio.Exn.register_pp`, which installs a printer for the
  whole process: leave it to the executable.

Dependencies also use `unsafe_` accessors, `Obj` and `Marshal`: the prelude
refuses them only in a file that opens it. It declares empty the units of
Eio 1.6 and of iomux; a unit another version adds is not covered.

Authority is not always readable from arguments. A top-level reference or
table can hold a capability the code was handed, and a function that reads
it later reaches that capability without taking it. An exception can carry
a capability from where it is raised to where it is caught.

The process environment, the command line, `exit` and the signals are kept
by design: Eio's env does not provide them, so there is no capability to
take instead.

A file that forgets the open is not checked, and an `OCAMLPARAM` in the
environment of the build can add compiler options the build files do not
show.

## Related work

- Eio's [design note on capabilities](https://github.com/ocaml-multicore/eio#design-note-capabilities)
  is where the prelude starts: OCaml does not stop code from ignoring Eio.
- [Emily](https://cs.pomona.edu/~rbull/emily/) (Stiegler and Miller, *How
  Emily Tamed the Caml*, HPL-2006-116) is a capability-secure subset of
  OCaml that a verifier checks; `hermetic` uses the stock compiler and keeps
  mutable globals.
- [Joe-E](https://people.eecs.berkeley.edu/~daw/papers/joe-e-ndss10.pdf) is
  a subset of Java that tames its library with an allowlist and allows only
  immutable globals.
- [Hardened JavaScript](https://hardenedjs.org/) tames the JavaScript
  runtime when the program starts, its clock and its randomness included.
- [cap-std](https://github.com/bytecodealliance/cap-std) is a
  capability-based standard library for Rust, and Clippy's
  [`disallowed-methods`](https://doc.rust-lang.org/nightly/clippy/lint_configuration.html)
  refuses the functions a project names, as the prelude refuses values.
- Pony's [trust boundary](https://tutorial.ponylang.io/object-capabilities/trust-boundary.html)
  lets only the packages named with `--safe` call C code.

## Licence

ISC. See [LICENSE.md](LICENSE.md).
