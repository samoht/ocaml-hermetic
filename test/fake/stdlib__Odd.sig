module R = Stdlib__Random.State

module Gen () : sig
  val x : int
end

module Anon (_ : sig end) : sig
  val y : int
end

module type A

module Abs : A

val ( mod ) : int -> int -> int

module Sub : sig
  val z : int
end
module L = Stdlib__Labels
