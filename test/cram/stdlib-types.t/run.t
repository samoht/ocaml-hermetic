The Hermetic prelude exports canonical ordinary standard-library types. Each
producer sees the Hermetic prelude; each consumer sees only that producer and
the compiler's standard library.

  $ OCAMLC=$(command -v ocamlc); HERMETIC_CMI=$(ocamlfind query hermetic)
  $ mkdir producer consumer
  $ cat > producer/produced_result.ml <<'EOF'
  > let value : (int, string) result = Ok 1
  > EOF
  $ cat > producer/produced_ref.ml <<'EOF'
  > let value = ref 0
  > EOF
  $ cat > producer/produced_input.ml <<'EOF'
  > let read (ic : in_channel) = input_char ic
  > EOF
  $ cat > producer/produced_output.ml <<'EOF'
  > let write (oc : out_channel) = output_char oc 'x'
  > EOF
  $ for source in producer/*.ml; do
  >   name=$(basename "$source" .ml); "$OCAMLC" -I "$HERMETIC_CMI" -open Hermetic -c -o "producer/$name.cmo" "$source" || exit
  > done
  $ cat > consumer/result.ml <<'EOF'
  > let value = match Produced_result.value with Ok _ -> true | Error _ -> false
  > EOF
  $ cat > consumer/ref_value.ml <<'EOF'
  > let () = incr Produced_ref.value
  > EOF
  $ cat > consumer/input.ml <<'EOF'
  > let read (ic : in_channel) = Produced_input.read ic
  > EOF
  $ cat > consumer/output.ml <<'EOF'
  > let write (oc : out_channel) = Produced_output.write oc
  > EOF
  $ for source in consumer/*.ml; do
  >   if "$OCAMLC" -I producer -c "$source" 2>&1; then echo 'consumer exit: 0'; else echo "consumer exit: $?"; fi
  > done
  File "consumer/input.ml", line 1, characters 49-51:
  1 | let read (ic : in_channel) = Produced_input.read ic
                                                       ^^
  Error: The value ic has type in_channel
         but an expression was expected of type Hermetic.in_channel
         Type Hermetic.in_channel is abstract because no corresponding cmi file
         was found in path.
  consumer exit: 2
  File "consumer/output.ml", line 1, characters 53-55:
  1 | let write (oc : out_channel) = Produced_output.write oc
                                                           ^^
  Error: The value oc has type out_channel
         but an expression was expected of type Hermetic.out_channel
         Type Hermetic.out_channel is abstract because no corresponding
         cmi file was found in path.
  consumer exit: 2
  File "consumer/ref_value.ml", line 1, characters 14-32:
  1 | let () = incr Produced_ref.value
                    ^^^^^^^^^^^^^^^^^^
  Error: The value Produced_ref.value has type int Hermetic.ref
         but an expression was expected of type int ref
         Type Hermetic.ref is abstract because no corresponding cmi file
         was found in path.
  consumer exit: 2
  File "consumer/result.ml", line 1, characters 45-49:
  1 | let value = match Produced_result.value with Ok _ -> true | Error _ -> false
                                                   ^^^^
  Error: This pattern matches values of type ('a, 'b) result
         but a pattern was expected which matches values of type
           (int, string) Hermetic.result
         Type Hermetic.result is abstract because no corresponding cmi file
         was found in path.
  consumer exit: 2
