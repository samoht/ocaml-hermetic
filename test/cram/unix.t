Unix's types reach nothing, so the prelude keeps them: a signature can name
Unix.file_descr, Unix.sockaddr or a constructor of Unix.error, and a source
file can match on Unix.Unix_error. The types are the originals, so an
interface that does not open the prelude names the same types. A socket that
is neither bound nor connected reaches no network, so Unix.socket and
UnixLabels.socket stay.

  $ cat > dune-project <<EOF
  > (lang dune 3.0)
  > EOF
  $ mkdir lib
  $ cat > lib/dune <<EOF
  > (library (name net) (libraries hermetic unix))
  > EOF
  $ cat > lib/net.mli <<'EOF'
  > val busy : Unix.error -> bool
  > val describe : Unix.file_descr -> Unix.sockaddr -> string
  > val retry : (unit -> 'a) -> 'a option
  > val loopback : bool
  > val stream : unit -> Unix.file_descr
  > val datagram : unit -> Unix.file_descr
  > EOF
  $ cat > lib/net.ml <<'EOF'
  > open! Hermetic
  > let busy = function Unix.EADDRINUSE -> true | _ -> false
  > let describe (_ : Unix.file_descr) = function
  >   | Unix.ADDR_UNIX path -> path
  >   | Unix.ADDR_INET (addr, port) ->
  >       Unix.string_of_inet_addr addr ^ ":" ^ string_of_int port
  > let retry f =
  >   match f () with
  >   | v -> Some v
  >   | exception Unix.Unix_error (e, _, _) -> ignore (Unix.error_message e); None
  > let loopback = Unix.inet_addr_of_string "127.0.0.1" = Unix.inet_addr_loopback
  > let stream () = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0
  > let datagram () = UnixLabels.socket ~cloexec:true ~domain:PF_INET ~kind:SOCK_DGRAM ~protocol:0
  > EOF
  $ dune build --root . --display quiet ./lib; echo "exit $?"
  exit 0

What reaches a capability through Unix is refused as ambient, as the
standard library's own values are: opening a file by name, reading the clock,
binding a socket to an address or connecting it to one.

  $ mkdir refused
  $ echo '(library (name refused) (libraries hermetic))' > refused/dune
  $ printf 'open! Hermetic\nlet fd = Unix.openfile "f" [ Unix.O_RDONLY ] 0\n' > refused/openfile.ml
  $ printf 'open! Hermetic\nlet now = Unix.time ()\n' > refused/time.ml
  $ printf 'open! Hermetic\nlet connect fd = Unix.connect fd (Unix.ADDR_UNIX "s")\n' > refused/connect.ml
  $ printf 'open! Hermetic\nlet bind fd = UnixLabels.bind fd ~addr:(ADDR_UNIX "s")\n' > refused/bind.ml
  $ dune build --root . --display quiet ./refused 2>&1 | tr -d '"' | grep -A1 -E '^Alert' | grep -v '^--' | sort
  Alert ambient: Hermetic.Unix.connect
  Alert ambient: Hermetic.Unix.openfile
  Alert ambient: Hermetic.Unix.time
  Alert ambient: Hermetic.UnixLabels.bind
  Opens a file by name: take Eio.Stdenv.fs or Eio.Stdenv.cwd (an Eio.Path) as an argument, or the file's contents.
  Reaches the network: take Eio.Stdenv.net as an argument.
  Reaches the network: take Eio.Stdenv.net as an argument.
  Reads the clock: take Eio.Stdenv.clock as an argument.
  $ dune build --root . --display quiet ./refused 2>&1 | tr -d '"' | grep -c '^Error: This expression has type ambient'
  4

A program that names only Unix's types links no code of Unix: neither the
unix library nor the prelude's restated Unix. The unix library forces its
own link, so such a program does not name it among its libraries: -I +unix
finds the interfaces its types are declared in.

  $ mkdir types
  $ cat > types/dune <<EOF
  > (executable (name main) (modes byte) (libraries hermetic)
  >  (flags (:standard -I +unix)))
  > EOF
  $ cat > types/main.ml <<'EOF'
  > open! Hermetic
  > let describe (_ : Unix.file_descr) (e : Unix.error) = e = Unix.EAGAIN
  > let () = ignore describe
  > EOF
  $ dune build --root . --display quiet --profile release ./types/main.bc
  $ ocamlobjinfo _build/default/types/main.bc |
  >   sed -n 's/.*compilation unit .\([A-Za-z_]*\).*/\1/p' | grep -c Unix
  0
  [1]
