#!/usr/bin/env sh

# Use repology.org to retrieve the version of Bubblewrap in Linux
# distributions we're tracking. Missing CentOS and OracleLinux.

command -v curl >/dev/null || exit
command -v jq >/dev/null || exit

curl -Ls 'https://repology.org/api/v1/project/bubblewrap' | \
    jq 'map(select(.repo | test("^(debian_1\\d$)|ubuntu_2|arch$|alpine_3_1[^0-5]|opensuse_leap_15_[^0-3]|fedora_3[^0-5]")) | {repo, origversion}) | unique | sort_by(.repo)'
