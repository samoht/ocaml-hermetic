(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Doc comments of the generated source. *)

val comment : Buffer.t -> int -> string -> unit
(** [comment buf depth text] adds to [buf] the doc comment of [text], indented
    by [depth] levels and its paragraphs filled to 80 columns. Paragraphs are
    separated by a blank line; one that opens a code block with [{\[] is kept
    line by line. *)
