(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

let cmt name = Fmt.str "check_fixtures/.%s.objs/byte/%s.cmt" name name
let findings r = r.Hermetic_check.findings
let pp_findings = Fmt.Dump.list Hermetic_check.pp_finding
let strings fs = List.map (Fmt.to_to_string Hermetic_check.pp_finding) fs

let test_hermetic_unit_passes () =
  let r = Hermetic_check.eio (cmt "fx_good") in
  Alcotest.(check (list string)) "no finding" [] (strings (findings r))

let test_unit_without_open_refused () =
  let r = Hermetic_check.eio (cmt "fx_plain") in
  match findings r with
  | Hermetic_check.Not_opened "Hermetic_eio" :: _ -> ()
  | fs ->
      Alcotest.failf "expected Not_opened Hermetic_eio first, got %a"
        pp_findings fs

let test_unix_import_refused () =
  let r = Hermetic_check.eio (cmt "fx_unix") in
  Alcotest.(check bool)
    "Import Unix" true
    (List.mem (Hermetic_check.Import "Unix") (findings r))

let test_boundary_allows_unix () =
  let r = Hermetic_check.eio ~boundary:true (cmt "fx_unix") in
  Alcotest.(check (list string)) "no finding" [] (strings (findings r))

let test_boundary_still_requires_open () =
  let r = Hermetic_check.eio ~boundary:true (cmt "fx_plain") in
  Alcotest.(check bool)
    "Not_opened" true
    (List.mem (Hermetic_check.Not_opened "Hermetic_eio") (findings r))

let test_missing_file_unreadable () =
  let r = Hermetic_check.eio (cmt "absent") in
  match findings r with
  | [ Hermetic_check.Unreadable _ ] -> ()
  | fs -> Alcotest.failf "expected Unreadable, got %a" pp_findings fs

let suite =
  ( "hermetic_check",
    [
      Alcotest.test_case "hermetic unit passes" `Quick test_hermetic_unit_passes;
      Alcotest.test_case "unit without the open is refused" `Quick
        test_unit_without_open_refused;
      Alcotest.test_case "unit importing Unix is refused" `Quick
        test_unix_import_refused;
      Alcotest.test_case "boundary allows Unix" `Quick test_boundary_allows_unix;
      Alcotest.test_case "boundary still requires the open" `Quick
        test_boundary_still_requires_open;
      Alcotest.test_case "missing file is unreadable" `Quick
        test_missing_file_unreadable;
    ] )
