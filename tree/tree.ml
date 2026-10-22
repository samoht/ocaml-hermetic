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

let prelude_library = "hermetic.eio"

(* The dune and local names of the libraries of [t]'s source packages that
   satisfy [f]. *)
let names_of f t =
  Project_index.source_package_list t
  |> List.concat_map Project_index.package_libraries
  |> List.filter f
  |> List.concat_map (fun l -> [ Library.name l; Library.local_name l ])
  |> List.sort_uniq String.compare

let names = names_of (fun _ -> true)
let adopted = names_of (fun l -> List.mem prelude_library (Library.deps l))

let relative ~root p =
  match Fpath.relativize ~root p with
  | Some r -> Fpath.normalize r
  | None -> Fpath.normalize p

let owner ~root t dir =
  match Project_index.packages_of_path t dir with
  | [] -> Fpath.v "./"
  | p :: _ -> (
      match Package.source_dir p with
      | Some d -> relative ~root (Fpath.to_dir_path d)
      | None -> Fpath.v "./")

type finding = { file : string; line : int; text : string }

let pp_finding ppf f =
  Fmt.pf ppf "File \"%s\", line %d, characters 0-0:@\nError: %s" f.file f.line
    f.text

let finding ~file ~line fmt = Fmt.kstr (fun text -> { file; line; text }) fmt

let mdx_names ms =
  List.concat_map
    (fun m ->
      let libs = Dune.File.Mdx.libraries m in
      if List.mem prelude_library libs then [] else libs)
    ms

let mdx_libraries ms =
  List.concat_map Dune.File.Mdx.libraries ms
  |> List.filter (( <> ) prelude_library)

let mdx ~adopted ~known ~dune ms =
  List.filter_map
    (fun lib ->
      if List.mem lib adopted then
        Some
          (finding ~file:dune ~line:1
             "an mdx stanza names %s, which opens %s, and not %s" lib prelude
             prelude_library)
      else if not (known lib) then
        Some
          (finding ~file:dune ~line:1
             "an mdx stanza names %s, which the rule of its package does not \
              read: regenerate the rules hermetic-tree --include prints"
             lib)
      else None)
    (mdx_names ms)

type ratchet = { file : string; libraries : (string * int) list }

let err_twice n lib =
  Fmt.kstr (fun s -> Error s) "line %d: %s is listed twice" n lib

let err_one n = Fmt.kstr (fun s -> Error s) "line %d: expected one library" n

let ratchet_of_string ~file s =
  let line (n, acc) l =
    let l =
      match String.index_opt l '#' with Some i -> String.sub l 0 i | None -> l
    in
    match String.split_on_char ' ' l |> List.filter (( <> ) "") with
    | [] -> Ok (n + 1, acc)
    | [ lib ] ->
        if List.mem_assoc lib acc then err_twice n lib
        else Ok (n + 1, (lib, n) :: acc)
    | _ -> err_one n
  in
  List.fold_left
    (fun acc l -> Result.bind acc (fun acc -> line acc l))
    (Ok (1, []))
    (String.split_on_char '\n' s)
  |> Result.map (fun (_, acc) -> { file; libraries = List.rev acc })

type verdict = {
  library : string;
  dune : string;
  boundary : bool;
  reports : Hermetic_check.report list;
}

let source_dir ~root l =
  match Library.source_dir l with
  | None -> Fpath.v "./"
  | Some d -> relative ~root (Fpath.to_dir_path d)

let objs l = Fpath.(v ("." ^ Library.local_name l ^ ".objs") / "byte")

