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

let test_issue_193 () =
  let open Dockerfile in
  let actual =
    buildkit_syntax @@ from "debian"
    @@ run_heredoc
         [
           ( heredoc ~word:"EOT"
               {|  set -ex
  apt-get update
  apt-get install -y vim|},
             Some "bash" );
         ]
    |> string_of_t
  and expected =
    {|# syntax=docker/dockerfile:1

FROM debian
RUN <<EOT bash
  set -ex
  apt-get update
  apt-get install -y vim
EOT
|}
  in
  Alcotest.(check' string)
    ~msg:"RUN heredocs multi-line script" ~expected ~actual;
  let actual =
    buildkit_syntax @@ from "debian"
    @@ run_heredoc [ (heredoc ~word:"EOT" {|  mkdir -p foo/bar|}, None) ]
    |> string_of_t
  and expected =
    {|# syntax=docker/dockerfile:1

FROM debian
RUN <<EOT
  mkdir -p foo/bar
EOT
|}
  in
  Alcotest.(check' string) ~msg:"RUN heredocs default shell" ~expected ~actual;
  let actual =
    buildkit_syntax @@ from "python:3.6"
    @@ run_heredoc
         [
           ( heredoc ~word:"EOT" {|#!/usr/bin/env python
print("hello world")|},
             None );
         ]
    |> string_of_t
  and expected =
    {|# syntax=docker/dockerfile:1

FROM python:3.6
RUN <<EOT
#!/usr/bin/env python
print("hello world")
EOT
|}
  in
  Alcotest.(check' string) ~msg:"RUN heredocs shebang header" ~expected ~actual;
  let actual =
    buildkit_syntax @@ from "alpine"
    @@ run_heredoc
         [
           (heredoc ~word:"FILE1" "I am\nfirst", Some "cat > file1");
           (heredoc ~word:"FILE2" "I am\nsecond", Some "cat > file2");
         ]
    |> string_of_t
  and expected =
    {|# syntax=docker/dockerfile:1

FROM alpine
RUN <<FILE1 cat > file1 && <<FILE2 cat > file2
I am
first
FILE1
I am
second
FILE2
|}
  in
  Alcotest.(check' string) ~msg:"RUN multiple heredocs" ~expected ~actual;
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
            test_case "Format RUN heredocs" `Quick test_issue_193;
          ] );
      ])
