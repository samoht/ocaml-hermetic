module State : sig
  val make : int -> int
end

module Fresh () : sig
  val v : int
end

val int : int -> int
