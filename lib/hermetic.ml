(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* Each module here is the original, except that a module refused as a whole
   is empty and a mutable global is [()]. The alerts live in hermetic.mli,
   which is what a library compiled with -open Hermetic is typed against. *)

module Stdlib = struct
  include Stdlib

  let do_domain_local_at_exit = ()

  module Arg = struct end
  module Callback = struct end
  module Atomic = struct end
  module Condition = struct end
  module Domain = struct end
  module Mutex = struct end
  module Semaphore = struct end
  module Gc = struct end
  module Weak = struct end
  module Ephemeron = struct end
  module Oo = struct end
  module Obj = struct end
  module Marshal = struct end

  module Sys = struct
    include Stdlib.Sys

    let argv = ()
    let interactive = ()
  end

  module Hashtbl = struct
    include Stdlib.Hashtbl
    module MakeSeeded = struct end
  end

  module MoreLabels = struct
    include Stdlib.MoreLabels

    module Hashtbl = struct
      include Stdlib.MoreLabels.Hashtbl
      module MakeSeeded = struct end
    end
  end
end

include Stdlib
module CamlinternalMod = struct end
module CamlinternalOO = struct end
module Fmt = Fmt
