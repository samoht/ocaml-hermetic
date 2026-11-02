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

val version_specific : string list
(** The refusal paths some supported compiler lacks. *)
