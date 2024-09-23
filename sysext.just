# Do no use this justfile directly. See sub-direcotries.

# zstd compression is still experimental in EROFS
# compression := "zstd"
compression := "lz4"

download:
    #!/bin/bash
    set -euxo pipefail

    rm -rf ./rpms
    mkdir rpms
    cd rpms
    dnf download --arch=noarch,{{arch()}} {{packages}}

build:
    #!/bin/bash
    set -euxo pipefail

    sudo rm -rf ./rootfs
    mkdir rootfs
    cd rootfs

    sudo install -d -m0755 usr/lib/extension-release.d
    echo "ID=\"_any\"" | sudo tee usr/lib/extension-release.d/extension-release.{{name}}

    for rpm in ../rpms/*.rpm; do
        rpm2cpio "${rpm}" | sudo cpio -idmv
    done

    sudo setfiles -r . /run/host/etc/selinux/targeted/contexts/files/file_contexts .
    sudo chcon --user="system_u" --recursive .

    cd ..

    mkfs.erofs -z{{compression}} {{name}}.raw rootfs

mount:
    sudo mount -o loop {{name}}.raw /mnt/nfs

unmount:
    sudo umount /mnt/nfs
