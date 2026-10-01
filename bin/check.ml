(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

type finding =
  | Not_opened of string
  | Not_fatal
  | Silenced of { loc : Location.t; spec : string }
  | Stdlib_unit of { loc : Location.t; unit : string }
  | External of { loc : Location.t; name : string; primitive : string }
  | Unreadable of string

type report = { name : string; findings : finding list }

let opened args =
  let rec go acc = function
    | "-open" :: m :: rest -> go (m :: acc) rest
    | _ :: rest -> go acc rest
    | [] -> acc
  in
  go [] args

let ambient =
  {
    Warnings.kind = "ambient";
    message = "";
    def = Location.none;
    use = Location.none;
  }

(* Whether the ambient alert is an error once [specs] are applied, in order,
   over [base], by the compiler's own parser of -alert options. *)
let fatal_after ~base specs =
  let saved = Warnings.backup () in
  Fun.protect ~finally:(fun () -> Warnings.restore saved) @@ fun () ->
  List.iter Warnings.parse_alert_option (base @ specs);
  match Warnings.report_alert ambient with
  | `Active { is_error; _ } -> is_error
  | `Inactive -> false

let alert_options args =
  let rec go acc = function
    | "-alert" :: spec :: rest -> go (spec :: acc) rest
    | _ :: rest -> go acc rest
    | [] -> List.rev acc
  in
  go [] args

(* The payload of an [[@alert "spec"]] attribute, which sets alerts for its
   scope, as opposed to [[@@alert name "message"]], which declares one. *)
let alert_setting (attr : Parsetree.attribute) =
  match (attr.attr_name.txt, attr.attr_payload) with
  | ( ("alert" | "ocaml.alert"),
      PStr
        [
          {
            pstr_desc =
              Pstr_eval
                ( {
                    pexp_desc =
                      Pexp_constant
                        { pconst_desc = Pconst_string (spec, _, _); _ };
                    _;
                  },
                  _ );
            _;
          };
        ] ) ->
      Some spec
  | _ -> None

let stdlib_unit path =
  let head = Path.head path in
  let name = Ident.name head in
  if Ident.persistent head && String.starts_with ~prefix:"Stdlib__" name then
    Some name
  else None

let walk structure =
  let found = ref [] in
  let add f = found := f :: !found in
  let default = Tast_iterator.default_iterator in
  let attribute sub (attr : Parsetree.attribute) =
    (match alert_setting attr with
    | Some spec when not (fatal_after ~base:[ "@ambient" ] [ spec ]) ->
        add (Silenced { loc = attr.attr_loc; spec })
    | Some _ | None -> ());
    default.attribute sub attr
  in
  let reference loc path =
    Option.iter (fun unit -> add (Stdlib_unit { loc; unit })) (stdlib_unit path)
  in
  let expr sub (e : Typedtree.expression) =
    (match e.exp_desc with
    | Texp_ident (path, _, _) -> reference e.exp_loc path
    | _ -> ());
    default.expr sub e
  in
  let module_expr sub (m : Typedtree.module_expr) =
    (match m.mod_desc with
    | Tmod_ident (path, _) -> reference m.mod_loc path
    | _ -> ());
    default.module_expr sub m
  in
  let value_description sub (vd : Typedtree.value_description) =
    (match vd.val_prim with
    | [] -> ()
    | primitive :: _ ->
        add (External { loc = vd.val_loc; name = vd.val_name.txt; primitive }));
    default.value_description sub vd
  in
  (* The default [attributes] visits each attribute with the default
     [attribute], not the iterator's, so both are replaced. *)
  let attributes sub attrs = List.iter (attribute sub) attrs in
  let iterator =
    { default with attribute; attributes; expr; module_expr; value_description }
  in
  iterator.structure iterator structure;
  let line = function
    | Silenced { loc; _ } | Stdlib_unit { loc; _ } | External { loc; _ } ->
        (loc.loc_start.pos_lnum, loc.loc_start.pos_cnum)
    | Not_opened _ | Not_fatal | Unreadable _ -> (0, 0)
  in
  List.stable_sort (fun a b -> compare (line a) (line b)) (List.rev !found)

let read path =
  match Cmt_format.read_cmt path with
  | cmt -> Ok cmt
  | exception Sys_error msg -> Error msg
  | exception
      ( Cmt_format.Error (Not_a_typedtree _)
      | Cmi_format.Error _ | End_of_file | Failure _ ) ->
      Error "not a .cmt file of this compiler"

let unit ~opens path =
  match read path with
  | Error msg -> { name = path; findings = [ Unreadable msg ] }
  | Ok cmt ->
      let args = Array.to_list cmt.cmt_args in
      let opened = opened args in
      let missing =
        List.filter_map
          (fun m -> if List.mem m opened then None else Some (Not_opened m))
          opens
      in
      let fatal =
        if fatal_after ~base:[] (alert_options args) then [] else [ Not_fatal ]
      in
      let body =
        match cmt.cmt_annots with
        | Implementation structure -> walk structure
        | Interface _ | Packed _ | Partial_implementation _
        | Partial_interface _ ->
            [ Unreadable "not the .cmt of an implementation" ]
      in
      let name = Option.value cmt.cmt_sourcefile ~default:path in
      { name; findings = missing @ fatal @ body }

let pp_finding ppf = function
  | Not_opened m -> Fmt.pf ppf "compiled without -open %s" m
  | Not_fatal -> Fmt.pf ppf "compiled without -alert @@ambient"
  | Silenced { loc; spec } ->
      Fmt.pf ppf "line %d: [@@alert %S] makes the ambient alert a warning"
        loc.loc_start.pos_lnum spec
  | Stdlib_unit { loc; unit } ->
      Fmt.pf ppf
        "line %d: %s names a unit of the standard library past the prelude"
        loc.loc_start.pos_lnum unit
  | External { loc; name; primitive } ->
      Fmt.pf ppf "line %d: external %s declares the primitive %S"
        loc.loc_start.pos_lnum name primitive
  | Unreadable msg -> Fmt.pf ppf "unreadable: %s" msg
