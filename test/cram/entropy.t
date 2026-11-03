A hash table is seeded from the system's entropy when its ?random argument
says so or when OCAMLRUNPARAM holds R. The prelude makes every table with
~random:false, through each route that would seed one: the generic tables of
Hashtbl and MoreLabels.Hashtbl, and the seeded functors of Hashtbl,
MoreLabels.Hashtbl and Ephemeron. The library below makes a table through each
route; a program run with OCAMLRUNPARAM=R checks that none is seeded. The
first line is a control, made with the standard library itself.

  $ cat > dune-project <<EOF
  > (lang dune 3.0)
  > EOF
  $ mkdir tables run
  $ echo '(library (name tables) (libraries hermetic))' > tables/dune
  $ cat > tables/tables.ml <<'EOF'
  > open! Hermetic
  > let keys = List.init 200 Fun.id
  > let order t = List.of_seq (Hashtbl.to_seq_keys t)
  > let fill t = List.iter (fun k -> Hashtbl.replace t k ()) keys; t
  > let reference () = fill (Unsafe.Hashtbl.create ~random:false 16)
  > let unseeded t = order t = order (reference ())
  > let seed = ref 0
  > module H = struct
  >   type t = int
  >   let equal = Int.equal
  >   let seeded_hash s x = seed := !seed lor s; Hashtbl.hash x
  >   let hash = seeded_hash (* OCaml 4.14 names it hash *)
  > end
  > module T = Hashtbl.MakeSeeded (H)
  > module L = MoreLabels.Hashtbl.MakeSeeded (H)
  > module E1 = Ephemeron.K1.MakeSeeded (H)
  > module E2 = Ephemeron.K2.MakeSeeded (H) (H)
  > module En = Ephemeron.Kn.MakeSeeded (H)
  > let seeded make = seed := 0; make (); !seed = 0
  > let pairs = List.to_seq [ (1, ()); (2, ()) ]
  > let checks () =
  >   [ ("control", unseeded (fill (Unsafe.Hashtbl.create 16)));
  >     ("Hashtbl.create", unseeded (fill (Hashtbl.create 16)));
  >     ("Hashtbl.rebuild", unseeded (Hashtbl.rebuild (reference ())));
  >     ("Hashtbl.of_seq",
  >      unseeded (Hashtbl.of_seq (List.to_seq (List.map (fun k -> (k, ())) keys))));
  >     ("MoreLabels.Hashtbl.create", unseeded (fill (MoreLabels.Hashtbl.create 16)));
  >     ("MoreLabels.Hashtbl.rebuild", unseeded (MoreLabels.Hashtbl.rebuild (reference ())));
  >     ("Hashtbl.MakeSeeded.create", seeded (fun () -> T.replace (T.create 1) 1 ()));
  >     ("Hashtbl.MakeSeeded.of_seq", seeded (fun () -> ignore (T.of_seq pairs)));
  >     ("MoreLabels.Hashtbl.MakeSeeded.create",
  >      seeded (fun () -> L.replace (L.create 1) ~key:1 ~data:()));
  >     ("Ephemeron.K1.MakeSeeded.create", seeded (fun () -> E1.replace (E1.create 1) 1 ()));
  >     ("Ephemeron.K1.MakeSeeded.of_seq", seeded (fun () -> ignore (E1.of_seq pairs)));
  >     ("Ephemeron.K2.MakeSeeded.create",
  >      seeded (fun () -> E2.replace (E2.create 1) (1, 2) ()));
  >     ("Ephemeron.Kn.MakeSeeded.create",
  >      seeded (fun () -> En.replace (En.create 1) [| 1 |] ())) ]
  > EOF
  $ echo '(executable (name run) (libraries tables))' > run/dune
  $ cat > run/run.ml <<'EOF'
  > let () =
  >   List.iter (fun (name, ok) -> Printf.printf "%s: %s\n" name
  >     (if ok then "not seeded" else "seeded")) (Tables.checks ())
  > EOF
  $ dune build --root . --display quiet --profile dev ./run/run.exe
  $ OCAMLRUNPARAM=R ./_build/default/run/run.exe
  control: seeded
  Hashtbl.create: not seeded
  Hashtbl.rebuild: not seeded
  Hashtbl.of_seq: not seeded
  MoreLabels.Hashtbl.create: not seeded
  MoreLabels.Hashtbl.rebuild: not seeded
  Hashtbl.MakeSeeded.create: not seeded
  Hashtbl.MakeSeeded.of_seq: not seeded
  MoreLabels.Hashtbl.MakeSeeded.create: not seeded
  Ephemeron.K1.MakeSeeded.create: not seeded
  Ephemeron.K1.MakeSeeded.of_seq: not seeded
  Ephemeron.K2.MakeSeeded.create: not seeded
  Ephemeron.Kn.MakeSeeded.create: not seeded

Since create is restated without its ?random argument, passing one is an
error that carries no alert. Compilers word the error differently.

  $ cat > tables/tables.ml <<'EOF'
  > open! Hermetic
  > let t : (int, int) Hashtbl.t = Hashtbl.create ~random:false 1
  > EOF
  $ dune build --root . --display quiet --profile dev ./tables 2>&1 | grep -oE '^(Alert|Error)'
  Error
