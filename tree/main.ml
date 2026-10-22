(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Cmdliner

let absolute p =
  let p = Fpath.v p in
  Fpath.to_dir_path
    (Fpath.normalize
       (if Fpath.is_abs p then p else Fpath.(v (Sys.getcwd ()) // p)))

let index ~fs ~root ?roots () =
  Project_index.build ?roots ~census:false ~installed:Project_index.Skip
    ~census_vendored:false ~fs ~monorepo:root ()

let selected index =
  Project_index.source_package_list index
  |> List.concat_map Project_index.package_libraries
  |> List.filter Tree.selected

let parse ~root dir =
  let file = Fpath.(dir / "dune") in
  let dune = Fpath.to_string (Tree.relative ~root file) in
  match Dune.File.of_file (Fpath.to_string file) with
  | Error e ->
      Error { Tree.file = dune; line = 1; text = Fmt.str "%a" Dune.Error.pp e }
  | Ok f -> Ok (dune, Dune.File.mdx_stanzas f)

let check ~fs ~root ~build ~ratchet ~scope ~summary =
  let idx, mine, known, owns =
    match scope with
    | None ->
        (index ~fs ~root (), (fun _ -> true), (fun _ -> true), fun _ -> true)
    | Some (dir, reads, outside) ->
        let roots = List.map (fun d -> Fpath.(root // d)) (dir :: reads) in
        let idx = index ~fs ~root ~roots () in
        let mine d =
          let d = Fpath.to_dir_path d in
          Fpath.is_rooted ~root:Fpath.(root // dir) d
          && Fpath.equal (Tree.owner ~root idx d) dir
        in
        let names = Tree.names idx in
        let packages =
          Project_index.source_package_list idx
          |> List.filter (fun p ->
              Option.fold ~none:false ~some:mine
                (Project_index.Package.source_dir p))
          |> List.map Project_index.Package.name
        in
        (* A public name's first segment is the package that installs it. *)
        let owns lib =
          List.mem (List.hd (String.split_on_char '.' lib)) packages
        in
        (idx, mine, (fun n -> List.mem n names || List.mem n outside), owns)
  in
  let verdicts =
    selected idx
    |> List.filter (fun l ->
        Option.fold ~none:(scope = None) ~some:mine
          (Project_index.Library.source_dir l))
    |> List.filter_map (Tree.verdict ~root ~build ~scoped:(scope <> None))
    |> List.sort (fun (a : Tree.verdict) b ->
        String.compare a.library b.library)
  in
  let lines, clean, listed = Tree.judge ~owns ratchet verdicts in
  let adopted = Tree.adopted idx in
  let mdx dir =
    match parse ~root dir with
    | Error f -> [ f ]
    | Ok (dune, ms) -> Tree.mdx ~adopted ~known ~dune ms
  in
  let lines =
    lines
    @ List.concat_map mdx
        (List.filter mine
           (List.sort Fpath.compare (Project_index.dune_dirs idx)))
  in
  List.iter (Fmt.pr "%a@." Tree.pp_finding) lines;
  if summary || lines <> [] then
    Fmt.pr "%d Eio libraries: %d hermetic, %d in the ratchet@."
      (List.length verdicts) clean listed;
  if lines = [] then 0 else 1

let print_include ~fs ~root ~ratchet ~ratchet_file =
  let idx = index ~fs ~root () in
  let owner d = Tree.owner ~root idx d in
  let libraries =
    Project_index.source_package_list idx
    |> List.concat_map Project_index.package_libraries
    |> List.filter_map (fun l ->
        Option.map (fun d -> (owner d, l)) (Project_index.Library.source_dir l))
  in
  let selected = List.filter (fun (_, l) -> Tree.selected l) libraries in
  let owners name =
    List.filter_map
      (fun (o, l) ->
        if
          name = Project_index.Library.name l
          || name = Project_index.Library.local_name l
        then Some o
        else None)
      libraries
    |> List.sort_uniq Fpath.compare
  in
  let stanzas =
    List.map
      (fun d -> (owner d, parse ~root d))
      (List.sort Fpath.compare (Project_index.dune_dirs idx))
  in
  let dirs =
    Project_index.source_package_list idx
    |> List.filter_map Project_index.Package.source_dir
    |> List.map (fun d -> Tree.relative ~root (Fpath.to_dir_path d))
    |> List.filter (fun d -> not (Fpath.equal d (Fpath.v "./")))
    |> List.sort_uniq Fpath.compare
  in
  let scope dir =
    let units =
      List.filter_map
        (fun (o, l) ->
          if Fpath.equal o dir then
            Some Fpath.(Tree.source_dir ~root:(root // dir) l // Tree.objs l)
          else None)
        selected
      |> List.sort_uniq Fpath.compare
    in
    let names =
      List.concat_map
        (fun (o, p) ->
          match p with
          | Ok (_, ms) when Fpath.equal o dir -> Tree.mdx_libraries ms
          | _ -> [])
        stanzas
      |> List.sort_uniq String.compare
    in
    let reads, outside =
      List.fold_left
        (fun (reads, outside) n ->
          match owners n with
          | [] -> (reads, n :: outside)
          | os when List.exists (Fpath.equal dir) os -> (reads, outside)
          | os -> (os @ reads, outside))
        ([], []) names
    in
    {
      Tree.dir;
      units;
      reads = List.sort_uniq Fpath.compare reads;
      outside = List.sort_uniq String.compare outside;
    }
  in
  let unowned file what =
    {
      Tree.file;
      line = 1;
      text = what ^ " in no package directory, so no rule checks it";
    }
  in
  let unowned =
    List.filter_map
      (fun (o, l) ->
        if List.exists (Fpath.equal o) dirs then None
        else
          Some
            (unowned
               (Fpath.to_string (Tree.relative ~root Fpath.(o / "dune")))
               (Project_index.Library.name l ^ ":")))
      selected
    @ List.filter_map
        (fun (o, p) ->
          match p with
          | Ok (dune, _ :: _) when not (List.exists (Fpath.equal o) dirs) ->
              Some (unowned dune "an mdx stanza")
          | _ -> None)
        stanzas
  in
  let findings =
    Tree.stale ratchet
      (List.map (fun (_, l) -> Project_index.Library.name l) selected)
    @ unowned
  in
  print_string (Tree.rules ~ratchet:ratchet_file (List.map scope dirs));
  List.iter (Fmt.epr "%a@." Tree.pp_finding) findings;
  if findings = [] then 0 else 1

let run root build ratchet_file scope reads outside include_ summary =
  let root = absolute root in
  let build = match build with None -> root | Some b -> absolute b in
  let ratchet =
    match ratchet_file with
    | None -> Tree.ratchet_of_string ~file:"" ""
    | Some f ->
        Tree.ratchet_of_string ~file:f
          (In_channel.with_open_bin f In_channel.input_all)
  in
  let dir s = Fpath.to_dir_path (Fpath.normalize (Fpath.v s)) in
  let scope =
    Option.map (fun s -> (dir s, List.map dir reads, outside)) scope
  in
  match ratchet with
  | Error e -> `Error (false, e)
  | Ok ratchet ->
      Eio_main.run @@ fun env ->
      let fs = Eio.Stdenv.fs env in
      if include_ then `Ok (print_include ~fs ~root ~ratchet ~ratchet_file)
      else `Ok (check ~fs ~root ~build ~ratchet ~scope ~summary)

let root =
  let doc = "The root of the source tree to index." in
  Arg.(value & opt dir "." & info [ "root" ] ~docv:"DIR" ~doc)

let build =
  let doc =
    "The build directory holding the tree's compiled units, \
     $(b,_build/default) seen from the source root. Defaults to the root \
     itself, which is the build directory when a dune rule runs the command."
  in
  Arg.(value & opt (some dir) None & info [ "build" ] ~docv:"DIR" ~doc)

let ratchet =
  let doc = "The libraries allowed to violate, one library name per line." in
  Arg.(value & opt (some file) None & info [ "ratchet" ] ~docv:"FILE" ~doc)

let scope =
  let doc =
    "Check only the package directory $(docv), relative to the root: the \
     selected libraries and the $(b,mdx) stanzas of the directories its \
     packages own. A library of the ratchet outside it is not judged."
  in
  Arg.(value & opt (some string) None & info [ "scope" ] ~docv:"DIR" ~doc)

let reads =
  let doc =
    "With $(b,--scope), the other package directories, relative to the root, \
     whose libraries the $(b,mdx) stanzas of the scope name: the check reads \
     whether those libraries name $(b,hermetic.eio) from their dune files."
  in
  Arg.(value & opt (list string) [] & info [ "reads" ] ~docv:"DIR,..." ~doc)

let outside =
  let doc =
    "With $(b,--scope), the libraries the $(b,mdx) stanzas of the scope name \
     that no package of the tree provides. A stanza naming a library neither \
     the scope, $(b,--reads) nor this list provides is refused, so that the \
     rules $(b,--include) prints say when they must be written again."
  in
  Arg.(value & opt (list string) [] & info [ "outside" ] ~docv:"LIB,..." ~doc)

let include_ =
  let doc =
    "Print, instead of checking, the dune rules that check each package \
     directory of the tree with $(b,--scope) in its own $(b,runtest) alias, \
     for an $(b,(include)) of the root's dune file. Refuse, on standard error, \
     a library of the ratchet that the tree does not select, and a selected \
     library or an $(b,mdx) stanza in no package directory."
  in
  Arg.(value & flag & info [ "include" ] ~doc)

let summary =
  let doc = "Print the count of libraries even when the tree passes." in
  Arg.(value & flag & info [ "summary" ] ~doc)

let cmd =
  let doc = "check every Eio library of a source tree against hermetic.eio" in
  let man =
    [
      `S Manpage.s_description;
      `P
        "$(cmd) indexes the source tree, selects each library that does its \
         I/O through Eio (its public name ends with $(b,-eio) or $(b,.eio), or \
         it names $(b,eio) among its libraries) and checks each of its \
         compiled units as $(b,hermetic-check --eio) does. A library of a \
         package whose $(b,dune-project) carries the tag \
         $(b,hermetic:eio-boundary) is checked as $(b,--boundary).";
      `P
        "A library named in the ratchet may violate. The tree is refused when \
         a library outside the ratchet violates, when a library in it is \
         hermetic, so that the list only shrinks, and when it names a library \
         the tree does not select.";
      `P
        "$(b,--include) prints dune rules that run $(cmd) $(b,--scope) over \
         each package directory in that directory's $(b,runtest), so that \
         testing a package checks it without building the rest of the tree.";
      `S Manpage.s_exit_status;
      `P "0 when the tree passes.";
      `P "1 when it is refused.";
      `P "124 on a command-line error.";
    ]
  in
  Cmd.v
    (Cmd.info "hermetic-tree" ~doc ~man ~exits:[])
    Term.(
      ret
        (const run $ root $ build $ ratchet $ scope $ reads $ outside $ include_
       $ summary))

let () = exit (Cmd.eval' cmd)
