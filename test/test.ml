let () =
  Alcotest.run "hermetic"
    [ Test_hermetic.suite; Test_hermetic_eio.suite; Test_hermetic_check.suite ]
