#!/bin/bash

# Clean up the docs folder from generated markdown pages.

set -euo pipefail
# set -x

main() {
    if [[ ! -d .github ]] || [[ ! -d .git ]]; then
        echo "This script must be run at the root of the repo"
        exit 1
    fi

    for s in $(git ls-tree -d --name-only HEAD | grep -Ev ".github|docs"); do
        rm -rf "./docs/${s}"
    done
}

main "${@}"
