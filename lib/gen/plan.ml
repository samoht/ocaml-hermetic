(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

type restated =
  | Sig of { items : item list; names : names }
  | Whole of Policy.refusal * item list
  | Functor of { params : (string * string) list; items : item list }
  | Gone

and item =
  | Refused of string * Policy.refusal
  | Retyped of { name : string; typ : string; impl : string; doc : string }
  | Removed of string
  | Sub of string * restated
  | Rewired of string * string

and names = {
  types : (string * int) list;
  module_types : string list;
  submodules : string list;
  class_types : bool;
}

type prelude = {
  values : item list;
  modules : (string * restated) list;
  in_stdlib : string list;
}

type outcome = Keep | Restate of restated | Remove

type ctx = {
  entries : (string, Policy.entry) Hashtbl.t;
  reviewed : Policy.reviewed;
  restated : string list;  (** The paths restated, at any depth. *)
  units : string list;
      (** The top-level modules that [Stdlib] does not name. *)
  mutable unreviewed : string list;
}

let join p n = if p = "" then n else p ^ "." ^ n
let known_module ctx p = List.mem p ctx.reviewed.modules

let contains ~sub s =
  let n = String.length sub in
  let rec go i =
    i + n <= String.length s && (String.sub s i n = sub || go (i + 1))
  in
  go 0

(* A value whose name says [unsafe] is kept only by an entry of the policy,
   never by the table of reviewed names. *)
let kept ctx p v =
  (not (contains ~sub:"unsafe" v))
  &&
  match List.assoc_opt p ctx.reviewed.kept with
  | Some names -> List.mem v names
  | None -> false

(* A path as a user spells it: through [Stdlib], unless its head is a unit
   that [Stdlib] does not name. *)
let spelled ctx path =
  let head = List.hd (String.split_on_char '.' path) in
  if List.mem head ctx.units then path else "Stdlib." ^ path

let unreviewed ctx path =
  ctx.unreviewed <- path :: ctx.unreviewed;
  Policy.unreviewed (spelled ctx path)

(* A module the reader cannot open, or that has to change in a way the
   prelude cannot express, is removed and reported as unreviewed. *)
let remove ctx path =
  ignore (unreviewed ctx path);
  Remove

let no_class p items =
  List.iter
    (function
      | Stdlib_tree.Class c ->
          failwith
            (Printf.sprintf
               "%s must be restated but has the class %s, which cannot be \
                restated"
               p c)
      | _ -> ())
    items

let names items =
  let pick f = List.filter_map f items in
  {
    types = pick (function Stdlib_tree.Type (t, n) -> Some (t, n) | _ -> None);
    module_types =
      pick (function Stdlib_tree.Module_type m -> Some m | _ -> None);
    submodules =
      pick (function Stdlib_tree.Module (m, _) -> Some m | _ -> None);
    class_types =
      List.exists
        (function Stdlib_tree.Class_type _ -> true | _ -> false)
        items;
  }

let rewire ctx m target =
  if List.mem target ctx.restated then Some (Rewired (m, target)) else None

let sub m = function
  | Keep -> None
  | Restate t -> Some (Sub (m, t))
  | Remove -> Some (Removed m)

let rec functor_params acc = function
  | Stdlib_tree.Functor { param; param_type; result } ->
      functor_params ((param, param_type) :: acc) result
  | node -> (List.rev acc, node)

(* A functor's result holds only values the prelude can restate; a submodule
   of it that must change cannot be named, so the functor is removed. *)
let functor_of ctx p params items =
  if List.for_all (function Refused _ | Retyped _ -> true | _ -> false) items
  then Restate (Functor { params; items })
  else remove ctx p

(* Every value of the module at [p] refused with [r], at any depth. A module
   whose contents cannot be opened is removed. *)
let rec refuse_all ctx p node r =
  match node with
  | Stdlib_tree.Sig items -> (
      no_class p items;
      let planned =
        List.filter_map
          (function
            | Stdlib_tree.Value v -> Some (Refused (v, r))
            | Type _ | Module_type _ | Class _ | Class_type _ -> None
            | Module (m, Alias target) | Module (m, Dotted (target, _)) ->
                rewire ctx m target
            | Module (m, Node n) -> sub m (refuse_all ctx (join p m) n r))
          items
      in
      match planned with [] -> Keep | planned -> Restate (Whole (r, planned)))
  | Functor _ -> (
      let params, result = functor_params [] node in
      match result with
      | Stdlib_tree.Sig items -> (
          no_class p items;
          match refuse_all ctx p result r with
          | Restate (Whole (_, planned)) -> functor_of ctx p params planned
          | Keep -> Keep
          | Restate _ | Remove -> Remove)
      | Functor _ | Opaque _ -> Remove)
  | Opaque _ -> Remove

let rec module_plan ctx p node =
  match Hashtbl.find_opt ctx.entries p with
  | Some (Policy.Module r) -> refuse_all ctx p node r
  | Some (Policy.Value _ | Policy.Retyped _ | Policy.Keep _) ->
      failwith (Printf.sprintf "%s: the policy names a module as a value" p)
  | None ->
      if known_module ctx p then restate ctx p node
      else refuse_all ctx p node (unreviewed ctx p)

and restate ctx p node =
  match node with
  | Stdlib_tree.Sig items -> (
      match List.filter_map (item ctx p) items with
      | [] -> Keep
      | planned ->
          no_class p items;
          Restate (Sig { items = planned; names = names items }))
  | Functor _ -> (
      let params, result = functor_params [] node in
      match result with
      | Stdlib_tree.Sig items -> (
          match List.filter_map (item ctx p) items with
          | [] -> Keep
          | planned ->
              no_class p items;
              functor_of ctx p params planned)
      | Functor _ | Opaque _ -> remove ctx p)
  | Opaque _ -> remove ctx p

and item ctx p = function
  | Stdlib_tree.Value v -> (
      let path = join p v in
      match Hashtbl.find_opt ctx.entries path with
      | Some (Policy.Value r) -> Some (Refused (v, r))
      | Some (Policy.Retyped { typ; impl; doc }) ->
          Some (Retyped { name = v; typ; impl; doc })
      | Some (Policy.Keep _) -> None
      | Some (Policy.Module _) ->
          failwith
            (Printf.sprintf "%s: the policy refuses a value as a module" path)
      | None ->
          if kept ctx p v then None else Some (Refused (v, unreviewed ctx path))
      )
  | Class c ->
      if kept ctx p c then None
      else
        failwith
          (Printf.sprintf
             "%s: a class the policy has not reviewed, which cannot be restated"
             (join p c))
  | Type _ | Module_type _ | Class_type _ -> None
  | Module (m, Alias target) | Module (m, Dotted (target, _)) ->
      rewire ctx m target
  | Module (m, Node n) -> sub m (module_plan ctx (join p m) n)

let walk ctx (tree : Stdlib_tree.t) =
  let values =
    List.filter_map (fun v -> item ctx "" (Stdlib_tree.Value v)) tree.values
  in
  let modules =
    List.filter_map
      (fun (m, node) ->
        match module_plan ctx m node with
        | Keep -> None
        | Restate t -> Some (m, t)
        | Remove -> Some (m, Gone))
      tree.modules
  in
  (values, modules)

(* The paths of the restated modules, at any depth. *)
let rec paths p = function
  | Sig { items; _ } | Whole (_, items) ->
      List.concat_map
        (function
          | Sub (m, t) -> join p m :: paths (join p m) t
          | Refused _ | Retyped _ | Removed _ | Rewired _ -> [])
        items
  | Functor _ | Gone -> []

let v ?(refusals = Policy.refusals) ?(reviewed = Policy.reviewed)
    (tree : Stdlib_tree.t) =
  let entries = Hashtbl.create 512 in
  List.iter (fun (path, e) -> Hashtbl.replace entries path e) refusals;
  (* An alias of a restated module is restated in turn, until no more module
     is. *)
  let rec fix restated =
    let units =
      List.filter_map
        (fun (m, _) -> if List.mem m tree.in_stdlib then None else Some m)
        tree.modules
    in
    let ctx = { entries; reviewed; restated; units; unreviewed = [] } in
    let values, modules = walk ctx tree in
    let now =
      List.concat_map (fun (m, t) -> m :: paths m t) modules
      |> List.sort_uniq String.compare
    in
    if now = restated then (values, modules, ctx) else fix now
  in
  let values, modules, ctx = fix [] in
  let in_stdlib =
    List.filter (fun m -> List.mem_assoc m modules) tree.in_stdlib
  in
  ({ values; modules; in_stdlib }, List.sort_uniq String.compare ctx.unreviewed)

let mistakes ?(refusals = Policy.refusals)
    ?(version_specific = Policy.version_specific) tree =
  List.filter_map
    (fun (path, _) ->
      if Stdlib_tree.mem tree path || List.mem path version_specific then None
      else Some path)
    refusals

(* A value is kept when no refusal names it or a module above it, and the
   policy keeps it, by an entry or by the table of reviewed names. *)
let channels ?(refusals = Policy.refusals) ?(reviewed = Policy.reviewed)
    (tree : Stdlib_tree.t) =
  let refused path =
    List.exists
      (fun (p, e) ->
        match e with
        | Policy.Value _ | Policy.Retyped _ -> p = path
        | Policy.Module _ -> String.starts_with ~prefix:(p ^ ".") path
        | Policy.Keep _ -> false)
      refusals
  in
  let kept path =
    match List.assoc_opt path refusals with
    | Some (Policy.Keep _) -> true
    | _ -> (
        let m, v =
          match String.rindex_opt path '.' with
          | Some i ->
              ( String.sub path 0 i,
                String.sub path (i + 1) (String.length path - i - 1) )
          | None -> ("", path)
        in
        (not (contains ~sub:"unsafe" v))
        &&
        match List.assoc_opt m reviewed.kept with
        | Some names -> List.mem v names
        | None -> false)
  in
  List.filter
    (fun path ->
      (not (refused path)) && kept path && not (List.mem path reviewed.channels))
    tree.channels
