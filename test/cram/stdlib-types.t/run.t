The prelude refuses a value by its type and keeps every type of the standard
library, so a library whose source files open Hermetic and whose interfaces
do not exports only standard library types. A consumer that sees only the
library's compiled interfaces, as an mdx toplevel or a downstream package
without hermetic in its path does, uses its values with the standard library.

  $ HERMETIC=$(ocamlfind query hermetic)
  $ mkdir producer consumer
  $ cat > producer/produced.mli <<'EOF'
  > val formatter : Buffer.t -> Format.formatter
  > val table : unit -> (string, int) Hashtbl.t
  > val flags : open_flag list
  > val message : (unit, Format.formatter, unit) format
  > val digest : string -> Digest.t
  > val bytes : int -> (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t
  > val state : int -> Random.State.t
  > val result : (int, string) result
  > val cell : int ref
  > val read : in_channel -> char
  > EOF
  $ cat > producer/produced.ml <<'EOF'
  > open! Hermetic
  > let formatter b = Format.formatter_of_buffer b
  > let table () : (string, int) Hashtbl.t = Hashtbl.create 1
  > let flags : open_flag list = [ Open_rdonly ]
  > let message : (unit, Format.formatter, unit) format = "done"
  > let digest s : Digest.t = Digest.string s
  > let bytes n = Bigarray.Array1.create Bigarray.char Bigarray.c_layout n
  > let state seed : Random.State.t = Random.State.make [| seed |]
  > let result = Ok 1
  > let cell = ref 0
  > let read ic = input_char ic
  > EOF
  $ ocamlc -I "$HERMETIC" -I producer -c producer/produced.mli
  $ ocamlc -I "$HERMETIC" -I producer -c producer/produced.ml
  $ cat > consumer/consumer.ml <<'EOF'
  > let () = Format.fprintf (Produced.formatter (Buffer.create 1)) "x"
  > let () = Hashtbl.replace (Produced.table ()) "a" 1
  > let _ = List.mem Open_rdonly Produced.flags
  > let () = Format.printf Produced.message
  > let _ = Digest.to_hex (Produced.digest "")
  > let _ = Bigarray.Array1.dim (Produced.bytes 1)
  > let _ = Random.State.int (Produced.state 1) 3
  > let () = match Produced.result with Ok _ | Error _ -> ()
  > let () = incr Produced.cell
  > let _ = Produced.read stdin
  > EOF
  $ ocamlc -I producer -c consumer/consumer.ml; echo "exit $?"
  exit 0

A source file with no interface exports the types its values have. A type it
infers is the standard library's, and so is a type it names through a module
the prelude keeps. A type it names through a module the prelude restates,
such as Digest.t, is the prelude's, and so is a constructor or a record field
of such a module: its consumer needs hermetic in its path too. So does every
interface of a library compiled with -open Hermetic as a flag. An interface
for each source file, which does not open the prelude, avoids both.

  $ mkdir bare
  $ cat > bare/bare.ml <<'EOF'
  > open! Hermetic
  > let digest = Digest.string ""
  > let table () = Hashtbl.create 1
  > let formatter = Format.formatter_of_buffer (Buffer.create 1)
  > let state = Random.State.make [| 1 |]
  > let buffer : Buffer.t = Buffer.create 1
  > let either : (int, string) Either.t = Either.Left 1
  > let named : Digest.t = Digest.string ""
  > let signal = Sys.Signal_ignore
  > EOF
  $ ocamlc -I "$HERMETIC" -I bare -c bare/bare.ml
  $ cat > consumer/inferred.ml <<'EOF'
  > let _ = Digest.to_hex Bare.digest
  > let () = Hashtbl.replace (Bare.table ()) "a" 1
  > let () = Format.fprintf Bare.formatter "x"
  > let _ = Random.State.bool Bare.state
  > let _ = Buffer.contents Bare.buffer
  > let _ = Either.is_left Bare.either
  > EOF
  $ ocamlc -I bare -c consumer/inferred.ml; echo "exit $?"
  exit 0
  $ echo 'let _ = Digest.to_hex Bare.named' > consumer/named.ml
  $ ocamlc -I bare -c consumer/named.ml 2>&1 | tr -d '"' | grep -o 'Hermetic.Digest.t is abstract'
  Hermetic.Digest.t is abstract
  $ echo 'let _ = Bare.signal = Sys.Signal_ignore' > consumer/constructor.ml
  $ ocamlc -I bare -c consumer/constructor.ml 2>&1 | tr -d '"' | grep -o 'Hermetic.Sys.signal_behavior is abstract'
  Hermetic.Sys.signal_behavior is abstract
  $ ocamlc -I bare -I "$HERMETIC" -c consumer/named.ml consumer/constructor.ml; echo "exit $?"
  exit 0

  $ mkdir flagged
  $ echo 'val digest : string -> Digest.t' > flagged/flagged.mli
  $ ocamlc -I "$HERMETIC" -open Hermetic -c flagged/flagged.mli
  $ echo 'let _ = Digest.to_hex (Flagged.digest "")' > consumer/use_flagged.ml
  $ ocamlc -I flagged -c consumer/use_flagged.ml 2>&1 | tr -d '"' | grep -o 'Hermetic.Digest.t is abstract'
  Hermetic.Digest.t is abstract
