#!/bin/bash

# SPDX-FileCopyrightText: Timothée Ravier <tim@siosm.fr>
# SPDX-License-Identifier: MIT

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

    local -r tmpl=".github/workflow-templates"
    if [[ ! -d "${tmpl}" ]]; then
        echo "Could not find the templates. Is this script run from the root of the repo?"
        exit 1
    fi

    # Remove all existing worflows
    rm -f "./.github/workflows/containers"*".yml"
    rm -f "./.github/workflows/sysexts"*".yml"

    local -r releaseurl="https://github.com/\${{ github.repository }}/releases/download"

    arches=(
        'x86_64'
        'aarch64'
    )

    images=(
        'quay.io/fedora-ostree-desktops/base-atomic:41'
        'quay.io/fedora-ostree-desktops/base-atomic:42'
        'quay.io/fedora-ostree-desktops/base-atomic:43'
        'quay.io/fedora-ostree-desktops/silverblue:41'
        'quay.io/fedora-ostree-desktops/silverblue:42'
        'quay.io/fedora-ostree-desktops/silverblue:43'
        'quay.io/fedora-ostree-desktops/kinoite:41'
        'quay.io/fedora-ostree-desktops/kinoite:42'
        'quay.io/fedora-ostree-desktops/kinoite:43'
        'quay.io/fedora/fedora-coreos:stable'
        'quay.io/fedora/fedora-coreos:next'
    )

    # Set jobnames
    declare -A jobnames
    jobnames["quay.io/fedora-ostree-desktops/base-atomic:41"]="fedora-41"
    jobnames["quay.io/fedora-ostree-desktops/base-atomic:42"]="fedora-42"
    jobnames["quay.io/fedora-ostree-desktops/base-atomic:43"]="fedora-43"
    jobnames["quay.io/fedora-ostree-desktops/silverblue:41"]="fedora-silverblue-41"
    jobnames["quay.io/fedora-ostree-desktops/silverblue:42"]="fedora-silverblue-42"
    jobnames["quay.io/fedora-ostree-desktops/silverblue:43"]="fedora-silverblue-43"
    jobnames["quay.io/fedora-ostree-desktops/kinoite:41"]="fedora-kinoite-41"
    jobnames["quay.io/fedora-ostree-desktops/kinoite:42"]="fedora-kinoite-42"
    jobnames["quay.io/fedora-ostree-desktops/kinoite:43"]="fedora-kinoite-43"
    jobnames["quay.io/fedora/fedora-coreos:stable"]="fedora-coreos-stable"
    jobnames["quay.io/fedora/fedora-coreos:next"]="fedora-coreos-next"

    # Get the list of sysexts for each image and each arch
    declare -A sysexts
    for arch in "${arches[@]}"; do
        for image in "${images[@]}"; do
            list=()
            for s in $(git ls-tree -d --name-only HEAD | grep -Ev ".github|docs"); do
                pushd "${s}" > /dev/null
                # Only require the architecture to be explicitly listed for non x86_64 for now
                if [[ "${arch}" == "x86_64" ]]; then
                    if [[ $(just targets | grep -c "${image}") == "1" ]]; then
                        list+=("${s}")
                    fi
                else
                    if [[ $(just targets | grep -cE "${image} .*${arch}.*") == "1" ]]; then
                        list+=("${s}")
                    fi
                fi
                popd > /dev/null
            done
            sysexts["${image}-${arch}"]="$(echo "${list[@]}" | tr ' ' ';')"
        done
    done

    # Generate EROFS sysexts workflows
    {
    sed -e "s|%%RELEASEURL%%|${releaseurl}|g" \
        "${tmpl}/00_sysexts_header"

    for arch in "${arches[@]}"; do
        runson="ubuntu-24.04"
        if [[ "${arch}" == "aarch64" ]]; then
            runson="ubuntu-24.04-arm"
        fi
        for image in "${images[@]}"; do
            sed -e "s|%%JOBNAME%%|${jobnames["${image}"]}-${arch}|g" \
                -e "s|%%RUNSON%%|${runson}|g" \
                -e "s|%%IMAGE%%|${image}|g" \
                "${tmpl}/10_sysexts_build_header"
            echo ""
            for s in $(echo "${sysexts["${image}-${arch}"]}" | tr ';' ' '); do
                sed "s|%%SYSEXT%%|${s}|g" "${tmpl}/15_sysexts_build"
                echo ""
            done
        done
    done

    # TODO: Dynamic list of jobs to depend on
    all_sysexts=()
    for arch in "${arches[@]}"; do
        for image in "${images[@]}"; do
            for s in $(echo "${sysexts["${image}-${arch}"]}" | tr ';' ' '); do
                all_sysexts+=("${s}")
            done
        done
    done
    uniq_sysexts="$(echo "${all_sysexts[@]}" | tr ' ' '\n' | sort -u | tr '\n' ';')"
    sed -e "s|%%SYSEXTS%%|${uniq_sysexts}|g" "${tmpl}/20_sysexts_gather"
    } > ".github/workflows/sysexts-fedora.yml"
}

main "${@}"