let verdict ~root ~build ~scoped l =
  let boundary = List.mem boundary_tag (Package.tags (Library.package l)) in
  let source = source_dir ~root l in
  let dune = Fpath.(to_string (normalize (source / "dune"))) in
  let units = Fpath.(source // objs l) in
  let dir = Fpath.(build // units) in
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
      let why =
        if scoped then
          Fmt.str
            "no compiled units in %a: the rule of its package names none, \
             regenerate the rules hermetic-tree --include prints"
            Fpath.pp units
        else Fmt.str "no compiled units in %a" Fpath.pp units
      in
      Some
        {
          library;
          dune;
          boundary;
          reports =
            [ { Hermetic_check.name = library; findings = [ Unreadable why ] } ];
        }
  | cmts ->
      Some
        {
          library;
          dune;
          boundary;
          reports = List.map (Hermetic_check.eio ~boundary) cmts;
        }

let hermetic v =
  List.for_all (fun (r : Hermetic_check.report) -> r.findings = []) v.reports

(* Where the finding [f] on the unit of [r], of the verdict [v], lies: the
   unit's source file, or [v]'s dune file when the unit names none. *)
let located v (r : Hermetic_check.report) (f : Hermetic_check.finding) =
  let file =
    match f with
    | Unreadable _ -> v.dune
    | _ when r.name = v.library || Filename.check_suffix r.name ".cmt" -> v.dune
    | _ -> r.name
  in
  let line =
    match f with
    | Silenced { loc; _ } | Stdlib_unit { loc; _ } | External { loc; _ } ->
        loc.loc_start.pos_lnum
    | Not_opened _ | Not_fatal | Import _ | Unreadable _ -> 1
  in
  finding ~file ~line "%s: %a" v.library Hermetic_check.pp_finding f

let unreadable (r : Hermetic_check.report) =
  List.filter
    (function Hermetic_check.Unreadable _ -> true | _ -> false)
    r.findings

let stale ratchet libraries =
  List.filter_map
    (fun (lib, line) ->
      if List.mem lib libraries then None
      else
        Some
          (finding ~file:ratchet.file ~line
             "%s: in the ratchet but not an Eio library of the tree" lib))
    ratchet.libraries

let judge ~owns ratchet verdicts =
  let at lib = List.assoc lib ratchet.libraries in
  let refuse v =
    match (hermetic v, List.mem_assoc v.library ratchet.libraries) with
    | false, true when List.exists (fun r -> unreadable r <> []) v.reports ->
        List.concat_map
          (fun r -> List.map (located v r) (unreadable r))
          v.reports
    | true, false | false, true -> []
    | true, true ->
        [
          finding ~file:ratchet.file ~line:(at v.library)
            "%s: hermetic, remove it from the ratchet" v.library;
        ]
    | false, false ->
        List.concat_map
          (fun (r : Hermetic_check.report) -> List.map (located v r) r.findings)
          v.reports
  in
  let libraries = List.map (fun v -> v.library) verdicts in
  let judged =
    {
      ratchet with
      libraries =
        List.filter
          (fun (lib, _) -> owns lib || List.mem lib libraries)
          ratchet.libraries;
    }
  in
  let clean = List.length (List.filter hermetic verdicts) in
  ( List.concat_map refuse verdicts @ stale judged libraries,
    clean,
    List.length judged.libraries )

let path p = Fpath.to_string (Fpath.rem_empty_seg (Fpath.normalize p))
let sources = [ "dune"; "dune-project"; "*.opam"; "*.inc" ]

type scope = {
  dir : Fpath.t;
  units : Fpath.t list;
  reads : Fpath.t list;
  outside : string list;
}

let rule ~ratchet s =
  let dir = path s.dir in
  let up =
    String.concat "" (List.map (fun _ -> "../") (Fpath.segs (Fpath.v dir)))
  in
  let globs base = List.map (Fmt.str "(glob_files_rec %s%s)" base) sources in
  let deps =
    (("(sandbox always)" :: Option.to_list (Option.map (( ^ ) up) ratchet))
    @ [ up ^ "dune"; up ^ "dune-project" ]
    @ globs ""
    @ List.concat_map (fun r -> globs (up ^ path r ^ "/")) s.reads)
    @ List.map (fun u -> Fmt.str "(glob_files %s/*.cmt)" (path u)) s.units
  in
  let last = List.length deps - 1 in
  let list flag = function
    | [] -> ""
    | xs -> Fmt.str " %s %s" flag (String.concat "," xs)
  in
  String.concat "\n"
    ([ "(subdir " ^ dir; " (rule"; "  (alias runtest)"; "  (deps" ]
    @ List.mapi (fun i d -> "   " ^ d ^ if i = last then ")" else "") deps
    @ [
        "  (action";
        "   (chdir";
        "    %{workspace_root}";
        Fmt.str "    (run %%{bin:hermetic-tree} --scope %s%s%s%s)))))" dir
          (match ratchet with None -> "" | Some r -> " --ratchet " ^ r)
          (list "--reads" (List.map path s.reads))
          (list "--outside" s.outside);
      ])

let rules ~ratchet scopes =
  String.concat "\n\n"
    ("; Written by hermetic-tree --include: do not edit."
    :: List.map (rule ~ratchet) scopes)
  ^ "\n"
