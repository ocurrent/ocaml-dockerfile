
let string_of_t () =
  let open Dockerfile in
  let dockerfile =
    from "macos-homebrew-ocaml-5.0"
    @@ run "rm -rf /"
    @@ from "macos-homebrew-ocaml-5.0"
    @@ copy ~src:[ "dockerfile.opam"; "dockerfile-cmd.opam" ] ~dst:"./" ()
  in
  let generated = string_of_t dockerfile in
  let expected =
    {|FROM macos-homebrew-ocaml-5.0
RUN rm -rf /

FROM macos-homebrew-ocaml-5.0
COPY [ "dockerfile.opam", "dockerfile-cmd.opam", "./" ]|}
  in
  Alcotest.(check string) "string_of_t" expected generated

let crunch () =
  let open Dockerfile in
  let dockerfile =
    run "touch hello"
    @@ run "echo \"hello\" > hello"
    @@ run "rm hello"
  in
  let generated = crunch dockerfile in
  let expected =
    {|RUN touch hello && \
  echo "hello" > hello && \
  rm hello|}
  in
  Alcotest.(check string) "crunch" expected (string_of_t generated)

let () =
  Alcotest.(run "test" [
    "dockerfile", [
      test_case "string_of_t" `Quick string_of_t;
      test_case "crunch" `Quick crunch;
    ];
  ])
