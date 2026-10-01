(* The prelude changes what compiles, never what runs: a value it keeps is the
   standard library's or Fmt's own, the same closure or constant, so a library
   compiled against it behaves as it would against the original. A prelude
   that wrapped, copied or stubbed a kept value fails these. What it refuses
   is shown by the cram pages, since a refusal is a compile error. *)

let same name kept original =
  Alcotest.(check bool) (name ^ " is the original") true (kept == original)

let test_kept_values_are_the_originals () =
  same "List.map" Hermetic.List.map Stdlib.List.map;
  same "String.concat" Hermetic.String.concat Stdlib.String.concat;
  same "Buffer.add_string" Hermetic.Buffer.add_string Stdlib.Buffer.add_string;
  same "Option.map" Hermetic.Option.map Stdlib.Option.map;
  same "Random.State.make" Hermetic.Random.State.make Stdlib.Random.State.make;
  same "Hashtbl.replace" Hermetic.Hashtbl.replace Stdlib.Hashtbl.replace;
  same "Filename.extension" Hermetic.Filename.extension
    Stdlib.Filename.extension;
  same "In_channel.input_all" Hermetic.In_channel.input_all
    Stdlib.In_channel.input_all;
  same "Fmt.str" Hermetic.Fmt.str Fmt.str;
  same "Fmt.pf" Hermetic.Fmt.pf Fmt.pf

let test_kept_constants_are_the_originals () =
  Alcotest.(check int)
    "Sys.word_size" Stdlib.Sys.word_size Hermetic.Sys.word_size;
  Alcotest.(check int)
    "Sys.max_string_length" Stdlib.Sys.max_string_length
    Hermetic.Sys.max_string_length;
  Alcotest.(check bool)
    "Sys.big_endian" Stdlib.Sys.big_endian Hermetic.Sys.big_endian;
  Alcotest.(check string) "Sys.os_type" Stdlib.Sys.os_type Hermetic.Sys.os_type

let suite =
  ( "hermetic",
    [
      Alcotest.test_case "kept values are the originals" `Quick
        test_kept_values_are_the_originals;
      Alcotest.test_case "kept constants are the originals" `Quick
        test_kept_constants_are_the_originals;
    ] )
