(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Cmdliner

let absolute p =
  let p = Fpath.v p in
  Fpath.normalize (if Fpath.is_abs p then p else Fpath.(v (Sys.getcwd ()) // p))

let run root build ratchet summary =
  let root = absolute root in
  let build = match build with None -> root | Some b -> absolute b in
  let ratchet =
    match ratchet with
    | None -> Tree.ratchet_of_string ~file:"" ""
    | Some f ->
        Tree.ratchet_of_string ~file:f
          (In_channel.with_open_bin f In_channel.input_all)
  in
  match ratchet with
  | Error e -> `Error (false, e)
  | Ok ratchet ->
      Eio_main.run @@ fun env ->
      let index =
        Project_index.build ~installed:Project_index.Skip ~census_vendored:false
          ~fs:(Eio.Stdenv.fs env) ~monorepo:root ()
      in
      let verdicts =
        Project_index.source_package_list index
        |> List.concat_map Project_index.package_libraries
        |> List.filter Tree.selected
        |> List.filter_map (Tree.verdict ~root ~build)
        |> List.sort (fun (a : Tree.verdict) b ->
            String.compare a.library b.library)
      in
      let lines, clean, listed = Tree.judge ratchet verdicts in
      let adopted =
        Project_index.source_package_list index
        |> List.concat_map Project_index.package_libraries
        |> List.concat_map Tree.adopted
      in
      let mdx dir =
        let file = Fpath.(dir / "dune") in
        let dune =
          match Fpath.relativize ~root file with
          | Some r -> Fpath.to_string r
          | None -> Fpath.to_string file
        in
        match Dune.File.of_file (Fpath.to_string file) with
        | Error e ->
            [
              {
                Tree.file = dune;
                line = 1;
                text = Fmt.str "%a" Dune.Error.pp e;
              };
            ]
        | Ok f -> Tree.mdx ~adopted ~dune (Dune.File.mdx_stanzas f)
      in
      let lines =
        lines
        @ List.concat_map mdx
            (List.sort Fpath.compare (Project_index.dune_dirs index))
      in
      List.iter (Fmt.pr "%a@." Tree.pp_finding) lines;
      if summary || lines <> [] then
        Fmt.pr "%d Eio libraries: %d hermetic, %d in the ratchet@."
          (List.length verdicts) clean listed;
      `Ok (if lines = [] then 0 else 1)

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
      `S Manpage.s_exit_status;
      `P "0 when the tree passes.";
      `P "1 when it is refused.";
      `P "124 on a command-line error.";
    ]
  in
  Cmd.v
    (Cmd.info "hermetic-tree" ~doc ~man ~exits:[])
    Term.(ret (const run $ root $ build $ ratchet $ summary))

let () = exit (Cmd.eval' cmd)
