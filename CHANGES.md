## 0.1.0

Initial release.

- `Hermetic`, a prelude opened at the top of each source file with
  `open! Hermetic`, which restates the standard library: in a file that
  opens it, a use of a standard library value is a type error when it
  reaches, without being handed it, something Eio's env provides as a
  capability: the file system, a clock, the network, the standard input,
  output or error, the system's entropy, a domain or a child process. Such
  a value, and a value that can forge a capability, gets a type nothing
  consumes, and its alert names the `Eio.Stdenv` capability to take
  instead. Everything else stays. The libraries, and the units of
  libraries, that reach the system past Eio's capabilities are declared
  empty, without depending on them: Eio's backends, such as `Eio_unix`,
  `Mtime_clock`, `Ptime_clock`, `Bytesrw_sysrandom`, `Fmt_tty`, and the
  units of Eio 1.6 that reach a capability or the standard error by their
  own names, such as `Eio__core__Debug` and `Eio_unix__Fd`.
- `Unix` and `UnixLabels` restated: their types and the exception
  `Unix_error` are kept, equal to the originals. Unix: every value that
  reaches a capability by name or address is refused; I/O on a descriptor
  handed in stays, and so does `socket`, since a socket neither bound nor
  connected reaches no network. `Thread` restated too: its types are kept.
  Thread: delay, select and the timed waits are refused, and so is wait_pid.
  `Event` is left whole. `hermetic` depends on neither the unix nor the
  threads library, so a program that names only their types links none of
  them.
- The prelude is generated from the installed compiler's standard library,
  for OCaml 5.3 to 5.5. A value a newer compiler adds is refused as
  unreviewed until the policy reviews it.
- Each restated module the policy names is a unit of its own, `StdLabels`
  included, so a program links only the units it uses. A module that only a
  newer compiler has goes in `Hermetic__Unreviewed` until it is reviewed.
