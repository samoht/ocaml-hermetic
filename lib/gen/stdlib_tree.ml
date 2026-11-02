(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

type node =
  | Sig of item list
  | Functor of { param : string; param_type : string; result : node }
  | Opaque of string

and item =
  | Value of string
  | Type of string * int
  | Module_type of string
  | Class of string
  | Class_type of string
  | Module of string * module_

and module_ = Alias of string | Dotted of string * node | Node of node

type t = {
  types : (string * int) list;
  values : string list;
  modules : (string * node) list;
  in_stdlib : string list;
  channels : string list;
}

(* The top-level name of a unit: [Stdlib__Sys] is [Sys]. *)
let top_name units unit =
  match List.assoc_opt unit units with Some name -> name | None -> unit

(* A path as the generated prelude spells it, before it shadows any name: the
   head unit is named through [Stdlib]. *)
let path_name units path =
  let rec go = function
    | Path.Pident id ->
        let name = Ident.name id in
        if Ident.global id then
          match List.assoc_opt name units with
          | Some top -> "Stdlib." ^ top
          | None -> name
        else name
    | Path.Pdot (p, s) -> go p ^ "." ^ s
    | Path.Papply (f, x) -> go f ^ "(" ^ go x ^ ")"
    | Path.Pextra_ty (p, _) -> go p
  in
  go path

(* A class declares a class type of the same name too: keep the class. *)
let classes_once items =
  let classes =
    List.filter_map (function Class c -> Some c | _ -> None) items
  in
  List.filter
    (function Class_type c -> not (List.mem c classes) | _ -> true)
    items

(* The path of a module of the standard library as the policy spells it:
   [Stdlib__Random.State] and [Stdlib.Random.State] are [Random.State]. *)
let policy_path units p =
  let rec go = function
    | Path.Pident u when Ident.global u -> (
        match List.assoc_opt (Ident.name u) units with
        | Some top -> Some [ top ]
        | None when Ident.name u = "Stdlib" -> Some []
        | None -> None)
    | Path.Pdot (p, s) -> Option.map (fun l -> l @ [ s ]) (go p)
    | Path.Pident _ | Path.Papply _ | Path.Pextra_ty _ -> None
  in
  match go p with
  | Some (_ :: _ as l) -> Some (String.concat "." l)
  | Some [] | None -> None

let rec node units env mty =
  match mty with
  | Types.Mty_alias p -> node units env (Env.find_module p env).md_type
  | _ -> (
      match Mtype.scrape env mty with
      | Types.Mty_signature sg ->
          let env = Env.add_signature sg env in
          Sig (classes_once (List.filter_map (item units env) sg))
      | Types.Mty_functor
          (Types.Named (Some id, (Types.Mty_ident p as pty)), res) ->
          let env = Env.add_module id Types.Mp_present pty env in
          Functor
            {
              param = Ident.name id;
              param_type = path_name units p;
              result = node units env res;
            }
      | Types.Mty_functor (Types.Unit, _) -> Opaque "generative functor"
      | Types.Mty_functor (Types.Named (None, _), _) ->
          Opaque "functor of an anonymous parameter"
      | Types.Mty_functor (Types.Named (Some _, _), _) ->
          Opaque "functor whose parameter is not a named module type"
      | Types.Mty_alias p -> node units env (Env.find_module p env).md_type
      | Types.Mty_ident _ -> Opaque "abstract module type")

(* An alias of a top-level module of the standard library is kept as an
   alias, so that the prelude can point it at its own module; an alias of
   any other path is followed. *)
and alias units env id p =
  match p with
  | Path.Pident u when Ident.global u ->
      Module (Ident.name id, Alias (top_name units (Ident.name u)))
  | Path.Pdot (Path.Pident s, name)
    when Ident.global s && Ident.name s = "Stdlib" ->
      Module (Ident.name id, Alias name)
  | _ -> (
      let n = node units env (Env.find_module p env).md_type in
      match policy_path units p with
      | Some path -> Module (Ident.name id, Dotted (path, n))
      | None -> Module (Ident.name id, Node n))

and item units env = function
  | Types.Sig_value (id, _, Types.Exported) -> Some (Value (Ident.name id))
  | Types.Sig_type (id, decl, _, Types.Exported) ->
      Some (Type (Ident.name id, List.length decl.type_params))
  | Types.Sig_modtype (id, _, Types.Exported) ->
      Some (Module_type (Ident.name id))
  | Types.Sig_class (id, _, _, Types.Exported) -> Some (Class (Ident.name id))
  | Types.Sig_class_type (id, _, _, Types.Exported) ->
      Some (Class_type (Ident.name id))
  | Types.Sig_module (id, _, md, _, Types.Exported) -> (
      match md.md_type with
      | Types.Mty_alias p -> Some (alias units env id p)
      | mty -> Some (Module (Ident.name id, Node (node units env mty))))
  | Types.Sig_typext _ -> None
  | Types.Sig_value (_, _, Types.Hidden)
  | Types.Sig_type (_, _, _, Types.Hidden)
  | Types.Sig_modtype (_, _, Types.Hidden)
  | Types.Sig_class (_, _, _, Types.Hidden)
  | Types.Sig_class_type (_, _, _, Types.Hidden)
  | Types.Sig_module (_, _, _, _, Types.Hidden) ->
      None

let unit_of_file f =
  if Filename.check_suffix f ".cmi" then
    let base = Filename.chop_suffix f ".cmi" in
    Some (String.capitalize_ascii base)
  else None

let rec pp_node depth ppf = function
  | Sig items -> List.iter (pp_item depth ppf) items
  | Functor { param; param_type; result } ->
      Format.fprintf ppf "%*sfunctor (%s : %s)@\n" depth "" param param_type;
      pp_node (depth + 2) ppf result
  | Opaque why -> Format.fprintf ppf "%*sopaque (%s)@\n" depth "" why

and pp_item depth ppf = function
  | Value v -> Format.fprintf ppf "%*sval %s@\n" depth "" v
  | Type (t, n) -> Format.fprintf ppf "%*stype %s/%d@\n" depth "" t n
  | Module_type m -> Format.fprintf ppf "%*smodule type %s@\n" depth "" m
  | Class c -> Format.fprintf ppf "%*sclass %s@\n" depth "" c
  | Class_type c -> Format.fprintf ppf "%*sclass type %s@\n" depth "" c
  | Module (m, Alias a) ->
      Format.fprintf ppf "%*smodule %s = %s@\n" depth "" m a
  | Module (m, Dotted (a, n)) ->
      Format.fprintf ppf "%*smodule %s = %s@\n" depth "" m a;
      pp_node (depth + 2) ppf n
  | Module (m, Node n) ->
      Format.fprintf ppf "%*smodule %s@\n" depth "" m;
      pp_node (depth + 2) ppf n

let pp ppf t =
  List.iter (fun (ty, n) -> Format.fprintf ppf "type %s/%d@\n" ty n) t.types;
  List.iter (fun v -> Format.fprintf ppf "val %s@\n" v) t.values;
  List.iter
    (fun (m, n) ->
      Format.fprintf ppf "module %s@\n" m;
      pp_node 2 ppf n)
    t.modules

(* The aliases of [Stdlib] to the units it names: [(Stdlib__Sys, Sys)]. *)
let units sg =
  List.filter_map
    (function
      | Types.Sig_module
          ( id,
            _,
            { md_type = Types.Mty_alias (Path.Pident u); _ },
            _,
            Types.Exported )
        when Ident.global u ->
          Some (Ident.name u, Ident.name id)
      | _ -> None)
    sg

(* The units of the standard library that [Stdlib] does not name: its
   runtime support, CamlinternalOO and the rest. *)
let internal_units dir =
  Sys.readdir dir |> Array.to_list |> List.sort String.compare
  |> List.filter_map unit_of_file
  |> List.filter (String.starts_with ~prefix:"Camlinternal")

(* {1 Values that hand out a channel} *)

let channel_types = [ "in_channel"; "out_channel"; "formatter" ]

(* Whether [ty] is a closure whose last result is [unit]: an output
   function. *)
let output_closure env ty =
  let rec result ty =
    match Types.get_desc (Ctype.expand_head env ty) with
    | Types.Tarrow (_, _, r, _) -> result r
    | Types.Tconstr (p, [], _) -> Path.same p Predef.path_unit
    | _ -> false
  in
  match Types.get_desc (Ctype.expand_head env ty) with
  | Types.Tarrow (_, _, r, _) -> result r
  | _ -> false

(* Whether [ty], expanded, is a channel, a formatter, or a record or a tuple
   that holds an output closure, such as [Format.formatter_out_functions]. *)
let channel_like env ty =
  match Types.get_desc ty with
  | Types.Tconstr (p, _, _) -> (
      List.mem (Path.last p) channel_types
      ||
      match (Env.find_type p env).type_kind with
      | Types.Type_record (fields, _) ->
          List.exists
            (fun (l : Types.label_declaration) -> output_closure env l.ld_type)
            fields
      | _ -> false
      | exception Not_found -> false)
  | Types.Ttuple _ ->
      let found = ref false in
      Btype.iter_type_expr
        (fun t -> if output_closure env t then found := true)
        ty;
      !found
  | _ -> false

(* [(gives, takes)]: whether a channel-like type occurs in a positive
   position of [ty], so that the value hands one out (as a result, or to a
   callback), and whether one occurs in a negative position, so that the
   value takes one as an argument. *)
let polarities env ty =
  let gives = ref false and takes = ref false in
  let seen = Hashtbl.create 16 in
  let rec go pos ty =
    let ty = Ctype.expand_head env ty in
    let key = (Types.get_id ty, pos) in
    if not (Hashtbl.mem seen key) then (
      Hashtbl.add seen key ();
      if channel_like env ty then if pos then gives := true else takes := true;
      match Types.get_desc ty with
      | Types.Tarrow (_, a, r, _) ->
          go (not pos) a;
          go pos r
      | _ -> Btype.iter_type_expr (go pos) ty)
  in
  go true ty;
  (!gives, !takes)

(* The values of the signature at [prefix] whose type hands out a channel,
   a formatter or output closures and takes none, by their path as {!Policy}
   spells it. An alias in [Stdlib] itself is followed to the unit it names;
   an alias below it is skipped, since the module it names is read on its
   own. *)
let rec channels_of env prefix mty =
  let join n = if prefix = "" then n else prefix ^ "." ^ n in
  match mty with
  | Types.Mty_alias p -> channels_of env prefix (Env.find_module p env).md_type
  | _ -> (
      match Mtype.scrape env mty with
      | Types.Mty_signature sg ->
          let env = Env.add_signature sg env in
          List.concat_map
            (function
              | Types.Sig_value (id, vd, Types.Exported) -> (
                  match polarities env vd.Types.val_type with
                  | true, false -> [ join (Ident.name id) ]
                  | _ -> [])
              | Types.Sig_module (id, _, md, _, Types.Exported) -> (
                  match md.Types.md_type with
                  | Types.Mty_alias p when prefix = "" ->
                      channels_of env (Ident.name id)
                        (Env.find_module p env).md_type
                  | Types.Mty_alias _ -> []
                  | mty -> channels_of env (join (Ident.name id)) mty)
              | _ -> [])
            sg
      | Types.Mty_functor (Types.Named (Some id, pty), res) ->
          channels_of (Env.add_module id Types.Mp_present pty env) prefix res
      | _ -> [])

let read dir =
  Clflags.no_std_include := true;
  Clflags.include_dirs := [ dir ];
  Compmisc.init_path ();
  let env = Compmisc.initial_env () in
  let find lid units =
    node units env (snd (Env.find_module_by_name lid env)).md_type
  in
  let _, stdlib = Env.find_module_by_name (Longident.Lident "Stdlib") env in
  let sg =
    match Mtype.scrape env stdlib.md_type with
    | Types.Mty_signature sg -> sg
    | _ -> failwith "Stdlib is not a signature"
  in
  let units = units sg in
  let items =
    match find (Longident.Lident "Stdlib") units with Sig i -> i | _ -> []
  in
  let in_stdlib =
    List.filter_map (function Module (m, _) -> Some m | _ -> None) items
  in
  let modules =
    List.map
      (fun m ->
        (m, find (Option.get (Longident.unflatten [ "Stdlib"; m ])) units))
      in_stdlib
    @ List.map
        (fun u -> (u, find (Longident.Lident u) units))
        (internal_units dir)
  in
  let channels =
    channels_of env "" stdlib.md_type
    @ List.concat_map
        (fun u ->
          channels_of env u
            (snd (Env.find_module_by_name (Longident.Lident u) env)).md_type)
        (internal_units dir)
  in
  {
    channels;
    types =
      List.filter_map (function Type (t, n) -> Some (t, n) | _ -> None) items;
    values = List.filter_map (function Value v -> Some v | _ -> None) items;
    modules;
    in_stdlib;
  }

let rec mem_node node = function
  | [] -> true
  | name :: rest -> (
      match node with
      | Sig items ->
          List.exists
            (function
              | Value v -> v = name && rest = []
              | Class c | Class_type c -> c = name && rest = []
              | Module (m, (Node n | Dotted (_, n))) ->
                  m = name && mem_node n rest
              | Module (m, Alias _) -> m = name && rest = []
              | Type _ | Module_type _ -> false)
            items
      | Functor { result; _ } -> mem_node result (name :: rest)
      | Opaque _ -> false)

let mem t path =
  match String.split_on_char '.' path with
  | [] -> false
  | [ name ] -> List.mem name t.values || List.mem_assoc name t.modules
  | m :: rest -> (
      match List.assoc_opt m t.modules with
      | Some n -> mem_node n rest
      | None -> false)
