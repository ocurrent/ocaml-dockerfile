(*
 * Copyright (c) 2014 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

open Dockerfile
open Printf

let run_sh fmt = ksprintf (run "sh -c %S") fmt
let run_as_user user fmt = ksprintf (run "sudo -u %s sh -c %S" user) fmt

module Git = struct
  let init ?(name = "Docker") ?(email = "docker@example.com") () =
    run "git config --global user.email %S" email
    @@ run "git config --global user.name %S" name
end

let sudo_nopasswd = "ALL=(ALL:ALL) NOPASSWD:ALL"

(** RPM rules *)
module RPM = struct
  let update = run "yum update -y"

  let install fmt =
    ksprintf
      (fun s -> update @@ run "yum install -y %s && yum clean all" s |> crunch)
      fmt

  let groupinstall fmt =
    ksprintf (fun s -> run "yum groupinstall -y %s && yum clean all" s) fmt

  let dev_packages ?extra () =
    let install = ksprintf (run "yum install -y %s") in
    update
    @@ install
         "sudo passwd bzip2 patch rsync nano gcc-c++ git tar curl xz \
          libX11-devel which m4 diffutils findutils%s"
         (match extra with None -> "" | Some x -> " " ^ x)
    @@ groupinstall "\"Development Tools\""
    |> crunch

  let add_user ?uid ?gid ?(sudo = false) username =
    let uid = match uid with Some u -> sprintf "-u %d " u | None -> "" in
    let gid = match gid with Some g -> sprintf "-g %d " g | None -> "" in
    let home = "/home/" ^ username in
    (match sudo with
    | false -> empty
    | true ->
        let sudofile = "/etc/sudoers.d/" ^ username in
        copy_heredoc
          ~src:[ heredoc ~strip:true "\t%s %s" username sudo_nopasswd ]
          ~dst:sudofile ()
        @@ run "chmod 440 %s" sudofile
        @@ run "chown root:root %s" sudofile
        @@ run "sed -i.bak 's/^Defaults.*requiretty//g' /etc/sudoers")
    @@ run "useradd -d %s %s%s-m -s /bin/bash %s" home uid gid username
    @@ run "passwd -l %s" username
    @@ run "chown -R %s:%s %s" username username home
    @@ user "%s" username
    @@ env [ ("HOME", home) ]
    @@ workdir "%s" home @@ run "mkdir .ssh" @@ run "chmod 700 .ssh"

  let install_system_ocaml = install "ocaml ocaml-camlp4-devel ocaml-ocamldoc"
end

(** Debian rules *)
module Apt = struct
  let update =
    run "apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade"

  let install fmt =
    ksprintf
      (fun s ->
        update
        @@ run "DEBIAN_FRONTEND=noninteractive apt-get -y install %s" s
        @@ run "rm -rf /var/lib/apt/lists/*"
        |> crunch)
      fmt

  let dev_packages ?extra () =
    copy_heredoc
      ~src:[ heredoc ~strip:true "\tAcquire::Retries \"5\";" ]
      ~dst:"/etc/apt/apt.conf.d/mirror-retry" ()
    @@ install
         "build-essential curl git rsync sudo unzip nano libcap-dev \
          libx11-dev%s"
         (match extra with None -> "" | Some x -> " " ^ x)

  let add_user ?uid ?gid ?(sudo = false) username =
    let uid = match uid with Some u -> sprintf "--uid %d " u | None -> "" in
    let gid = match gid with Some g -> sprintf "--gid %d " g | None -> "" in
    let home = "/home/" ^ username in
    (match sudo with
    | false -> empty
    | true ->
        let sudofile = "/etc/sudoers.d/" ^ username in
        copy_heredoc
          ~src:[ heredoc ~strip:true "\t%s %s" username sudo_nopasswd ]
          ~dst:sudofile ()
        @@ run "chmod 440 %s" sudofile
        @@ run "chown root:root %s" sudofile)
    @@ run "adduser %s%s--disabled-password --gecos '' %s" uid gid username
    @@ run "passwd -l %s" username
    @@ run "chown -R %s:%s %s" username username home
    @@ user "%s" username
    @@ env [ ("HOME", home) ]
    @@ workdir "%s" home @@ run "mkdir .ssh" @@ run "chmod 700 .ssh"

  let install_system_ocaml =
    install "ocaml ocaml-native-compilers camlp4-extra rsync"
end

(** Alpine rules *)
module Apk = struct
  let update = run "apk update && apk upgrade"

  let install fmt =
    ksprintf
      (fun s ->
        update @@ run "apk add %s && rm -f /var/cache/apk/*" s |> crunch)
      fmt

  let dev_packages ?extra () =
    install
      "build-base patch tar ca-certificates git rsync curl sudo bash \
       libx11-dev nano coreutils xz ncurses-dev%s"
      (match extra with None -> "" | Some x -> " " ^ x)

  let add_user ?uid ?gid ?(sudo = false) username =
    let home = "/home/" ^ username in
    (match gid with
    | None -> empty
    | Some gid -> run "addgroup -S -g %d %s" gid username)
    @@ run "adduser -S %s%s%s"
         (match uid with None -> "" | Some d -> sprintf "-u %d " d)
         (match gid with None -> "" | Some _ -> sprintf "-G %s " username)
         username
    @@ (match sudo with
       | false -> empty
       | true ->
           let sudofile = "/etc/sudoers.d/" ^ username in
           copy_heredoc
             ~src:[ heredoc ~strip:true "\t%s %s" username sudo_nopasswd ]
             ~dst:sudofile ()
           @@ run "chmod 440 %s" sudofile
           @@ run "chown root:root %s" sudofile
           @@ run "sed -i.bak 's/^Defaults.*requiretty//g' /etc/sudoers")
    @@ user "%s" username @@ workdir "%s" home @@ run "mkdir .ssh"
    @@ run "chmod 700 .ssh"

  let install_system_ocaml = install "ocaml camlp4"

  let add_repository ?tag url =
    run "<<-EOF cat >> /etc/apk/repositories\n\t%s\nEOF"
      (match tag with None -> url | Some tag -> sprintf "@%s %s" tag url)

  let add_repositories repos =
    let repos =
      String.concat ""
        (List.map
           (function
             | None, url -> url | Some tag, url -> sprintf "\n\t@%s %s" tag url)
           repos)
    in
    run "<<-EOF cat >> /etc/apk/repositories%s\nEOF" repos
end

(* Zypper (opensuse) rules *)
module Zypper = struct
  let update = run "zypper update -y"

  let install fmt =
    ksprintf
      (fun s ->
        update
        @@ run "zypper install --force-resolution -y %s" s
        @@ run "zypper clean --all"
        |> crunch)
      fmt

  let dev_packages ?extra () =
    let install fmt =
      ksprintf (run "zypper install --force-resolution -y %s") fmt
    in
    update
    @@ install "-t pattern devel_C_C++"
    @@ install
         "sudo git unzip curl gcc-c++ libcap-devel xz libX11-devel bzip2 which \
          rsync gzip%s"
         (match extra with None -> "" | Some x -> " " ^ x)
    @@ run "zypper clean --all"
    |> crunch

  let add_user ?uid ?gid ?(sudo = false) username =
    let home = "/home/" ^ username in
    run "useradd %s%s -d %s -m --user-group %s"
      (match uid with None -> "" | Some d -> sprintf "-u %d " d)
      (match gid with None -> "" | Some g -> sprintf "-g %d " g)
      home username
    @@ (match sudo with
       | false -> empty
       | true ->
           let sudofile = "/etc/sudoers.d/" ^ username in
           copy_heredoc
             ~src:[ heredoc ~strip:true "\t%s %s" username sudo_nopasswd ]
             ~dst:sudofile ()
           @@ run "chmod 440 %s" sudofile
           @@ run "chown root:root %s" sudofile)
    @@ user "%s" username @@ workdir "%s" home @@ run "mkdir .ssh"
    @@ run "chmod 700 .ssh"

  let install_system_ocaml = install "ocaml camlp4 ocaml-ocamldoc"
end

(** Pacman rules *)
module Pacman = struct
  let update = run "pacman -Syu --noconfirm"

  let install fmt =
    ksprintf (fun s -> run "pacman -Syu --noconfirm %s && pacman -Scc" s) fmt

  let dev_packages ?extra () =
    install
      "make gcc patch tar ca-certificates git rsync curl sudo bash libx11 nano \
       coreutils xz ncurses diffutils unzip%s"
      (match extra with None -> "" | Some x -> " " ^ x)

  let add_user ?uid ?gid ?(sudo = false) username =
    let home = "/home/" ^ username in
    run "useradd %s%s -d %s -m --user-group %s"
      (match uid with None -> "" | Some d -> sprintf "-u %d " d)
      (match gid with None -> "" | Some g -> sprintf "-g %d " g)
      home username
    @@ (match sudo with
       | false -> empty
       | true ->
           let sudofile = "/etc/sudoers.d/" ^ username in
           copy_heredoc
             ~src:[ heredoc ~strip:true "\t%s %s" username sudo_nopasswd ]
             ~dst:sudofile ()
           @@ run "chmod 440 %s" sudofile
           @@ run "chown root:root %s" sudofile)
    @@ user "%s" username @@ workdir "%s" home @@ run "mkdir .ssh"
    @@ run "chmod 700 .ssh"

  let install_system_ocaml = install "ocaml ocaml-compiler-libs"
end
