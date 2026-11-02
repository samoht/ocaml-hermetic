Every unit of the libraries that reach the system past Eio's capabilities
is declared empty, with the module of aliases dune makes for each: eio.unix,
eio_posix, eio_linux, eio_windows, eio_main and iomux. Each compiled
interface installed for one of them names a unit the prelude declares, so
a unit that another version of the library adds shows here. A library that
is not installed is skipped.

  $ HERMETIC=$(ocamlfind query hermetic)
  $ for lib in eio.unix eio_posix eio_linux eio_windows eio_main iomux; do
  >   dir=$(ocamlfind query "$lib" 2> /dev/null) || continue
  >   for cmi in "$dir"/*.cmi; do
  >     unit=$(basename "$cmi" .cmi | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }')
  >     printf 'open! Hermetic\nmodule _ = %s\n' "$unit" > use.ml
  >     ocamlc -I "$HERMETIC" -c use.ml 2>&1 |
  >       grep -qx "Alert ambient: module Hermetic.$unit" ||
  >       echo "$lib: $unit is not declared empty"
  >   done
  > done
