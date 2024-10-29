#!/bin/bash

set -euo pipefail
# set -x

main() {
    if [[ ${#} -eq 0 ]]; then
        ${0} \
            'quay.io/fedora/fedora-coreos' \
            'next' \
            'Fedora CoreOS (next)' \
            'fedora-coreos' \
            'quay.io/travier' \
            'fedora-coreos-sysexts'

        ${0} \
            'quay.io/fedora-ostree-desktops/kinoite' \
            '41' \
            'Fedora Kinoite (41)' \
            'fedora-kinoite' \
            'quay.io/travier' \
            'fedora-kinoite-sysexts'

        exit 0
    fi

    local -r image="${1}"
    local -r release="${2}"
    local -r name="${3}"
    local -r shortname="${4}"
    local -r registry="${5}"
    local -r destination="${6}"

    # Get the list of sysexts
    sysexts=()
    for s in $(git ls-tree -d --name-only HEAD ../.. | grep -Ev ".github|^../$" | sed 's|../../||'); do
        pushd "../../${s}" > /dev/null
        if [[ $(just targets | grep -c "${image}:${release}") == "1" ]]; then
            sysexts+=("${s}")
        fi
        popd > /dev/null
    done

    # Generate EROFS sysexts workflows
    {
    sed \
        -e "s|%%IMAGE%%|${image}:${release}|g" \
        -e "s|%%RELEASE%%|${release}|g" \
        -e "s|%%NAME%%|${name}|g" \
        -e "s|%%SHORTNAME%%|${name}|g" \
        templates/sysexts_header
    echo ""
    for s in "${sysexts[@]}"; do
        sed "s|%%SYSEXT%%|${s}|g" templates/sysexts_body
        echo ""
    done
    cat templates/sysexts_footer
    } > "sysexts-${shortname}-${release}.yml"

    # Generate container sysexts workflows
    {
    sed \
        -e "s|%%IMAGE%%|${image}|g" \
        -e "s|%%RELEASE%%|${release}|g" \
        -e "s|%%NAME%%|${name}|g" \
        -e "s|%%REGISTRY%%|${registry}|g" \
        -e "s|%%DESTINATION%%|${destination}|g" \
        templates/containers_header
    echo ""
    for s in "${sysexts[@]}"; do
        sed "s|%%SYSEXT%%|${s}|g" templates/containers_build
        echo ""
    done
    cat templates/containers_logincosign
    for s in "${sysexts[@]}"; do
        sed "s|%%SYSEXT%%|${s}|g" templates/containers_pushsign
        echo ""
    done
    } > "containers-${shortname}-${release}.yml"
}

main "${@}"
