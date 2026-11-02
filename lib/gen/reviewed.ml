(*---------------------------------------------------------------------------
  Copyright (c) 2026 Thomas Gazagnaire. All rights reserved.
  SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(* The names of the standard library that the policy has reviewed and keeps,
   read from OCaml 5.3, 5.4 and 5.5 with [gen --review] and merged. A name
   that policy.ml refuses or names is not listed here, and neither is a value
   whose name says [unsafe], which only policy.ml can keep. A newer
   compiler's names are missing until they are reviewed; until then the
   prelude refuses them.

   The reason of each group is one word:
   - core: the language's own operations, conversions and references;
   - pure: a function of its arguments;
   - data: a data structure, read or changed through a value handed in;
   - channel, format: works on a channel, formatter or buffer handed in;
   - given: works on what it is handed: a lexer buffer, an argv, a channel,
     a file descriptor, a socket or a child process;
   - process: the process environment, a fact of the process, its user or
     its host, the processor time it has used, its exit and its signals,
     none of which is an Eio capability;
   - constant: a fact fixed when the program is built;
   - concurrency: threads, synchronisation and domain-local state, which
     reach no capability;
   - runtime: the runtime's own state (the garbage collector, backtraces,
     registered printers, counters, whether tables are randomised), which
     reaches no capability;
   - local: the default generator, which is domain-local and seeded
     deterministically;
   - seeded: a generator made from a seed handed in;
   - internal: the runtime support the compiler's output calls. *)

let modules =
  [
    "Arg";
    "Array";
    "Array.Floatarray";
    "ArrayLabels";
    "ArrayLabels.Floatarray";
    "Atomic";
    "Atomic.Loc";
    "Bigarray";
    "Bigarray.Array0";
    "Bigarray.Array1";
    "Bigarray.Array2";
    "Bigarray.Array3";
    "Bigarray.Genarray";
    "Bool";
    "Buffer";
    "Bytes";
    "BytesLabels";
    "Callback";
    "CamlinternalFormat";
    "CamlinternalFormat.Args";
    "CamlinternalFormatBasics";
    "CamlinternalLazy";
    "Char";
    "Char.Ascii";
    "Complex";
    "Condition";
    "Digest";
    "Digest.BLAKE128";
    "Digest.BLAKE256";
    "Digest.BLAKE512";
    "Digest.MD5";
    "Domain";
    "Domain.DLS";
    "Dynarray";
    "Effect";
    "Effect.Deep";
    "Effect.Shallow";
    "Either";
    "Ephemeron";
    "Event";
    "Ephemeron.K1";
    "Ephemeron.K1.Bucket";
    "Ephemeron.K1.Make";
    "Ephemeron.K1.MakeSeeded";
    "Ephemeron.K2";
    "Ephemeron.K2.Bucket";
    "Ephemeron.K2.Make";
    "Ephemeron.K2.MakeSeeded";
    "Ephemeron.Kn";
    "Ephemeron.Kn.Bucket";
    "Ephemeron.Kn.Make";
    "Ephemeron.Kn.MakeSeeded";
    "Filename";
    "Float";
    "Float.Array";
    "Float.ArrayLabels";
    "Format";
    "Format.Args";
    "Fun";
    "Gc";
    "Gc.Memprof";
    "Gc.Tweak";
    "Hashtbl";
    "Hashtbl.Make";
    "Hashtbl.MakeSeeded";
    "Iarray";
    "In_channel";
    "Int";
    "Int32";
    "Int64";
    "LargeFile";
    "Lazy";
    "Lazy.Mutexed";
    "Lexing";
    "List";
    "ListLabels";
    "Map";
    "Map.Make";
    "Marshal";
    "MoreLabels";
    "MoreLabels.Hashtbl";
    "MoreLabels.Hashtbl.Make";
    "MoreLabels.Hashtbl.MakeSeeded";
    "MoreLabels.Map";
    "MoreLabels.Map.Make";
    "MoreLabels.Set";
    "MoreLabels.Set.Make";
    "Mutex";
    "Nativeint";
    "Oo";
    "Option";
    "Option.Syntax";
    "Out_channel";
    "Pair";
    "Parsing";
    "Pqueue";
    "Pqueue.MakeMax";
    "Pqueue.MakeMaxPoly";
    "Pqueue.MakeMin";
    "Pqueue.MakeMinPoly";
    "Printexc";
    "Printexc.Slot";
    "Printf";
    "Printf.Args";
    "Queue";
    "Random";
    "Random.State";
    "Repr";
    "Result";
    "Result.Syntax";
    "Scanf";
    "Scanf.Scanning";
    "Semaphore";
    "Semaphore.Binary";
    "Semaphore.Counting";
    "Seq";
    "Set";
    "Set.Make";
    "Stack";
    "StdLabels";
    "Std_exit";
    "String";
    "StringLabels";
    "Sys";
    "Sys.Immediate64";
    "Sys.Immediate64.Make";
    "Thread";
    "Type";
    "Type.Id";
    "Uchar";
    "Unit";
    "Unix";
    "Unix.LargeFile";
    "UnixLabels";
    "UnixLabels.LargeFile";
    "Weak";
    "Weak.Make";
  ]

let kept =
  [
    ( "",
      "core",
      "__FILE__ __FUNCTION__ __LINE__ __LINE_OF__ __LOC__ __LOC_OF__ \
       __MODULE__ __POS__ __POS_OF__ - -. := ! != @ @@ * *. ** / /. && ^ ^^ + \
       +. < <= <> = == > >= |> || ~- ~-. ~+ ~+. abs abs_float acos acosh asin \
       asinh asr atan atan2 atanh bool_of_string bool_of_string_opt ceil \
       char_of_int classify_float close_in close_in_noerr close_out \
       close_out_noerr compare copysign cos cosh decr epsilon_float exp expm1 \
       failwith float float_of_int float_of_string float_of_string_opt floor \
       flush format_of_string frexp fst hypot ignore in_channel_length incr \
       infinity input input_binary_int input_byte input_char input_line \
       int_of_char int_of_float int_of_string int_of_string_opt invalid_arg \
       land ldexp lnot log log10 log1p lor lsl lsr lxor max max_float max_int \
       min min_float min_int mod mod_float modf nan neg_infinity not \
       out_channel_length output output_binary_int output_byte output_bytes \
       output_char output_string output_substring output_value pos_in pos_out \
       pred raise raise_notrace really_input really_input_string ref seek_in \
       seek_out set_binary_mode_in set_binary_mode_out sin sinh snd sqrt \
       string_of_bool string_of_float string_of_format string_of_int succ tan \
       tanh truncate valid_float_lexem" );
    ("", "process", "at_exit do_at_exit do_domain_local_at_exit exit");
    ( "Arg",
      "given",
      "align current parse_and_expand_argv_dynamic parse_argv \
       parse_argv_dynamic usage_string" );
    ( "Array",
      "data",
      "append blit combine compare concat copy create_float equal exists \
       exists2 fast_sort fill find_index find_map find_mapi find_opt fold_left \
       fold_left_map fold_right for_all for_all2 get init init_matrix iter \
       iter2 iteri length make make_matrix map map_inplace map2 mapi \
       mapi_inplace mem memq of_list of_seq set shuffle sort split stable_sort \
       stable_sort_sub sub to_list to_seq to_seqi" );
    ("Array.Floatarray", "data", "create get length set");
    ( "ArrayLabels",
      "data",
      "append blit combine compare concat copy create_float equal exists \
       exists2 fast_sort fill find_index find_map find_mapi find_opt fold_left \
       fold_left_map fold_right for_all for_all2 get init init_matrix iter \
       iter2 iteri length make make_matrix map map_inplace map2 mapi \
       mapi_inplace mem memq of_list of_seq set shuffle sort split stable_sort \
       stable_sort_sub sub to_list to_seq to_seqi" );
    ("ArrayLabels.Floatarray", "data", "create get length set");
    ( "Atomic",
      "concurrency",
      "compare_and_set decr exchange fetch_and_add get incr make \
       make_contended set" );
    ( "Atomic.Loc",
      "concurrency",
      "compare_and_set decr exchange fetch_and_add get incr set" );
    ( "Bigarray",
      "data",
      "array0_of_genarray array1_of_genarray array2_of_genarray \
       array3_of_genarray c_layout char complex32 complex64 float16 float32 \
       float64 fortran_layout genarray_of_array0 genarray_of_array1 \
       genarray_of_array2 genarray_of_array3 int int16_signed int16_unsigned \
       int32 int64 int8_signed int8_unsigned kind_size_in_bytes nativeint \
       reshape reshape_0 reshape_1 reshape_2 reshape_3" );
    ( "Bigarray.Array0",
      "data",
      "blit change_layout create fill get init kind layout of_value set \
       size_in_bytes" );
    ( "Bigarray.Array1",
      "data",
      "blit change_layout create dim fill get init kind layout of_array set \
       size_in_bytes slice sub" );
    ( "Bigarray.Array2",
      "data",
      "blit change_layout create dim1 dim2 fill get init kind layout of_array \
       set size_in_bytes slice_left slice_right sub_left sub_right" );
    ( "Bigarray.Array3",
      "data",
      "blit change_layout create dim1 dim2 dim3 fill get init kind layout \
       of_array set size_in_bytes slice_left_1 slice_left_2 slice_right_1 \
       slice_right_2 sub_left sub_right" );
    ( "Bigarray.Genarray",
      "data",
      "blit change_layout create dims fill get init kind layout nth_dim \
       num_dims set size_in_bytes slice_left slice_right sub_left sub_right" );
    ( "Bool",
      "pure",
      "&& || compare equal hash logand logor logxor not seeded_hash to_float \
       to_int to_string" );
    ( "Buffer",
      "data",
      "add_buffer add_bytes add_channel add_char add_int16_be add_int16_le \
       add_int16_ne add_int32_be add_int32_le add_int32_ne add_int64_be \
       add_int64_le add_int64_ne add_int8 add_seq add_string add_subbytes \
       add_substitute add_substring add_uint16_be add_uint16_le add_uint16_ne \
       add_uint8 add_utf_16be_uchar add_utf_16le_uchar add_utf_8_uchar blit \
       clear contents create length nth of_seq output_buffer reset sub \
       to_bytes to_seq to_seqi truncate" );
    ( "Bytes",
      "data",
      "blit blit_string capitalize_ascii cat compare concat contains \
       contains_from copy create empty ends_with equal escaped exists extend \
       fill fold_left fold_right for_all get get_int16_be get_int16_le \
       get_int16_ne get_int32_be get_int32_le get_int32_ne get_int64_be \
       get_int64_le get_int64_ne get_int8 get_uint16_be get_uint16_le \
       get_uint16_ne get_uint8 get_utf_16be_uchar get_utf_16le_uchar \
       get_utf_8_uchar index index_from index_from_opt index_opt init \
       is_valid_utf_16be is_valid_utf_16le is_valid_utf_8 iter iteri length \
       lowercase_ascii make map mapi of_seq of_string rcontains_from rindex \
       rindex_from rindex_from_opt rindex_opt set set_int16_be set_int16_le \
       set_int16_ne set_int32_be set_int32_le set_int32_ne set_int64_be \
       set_int64_le set_int64_ne set_int8 set_uint16_be set_uint16_le \
       set_uint16_ne set_uint8 set_utf_16be_uchar set_utf_16le_uchar \
       set_utf_8_uchar split_on_char starts_with sub sub_string to_seq to_seqi \
       to_string trim uncapitalize_ascii uppercase_ascii" );
    ( "BytesLabels",
      "data",
      "blit blit_string capitalize_ascii cat compare concat contains \
       contains_from copy create empty ends_with equal escaped exists extend \
       fill fold_left fold_right for_all get get_int16_be get_int16_le \
       get_int16_ne get_int32_be get_int32_le get_int32_ne get_int64_be \
       get_int64_le get_int64_ne get_int8 get_uint16_be get_uint16_le \
       get_uint16_ne get_uint8 get_utf_16be_uchar get_utf_16le_uchar \
       get_utf_8_uchar index index_from index_from_opt index_opt init \
       is_valid_utf_16be is_valid_utf_16le is_valid_utf_8 iter iteri length \
       lowercase_ascii make map mapi of_seq of_string rcontains_from rindex \
       rindex_from rindex_from_opt rindex_opt set set_int16_be set_int16_le \
       set_int16_ne set_int32_be set_int32_le set_int32_ne set_int64_be \
       set_int64_le set_int64_ne set_int8 set_uint16_be set_uint16_le \
       set_uint16_ne set_uint8 set_utf_16be_uchar set_utf_16le_uchar \
       set_utf_8_uchar split_on_char starts_with sub sub_string to_seq to_seqi \
       to_string trim uncapitalize_ascii uppercase_ascii" );
    ("Callback", "runtime", "register register_exception");
    ( "CamlinternalFormat",
      "internal",
      "add_in_char_set bufput_acc char_of_iconv create_char_set \
       fmt_ebb_of_string format_of_string_fmtty format_of_string_format \
       freeze_char_set is_in_char_set make_iprintf make_lprintf make_printf \
       open_box_of_string output_acc param_format_of_ignored_format recast \
       rev_char_set string_of_fmt string_of_fmtty string_of_formatting_lit \
       strput_acc symm trans type_format" );
    ("CamlinternalFormat.Args", "internal", "@ apply");
    ( "CamlinternalFormatBasics",
      "internal",
      "concat_fmt concat_fmtty erase_rel string_concat_map" );
    ("CamlinternalLazy", "internal", "force_gen force_lazy_block indirect");
    ( "Char",
      "pure",
      "chr code compare equal escaped hash lowercase_ascii seeded_hash \
       uppercase_ascii" );
    ( "Char.Ascii",
      "pure",
      "digit_of_int digit_to_int hex_digit_to_int is_alphanum is_blank \
       is_control is_digit is_graphic is_hex_digit is_letter is_lower is_print \
       is_upper is_valid is_white lower_hex_digit_of_int lowercase max min \
       upper_hex_digit_of_int uppercase" );
    ( "Complex",
      "pure",
      "add arg conj div exp i inv log mul neg norm norm2 one polar pow sqrt \
       sub zero" );
    ("Condition", "concurrency", "broadcast create signal wait");
    ( "Digest",
      "pure",
      "bytes channel compare equal from_hex input of_hex output string \
       subbytes substring to_hex" );
    ( "Digest.BLAKE128",
      "pure",
      "bytes channel compare equal hash_length input of_hex output string \
       subbytes substring to_hex" );
    ( "Digest.BLAKE256",
      "pure",
      "bytes channel compare equal hash_length input of_hex output string \
       subbytes substring to_hex" );
    ( "Digest.BLAKE512",
      "pure",
      "bytes channel compare equal hash_length input of_hex output string \
       subbytes substring to_hex" );
    ( "Digest.MD5",
      "pure",
      "bytes channel compare equal hash_length input of_hex output string \
       subbytes substring to_hex" );
    ( "Domain",
      "concurrency",
      "before_first_spawn count cpu_relax get_id is_main_domain join self \
       self_index" );
    ("Domain", "process", "at_exit recommended_domain_count");
    ("Domain.DLS", "concurrency", "get new_key set");
    ( "Dynarray",
      "data",
      "add_last append append_array append_iter append_list append_seq blit \
       capacity clear compare copy create ensure_capacity \
       ensure_extra_capacity equal exists exists2 filter filter_map find_index \
       find_last find_map find_mapi find_opt fit_capacity fold_left fold_right \
       for_all for_all2 get get_last init is_empty iter iteri length make map \
       mapi mem memq of_array of_list of_seq pop_last pop_last_opt remove_last \
       reset rev_iter rev_iteri set set_capacity to_array to_list to_seq \
       to_seq_reentrant to_seq_rev to_seq_rev_reentrant truncate" );
    ("Effect", "runtime", "perform");
    ( "Effect.Deep",
      "runtime",
      "continue discontinue discontinue_with_backtrace get_callstack \
       match_with try_with" );
    ( "Effect.Shallow",
      "runtime",
      "continue_with discontinue_with discontinue_with_backtrace fiber \
       get_callstack" );
    ( "Either",
      "pure",
      "compare equal find_left find_right fold for_all get_left get_right \
       is_left is_right iter left map map_left map_right retract right" );
    ("Ephemeron.K1", "runtime", "make query");
    ("Ephemeron.K1.Bucket", "runtime", "add clear find length make remove");
    ( "Ephemeron.K1.Make",
      "runtime",
      "add add_seq clean clear copy create find find_all find_opt length mem \
       of_seq remove replace replace_seq reset stats stats_alive" );
    ( "Ephemeron.K1.MakeSeeded",
      "runtime",
      "add add_seq clean clear copy find find_all find_opt length mem remove \
       replace replace_seq reset stats stats_alive" );
    ("Ephemeron.K2", "runtime", "make query");
    ("Ephemeron.K2.Bucket", "runtime", "add clear find length make remove");
    ( "Ephemeron.K2.Make",
      "runtime",
      "add add_seq clean clear copy create find find_all find_opt length mem \
       of_seq remove replace replace_seq reset stats stats_alive" );
    ( "Ephemeron.K2.MakeSeeded",
      "runtime",
      "add add_seq clean clear copy find find_all find_opt length mem remove \
       replace replace_seq reset stats stats_alive" );
    ("Ephemeron.Kn", "runtime", "make query");
    ("Ephemeron.Kn.Bucket", "runtime", "add clear find length make remove");
    ( "Ephemeron.Kn.Make",
      "runtime",
      "add add_seq clean clear copy create find find_all find_opt length mem \
       of_seq remove replace replace_seq reset stats stats_alive" );
    ( "Ephemeron.Kn.MakeSeeded",
      "runtime",
      "add add_seq clean clear copy find find_all find_opt length mem remove \
       replace replace_seq reset stats stats_alive" );
    ( "Event",
      "concurrency",
      "always choose guard new_channel poll receive select send sync wrap \
       wrap_abort" );
    ( "Filename",
      "pure",
      "basename check_suffix chop_extension chop_suffix chop_suffix_opt concat \
       current_dir_name dir_sep dirname extension is_implicit is_relative null \
       parent_dir_name quote quote_command remove_extension" );
    ("Filename", "process", "get_temp_dir_name set_temp_dir_name");
    ( "Float",
      "pure",
      "abs acos acosh add asin asinh atan atan2 atanh cbrt ceil classify_float \
       compare copy_sign cos cosh div epsilon equal erf erfc exp exp2 expm1 \
       floor fma frexp hash hypot infinity is_finite is_infinite is_integer \
       is_nan ldexp log log10 log1p log2 max max_float max_num min min_float \
       min_max min_max_num min_num minus_one modf mul nan neg neg_infinity \
       next_after of_int of_string of_string_opt one pi pow pred quiet_nan rem \
       round seeded_hash sign_bit signaling_nan sin sinh sqrt sub succ tan \
       tanh to_int to_string trunc zero" );
    ( "Float.Array",
      "pure",
      "append blit compare concat copy create equal exists fast_sort fill \
       find_index find_map find_mapi find_opt fold_left fold_right for_all get \
       init init_matrix iter iter2 iteri length make make_matrix map \
       map_from_array map_inplace map_to_array map2 mapi mapi_inplace mem \
       mem_ieee of_list of_seq set shuffle sort stable_sort sub to_list to_seq \
       to_seqi" );
    ( "Float.ArrayLabels",
      "pure",
      "append blit compare concat copy create equal exists fast_sort fill \
       find_index find_map find_mapi find_opt fold_left fold_right for_all get \
       init init_matrix iter iter2 iteri length make make_matrix map \
       map_from_array map_inplace map_to_array map2 mapi mapi_inplace mem \
       mem_ieee of_list of_seq set shuffle sort stable_sort sub to_list to_seq \
       to_seqi" );
    ( "Format",
      "format",
      "add_symbolic_output_item ascii_width asprintf check_geometry \
       clear_symbolic_output_buffer dprintf flush_str_formatter \
       flush_symbolic_output_buffer format_text formatter_of_buffer \
       formatter_of_out_channel formatter_of_out_functions \
       formatter_of_symbolic_output_buffer fprintf get_ellipsis_text \
       get_geometry get_margin get_mark_tags get_max_boxes get_max_indent \
       get_print_tags get_stdbuf get_str_formatter get_symbolic_output_buffer \
       ifprintf ikfprintf kasprintf kdprintf kfprintf ksprintf lasprintf \
       ldprintf lfprintf make_formatter make_symbolic_output_buffer \
       make_synchronized_formatter over_max_boxes pp_close_box pp_close_stag \
       pp_close_tbox pp_force_newline pp_get_ellipsis_text \
       pp_get_formatter_out_functions pp_get_formatter_output_functions \
       pp_get_formatter_stag_functions pp_get_geometry pp_get_margin \
       pp_get_mark_tags pp_get_max_boxes pp_get_max_indent pp_get_print_tags \
       pp_infinity pp_open_box pp_open_hbox pp_open_hovbox pp_open_hvbox \
       pp_open_stag pp_open_tbox pp_open_vbox pp_over_max_boxes pp_print_array \
       pp_print_as pp_print_bool pp_print_break pp_print_bytes pp_print_char \
       pp_print_custom_break pp_print_cut pp_print_either pp_print_float \
       pp_print_flush pp_print_if_newline pp_print_int pp_print_iter \
       pp_print_list pp_print_newline pp_print_nothing pp_print_option \
       pp_print_result pp_print_seq pp_print_space pp_print_string \
       pp_print_substring pp_print_substring_as pp_print_tab pp_print_tbreak \
       pp_print_text pp_safe_set_geometry pp_set_ellipsis_text \
       pp_set_formatter_out_channel pp_set_formatter_out_functions \
       pp_set_formatter_output_functions pp_set_formatter_stag_functions \
       pp_set_geometry pp_set_margin pp_set_mark_tags pp_set_max_boxes \
       pp_set_max_indent pp_set_print_tags pp_set_tab pp_set_tags \
       pp_update_geometry safe_set_geometry set_ellipsis_text \
       set_formatter_out_channel set_formatter_out_functions \
       set_formatter_output_functions set_formatter_stag_functions \
       set_geometry set_margin set_mark_tags set_max_boxes set_max_indent \
       set_print_tags set_tags sprintf stdbuf str_formatter \
       synchronized_formatter_of_out_channel update_geometry \
       utf_8_scalar_width" );
    ("Format.Args", "format", "@ apply");
    ("Fun", "pure", "compose const flip id negate protect");
    ( "Gc",
      "runtime",
      "allocated_bytes compact counters create_alarm delete_alarm \
       eventlog_pause eventlog_resume finalise finalise_last finalise_release \
       full_major get get_minor_free major major_slice minor minor_words \
       print_stat quick_stat ramp_down ramp_up set stat" );
    ( "Gc.Memprof",
      "runtime",
      "discard is_sampling null_tracker start stop string_of_allocation_source"
    );
    ("Gc.Tweak", "runtime", "get list_active set");
    ( "Hashtbl",
      "data",
      "add add_seq clear copy filter_map_inplace find find_all find_and_remove \
       find_and_replace find_opt fold hash hash_param iter length mem remove \
       replace replace_seq reset seeded_hash seeded_hash_param stats to_seq \
       to_seq_keys to_seq_values" );
    ("Hashtbl", "runtime", "is_randomized randomize");
    ( "Hashtbl.Make",
      "data",
      "add add_seq clear copy create filter_map_inplace find find_all \
       find_and_remove find_and_replace find_opt fold iter length mem of_seq \
       remove replace replace_seq reset stats to_seq to_seq_keys to_seq_values"
    );
    ( "Hashtbl.MakeSeeded",
      "data",
      "add add_seq clear copy filter_map_inplace find find_all find_and_remove \
       find_and_replace find_opt fold iter length mem remove replace \
       replace_seq reset stats to_seq to_seq_keys to_seq_values" );
    ( "Iarray",
      "data",
      "append combine compare concat equal exists exists2 fast_sort find_index \
       find_map find_mapi find_opt fold_left fold_left_map fold_right for_all \
       for_all2 get init iter iter2 iteri length map map2 mapi mem memq \
       of_array of_list of_seq sort split stable_sort sub to_array to_list \
       to_seq to_seqi" );
    ( "In_channel",
      "channel",
      "close close_noerr fold_lines input input_all input_bigarray input_byte \
       input_char input_line input_lines is_binary_mode isatty length pos \
       really_input really_input_bigarray really_input_string seek \
       set_binary_mode" );
    ( "Int",
      "pure",
      "abs add cdiv compare div ediv equal erem fdiv hash leading_sign_bits \
       leading_zeros logand lognot logor logxor max max_int min min_int \
       minus_one mul neg of_float one popcount pred rem seeded_hash shift_left \
       shift_right shift_right_logical signed_bitsize sub succ to_float \
       to_string trailing_zeros unsigned_bitsize zero" );
    ( "Int32",
      "pure",
      "abs add bits_of_float cdiv compare div ediv equal erem fdiv \
       float_of_bits hash leading_sign_bits leading_zeros logand lognot logor \
       logxor max max_int min min_int minus_one mul neg of_float of_int \
       of_string of_string_opt one popcount pred rem seeded_hash shift_left \
       shift_right shift_right_logical signed_bitsize sub succ to_float to_int \
       to_string trailing_zeros unsigned_bitsize unsigned_compare unsigned_div \
       unsigned_rem unsigned_to_int zero" );
    ( "Int64",
      "pure",
      "abs add bits_of_float cdiv compare div ediv equal erem fdiv \
       float_of_bits hash leading_sign_bits leading_zeros logand lognot logor \
       logxor max max_int min min_int minus_one mul neg of_float of_int \
       of_int32 of_nativeint of_string of_string_opt one popcount pred rem \
       seeded_hash shift_left shift_right shift_right_logical signed_bitsize \
       sub succ to_float to_int to_int32 to_nativeint to_string trailing_zeros \
       unsigned_bitsize unsigned_compare unsigned_div unsigned_rem \
       unsigned_to_int zero" );
    ( "LargeFile",
      "channel",
      "in_channel_length out_channel_length pos_in pos_out seek_in seek_out" );
    ( "Lazy",
      "concurrency",
      "force force_val from_fun from_val is_val map map_val" );
    ("Lazy.Mutexed", "concurrency", "force from_fun from_val is_val");
    ( "Lexing",
      "given",
      "dummy_pos flush_input from_channel from_function from_string lexeme \
       lexeme_char lexeme_end lexeme_end_p lexeme_start lexeme_start_p \
       new_line set_filename set_position sub_lexeme sub_lexeme_char \
       sub_lexeme_char_opt sub_lexeme_opt with_positions" );
    ( "List",
      "pure",
      "append assoc assoc_opt assq assq_opt combine compare \
       compare_length_with compare_lengths concat concat_map cons drop \
       drop_while equal exists exists2 fast_sort filter filter_map filter_mapi \
       filteri find find_all find_index find_map find_mapi find_opt flatten \
       fold_left fold_left_map fold_left2 fold_right fold_right2 for_all \
       for_all2 hd init is_empty iter iter2 iteri length map map2 mapi mem \
       mem_assoc mem_assq memq merge nth nth_opt of_seq partition \
       partition_map remove_assoc remove_assq rev rev_append rev_map rev_map2 \
       singleton sort sort_uniq split split_map stable_sort take take_while tl \
       to_seq" );
    ( "ListLabels",
      "pure",
      "append assoc assoc_opt assq assq_opt combine compare \
       compare_length_with compare_lengths concat concat_map cons drop \
       drop_while equal exists exists2 fast_sort filter filter_map filter_mapi \
       filteri find find_all find_index find_map find_mapi find_opt flatten \
       fold_left fold_left_map fold_left2 fold_right fold_right2 for_all \
       for_all2 hd init is_empty iter iter2 iteri length map map2 mapi mem \
       mem_assoc mem_assq memq merge nth nth_opt of_seq partition \
       partition_map remove_assoc remove_assq rev rev_append rev_map rev_map2 \
       singleton sort sort_uniq split split_map stable_sort take take_while tl \
       to_seq" );
    ( "Map.Make",
      "pure",
      "add add_seq add_to_list bindings cardinal choose choose_opt compare \
       empty equal exists filter filter_map find find_first find_first_opt \
       find_last find_last_opt find_opt fold for_all is_empty is_singleton \
       iter map mapi max_binding max_binding_opt mem merge min_binding \
       min_binding_opt of_list of_seq partition remove singleton split to_list \
       to_rev_seq to_seq to_seq_from union update" );
    ( "Marshal",
      "given",
      "data_size header_size to_buffer to_bytes to_channel to_string total_size"
    );
    ( "MoreLabels.Hashtbl",
      "data",
      "add add_seq clear copy filter_map_inplace find find_all find_and_remove \
       find_and_replace find_opt fold hash hash_param iter length mem remove \
       replace replace_seq reset seeded_hash seeded_hash_param stats to_seq \
       to_seq_keys to_seq_values" );
    ("MoreLabels.Hashtbl", "runtime", "is_randomized randomize");
    ( "MoreLabels.Hashtbl.Make",
      "data",
      "add add_seq clear copy create filter_map_inplace find find_all \
       find_and_remove find_and_replace find_opt fold iter length mem of_seq \
       remove replace replace_seq reset stats to_seq to_seq_keys to_seq_values"
    );
    ( "MoreLabels.Hashtbl.MakeSeeded",
      "data",
      "add add_seq clear copy filter_map_inplace find find_all find_and_remove \
       find_and_replace find_opt fold iter length mem remove replace \
       replace_seq reset stats to_seq to_seq_keys to_seq_values" );
    ( "MoreLabels.Map.Make",
      "data",
      "add add_seq add_to_list bindings cardinal choose choose_opt compare \
       empty equal exists filter filter_map find find_first find_first_opt \
       find_last find_last_opt find_opt fold for_all is_empty is_singleton \
       iter map mapi max_binding max_binding_opt mem merge min_binding \
       min_binding_opt of_list of_seq partition remove singleton split to_list \
       to_rev_seq to_seq to_seq_from union update" );
    ( "MoreLabels.Set.Make",
      "data",
      "add add_seq cardinal choose choose_opt compare diff disjoint elements \
       empty equal exists filter filter_map find find_first find_first_opt \
       find_last find_last_opt find_opt fold for_all inter is_empty \
       is_singleton iter map max_elt max_elt_opt mem min_elt min_elt_opt \
       of_list of_seq partition remove singleton split subset to_list \
       to_rev_seq to_seq to_seq_from union" );
    ("Mutex", "concurrency", "create lock protect try_lock unlock");
    ( "Nativeint",
      "pure",
      "abs add cdiv compare div ediv equal erem fdiv hash leading_sign_bits \
       leading_zeros logand lognot logor logxor max max_int min min_int \
       minus_one mul neg of_float of_int of_int32 of_string of_string_opt one \
       popcount pred rem seeded_hash shift_left shift_right \
       shift_right_logical signed_bitsize size sub succ to_float to_int \
       to_int32 to_string trailing_zeros unsigned_bitsize unsigned_compare \
       unsigned_div unsigned_rem unsigned_to_int zero" );
    ("Oo", "runtime", "copy id new_method public_method_label");
    ( "Option",
      "pure",
      "bind blend compare equal exists fold for_all get is_none is_some iter \
       join map none product some to_list to_result to_seq value" );
    ("Option.Syntax", "pure", "and* and+ let* let+");
    ( "Out_channel",
      "channel",
      "close close_noerr flush is_binary_mode is_buffered isatty length output \
       output_bigarray output_byte output_bytes output_char output_string \
       output_substring pos seek set_binary_mode set_buffered" );
    ( "Pair",
      "pure",
      "compare equal fold fst iter make map map_fst map_snd snd swap" );
    ( "Parsing",
      "given",
      "clear_parser is_current_lookahead parse_error rhs_end rhs_end_pos \
       rhs_start rhs_start_pos set_trace symbol_end symbol_end_pos \
       symbol_start symbol_start_pos" );
    ( "Pqueue.MakeMax",
      "data",
      "add add_iter clear copy create fold_unordered get_max_elt is_empty \
       iter_unordered length max_elt of_array of_iter of_list pop_max \
       remove_max" );
    ( "Pqueue.MakeMaxPoly",
      "data",
      "add add_iter clear copy create fold_unordered get_max_elt is_empty \
       iter_unordered length max_elt of_array of_iter of_list pop_max \
       remove_max" );
    ( "Pqueue.MakeMin",
      "data",
      "add add_iter clear copy create fold_unordered get_min_elt is_empty \
       iter_unordered length min_elt of_array of_iter of_list pop_min \
       remove_min" );
    ( "Pqueue.MakeMinPoly",
      "data",
      "add add_iter clear copy create fold_unordered get_min_elt is_empty \
       iter_unordered length min_elt of_array of_iter of_list pop_min \
       remove_min" );
    ( "Printexc",
      "runtime",
      "backtrace_slots backtrace_slots_of_raw_entry backtrace_status \
       convert_raw_backtrace_slot exn_slot_id exn_slot_name get_backtrace \
       get_callstack get_raw_backtrace get_raw_backtrace_next_slot \
       get_raw_backtrace_slot print_backtrace print_raw_backtrace \
       raise_with_backtrace raw_backtrace_entries raw_backtrace_length \
       raw_backtrace_to_string record_backtrace register_printer \
       string_of_extension_constructor to_string to_string_default \
       use_printers" );
    ("Printexc", "process", "set_uncaught_exception_handler");
    ("Printexc.Slot", "runtime", "format is_inline is_raise location name");
    ( "Printf",
      "format",
      "bprintf fprintf ibprintf ifprintf ikbprintf ikfprintf kbprintf kfprintf \
       kprintf ksprintf lbprintf lfprintf lsprintf sprintf" );
    ("Printf.Args", "format", "@ apply");
    ( "Queue",
      "data",
      "add add_seq clear copy create drop fold is_empty iter length of_seq \
       peek peek_opt pop push take take_opt to_seq top transfer" );
    ( "Random",
      "local",
      "bits bits32 bits64 bool float full_init full_int get_state init int \
       int_in_range int32 int32_in_range int64 int64_in_range nativebits \
       nativeint nativeint_in_range set_state split" );
    ( "Random.State",
      "seeded",
      "bits bits32 bits64 bool copy float full_int int int_in_range int32 \
       int32_in_range int64 int64_in_range make nativebits nativeint \
       nativeint_in_range of_binary_string split to_binary_string" );
    ("Repr", "pure", "compare equal max min phys_equal");
    ( "Result",
      "pure",
      "bind compare equal error error_to_failure fold get_error get_ok get_ok' \
       is_error is_ok iter iter_error join map map_error ok product retract \
       to_list to_option to_seq value" );
    ("Result.Syntax", "pure", "and* and+ let* let+");
    ( "Scanf",
      "format",
      "bscanf bscanf_format bscanf_opt format_from_string kscanf ksscanf \
       sscanf sscanf_format sscanf_opt unescaped" );
    ( "Scanf.Scanning",
      "format",
      "beginning_of_input close_in end_of_input from_channel from_function \
       from_string name_of_input" );
    ("Semaphore.Binary", "concurrency", "acquire make release try_acquire");
    ( "Semaphore.Counting",
      "concurrency",
      "acquire get_value make release try_acquire" );
    ( "Seq",
      "pure",
      "append compare concat concat_map cons cycle delay drop drop_while empty \
       equal exists exists2 filter filter_map filteri find find_index find_map \
       find_mapi flat_map fold_left fold_left2 fold_lefti for_all for_all2 \
       forever group init interleave ints is_empty iter iter2 iterate iteri \
       length map map_product map2 mapi memoize of_dispenser once partition \
       partition_map product repeat return scan singleton sorted_merge split \
       take take_while to_dispenser transpose uncons unfold unzip zip" );
    ( "Set.Make",
      "pure",
      "add add_seq cardinal choose choose_opt compare diff disjoint elements \
       empty equal exists filter filter_map find find_first find_first_opt \
       find_last find_last_opt find_opt fold for_all inter is_empty \
       is_singleton iter map max_elt max_elt_opt mem min_elt min_elt_opt \
       of_list of_seq partition remove singleton split subset to_list \
       to_rev_seq to_seq to_seq_from union" );
    ( "Stack",
      "data",
      "add_seq clear copy create drop fold is_empty iter length of_seq pop \
       pop_opt push to_seq top top_opt" );
    ( "String",
      "pure",
      "blit capitalize_ascii cat compare concat contains contains_from \
       cut_first cut_first_while cut_last cut_last_while drop_first \
       drop_first_while drop_last drop_last_while edit_distance empty \
       ends_with equal escaped exists find_all find_first find_first_index \
       find_last find_last_index fold_left fold_right for_all get get_int16_be \
       get_int16_le get_int16_ne get_int32_be get_int32_le get_int32_ne \
       get_int64_be get_int64_le get_int64_ne get_int8 get_uint16_be \
       get_uint16_le get_uint16_ne get_uint8 get_utf_16be_uchar \
       get_utf_16le_uchar get_utf_8_uchar hash includes index index_from \
       index_from_opt index_opt init is_empty is_valid_utf_16be \
       is_valid_utf_16le is_valid_utf_8 iter iteri length lowercase_ascii make \
       map mapi of_bytes of_char of_seq rcontains_from replace_all \
       replace_first replace_last rfind_all rindex rindex_from rindex_from_opt \
       rindex_opt rsplit_all seeded_hash spellcheck split_all split_first \
       split_last split_on_char starts_with sub take_first take_first_while \
       take_last take_last_while to_bytes to_seq to_seqi trim \
       uncapitalize_ascii uppercase_ascii" );
    ( "StringLabels",
      "pure",
      "blit capitalize_ascii cat compare concat contains contains_from \
       cut_first cut_first_while cut_last cut_last_while drop_first \
       drop_first_while drop_last drop_last_while edit_distance empty \
       ends_with equal escaped exists find_all find_first find_first_index \
       find_last find_last_index fold_left fold_right for_all get get_int16_be \
       get_int16_le get_int16_ne get_int32_be get_int32_le get_int32_ne \
       get_int64_be get_int64_le get_int64_ne get_int8 get_uint16_be \
       get_uint16_le get_uint16_ne get_uint8 get_utf_16be_uchar \
       get_utf_16le_uchar get_utf_8_uchar hash includes index index_from \
       index_from_opt index_opt init is_empty is_valid_utf_16be \
       is_valid_utf_16le is_valid_utf_8 iter iteri length lowercase_ascii make \
       map mapi of_bytes of_char of_seq rcontains_from replace_all \
       replace_first replace_last rfind_all rindex rindex_from rindex_from_opt \
       rindex_opt rsplit_all seeded_hash spellcheck split_all split_first \
       split_last split_on_char starts_with sub take_first take_first_while \
       take_last take_last_while to_bytes to_seq to_seqi trim \
       uncapitalize_ascii uppercase_ascii" );
    ( "Sys",
      "constant",
      "backend_type big_endian cygwin development_version \
       enable_runtime_warnings int_size io_buffer_size max_array_length \
       max_floatarray_length max_string_length ocaml_release ocaml_version \
       opaque_identity os_type runtime_variant runtime_warnings_enabled \
       sigabrt sigalrm sigbus sigchld sigcont sigfpe sighup sigill sigint \
       sigio sigkill signal_of_int signal_to_int signal_to_string sigpipe \
       sigpoll sigprof sigquit sigsegv sigstop sigsys sigterm sigtrap sigtstp \
       sigttin sigttou sigurg sigusr1 sigusr2 sigvtalrm sigwinch sigxcpu \
       sigxfsz unix win32 word_size" );
    ( "Sys",
      "process",
      "argv catch_break executable_name getenv getenv_opt interactive \
       poll_actions runtime_executable runtime_parameters set_signal signal \
       time" );
    ("Sys.Immediate64.Make", "constant", "repr");
    ( "Thread",
      "concurrency",
      "create exit id join select self set_current_thread_name \
       set_uncaught_exception_handler sigmask wait_pid wait_signal \
       wait_timed_read wait_timed_write yield" );
    ("Type.Id", "runtime", "make provably_equal uid");
    ( "Uchar",
      "pure",
      "bom compare equal hash is_char is_valid max max_utf_8_decode_length min \
       of_char of_int pred rep seeded_hash succ to_char to_int \
       utf_16_byte_length utf_8_byte_length utf_8_decode_length_of_byte \
       utf_decode utf_decode_invalid utf_decode_is_valid utf_decode_length \
       utf_decode_uchar" );
    ("Unit", "pure", "compare equal to_string");
    ( "Unix",
      "pure",
      "domain_of_sockaddr error_message gmtime inet6_addr_any \
       inet6_addr_loopback inet_addr_any inet_addr_loopback \
       inet_addr_of_string is_inet6_addr string_of_inet_addr" );
    ( "Unix",
      "given",
      "accept clear_close_on_exec clear_nonblock close close_process \
       close_process_full close_process_in close_process_out closedir \
       descr_of_in_channel descr_of_out_channel dup dup2 fchmod fchown fstat \
       fsync ftruncate getpeername getsockname getsockopt getsockopt_error \
       getsockopt_float getsockopt_int getsockopt_optint in_channel_of_descr \
       isatty listen lockf lseek map_file out_channel_of_descr pipe \
       process_full_pid process_in_pid process_out_pid process_pid read \
       read_bigarray readdir recv recvfrom rewinddir send send_substring \
       set_close_on_exec set_nonblock setsockopt setsockopt_float \
       setsockopt_int setsockopt_optint shutdown shutdown_connection \
       single_write single_write_bigarray single_write_substring socketpair \
       tcdrain tcflow tcflush tcgetattr tcsendbreak tcsetattr write \
       write_bigarray write_substring" );
    ("Unix.LargeFile", "given", "fstat ftruncate lseek");
    ( "Unix",
      "process",
      "_exit environment getegid getenv geteuid getgid getgroups getgrgid \
       getgrnam gethostname getlogin getpid getppid getpwnam getpwuid getuid \
       has_symlink initgroups localtime mktime nice pause putenv setgid \
       setgroups setsid setuid sigpending sigprocmask sigsuspend sigwait times \
       umask unsetenv" );
    ( "UnixLabels",
      "pure",
      "domain_of_sockaddr error_message gmtime inet6_addr_any \
       inet6_addr_loopback inet_addr_any inet_addr_loopback \
       inet_addr_of_string is_inet6_addr string_of_inet_addr" );
    ( "UnixLabels",
      "given",
      "accept clear_close_on_exec clear_nonblock close close_process \
       close_process_full close_process_in close_process_out closedir \
       descr_of_in_channel descr_of_out_channel dup dup2 fchmod fchown fstat \
       fsync ftruncate getpeername getsockname getsockopt getsockopt_error \
       getsockopt_float getsockopt_int getsockopt_optint in_channel_of_descr \
       isatty listen lockf lseek map_file out_channel_of_descr pipe \
       process_full_pid process_in_pid process_out_pid process_pid read \
       read_bigarray readdir recv recvfrom rewinddir send send_substring \
       set_close_on_exec set_nonblock setsockopt setsockopt_float \
       setsockopt_int setsockopt_optint shutdown shutdown_connection \
       single_write single_write_bigarray single_write_substring socketpair \
       tcdrain tcflow tcflush tcgetattr tcsendbreak tcsetattr write \
       write_bigarray write_substring" );
    ("UnixLabels.LargeFile", "given", "fstat ftruncate lseek");
    ( "UnixLabels",
      "process",
      "_exit environment getegid getenv geteuid getgid getgroups getgrgid \
       getgrnam gethostname getlogin getpid getppid getpwnam getpwuid getuid \
       has_symlink initgroups localtime mktime nice pause putenv setgid \
       setgroups setsid setuid sigpending sigprocmask sigsuspend sigwait times \
       umask unsetenv" );
    ("Weak", "runtime", "blit check create fill get get_copy length set");
    ( "Weak.Make",
      "runtime",
      "add clear count create find find_all find_opt fold iter mem merge \
       remove stats" );
  ]

let version_specific =
  [
    "Dynarray.unsafe_to_iarray";
    "Iarray.unsafe_get";
    "Printf.lprintf";
    "Printf.leprintf";
    "Format.lprintf";
    "Format.leprintf";
    "Thread.set_current_thread_name";
  ]

(* The kept values that hand out a channel, a formatter or output closures
   without taking one as an argument, each reviewed as making it from what it
   is handed, or from state that reaches no world. *)
let channels =
  [
    ("Format.formatter_of_buffer", "writes to the buffer it is handed");
    ( "Format.formatter_of_symbolic_output_buffer",
      "writes to the buffer it is handed" );
    ("Format.make_formatter", "writes with the functions it is handed");
    ( "Format.make_synchronized_formatter",
      "writes with the functions it is handed" );
    ("Format.str_formatter", "writes to Format.stdbuf, a buffer");
    ("Format.get_str_formatter", "writes to Format.stdbuf, a buffer");
    ("Gc.Memprof.null_tracker", "its callbacks do nothing");
    ("Lexing.from_string", "reads the string it is handed");
    ("Lexing.from_function", "reads with the function it is handed");
    ("Scanf.Scanning.from_string", "reads the string it is handed");
    ("Scanf.Scanning.from_function", "reads with the function it is handed");
    ("Unix.in_channel_of_descr", "reads the descriptor it is handed");
    ("Unix.out_channel_of_descr", "writes to the descriptor it is handed");
    ("UnixLabels.in_channel_of_descr", "reads the descriptor it is handed");
    ("UnixLabels.out_channel_of_descr", "writes to the descriptor it is handed");
  ]
