(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Cmdliner

let check opens paths =
  let opens = "Hermetic" :: opens in
  let reports = List.map (Check.unit ~opens) paths in
  List.iter
    (fun { Check.name; findings } ->
      List.iter (fun f -> Fmt.pr "%s: %a@." name Check.pp_finding f) findings)
    reports;
  if List.for_all (fun (r : Check.report) -> r.findings = []) reports then 0
  else 1

let opens =
  let doc =
    "Require the units to be compiled with $(b,-open) $(docv) too, after \
     $(b,Hermetic): the prelude of another library's ambient values. Repeat \
     for several."
  in
  Arg.(value & opt_all string [] & info [ "open" ] ~docv:"MODULE" ~doc)

let paths =
  let doc = "The $(b,.cmt) file of a unit to check." in
  Arg.(non_empty & pos_all file [] & info [] ~docv:"CMT" ~doc)

let cmd =
  let doc = "refuse the compiled units of a library that are not hermetic" in
  let man =
    [
      `S Manpage.s_description;
      `P
        "$(cmd) reads the $(b,.cmt) file of each unit of a library meant to be \
         hermetic and prints one line per reason to refuse it: a unit compiled \
         without $(b,-open Hermetic) (or a module $(b,--open) names), a unit \
         under which the $(b,ambient) alert is not an error, and each \
         $(b,external) declaration, which names a C primitive no prelude can \
         shadow.";
      `S Manpage.s_exit_status;
      `P "0 when every unit is hermetic.";
      `P "1 when a unit is refused or a file cannot be read as a $(b,.cmt).";
      `P "124 on a command-line error.";
    ]
  in
  Cmd.v
    (Cmd.info "hermetic-check" ~doc ~man ~exits:[])
    Term.(const check $ opens $ paths)

let () = exit (Cmd.eval' cmd)
