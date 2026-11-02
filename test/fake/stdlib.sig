module List = Stdlib__List
module Random = Stdlib__Random
module Odd = Stdlib__Odd
module Classy = Stdlib__Classy
module Typed = Stdlib__Typed
module Labels = Stdlib__Labels

type out_channel
type formatter
type out_functions = { out_string : string -> unit; out_flush : unit -> unit }
type point = { x : int; y : int }
val stderr : out_channel
val err_functions : unit -> out_functions
val err_output : unit -> (string -> unit) * (unit -> unit)
val with_err : (out_channel -> 'a) -> 'a
val formatter_of_out_channel : out_channel -> formatter
val formatter_of_string : string -> formatter
val output_string : out_channel -> string -> unit
val origin : point
