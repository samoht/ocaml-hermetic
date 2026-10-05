(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

module Library = Project_index.Library
module Package = Project_index.Package

let boundary_tag = "hermetic:eio-boundary"
let prelude = "Hermetic_eio"

let eio_name = function
  | None -> false
  | Some n ->
      String.ends_with ~suffix:"-eio" n || String.ends_with ~suffix:".eio" n

let selected l =
  (not (Library.is_vendored l))
  && String.capitalize_ascii (Library.local_name l) <> prelude
  && (eio_name (Library.public_name l) || List.mem "eio" (Library.deps l))

type ratchet = string list

let err_twice n lib =
  Fmt.kstr (fun s -> Error s) "line %d: %s is listed twice" n lib

let err_one n = Fmt.kstr (fun s -> Error s) "line %d: expected one library" n
let some_str fmt = Fmt.kstr (fun s -> Some s) fmt

let ratchet_of_string s =
  let line (n, acc) l =
    let l =
      match String.index_opt l '#' with Some i -> String.sub l 0 i | None -> l
    in
    match String.split_on_char ' ' l |> List.filter (( <> ) "") with
    | [] -> Ok (n + 1, acc)
    | [ lib ] ->
        if List.mem lib acc then err_twice n lib else Ok (n + 1, lib :: acc)
    | _ -> err_one n
  in
  List.fold_left
    (fun acc l -> Result.bind acc (fun acc -> line acc l))
    (Ok (1, []))
    (String.split_on_char '\n' s)
  |> Result.map (fun (_, acc) -> List.rev acc)

type verdict = {
  library : string;
  boundary : bool;
  reports : Hermetic_check.report list;
}

let objs ~root ~build l =
  let dir =
    match Library.source_dir l with
    | None -> Fpath.v "."
    | Some d -> ( match Fpath.relativize ~root d with Some r -> r | None -> d)
  in
  Fpath.(build // dir / ("." ^ Library.local_name l ^ ".objs") / "byte")

let verdict ~root ~build l =
  let boundary = List.mem boundary_tag (Package.tags (Library.package l)) in
  let dir = objs ~root ~build l in
  let cmts =
    match Sys.readdir (Fpath.to_string dir) with
    | names ->
        Array.to_list names
        |> List.filter (String.ends_with ~suffix:".cmt")
        |> List.sort String.compare
        |> List.map (fun n -> Fpath.(to_string (dir / n)))
    | exception Sys_error _ -> []
  in
  let library = Library.name l in
  match cmts with
  | [] when Library.gated l -> None
  | [] ->
      let why = Fmt.str "no compiled units in %a" Fpath.pp dir in
      Some
        {
          library;
          boundary;
          reports =
            [ { Hermetic_check.name = library; findings = [ Unreadable why ] } ];
        }
  | cmts ->
      Some
        {
          library;
          boundary;
          reports = List.map (Hermetic_check.eio ~boundary) cmts;
        }

let hermetic v =
  List.for_all (fun (r : Hermetic_check.report) -> r.findings = []) v.reports

let judge ratchet verdicts =
  let refuse v =
    match (hermetic v, List.mem v.library ratchet) with
    | true, false | false, true -> []
    | true, true ->
        [ Fmt.str "%s: hermetic, remove it from the ratchet" v.library ]
    | false, false ->
        List.concat_map
          (fun (r : Hermetic_check.report) ->
            List.map
              (fun f ->
                Fmt.str "%s: %s: %a" v.library r.name Hermetic_check.pp_finding
                  f)
              r.findings)
          v.reports
  in
  let stale =
    List.filter_map
      (fun lib ->
        if List.exists (fun v -> v.library = lib) verdicts then None
        else
          some_str "%s: in the ratchet but not an Eio library of the tree" lib)
      ratchet
  in
  let clean = List.length (List.filter hermetic verdicts) in
  (List.concat_map refuse verdicts @ stale, clean, List.length ratchet)
