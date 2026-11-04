let test_distro_compare () =
  let open Dockerfile_opam in
  (* Check that Distro.compare thinks that Distro.distros is in sort order *)
  match Distro.distros with
  | [] -> assert false
  | hd :: tl ->
      let check (errors, prev) this =
        let errors =
          if
            Distro.is_same_distro prev this
            && Dockerfile_opam.Distro.compare this prev < 0
          then
            let this = Distro.human_readable_string_of_distro this in
            let prev = Distro.human_readable_string_of_distro prev in
            Printf.sprintf "%s < %s" this prev :: errors
          else errors
        in
        (errors, this)
      in
      let errors, _ = List.fold_left check ([], hd) tl in
      let msg = String.concat "\n" errors in
      Alcotest.(check' bool) ~msg ~expected:true ~actual:(errors = [])

let test_opam_version () =
  let open Dockerfile_opam in
  let pp = Opam_version.pp in
  let t = Alcotest.testable pp Opam_version.equal in
  (* every version round-trips through its string form *)
  List.iter
    (fun v ->
      Alcotest.(check (result t (Alcotest.of_pp (fun _ _ -> ()))))
        (Opam_version.to_string v) (Ok v)
        (Opam_version.of_string (Opam_version.to_string v)))
    Opam_version.all;
  (* [all] is in ascending order and ends with [`Dev] *)
  let rec ascending = function
    | a :: (b :: _ as tl) -> Opam_version.compare a b < 0 && ascending tl
    | _ -> true
  in
  Alcotest.(check bool) "all ascending" true (ascending Opam_version.all);
  Alcotest.(check t)
    "last is dev" `Dev
    (List.nth Opam_version.all (List.length Opam_version.all - 1));
  Alcotest.(check bool)
    "releases excludes dev" false
    (List.mem `Dev Opam_version.releases);
  Alcotest.(check bool)
    "latest < dev" true
    (Opam_version.compare Opam_version.latest `Dev < 0);
  Alcotest.(check string) "binary" "opam-dev" (Opam_version.binary `Dev);
  Alcotest.(check string) "branch" "master" (Opam_version.branch `Dev);
  Alcotest.(check string) "branch" "2.6" (Opam_version.branch `V2_6);
  Alcotest.(check (result t string))
    "yojson round-trip" (Ok `V2_6)
    Opam_version.(of_yojson (to_yojson `V2_6));
  (* The exact shape is what [@@deriving yojson] produced in the CIs before
     this module existed; it is baked into their cache digests. *)
  Alcotest.(check bool)
    "yojson shape matches deriving yojson" true
    (Opam_version.to_yojson `V2_6 = `List [ `String "V2_6" ]
    && Opam_version.to_yojson `Dev = `List [ `String "Dev" ]);
  Alcotest.(check bool)
    "yojson rejects the string form" true
    (Result.is_error (Opam_version.of_yojson (`String "2.6")));
  Alcotest.(check bool)
    "yojson rejects unknown constructor" true
    (Result.is_error (Opam_version.of_yojson (`List [ `String "V9_9" ])))

(* [opam] links to the oldest version requested, so the default follows the
   list rather than a constant that needs editing when a release is dropped. *)
let test_default_opam_link () =
  let open Dockerfile_opam in
  let gen distro versions =
    let opam_hashes = List.map (fun v -> (v, "deadbeef")) versions in
    Dockerfile.string_of_t (snd (gen_opam2_distro ~opam_hashes distro))
  in
  let linux = `Debian `V12 and windows = `WindowsServer (`Mingw, `Ltsc2022) in
  let contains needle haystack =
    let n = String.length needle and h = String.length haystack in
    let rec go i =
      i + n <= h && (String.sub haystack i n = needle || go (i + 1))
    in
    go 0
  in
  Alcotest.(check bool)
    "linux links opam to 2.1 given all" true
    (contains "ln /usr/bin/opam-2.1 /usr/bin/opam\n"
       (gen linux Opam_version.all));
  Alcotest.(check bool)
    "linux links opam to the oldest requested" true
    (contains "ln /usr/bin/opam-2.3 /usr/bin/opam\n"
       (gen linux [ `V2_6; `V2_3; `Dev ]));
  Alcotest.(check bool)
    "windows links opam.exe to 2.2 given all" true
    (contains {|opam.exe C:\cygwin64\usr\local\bin\opam-2.2.exe|}
       (gen windows Opam_version.all));
  Alcotest.(check bool)
    "windows skips 2.1 and links the oldest native" true
    (contains {|opam.exe C:\cygwin64\usr\local\bin\opam-2.3.exe|}
       (gen windows [ `V2_1; `V2_3; `Dev ]));
  Alcotest.check_raises "without dev"
    (Invalid_argument "gen_opam2_distro: no hash given for opam dev") (fun () ->
      ignore (gen linux Opam_version.releases))

let () =
  Alcotest.(
    run "test"
      [
        ( "dockerfile-opam",
          [
            test_case "Distro.compare" `Quick test_distro_compare;
            test_case "Opam_version" `Quick test_opam_version;
            test_case "default opam link" `Quick test_default_opam_link;
          ] );
      ])
