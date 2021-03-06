#!/usr/bin/env bash

usage() {
  echo "Usage: bash $0 > manifests/init.pp"
  exit 1
}
[ "$1" == -h ] && usage

header() {
  cat <<'EOF'
# @summary A defined type wrapper for spawning
#   [puppetlabs/firewall](https://github.com/puppetlabs/puppetlabs-firewall)
#   resources for arrays of certain inputs.
#
# @param [Array] source An array of source IPs or CIDRs.
# @param [Array] destination An array of destination IPs or CIDRs.
# @param [Array] proto An array of protocols.
# @param [Array] icmp An array of ICMP types.
# @param [Array] provider An array of providers.
#
define firewall_multi (
  $ensure                      = undef,
  $provider                    = undef,
EOF
}

middle() {
  cat <<'EOF'
) {

  $firewalls = firewall_multi(
    {
      $name => {
        ensure                      => $ensure,
        provider                    => $provider,
EOF
}

footer() {
  cat <<'EOF'
      }
    }
  )

  create_resources(firewall, $firewalls)
}
EOF
}

firewall_lib() {
  cat "$path_to_firewall"'/lib/puppet/type/firewall.rb'
}

sort_cols() {
  sort | column -t
}

first_transform() {
  firewall_lib \
    | gsed -nE '
      /^  new/ {
        /(property|param)/ {
          /:name/! {
            s/^  newp.*\(:([^,\)]*).*/$\1 = undef,/p
          }
        }
      }
    ' | sort_cols | gsed '
      s/^/  /
      s/ = /=/
    '
}

second_transform() {
  firewall_lib \
    | gsed -nE '
      /^  new/ {
        /(property|param)/ {
          /:name/! {
            s/^  newp.*\(:([^,\)]*).*/\1 => $\1,/p
          }
        }
      }
    ' | sort_cols | gsed '
      s/^/        /
      s/ => /=>/
    '
}

main() {
  header
  first_transform
  middle
  second_transform
  footer
}

path_to_firewall=../puppetlabs-firewall

if [ "$0" == "${BASH_SOURCE[0]}" ] ; then
  main
fi

# vim: set ft=sh:
