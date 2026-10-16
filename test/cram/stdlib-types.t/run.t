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
  consumer exit: 0
  consumer exit: 0
  consumer exit: 0
  consumer exit: 0
