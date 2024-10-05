# Do no use this justfile directly. See sub-directories.

# Explicitely allow to override variables in justfiles importing this one
set allow-duplicate-variables := true

# Do not download any packages by default
packages := ""

# Do not enable additional repos by default
enable_repos := ""

# Default to noarch + current architecture
arch := "noarch," + arch()

# Do not install any additional files by default
files := ""

# zstd compression is still experimental in EROFS
# compression := "zstd"
compression := "lz4"

# The default list of steps to use
all: download-rpms setup-rootfs install-rpms install-files reset-selinux-labels build-erofs

# Download RPMs to install. Use the following variables:
# - packages: List of packages to download (and later install)
# - enable_repos: List of additional repos to enable
download-rpms:
    #!/bin/bash
    set -euo pipefail
    # set -x

    echo "🧹 Cleaning up previous RPMs"
    rm -rf ./rpms
    mkdir rpms
    cd rpms

    enablerepos=""
    if [[ -n "{{enable_repos}}" ]]; then
        for r in {{enable_repos}}; do
            echo "➕ Enabling repo: ${r}"
            enablerepos+=" --enablerepo=${r}"
        done
    fi

    echo "⬇️ Downloading packages ({{arch}}): {{packages}}"
    dnf download --arch={{arch}} ${enablerepos} {{packages}}

# Sets up the rootfs directory and creates the extension release config
setup-rootfs:
    #!/bin/bash
    set -euo pipefail
    # set -x

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    echo "🧹 Cleaning up previous rootfs"
    ${SUDO} rm -rf ./rootfs
    mkdir rootfs
    cd rootfs

    echo "➡️ Setting up extension config file"
    ${SUDO} install -d -m0755 usr/lib/extension-release.d
    echo "ID=\"_any\"" | ${SUDO} tee usr/lib/extension-release.d/extension-release.{{name}} > /dev/null

# Install (extract) RPM packages download in download-rpms recipe. Uses:
# - packages: List of packages to install
install-rpms:
    #!/bin/bash
    set -euo pipefail
    # set -x

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    cd rootfs

    echo "📦 Extracting packages"
    for rpm in ../rpms/*.rpm; do
        echo -n "$(basename ${rpm}) "
        rpm2cpio "${rpm}" | ${SUDO} cpio -idmv &> /dev/null
    done
    echo ""

# Install files from the current directory. Uses:
# - files: List of folders or files to copy to `rootfs`. Use either `usr` or
#   `opt` as everything else is ignored. Spaces are not supported.
install-files:
    #!/bin/bash
    set -euo pipefail
    # set -x

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    cd rootfs

    if [[ -z "{{files}}" ]]; then
        exit 0
    fi

    echo "📁 Copying additional files from: {{files}}"
    for f in {{files}}; do
        ${SUDO} cp -a ../${f} .
    done

# Reset SELinux labels to expected values from the policy
reset-selinux-labels:
    #!/bin/bash
    set -euo pipefail
    # set -x

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    cd rootfs

    # Look in the current execution environment first
    filecontexts="/etc/selinux/targeted/contexts/files/file_contexts"
    if [[ ! -f "${filecontexts}" ]]; then
        # If not found, look on the host (i.e. when running from a toolbox)
        filecontexts="/run/host/${filecontexts}"
    fi
    if [[ ! -f "${filecontexts}" ]]; then
        echo "Could not find a list of file contexts from an SELinux policy"
        exit 1
    fi

    echo "🏷️ Resetting SELinux labels"
    ${SUDO} setfiles -r . "${filecontexts}" .
    ${SUDO} chcon --user="system_u" --recursive .

# Creates the EROFS sysext file
build-erofs:
    #!/bin/bash
    set -euo pipefail
    # set -x

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    echo "🔒 Creating EROFS sysext ({{compression}})"
    ${SUDO} mkfs.erofs -z{{compression}} {{name}}.raw rootfs > /dev/null

    if [[ "${UID}" != "0" ]]; then
        ${SUDO} chown "${USER}:" {{name}}.raw
    fi

    echo "🎉 Done!"

# Clean up files used for building and generated sysext
clean:
    #!/bin/bash
    set -euo pipefail
    # set -x

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    echo "🧹 Cleaning up files from previous builds"
    rm -rf ./rpms
    rm -rf ./binaries
    ${SUDO} rm -rf ./rootfs
    rm -f ./*.raw
