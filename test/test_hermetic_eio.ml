(* The Eio prelude changes what compiles, never what runs: a value it keeps is
   the standard library's own, the same closure, so a library compiled against
   it behaves as it would against the original. A prelude that wrapped, copied
   or stubbed a kept value fails these. What it refuses is shown by eio.t,
   since a refusal is a compile error. *)

let same name kept original =
  Alcotest.(check bool) (name ^ " is the original") true (kept == original)

let test_kept_values_are_the_originals () =
  same "List.map" Hermetic_eio.List.map Stdlib.List.map;
  same "Hashtbl.iter" Hermetic_eio.Hashtbl.iter Stdlib.Hashtbl.iter;
  same "Atomic.make" Hermetic_eio.Atomic.make Stdlib.Atomic.make;
  same "Random.int" Hermetic_eio.Random.int Stdlib.Random.int;
  same "Filename.concat" Hermetic_eio.Filename.concat Stdlib.Filename.concat;
  same "In_channel.input_all" Hermetic_eio.In_channel.input_all
    Stdlib.In_channel.input_all;
  same "Out_channel.output_string" Hermetic_eio.Out_channel.output_string
    Stdlib.Out_channel.output_string;
  same "Digest.string" Hermetic_eio.Digest.string Stdlib.Digest.string;
  same "Buffer.add_string" Hermetic_eio.Buffer.add_string
    Stdlib.Buffer.add_string

let test_kept_constants_are_the_originals () =
  Alcotest.(check int)
    "Sys.word_size" Stdlib.Sys.word_size Hermetic_eio.Sys.word_size;
  Alcotest.(check string)
    "Sys.os_type" Stdlib.Sys.os_type Hermetic_eio.Sys.os_type

let suite =
  ( "hermetic_eio",
    [
      Alcotest.test_case "kept values are the originals" `Quick
        test_kept_values_are_the_originals;
      Alcotest.test_case "kept constants are the originals" `Quick
        test_kept_constants_are_the_originals;
    ] )
