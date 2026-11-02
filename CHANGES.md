## 0.1.0

Initial release.

- `Hermetic`, a prelude opened at the top of each source file with
  `open! Hermetic`, which restates the standard library: in a file that
  opens it, a use of a standard library value that reaches the world
  without being handed it is a type error. A value that reaches the world
  without being handed it, or that can forge memory or a value of any type,
  gets a type nothing consumes, and an alert says why and what to take
  instead. Library code does not write to the standard channels, and the
  libraries that reach the system past Eio's capabilities, such as
  `Eio_unix`, are declared empty.
- `Unix` and `UnixLabels` restated: their types and the exception
  `Unix_error` are kept, equal to the originals, their pure values are kept,
  and every value that reaches the world is refused. `Thread` restated too:
  its types are kept, and `Thread.create` and `Thread.delay` are refused;
  `Event` is left whole. `hermetic` depends on neither the unix nor the
  threads library, so a program that names only their types links none of
  them.
- The prelude is generated from the installed compiler's standard library,
  for OCaml 5.3 to 5.5. A value a newer compiler adds is refused as
  unreviewed until the policy reviews it.
- Each restated module the policy names is a unit of its own, `StdLabels`
  included, so a program links only the units it uses. A module that only a
  newer compiler has goes in `Hermetic__Unreviewed` until it is reviewed.
