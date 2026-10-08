(** A fixture that aliases a module of its own library and declares a value,
    compiled without the prelude. *)

module X = Fx_mixed_x

val words : int
(** The word size. *)
