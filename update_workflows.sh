#!/bin/bash

# Re-generate the GitHub workflows based on templates. We do not use a matrix
# build strategy in GitHub worflows to reduce overall build time and avoid
# pulling the same base container image multiple time, once for each individual
# job.

set -euo pipefail
# set -x

main() {
    if [[ ! -d .github ]] || [[ ! -d .git ]]; then
        echo "This script must be run at the root of the repo"
        exit 1
    fi

    # Re-run for each target
    if [[ ${#} -eq 0 ]]; then
        # Remove all existing worflows
        rm "./.github/workflows/containers"*".yml"
        rm "./.github/workflows/sysexts"*".yml"

        ${0} \
            'quay.io/fedora/fedora-coreos' \
            'stable' \
            'x86_64' \
            'Fedora CoreOS (stable)' \
            'fedora-coreos' \
            'quay.io/travier' \
            'fedora-coreos-sysexts'

        ${0} \
            'quay.io/fedora/fedora-coreos' \
            'stable' \
            'aarch64' \
            'Fedora CoreOS (stable)' \
            'fedora-coreos' \
            'quay.io/travier' \
            'fedora-coreos-sysexts'

        ${0} \
            'quay.io/fedora-ostree-desktops/kinoite' \
            '41' \
            'x86_64' \
            'Fedora Kinoite (41)' \
            'fedora-kinoite' \
            'quay.io/travier' \
            'fedora-kinoite-sysexts'

        ${0} \
            'quay.io/fedora-ostree-desktops/silverblue' \
            '41' \
            'x86_64' \
            'Fedora Silverblue (41)' \
            'fedora-silverblue' \
            'quay.io/travier' \
            'fedora-silverblue-sysexts'

        exit 0
    fi

    local -r image="${1}"
    local -r release="${2}"
    local -r arch="${3}"
    local -r name="${4}"
    local -r shortname="${5}"
    local -r registry="${6}"
    local -r destination="${7}"

    # Get the list of sysexts for a given target
    sysexts=()
    for s in $(git ls-tree -d --name-only HEAD | grep -Ev ".github|templates"); do
        pushd "${s}" > /dev/null
        # Only require the architecture to be explicitly listed for non x86_64 for now
        if [[ "${arch}" == "x86_64" ]]; then
            if [[ $(just targets | grep -c "${image}:${release}") == "1" ]]; then
                sysexts+=("${s}")
            fi
        else
            if [[ $(just targets | grep -cE "${image}:${release} .*${arch}.*") == "1" ]]; then
                sysexts+=("${s}")
            fi
        fi
        popd > /dev/null
    done

    local -r tmpl=".workflow-templates/"
    if [[ ! -d "${tmpl}" ]]; then
        echo "Could not find the templates. Is this script run from the root of the repo?"
        exit 1
    fi

    # Generate EROFS sysexts workflows
    {
    sed \
        -e "s|%%IMAGE%%|${image}:${release}|g" \
        -e "s|%%RELEASE%%|${release}|g" \
        -e "s|%%NAME%%|${name}|g" \
        -e "s|%%SHORTNAME%%|${shortname}|g" \
        -e "s|%%ARCH%%|${arch}|g" \
        "${tmpl}/sysexts_header"
    echo ""
    for s in "${sysexts[@]}"; do
        sed "s|%%SYSEXT%%|${s}|g" "${tmpl}/sysexts_body"
        echo ""
    done
    cat "${tmpl}/sysexts_footer"
    } > ".github/workflows/sysexts-${shortname}-${release}-${arch}.yml"

    # Fix GitHub runner for aarch64
    if [[ "${arch}" == "aarch64" ]]; then
        sed -i "s/ubuntu-24.04/ubuntu-24.04-arm/" ".github/workflows/sysexts-${shortname}-${release}-${arch}.yml"
    fi

    # Generate container sysexts workflows
    # Skip non x86-64 builds for now
    if [[ "${arch}" != "x86_64" ]]; then
        return 0
    fi
    {
    sed \
        -e "s|%%IMAGE%%|${image}|g" \
        -e "s|%%RELEASE%%|${release}|g" \
        -e "s|%%NAME%%|${name}|g" \
        -e "s|%%REGISTRY%%|${registry}|g" \
        -e "s|%%DESTINATION%%|${destination}|g" \
        "${tmpl}/containers_header"
    echo ""
    for s in "${sysexts[@]}"; do
        if [[ -f "${s}/Containerfile" ]]; then
            sed \
                -e "s|%%SYSEXT%%|${s}|g" \
                -e "s|%%SYSEXT_NODOT%%|${s//\./_}|g" \
                "${tmpl}/containers_build"
            echo ""
        fi
    done
    # cat "${tmpl}/containers_logincosign"
    # echo ""
    # for s in "${sysexts[@]}"; do
    #     if [[ -f "${s}/Containerfile" ]]; then
    #         sed \
    #             -e "s|%%SYSEXT%%|${s}|g" \
    #             -e "s|%%SYSEXT_NODOT%%|${s//\./_}|g" \
    #             "${tmpl}/containers_pushsign"
    #         echo ""
    #     fi
    # done
    } > ".github/workflows/containers-${shortname}-${release}.yml"
}

main "${@}"
