let test_distro_compare () =
  let open Dockerfile_opam in
  (* Check that Distro.compare thinks that Distro.distros is in sort order *)
  match Distro.distros with
  | [] -> assert false
  | hd::tl ->
      let check (errors, prev) this =
        let errors =
          if Distro.is_same_distro prev this
             && Dockerfile_opam.Distro.compare this prev < 0 then
            let this = Distro.human_readable_string_of_distro this in
            let prev = Distro.human_readable_string_of_distro prev in
(Printf.sprintf "%s < %s" this prev) :: errors
          else
            errors
        in
        (errors, this)
      in
      let errors, _ = List.fold_left check ([], hd) tl in
      let msg = String.concat "\n" errors in
      Alcotest.(check' bool) ~msg ~expected:true ~actual:(errors = [])

let () =
  Alcotest.(
    run "test"
      [
        ( "dockerfile-opam",
          [
            test_case "Distro.compare" `Quick
              test_distro_compare;
          ] );
      ])
