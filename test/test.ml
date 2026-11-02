(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The prelude changes what compiles, never what runs: every value it keeps is
   the standard library's own closure, reached through an alias or an
   include, so a library compiled against it behaves as it would against the
   original. A prelude that wrapped or copied a kept value fails these. The
   values compared are functions, not primitives, since a primitive used as a
   value is a fresh closure at each use. What it refuses is shown by the cram
   tests, since a refusal is a type error. *)

let same name kept original =
  Alcotest.(check bool) (name ^ " is the original") true (kept == original)

let test_restated_modules () =
  same "String.concat" Hermetic.String.concat Stdlib.String.concat;
  same "Bytes.to_string" Hermetic.Bytes.to_string Stdlib.Bytes.to_string;
  same "Hashtbl.replace" Hermetic.Hashtbl.replace Stdlib.Hashtbl.replace;
  same "Hashtbl.iter" Hermetic.Hashtbl.iter Stdlib.Hashtbl.iter;
  same "Random.State.make" Hermetic.Random.State.make Stdlib.Random.State.make;
  same "Filename.extension" Hermetic.Filename.extension
    Stdlib.Filename.extension;
  same "In_channel.input_all" Hermetic.In_channel.input_all
    Stdlib.In_channel.input_all;
  same "Printexc.to_string" Hermetic.Printexc.to_string
    Stdlib.Printexc.to_string

let test_kept_modules () =
  same "Stdlib.List.map" Hermetic.Stdlib.List.map Stdlib.List.map;
  same "Stdlib.Buffer.add_string" Hermetic.Stdlib.Buffer.add_string
    Stdlib.Buffer.add_string;
  same "Out_channel.output_string" Hermetic.Out_channel.output_string
    Stdlib.Out_channel.output_string;
  same "StdLabels.List.map" Hermetic.StdLabels.List.map
    Stdlib.StdLabels.List.map

let test_kept_values () =
  same "Stdlib.string_of_int" Hermetic.Stdlib.string_of_int Stdlib.string_of_int;
  same "Stdlib.( @ )" Hermetic.Stdlib.( @ ) Stdlib.( @ );
  same "Stdlib.output_string" Hermetic.Stdlib.output_string Stdlib.output_string;
  same "Random.int" Hermetic.Random.int Stdlib.Random.int

let test_constants () =
  Alcotest.(check int)
    "Sys.word_size" Stdlib.Sys.word_size Hermetic.Sys.word_size;
  Alcotest.(check string) "Sys.os_type" Stdlib.Sys.os_type Hermetic.Sys.os_type

let test_original () =
  same "Stdlib_original.Sys.getenv_opt" Hermetic.Stdlib_original.Sys.getenv_opt
    Stdlib.Sys.getenv_opt

let prelude =
  ( "prelude",
    [
      Alcotest.test_case "restated modules keep the originals" `Quick
        test_restated_modules;
      Alcotest.test_case "kept modules are the originals" `Quick
        test_kept_modules;
      Alcotest.test_case "kept values are the originals" `Quick test_kept_values;
      Alcotest.test_case "kept constants are the originals" `Quick
        test_constants;
      Alcotest.test_case "Stdlib_original is the standard library" `Quick
        test_original;
    ] )

let () = Alcotest.run "hermetic" [ prelude; Test_plan.suite ]
