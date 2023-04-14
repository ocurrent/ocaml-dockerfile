let test_string_of_t_formatting_simple_image () =
  let open Dockerfile in
  let actual = from "image" @@ run "script" |> string_of_t
  and expected = "FROM image\nRUN script\n" in
  Alcotest.(check' string) ~msg:"basic" ~expected ~actual;
  let actual = comment "comment" @@ from "image" @@ run "script" |> string_of_t
  and expected = "# comment\nFROM image\nRUN script\n" in
  Alcotest.(check' string) ~msg:"basic comment" ~expected ~actual;
  let actual =
    parser_directive (`Syntax "\\") @@ from "image" @@ run "script"
    |> string_of_t
  and expected = "# syntax=\\\n\nFROM image\nRUN script\n" in
  Alcotest.(check' string) ~msg:"with parser_directive" ~expected ~actual;
  let actual =
    parser_directive (`Syntax "\\")
    @@ comment "comment" @@ from "image" @@ run "script"
    |> string_of_t
  and expected = "# syntax=\\\n\n# comment\nFROM image\nRUN script\n" in
  Alcotest.(check' string)
    ~msg:"with parser_directive and comment" ~expected ~actual

let test_string_of_t_formatting_multiple_images () =
  let open Dockerfile in
  let actual =
    parser_directive (`Syntax "\\")
    @@ comment "comment" @@ from "image" @@ run "script" @@ from "image"
    @@ run "script"
    |> string_of_t
  and expected =
    {|# syntax=\

# comment
FROM image
RUN script

FROM image
RUN script
|}
  in
  Alcotest.(check' string) ~msg:"without comment" ~expected ~actual;
  let actual =
    parser_directive (`Syntax "\\")
    @@ comment "comment" @@ from "image" @@ run "script" @@ comment "comment"
    @@ from "image" @@ run "script"
    |> string_of_t
  and expected =
    {|# syntax=\

# comment
FROM image
RUN script

# comment
FROM image
RUN script
|}
  in
  Alcotest.(check' string) ~msg:"with comment" ~expected ~actual;
  let actual =
    parser_directive (`Syntax "\\")
    @@ arg "FOO" @@ arg "BAR" @@ from "image" @@ run "script"
    @@ comment "comment" @@ from "image" @@ arg "BAZ" @@ run "script"
    |> string_of_t
  and expected =
    {|# syntax=\

ARG FOO
ARG BAR

FROM image
RUN script

# comment
FROM image
ARG BAZ
RUN script
|}
  in
  Alcotest.(check' string) ~msg:"with args and comment" ~expected ~actual;
  let actual =
    parser_directive (`Syntax "\\")
    @@ comment "comment" @@ arg "FOO" @@ comment "comment" @@ arg "BAR"
    @@ comment "comment" @@ from "image" @@ run "script" @@ comment "comment"
    @@ from "image" @@ arg "BAZ" @@ run "script" @@ comment "comment"
    @@ run "script"
    |> string_of_t
  and expected =
    {|# syntax=\

# comment
ARG FOO

# comment
ARG BAR

# comment
FROM image
RUN script

# comment
FROM image
ARG BAZ
RUN script
# comment
RUN script
|}
  in
  Alcotest.(check' string) ~msg:"complete" ~expected ~actual;
  ()

let () =
  Alcotest.(
    run "test"
      [
        ( "dockerfile",
          [
            test_case "string_of_t" `Quick
              test_string_of_t_formatting_simple_image;
            test_case "string_of_t" `Quick
              test_string_of_t_formatting_multiple_images;
          ] );
      ])
