hermetic-check reads the compiled units of a library meant to be hermetic and
refuses what the prelude cannot: a unit compiled without it, a unit under which
its alert is not an error, an attribute that makes the alert a warning again, a
unit of the standard library named past the prelude, and an external
declaration, which names a primitive directly.

  $ cat > dune-project <<EOF
  > (lang dune 3.21)
  > EOF
  $ unit () {
  >   mkdir -p "$1"
  >   printf '(library (name %s) (libraries hermetic %s) (flags (:standard %s)))\n' \
  >     "$1" "$2" "$3" > "$1/dune"
  >   cat > "$1/$1.ml"
  > }
  $ cmt () { echo "_build/default/$1/.$1.objs/byte/$1.cmt"; }
  $ check () {
  >   hermetic-check "$@"
  >   echo "exit $?"
  > }

A unit compiled with the prelude and its alert fatal passes.

  $ unit good "" "-open Hermetic -alert @ambient" <<EOF
  > let words = List.length [ Sys.word_size ]
  > EOF

A unit compiled without the prelude is refused, and so is one where the
alert is a warning: there, Sys.getenv would build.

  $ unit plain "" "" <<EOF
  > let home = Sys.getenv "HOME"
  > EOF
  $ unit warning "" "-open Hermetic" <<EOF
  > let home = Sys.getenv "HOME"
  > EOF

The alert options are replayed in order, as the compiler applies them: a
later -alert -ambient undoes an earlier @ambient, and the reverse does not.

  $ unit undone "" "-open Hermetic -alert @ambient -alert -ambient" <<EOF
  > let x = 1
  > EOF
  $ unit redone "" "-open Hermetic -alert -ambient -alert @ambient" <<EOF
  > let x = 1
  > EOF

An external declaration names a primitive the prelude cannot shadow, wherever
it is: at the top, in a submodule, in a local module, in a functor's body, in
a signature, and for the compiler's own primitives too.

  $ unit externals "" "-open Hermetic -alert @ambient" <<EOF
  > external getenv : string -> string = "caml_sys_getenv"
  > module M = struct
  >   external time : unit -> float = "caml_sys_time"
  > end
  > let cast x = let module C = struct external magic : 'a -> 'b = "%identity" end in C.magic x
  > module F (X : sig end) = struct external argv : unit -> string array = "%sys_argv" end
  > module type S = sig external exit : int -> 'a = "caml_sys_exit" end
  > EOF

An [@alert] attribute sets alerts for its scope, over the command line: on
the whole file, on one item, on one expression, for every alert at once, or
leaving ambient enabled but no longer an error. Each is refused where the
ambient alert ends up a warning, and one that keeps it an error, or that
declares an alert of the unit's own, is not.

  $ unit silenced "" "-open Hermetic -alert @ambient" <<EOF
  > [@@@alert "-ambient"]
  > let home = Sys.getenv "HOME" [@@alert "-ambient"]
  > let time () = (Sys.time [@alert "-all"]) ()
  > let argv = Sys.executable_name [@@ocaml.alert "--ambient"]
  > let kept = Sys.word_size [@@alert "+ambient"]
  > let own = 1 [@@alert unstable "The unit's own alert."]
  > EOF

A unit of the standard library named by its own name is reached past the
prelude, by a value, an alias, an open, a functor argument or a first-class
module.

  $ unit units "" "-open Hermetic -alert @ambient" <<EOF
  > let home = Stdlib__Sys.getenv "HOME"
  > module S = Stdlib__Sys
  > open Stdlib__In_channel
  > module F (X : sig val word_size : int end) = struct let w = X.word_size end
  > module M = F (Stdlib__Sys)
  > module type W = sig val word_size : int end
  > let m = (module Stdlib__Sys : W)
  > EOF

Everything builds, the unit where the alert is a warning included.

  $ dune build --root . --display quiet --profile release 2> build.log; echo "exit $?"
  exit 0
  $ grep '^Alert' build.log | sort -u
  Alert ambient: Hermetic.Sys.getenv
  $ check $(cmt good)
  exit 0
  $ check $(cmt plain)
  plain/plain.ml: compiled without -open Hermetic
  plain/plain.ml: compiled without -alert @ambient
  exit 1
  $ check $(cmt warning)
  warning/warning.ml: compiled without -alert @ambient
  exit 1
  $ check $(cmt undone) $(cmt redone)
  undone/undone.ml: compiled without -alert @ambient
  exit 1
  $ check $(cmt silenced)
  silenced/silenced.ml: line 1: [@alert "-ambient"] makes the ambient alert a warning
  silenced/silenced.ml: line 2: [@alert "-ambient"] makes the ambient alert a warning
  silenced/silenced.ml: line 3: [@alert "-all"] makes the ambient alert a warning
  silenced/silenced.ml: line 4: [@alert "--ambient"] makes the ambient alert a warning
  exit 1
  $ check $(cmt units)
  units/units.ml: line 1: Stdlib__Sys names a unit of the standard library past the prelude
  units/units.ml: line 2: Stdlib__Sys names a unit of the standard library past the prelude
  units/units.ml: line 3: Stdlib__In_channel names a unit of the standard library past the prelude
  units/units.ml: line 5: Stdlib__Sys names a unit of the standard library past the prelude
  units/units.ml: line 7: Stdlib__Sys names a unit of the standard library past the prelude
  exit 1
  $ check $(cmt externals)
  externals/externals.ml: line 1: external getenv declares the primitive "caml_sys_getenv"
  externals/externals.ml: line 3: external time declares the primitive "caml_sys_time"
  externals/externals.ml: line 5: external magic declares the primitive "%identity"
  externals/externals.ml: line 6: external argv declares the primitive "%sys_argv"
  externals/externals.ml: line 7: external exit declares the primitive "caml_sys_exit"
  exit 1

A library may hold the ambient values of another of its dependencies in a
prelude of its own; --open requires the units to open it too.

  $ unit extra "" "" <<EOF
  > let x = 1
  > EOF
  $ unit both "extra" "-open Hermetic -open Extra -alert @ambient" <<EOF
  > let y = x
  > EOF
  $ dune build --root . --display quiet --profile release
  $ check --open Extra $(cmt both)
  exit 0
  $ check --open Extra $(cmt good)
  good/good.ml: compiled without -open Extra
  exit 1

A file that is not the .cmt of an implementation is refused, never passed.

  $ echo 'not a cmt' > junk.cmt
  $ check junk.cmt
  junk.cmt: unreadable: not a .cmt file of this compiler
  exit 1
  $ unit sig "" "-open Hermetic -alert @ambient" <<EOF
  > let x = 1
  > EOF
  $ echo 'val x : int' > sig/sig.mli
  $ dune build --root . --display quiet --profile release
  $ check _build/default/sig/.sig.objs/byte/sig.cmti
  sig/sig.mli: unreadable: not the .cmt of an implementation
  exit 1
