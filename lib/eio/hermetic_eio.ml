(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* Each module here is the original, except that a module refused as a whole
   is empty and Sys.argv, a mutable global, is [()]. The alerts live in hermetic_eio.mli, which is what a library
   compiled with -open Hermetic_eio is typed against. *)

module Stdlib = struct
  include Stdlib
  module Condition = struct end
  module Mutex = struct end
  module Semaphore = struct end

  module Sys = struct
    include Stdlib.Sys

    let argv = ()
  end
end

include Stdlib
