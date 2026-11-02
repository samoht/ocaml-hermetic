(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The fail-closed paths of the generator, on the small standard library of
   fake/, which has the shapes the real one lacks today. *)

open Hermetic_gen

let tree = lazy (Stdlib_tree.read "fake")

let module_ name =
  match List.assoc_opt name (Lazy.force tree).modules with
  | Some n -> n
  | None -> Alcotest.failf "no module %s" name

let without names (t : Stdlib_tree.t) =
  {
    t with
    modules = List.filter (fun (m, _) -> not (List.mem m names)) t.modules;
  }

let reviewed : Policy.reviewed =
  {
    modules =
      [ "List"; "Random"; "Random.State"; "Random.Fresh"; "Classy"; "Typed" ];
    kept =
      [
        ( "",
          [
            "stderr";
            "err_functions";
            "err_output";
            "with_err";
            "formatter_of_out_channel";
            "formatter_of_string";
            "output_string";
            "origin";
          ] );
        ("List", [ "map"; "unsafe_peek" ]);
        ("Random.State", [ "make" ]);
        ("Random.Fresh", [ "v" ]);
        ("Classy", [ "c"; "v" ]);
      ];
    channels = [];
  }

let ambient message = Policy.Value { kind = Ambient; message }
let refusals = [ ("Random.int", ambient "Draws.") ]
let plan ?(refusals = refusals) tree = Plan.v ~refusals ~reviewed tree

let item_name = function
  | Plan.Refused (v, r) -> v ^ ":" ^ Policy.kind_name r.kind
  | Plan.Retyped { name; _ } -> name ^ ":retyped"
  | Plan.Removed m -> m ^ ":removed"
  | Plan.Sub (m, _) -> m ^ ":restated"
  | Plan.Rewired (m, t) -> m ^ ":" ^ t

let items = function
  | Plan.Sig { items; _ } | Plan.Whole (_, items) | Plan.Functor { items; _ } ->
      List.map item_name items
  | Plan.Gone -> []

let restated (p : Plan.prelude) m =
  match List.assoc_opt m p.modules with
  | Some t -> items t
  | None -> Alcotest.failf "%s is not restated" m

let strings = Alcotest.(list string)

let item_text = function
  | Stdlib_tree.Value v -> "val " ^ v
  | Class c -> "class " ^ c
  | Class_type c -> "class type " ^ c
  | Type (t, _) -> "type " ^ t
  | Module_type m -> "module type " ^ m
  | Module (m, Alias a) -> "module " ^ m ^ " = " ^ a
  | Module (m, Dotted (a, _)) -> "module " ^ m ^ " = " ^ a
  | Module (m, Node (Stdlib_tree.Opaque why)) ->
      "module " ^ m ^ " (" ^ why ^ ")"
  | Module (m, Node _) -> "module " ^ m

let names = function
  | Stdlib_tree.Sig items -> List.map item_text items
  | _ -> []

let test_reading () =
  Alcotest.check strings "Odd"
    [
      "module R = Random.State";
      "module Gen (generative functor)";
      "module Anon (functor of an anonymous parameter)";
      "module type A";
      "module Abs (abstract module type)";
      "val mod";
      "module Sub";
      "module L = Labels";
    ]
    (names (module_ "Odd"));
  Alcotest.check strings "Classy"
    [ "class c"; "type c"; "val v" ]
    (names (module_ "Classy"));
  Alcotest.check strings "Typed"
    [ "class type ct"; "type ct"; "val w" ]
    (names (module_ "Typed"))

let test_unreviewed () =
  let p, unreviewed = plan (without [ "Classy" ] (Lazy.force tree)) in
  Alcotest.check strings "unreviewed"
    [
      "Labels";
      "List.new_thing";
      "List.unsafe_peek";
      "Odd";
      "Random.Fresh";
      "Stray";
      "Typed.w";
    ]
    unreviewed;
  Alcotest.check strings "a new value, and one named unsafe, of a kept module"
    [ "new_thing:unreviewed"; "unsafe_peek:unreviewed" ]
    (restated p "List");
  Alcotest.check strings "a refusal, and a reviewed functor gone opaque"
    [ "Fresh:removed"; "int:ambient" ]
    (restated p "Random");
  Alcotest.check strings "a new module, refused, its opaque parts removed"
    [
      "Gen:removed";
      "Anon:removed";
      "Abs:removed";
      "mod:unreviewed";
      "Sub:restated";
      "L:Labels";
    ]
    (restated p "Odd");
  Alcotest.check strings "a module with a class type" [ "w:unreviewed" ]
    (restated p "Typed");
  Alcotest.check strings "a unit that Stdlib does not name" [ "v:unreviewed" ]
    (restated p "Stray")

let test_rewired () =
  let refusals = refusals @ [ ("Random.State.make", ambient "Makes.") ] in
  let p, _ = plan ~refusals (without [ "Classy" ] (Lazy.force tree)) in
  Alcotest.(check bool)
    "an alias of a restated submodule is rewired" true
    (List.mem "R:Random.State" (restated p "Odd"))

