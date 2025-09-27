#!/bin/bash

# SPDX-FileCopyrightText: Timothée Ravier <tim@siosm.fr>
# SPDX-License-Identifier: CC0-1.0

# Dynamically generate the list of sysexts to publish. Mainly used for the
# gather action in CI.

set -euo pipefail
# set -x

main() {
    if [[ ! -d .github ]] || [[ ! -d .git ]]; then
        echo "This script must be run at the root of the repo"
        exit 1
    fi

    # Get the list of sysexts
    sysexts=()
    for s in $(git ls-tree -d --name-only HEAD | grep -Ev ".github|docs|LICENSES"); do
        if [[ -f ./${s}/.ignore ]]; then
            continue
        fi
        sysexts+=("${s}")
    done
    echo "${sysexts[@]}"
}

main "${@}"
