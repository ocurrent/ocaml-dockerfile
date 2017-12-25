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
  let init ?(name="Docker") ?(email="docker@example.com") () =
    run "git config --global user.email %S" email @@
    run "git config --global user.name %S" name
end

let sudo_nopasswd = "ALL=(ALL:ALL) NOPASSWD:ALL"

(** RPM rules *)
module RPM = struct
  let update = run "yum update -y"
  let install fmt = ksprintf (run "rpm --rebuilddb && yum install -y %s && yum clean all") fmt
  let groupinstall fmt = ksprintf (run "rpm --rebuilddb && yum groupinstall -y %s && yum clean all") fmt

  let add_user ?uid ?gid ?(sudo=false) username =
    let uid = match uid with Some u -> sprintf "-u %d " u | None -> "" in
    let gid = match gid with Some g -> sprintf "-g %d " g | None -> "" in
    let home = "/home/"^username in
    (match sudo with
    | false -> empty
    | true ->
        let sudofile = "/etc/sudoers.d/"^username in
        run "echo '%s %s' > %s" username sudo_nopasswd sudofile @@
        run "chmod 440 %s" sudofile @@
        run "chown root:root %s" sudofile @@
        run "sed -i.bak 's/^Defaults.*requiretty//g' /etc/sudoers") @@
    run "useradd -d %s %s%s-m -s /bin/bash %s" home uid gid username @@
    run "passwd -l %s" username @@
    run "chown -R %s:%s %s" username username home @@
    user "%s" username @@
    env ["HOME", home] @@
    workdir "%s" home @@
    run "mkdir .ssh" @@
    run "chmod 700 .ssh"

  let dev_packages ?extra () =
    install "sudo passwd bzip2 patch nano gcc-c++ git%s" (match extra with None -> "" | Some x -> " " ^ x) @@
    groupinstall "\"Development Tools\""

  let install_system_ocaml =
    install "ocaml ocaml-camlp4-devel ocaml-ocamldoc"
end

(** Debian rules *)
module Apt = struct
  let update = run "apt-get -y update" @@ run "DEBIAN_FRONTEND=noninteractive apt-get -y upgrade"
  let install fmt = ksprintf (fun s -> update @@ run "DEBIAN_FRONTEND=noninteractive apt-get -y install %s" s) fmt

  let dev_packages ?extra () =
    update @@
    run "echo 'Acquire::Retries \"5\";' > /etc/apt/apt.conf.d/mirror-retry" @@
    install "sudo pkg-config git build-essential m4 software-properties-common aspcud unzip rsync curl dialog nano libx11-dev%s"
      (match extra with None -> "" | Some x -> " " ^ x)

  let add_user ?uid ?gid ?(sudo=false) username =
    let uid = match uid with Some u -> sprintf "--uid %d " u | None -> "" in
    let gid = match gid with Some g -> sprintf "--gid %d " g | None -> "" in
    let home = "/home/"^username in
    (match sudo with
    | false -> empty
    | true ->
        let sudofile = "/etc/sudoers.d/"^username in
        run "echo '%s %s' > %s" username sudo_nopasswd sudofile @@
        run "chmod 440 %s" sudofile @@
        run "chown root:root %s" sudofile) @@
    run "adduser %s%s--disabled-password --gecos '' %s" uid gid username @@
    run "passwd -l %s" username @@
    run "chown -R %s:%s %s" username username home @@
    user "%s" username @@
    env ["HOME", home] @@
    workdir "%s" home @@
    run "mkdir .ssh" @@
    run "chmod 700 .ssh"

  let install_system_ocaml =
    install "ocaml ocaml-native-compilers camlp4-extra rsync"

end

(** Alpine rules *)
module Apk = struct
  let update = run "apk update && apk upgrade"
  let install fmt = ksprintf (fun s -> update @@ run "apk add %s" s) fmt

  let dev_packages ?extra () =
    install "alpine-sdk openssh bash nano ncurses-dev %s"
      (match extra with None -> "" | Some x -> " " ^ x)

  let add_user ?uid ?gid ?(sudo=false) username =
    let home = "/home/"^username in
    run "adduser -S %s%s%s"
      (match uid with None -> "" | Some d -> sprintf "-u %d " d)
      (match gid with None -> "" | Some g -> sprintf "-g %d " g)
      username @@
    (match sudo with
    | false -> empty
    | true ->
        let sudofile = "/etc/sudoers.d/"^username in
        run "echo '%s %s' > %s" username sudo_nopasswd sudofile @@
        run "chmod 440 %s" sudofile @@
        run "chown root:root %s" sudofile @@
        run "sed -i.bak 's/^Defaults.*requiretty//g' /etc/sudoers") @@
    user "%s" username @@
    workdir "%s" home @@
    run "mkdir .ssh" @@
    run "chmod 700 .ssh"

  let install_system_ocaml =
    run "apk add ocaml camlp4"
end

(* Zypper (opensuse) rules *)
module Zypper = struct
  let update = run "zypper update -y"
  let install fmt = ksprintf (fun s -> update @@ run "zypper install --force-resolution -y %s" s) fmt

  let dev_packages ?extra () =
    install "-t pattern devel_C_C++" @@
    install "sudo git unzip curl gcc-c++" @@
    (maybe (install "%s") extra)

  let add_user ?uid ?gid ?(sudo=false) username =
    let home = "/home/"^username in
    run "useradd %s%s -d %s -m %s"
      (match uid with None -> "" | Some d -> sprintf "-u %d " d)
      (match gid with None -> "" | Some g -> sprintf "-g %d " g)
      home username @@
    (match sudo with
    | false -> empty
    | true ->
        let sudofile = "/etc/sudoers.d/"^username in
        run "echo '%s %s' > %s" username sudo_nopasswd sudofile @@
        run "chmod 440 %s" sudofile @@
        run "chown root:root %s" sudofile) @@
    user "%s" username @@
    workdir "%s" home @@
    run "mkdir .ssh" @@
    run "chmod 700 .ssh"

  let install_system_ocaml =
    install "ocaml camlp4 ocaml-ocamldoc"
end
