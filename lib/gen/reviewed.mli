(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** The names of the standard library that the policy has reviewed. *)

val modules : string list
(** The path of every reviewed module, at any depth. *)

val kept : (string * string * string) list
(** [(path, reason, names)]: the space-separated [names] of the module at [path]
    are kept, for [reason]. A module may have several groups. *)

val channels : (string * string) list
(** [(path, reason)]: the kept value at [path] hands out a channel, a formatter
    or output closures without taking one as an argument, and is reviewed as
    making it from what it is handed, for [reason]. *)

val version_specific : string list
(** The refusal paths some supported compiler lacks. *)
