(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* Paragraphs of [text], separated by blank lines. *)
let paragraphs text =
  let rec go acc cur = function
    | [] -> List.rev (if cur = [] then acc else List.rev cur :: acc)
    | "" :: rest -> go (if cur = [] then acc else List.rev cur :: acc) [] rest
    | l :: rest -> go acc (l :: cur) rest
  in
  go [] [] (String.split_on_char '\n' text)

(* [words] filled to 80 columns, the first line starting at column [start],
   the others indented by [indent]. *)
let fill ~start ~indent words =
  let b = Buffer.create 256 in
  let col = ref start in
  List.iteri
    (fun i w ->
      if i > 0 && !col + 1 + String.length w > 80 then (
        Buffer.add_char b '\n';
        Buffer.add_string b indent;
        col := String.length indent)
      else if i > 0 then (
        Buffer.add_char b ' ';
        incr col);
      Buffer.add_string b w;
      col := !col + String.length w)
    words;
  Buffer.contents b

(* A doc comment, its paragraphs filled to 80 columns. A paragraph that opens
   a code block is kept line by line. *)
let comment buf depth text =
  let first = String.make (2 * depth) ' ' ^ "(** " in
  let indent = String.make ((2 * depth) + 4) ' ' in
  let para i lines =
    let start = if i = 0 then String.length first else String.length indent in
    let lead = if i = 0 then first else indent in
    match lines with
    | l :: _ when String.starts_with ~prefix:"{[" l ->
        lead ^ String.concat ("\n" ^ indent) lines
    | _ ->
        let words =
          List.concat_map (String.split_on_char ' ') lines
          |> List.filter (( <> ) "")
        in
        lead ^ fill ~start ~indent words
  in
  Buffer.add_string buf
    (String.concat "\n\n" (List.mapi para (paragraphs text)));
  Buffer.add_string buf " *)\n"