let test_class () =
  let reviewed = { reviewed with kept = [ ("Classy", [ "c" ]) ] } in
  let only =
    { (Lazy.force tree) with modules = [ ("Classy", module_ "Classy") ] }
  in
  match Plan.v ~refusals ~reviewed only with
  | _ -> Alcotest.fail "a module with a class was restated"
  | exception Failure msg ->
      Alcotest.(check bool)
        "names the class" true
        (String.ends_with ~suffix:"the class c, which cannot be restated" msg)

let contains text contents =
  let n = String.length text in
  let rec go i =
    i + n <= String.length contents
    && (String.sub contents i n = text || go (i + 1))
  in
  go 0

let test_emitted () =
  let p, _ = plan (without [ "Classy" ] (Lazy.force tree)) in
  let files = Emit.files p in
  let has file text =
    Alcotest.(check bool)
      (file ^ " has " ^ text)
      true
      (contains text (List.assoc file files))
  in
  has "hermetic.mli" "module Odd = Hermetic__Unreviewed.Odd";
  has "hermetic__Unreviewed.mli" "val ( mod ) : Hermetic__Refused.unreviewed";
  has "hermetic__Unreviewed.mli" "[@@alert unreviewed";
  has "hermetic__Unreviewed.mli" "module Gen := Stdlib.Odd.Gen";
  has "hermetic__Random.mli" "val int : Hermetic__Refused.ambient"

(* The generated prelude compiles against the small standard library. *)
let test_compiles () =
  let ocamlc =
    match Sys.getenv_opt "OCAMLC" with Some c -> c | None -> "ocamlc"
  in
  let p, _ = plan (without [ "Classy" ] (Lazy.force tree)) in
  let dir = Filename.temp_dir "hermetic" "fake" in
  List.iter
    (fun (name, contents) ->
      Out_channel.with_open_bin (Filename.concat dir name) (fun oc ->
          output_string oc contents))
    (Emit.files p);
  let compile file =
    let log = Filename.concat dir "log" in
    Sys.command
      (Filename.quote_command ocamlc ~stdout:log ~stderr:log
         [
           "-nostdlib";
           "-I";
           "fake";
           "-I";
           dir;
           "-no-alias-deps";
           "-w";
           "-a";
           "-c";
           Filename.concat dir file;
         ])
    = 0
  in
  let interfaces, implementations =
    List.partition
      (fun f -> Filename.check_suffix f ".mli")
      (List.map fst (Emit.files p))
  in
  (* Each round compiles what the previous rounds made possible. *)
  let rec rounds pending =
    let left = List.filter (fun f -> not (compile f)) pending in
    if left = [] || List.length left = List.length pending then left
    else rounds left
  in
  Alcotest.check strings "interfaces that do not compile" [] (rounds interfaces);
  Alcotest.check strings "implementations that do not compile" []
    (rounds implementations)

let test_keyword_operators () =
  List.iter
    (fun op ->
      Alcotest.(check string) op ("( " ^ op ^ " )") (Emit.value_name op))
    [ "or"; "mod"; "land"; "lor"; "lxor"; "lsl"; "lsr"; "asr"; "+"; "let*" ];
  Alcotest.(check string) "a name" "map" (Emit.value_name "map")

let test_mistakes () =
  let refusals = refusals @ [ ("List.mpa", ambient "Typo.") ] in
  Alcotest.check strings "a typo" [ "List.mpa" ]
    (Plan.mistakes ~refusals ~version_specific:[] (Lazy.force tree));
  Alcotest.check strings "a path a supported compiler lacks" []
    (Plan.mistakes ~refusals ~version_specific:[ "List.mpa" ] (Lazy.force tree))

(* A value that hands out a channel, a formatter, or a record or a tuple of
   output closures, and takes none, is flagged; one that takes a channel as
   an argument is not. A flagged value must be refused or reviewed. *)
let test_channels () =
  let tree = Lazy.force tree in
  Alcotest.check strings "the values that hand out a channel"
    [
      "stderr"; "err_functions"; "err_output"; "with_err"; "formatter_of_string";
    ]
    tree.channels;
  let refusals = refusals @ [ ("stderr", ambient "Writes.") ] in
  let reviewed = { reviewed with channels = [ "formatter_of_string" ] } in
  Alcotest.check strings "the ones neither refused nor reviewed"
    [ "err_functions"; "err_output"; "with_err" ]
    (Plan.channels ~refusals ~reviewed tree)

let suite =
  ( "plan",
    [
      Alcotest.test_case "reading the compiled interfaces" `Quick test_reading;
      Alcotest.test_case "unreviewed names are refused" `Quick test_unreviewed;
      Alcotest.test_case "aliases of restated modules" `Quick test_rewired;
      Alcotest.test_case "a class cannot be restated" `Quick test_class;
      Alcotest.test_case "the emitted units" `Quick test_emitted;
      Alcotest.test_case "the emitted units compile" `Quick test_compiles;
      Alcotest.test_case "keyword operators" `Quick test_keyword_operators;
      Alcotest.test_case "mistakes in the policy" `Quick test_mistakes;
      Alcotest.test_case "values that hand out a channel" `Quick test_channels;
    ] )
