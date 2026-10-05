(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Cmdliner
module Check = Hermetic_check

type mode = Eio | Boundary

let check modes opens paths =
  let eio = List.mem Eio modes and boundary = List.mem Boundary modes in
  if boundary && not eio then `Error (true, "--boundary needs --eio")
  else
    let prelude = if eio then "Hermetic_eio" else "Hermetic" in
    let opens = prelude :: opens in
    let imports = if eio && not boundary then Check.past_eio else [] in
    let externals = not boundary in
    let reports = List.map (Check.unit ~imports ~externals ~opens) paths in
    List.iter
      (fun { Check.name; findings } ->
        List.iter (fun f -> Fmt.pr "%s: %a@." name Check.pp_finding f) findings)
      reports;
    if List.for_all (fun (r : Check.report) -> r.findings = []) reports then
      `Ok 0
    else `Ok 1

let eio =
  let doc =
    "Check a library that does its I/O through Eio: require $(b,-open \
     Hermetic_eio) in place of $(b,-open Hermetic), and refuse a unit that \
     imports Unix, UnixLabels, Thread or Event."
  in
  (Eio, Arg.info [ "eio" ] ~doc)

let boundary =
  let doc =
    "With $(b,--eio), the library is a sanctioned boundary between Eio and the \
     system: its imports past Eio and its $(b,external) declarations are \
     allowed. A library declares it in its own stanza."
  in
  (Boundary, Arg.info [ "boundary" ] ~doc)

let modes = Arg.(value & vflag_all [] [ eio; boundary ])

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
         under which the $(b,ambient) alert is not an error, an $(b,[@alert]) \
         attribute under which it stops being one, a unit of the standard \
         library named by its own name ($(b,Stdlib__Sys)), and an \
         $(b,external) declaration, which names a primitive no prelude can \
         shadow.";
      `P
        "With $(b,--eio), it checks a library that does its I/O through Eio \
         against the $(b,Hermetic_eio) prelude instead, and also refuses a \
         unit that imports the Unix binding or the threads library.";
      `S Manpage.s_exit_status;
      `P "0 when every unit is hermetic.";
      `P "1 when a unit is refused or a file cannot be read as a $(b,.cmt).";
      `P "124 on a command-line error.";
    ]
  in
  Cmd.v
    (Cmd.info "hermetic-check" ~doc ~man ~exits:[])
    Term.(ret (const check $ modes $ opens $ paths))

let () = exit (Cmd.eval' cmd)
