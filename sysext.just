# Do no use this justfile directly. See sub-directories.

# Explicitely allow to override variables in justfiles importing this one
set allow-duplicate-variables := true

# Do not download any packages by default
packages := ""

# Do not enable additional repos by default
enable_repos := ""

# zstd compression is still experimental in EROFS
# compression := "zstd"
compression := "lz4"

# The default list of steps to use
all: download-rpms setup-rootfs install-rpms reset-selinux-labels build-erofs

# Download RPMs to install. Use the following variables:
# - packages: List of packages to download (and later install)
# - enable_repos: List of additional repos to enable
download-rpms:
    #!/bin/bash
    set -euxo pipefail

    rm -rf ./rpms
    mkdir rpms
    cd rpms

    enablerepos=""
    if [[ -n "{{enable_repos}}" ]]; then
        for r in {{enable_repos}}; do
            enablerepos+=" --enablerepo=${r}"
        done
    fi

    dnf download --arch=noarch,{{arch()}} ${enablerepos} {{packages}}

# Sets up the rootfs directory and creates the extension release config
setup-rootfs:
    #!/bin/bash
    set -euxo pipefail

    sudo rm -rf ./rootfs
    mkdir rootfs
    cd rootfs

    sudo install -d -m0755 usr/lib/extension-release.d
    echo "ID=\"_any\"" | sudo tee usr/lib/extension-release.d/extension-release.{{name}}

# Install (extract) RPM packages download in download-rpms recipe. Uses:
# - packages: List of packages to install
install-rpms:
    #!/bin/bash
    set -euxo pipefail

    cd rootfs

    for rpm in ../rpms/*.rpm; do
        rpm2cpio "${rpm}" | sudo cpio -idmv
    done

# Reset SELinux labels to expected values from the policy
reset-selinux-labels:
    #!/bin/bash
    set -euxo pipefail

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
    sudo setfiles -r . "${filecontexts}" .
    sudo chcon --user="system_u" --recursive .

# Creates the EROFS sysext file
build-erofs:
    #!/bin/bash
    set -euxo pipefail

    sudo mkfs.erofs -z{{compression}} {{name}}.raw rootfs
    sudo chown "${USER}:" {{name}}.raw

# Clean up files used for building and generated sysext
clean:
    #!/bin/bash
    set -euxo pipefail
    rm -rf ./rpms
    rm -rf ./binaries
    sudo rm -rf ./rootfs
    rm -f {{name}}.raw
