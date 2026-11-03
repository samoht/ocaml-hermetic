(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* Generates the prelude from the policy and the installed standard library.

   gen STDLIB DIR        writes the prelude's files into DIR.
   gen --strict STDLIB   checks that the policy has reviewed every name of
                         STDLIB, names nothing STDLIB lacks but should have,
                         and keeps no value that hands out a channel without
                         taking one, unless it is reviewed as such.
   gen --review STDLIB   prints the names of STDLIB the policy keeps, to merge
                         into reviewed.ml.
   gen --absent STDLIB   prints the refusals whose path STDLIB lacks.
   gen --dump STDLIB     prints every name of STDLIB.
   gen --list            prints the refusals, one per line.
   gen --uses STDLIB     prints each refused value of STDLIB and its type.
   gen --dune            prints the dune rule that runs the generator. *)

open Hermetic_gen

let fail fmt = Printf.ksprintf failwith fmt

(* The prelude declares these names; the standard library must not. *)
let check_names (tree : Stdlib_tree.t) =
  List.iter
    (fun (t, _) ->
      if List.mem t [ "ambient"; "unsafe"; "unreviewed" ] then
        fail "Stdlib declares the type %s, which the prelude declares" t)
    tree.types;
  List.iter
    (fun (m, _) ->
      if m = "Unsafe" || String.starts_with ~prefix:Policy.name m then
        fail "Stdlib declares the module %s, which the prelude declares" m)
    tree.modules

let write stdlib dir =
  let tree = Stdlib_tree.read stdlib in
  check_names tree;
  let plan, _ = Plan.v tree in
  List.iter
    (fun (name, contents) ->
      if not (List.mem name Emit.file_names) then
        fail "%s is not a file the dune rule declares: run gen --dune" name;
      let oc = open_out_bin (Filename.concat dir name) in
      output_string oc contents;
      close_out oc)
    (Emit.files plan)

let absent tree =
  List.filter_map
    (fun (path, _) -> if Stdlib_tree.mem tree path then None else Some path)
    Policy.refusals

let strict stdlib =
  let tree = Stdlib_tree.read stdlib in
  let _, unreviewed = Plan.v tree in
  let mistakes = Plan.mistakes tree in
  let channels = Plan.channels tree in
  let spelled path =
    let head = List.hd (String.split_on_char '.' path) in
    if List.mem_assoc head tree.modules && not (List.mem head tree.in_stdlib)
    then path
    else "Stdlib." ^ path
  in
  List.iter
    (fun p -> Printf.eprintf "%s is not reviewed\n" (spelled p))
    unreviewed;
  List.iter
    (fun p ->
      Printf.eprintf "%s is kept, but hands out a channel without taking one\n"
        (spelled p))
    channels;
  List.iter
    (Printf.eprintf "%s is refused, but no supported compiler has it\n")
    mistakes;
  if unreviewed <> [] then
    prerr_endline
      "Review each name: refuse it in lib/gen/policy.ml or keep it in \
       lib/gen/reviewed.ml.";
  if channels <> [] then
    prerr_endline
      "Refuse each value that hands out a channel in lib/gen/policy.ml, or \
       review it in Reviewed.channels if it makes the channel from what it is \
       handed.";
  if unreviewed <> [] || mistakes <> [] || channels <> [] then exit 1

(* The names the policy keeps, one per line: [M path] for a module, [V path
   name] for a value or a class. A module the policy refuses as a whole is
   not listed, and neither is a value it refuses or names, nor a value whose
   name says [unsafe], which only an entry of the policy can keep. *)
let review stdlib =
  let tree = Stdlib_tree.read stdlib in
  let refused p = List.mem_assoc p Policy.refusals in
  let unsafe v =
    let n = String.length v in
    let rec go i = i + 6 <= n && (String.sub v i 6 = "unsafe" || go (i + 1)) in
    go 0
  in
  let join p n = if p = "" then n else p ^ "." ^ n in
  let rec walk p = function
    | Stdlib_tree.Sig items ->
        List.iter
          (function
            | Stdlib_tree.Value v | Class v ->
                if not (refused (join p v) || unsafe v) then
                  Printf.printf "V %s %s\n" p v
            | Module (m, Node n) -> module_ (join p m) n
            | Module (_, (Alias _ | Dotted _))
            | Type _ | Module_type _ | Class_type _ ->
                ())
          items
    | Functor { result; _ } -> walk p result
    | Opaque _ -> ()
  and module_ p n =
    if not (refused p) then (
      Printf.printf "M %s\n" p;
      walk p n)
  in
  List.iter
    (fun v -> if not (refused v) then Printf.printf "V  %s\n" v)
    tree.values;
  List.iter (fun (m, n) -> module_ m n) tree.modules

(* A use of each refused value the installed compiler has, one per line with
   the type of its refusal, for a test to compile. A value of a functor's
   result cannot be named, so it is left out. *)
let uses stdlib =
  let plan, _ = Plan.v (Stdlib_tree.read stdlib) in
  let join p n = if p = "" then n else p ^ "." ^ n in
  let rec items p =
    List.iter (function
      | Plan.Refused (v, r) ->
          Printf.printf "%s %s\n" (join p v) (Policy.kind_name r.kind)
      | Plan.Sub (m, (Plan.Sig { items = is; _ } | Plan.Whole (_, is))) ->
          items (join p m) is
      | Plan.Sub (_, (Plan.Functor _ | Plan.Gone))
      | Plan.Retyped _ | Plan.Removed _ | Plan.Rewired _ ->
          ())
  in
  items "" plan.values;
  List.iter (fun (m, t) -> items "" [ Plan.Sub (m, t) ]) plan.modules

let list () =
  List.map
    (fun (path, entry) ->
      match entry with
      | Policy.Value r -> Printf.sprintf "%s: %s" path (Policy.kind_name r.kind)
      | Policy.Module r ->
          Printf.sprintf "%s.*: %s" path (Policy.kind_name r.kind)
      | Policy.Retyped _ -> Printf.sprintf "%s: retyped" path
      | Policy.Keep _ -> Printf.sprintf "%s: kept" path)
    Policy.refusals
  @ List.map (fun (m, _) -> m ^ ": ambient, declared empty") Policy.shadowed
  |> List.sort_uniq String.compare
  |> List.iter print_endline

let main () =
  match List.tl (Array.to_list Sys.argv) with
  | [ "--strict"; stdlib ] -> strict stdlib
  | [ "--review"; stdlib ] -> review stdlib
  | [ "--absent"; stdlib ] ->
      List.iter print_endline (absent (Stdlib_tree.read stdlib))
  | [ "--dump"; stdlib ] ->
      Format.printf "%a@." Stdlib_tree.pp (Stdlib_tree.read stdlib)
  | [ "--list" ] -> list ()
  | [ "--uses"; stdlib ] -> uses stdlib
  | [ "--dune" ] -> print_string (Emit.dune ~gen:"%{exe:gen/gen.exe}")
  | [ stdlib; dir ] -> write stdlib dir
  | _ ->
      prerr_endline
        "usage: gen STDLIB DIR | gen (--strict | --review | --absent | --dump \
         | --uses) STDLIB | gen --list | gen --dune";
      exit 2

(* An error of the compiler's libraries, such as a compiled interface of
   another version, is reported as the compiler reports it. *)
let () =
  match main () with
  | () -> ()
  | exception ((Cmi_format.Error _ | Persistent_env.Error _ | Env.Error _) as e)
    ->
      Location.report_exception Format.err_formatter e;
      exit 2
  | exception Failure msg ->
      prerr_endline ("gen: " ^ msg);
      exit 2
