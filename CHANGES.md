## unreleased

- Move the restated `Unix` and `UnixLabels` to the library `hermetic.unix`,
  and the restated `Thread` to `hermetic.threads`, so that `hermetic`
  depends on the standard library only. A program that links every unit of
  `hermetic`, with `-linkall` or with `wasm_of_ocaml`'s development profile,
  no longer needs unix and threads, and dune's order of the libraries no
  longer fails the link with `Wrong link order`. A library that uses `Unix`
  or `Thread` through the prelude adds the sub-library to its libraries.

## 0.1.0 (3/11/2026)

Initial release.
