Unix's types reach nothing, so the prelude keeps them: a signature can name
Unix.file_descr, Unix.sockaddr or a constructor of Unix.error, and a source
file can match on Unix.Unix_error. The types are the originals, so an
interface that does not open the prelude names the same types. I/O on a descriptor the code is handed stays, and so does accepting
a connection on a listening socket it is handed.

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
  > val serve : Unix.file_descr -> Unix.file_descr
  > val greet : Unix.file_descr -> int
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
  > let serve fd = fst (Unix.accept fd)
  > let greet fd = UnixLabels.write_substring fd ~buf:"hello" ~pos:0 ~len:5
  > EOF
  $ dune build --root . --display quiet ./lib; echo "exit $?"
  exit 0

What reaches a capability through Unix is refused as ambient, as the
standard library's own values are: opening a file by name, reading the clock,
binding a socket to an address or connecting it to one. So is a descriptor
the code was not handed: listen on a fresh socket binds it to a port on
every interface, and the times fstat reads of a fresh socket or pipe are the
clock's. So are listen, which binds a socket that is not bound,
setsockopt_float, whose only options make a receive or a send a timed wait
on the clock, and setsockopt_optint, whose only option, SO_LINGER, makes
close one. umask is refused for the reason chdir is: it changes the mode of
every file the executable creates later.

  $ mkdir refused
  $ echo '(library (name refused) (libraries hermetic))' > refused/dune
  $ printf 'open! Hermetic\nlet fd = Unix.openfile "f" [ Unix.O_RDONLY ] 0\n' > refused/openfile.ml
  $ printf 'open! Hermetic\nlet now = Unix.time ()\n' > refused/time.ml
  $ printf 'open! Hermetic\nlet connect fd = Unix.connect fd (Unix.ADDR_UNIX "s")\n' > refused/connect.ml
  $ printf 'open! Hermetic\nlet bind fd = UnixLabels.bind fd ~addr:(ADDR_UNIX "s")\n' > refused/bind.ml
  $ printf 'open! Hermetic\nlet s = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0\n' > refused/socket.ml
  $ printf 'open! Hermetic\nlet s = UnixLabels.socket ~domain:PF_INET ~kind:SOCK_DGRAM ~protocol:0\n' > refused/socket_labels.ml
  $ printf 'open! Hermetic\nlet a, b = Unix.socketpair Unix.PF_UNIX Unix.SOCK_STREAM 0\n' > refused/socketpair.ml
  $ printf 'open! Hermetic\nlet r, w = Unix.pipe ()\n' > refused/pipe.ml
  $ printf 'open! Hermetic\nlet listen fd = Unix.listen fd 1\n' > refused/listen.ml
  $ printf 'open! Hermetic\nlet wait fd = Unix.setsockopt_float fd Unix.SO_RCVTIMEO 1.\n' > refused/timeout.ml
  $ printf 'open! Hermetic\nlet linger fd = Unix.setsockopt_optint fd Unix.SO_LINGER (Some 2)\n' > refused/linger.ml
  $ printf 'open! Hermetic\nlet mask () = UnixLabels.umask 0o077\n' > refused/umask.ml
  $ dune build --root . --display quiet ./refused 2>&1 | sed 's/"//g; s/Hermetic__Refused\.//g' | grep -A1 -E '^Alert' | grep -v '^--' | sort
  Alert ambient: Hermetic.Unix.connect
  Alert ambient: Hermetic.Unix.listen
  Alert ambient: Hermetic.Unix.openfile
  Alert ambient: Hermetic.Unix.pipe
  Alert ambient: Hermetic.Unix.setsockopt_float
  Alert ambient: Hermetic.Unix.setsockopt_optint
  Alert ambient: Hermetic.Unix.socket
  Alert ambient: Hermetic.Unix.socketpair
  Alert ambient: Hermetic.Unix.time
  Alert ambient: Hermetic.UnixLabels.bind
  Alert ambient: Hermetic.UnixLabels.socket
  Alert ambient: Hermetic.UnixLabels.umask
  Binds a socket that is not bound to a port on every interface: take Eio.Stdenv.net as an argument and use Eio.Net.listen.
  Changes the process's file-creation mask, which sets the mode of every file the executable creates later: take Eio.Stdenv.fs or Eio.Stdenv.cwd (an Eio.Path) as an argument and give each file its ~perm.
  Makes a pair of sockets the code was not handed, whose fstat reads the clock: take the sockets as arguments, which the executable makes with Eio_unix.Net.socketpair_stream.
  Makes a pipe the code was not handed, whose fstat reads the clock: take its ends as arguments, which the executable makes with Eio_unix.pipe.
  Makes a socket the code was not handed, which listen binds to every interface and whose fstat reads the clock: take Eio.Stdenv.net as an argument.
  Makes a socket the code was not handed, which listen binds to every interface and whose fstat reads the clock: take Eio.Stdenv.net as an argument.
  Opens a file by name: take Eio.Stdenv.fs or Eio.Stdenv.cwd (an Eio.Path) as an argument, or the file's contents.
  Reaches the network: take Eio.Stdenv.net as an argument.
  Reaches the network: take Eio.Stdenv.net as an argument.
  Reads the clock: take Eio.Stdenv.clock as an argument.
  Sets SO_LINGER on a socket, which makes close a timed wait on the clock: take Eio.Stdenv.clock as an argument and use Eio.Time.with_timeout.
  Sets a timeout on a socket, which makes a receive or a send a timed wait on the clock: take Eio.Stdenv.clock as an argument and use Eio.Time.with_timeout.
  $ dune build --root . --display quiet ./refused 2>&1 | sed 's/"//g; s/Hermetic__Refused\.//g' | grep -c '^Error: This expression has type ambient'
  12

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
