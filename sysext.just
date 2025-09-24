# Do no use this justfile directly. See sub-directories.

# Explicitely allow overriding variables and recipes in justfiles importing this one
set allow-duplicate-variables := true
set allow-duplicate-recipes := true

# sysexts must explicitely say which base operating system images they target
base_images := ""

# Default to building for the current architecture
arch := arch()

# Do not download any packages by default
packages := ""

# Package to use to set the version for a sysext
version_package := ""

# Do not enable additional repos by default
enable_repos := ""

# Do not enable any Copr repos by default
copr_repos := ""

# Do not enable RPM Fusion repos by default
rpm_fusion_repos := ""

# Disable repos from the build container
disable_repos := ""

# Do not enable any external repos by default
external_repos := ""

# Do not run any commands before downloading RPMs by default
pre_commands := ""

# Install weak dependencies by default
dnf_weak_deps := ""

# Do not exclude any dependency by default
exclude_packages := ""

# Default to noarch + current architecture
dnf_arch := ""

# Do not install any additional files by default
files := ""

# Path to files to manually exclude from the sysext
cleanup_files := ""

# Do not setup any upholds for units by default
upholds := ""

# zstd compression is still experimental in EROFS
# compression := "zstd"
compression := "lz4"

# Print more logs to help debugging. Enable by setting JUST_DEBUG env variable.
# Default to false.
debug := env('JUST_DEBUG', '')

# Set JUST_PODMAN_EXTRA_OPTS to pass extra opts to podman commands.
# Use '--pull=never' for example to disable image update checks and pulls
podman_extra_opts := env('JUST_PODMAN_EXTRA_OPTS', '')

# Default podman options
podman_opts := "--rm --arch=" + arch + " --security-opt label=disable" + podman_extra_opts

# Default, empty, just recipe
default:
    #!/bin/bash
    set -euo pipefail
    # set -x

    echo "Usage: 'just build <target>'"
    echo ""
    echo "Valid targets for this sysext:"
    echo "{{base_images}}"

# Main recipe with all the steps to use to build a sysext
build target arch=arch: \
    (check target arch) \
    clean \
    (download-rpms target arch) \
    (download-manual arch) \
    version \
    (inputs target arch) \
    (setup-rootfs target arch) \
    install-rpms \
    install-files \
    install-manual \
    move-etc \
    validate \
    (reset-selinux-labels target arch) \
    (build-erofs target arch)

# Split recipes for faster skip-builds in CI: Only download and generate inputs
prepare-build target arch=arch: \
    (check target arch) \
    clean \
    (download-rpms target arch) \
    (download-manual arch) \
    version \
    (inputs target arch)

# Split recipes for faster skip-builds in CI: Only builds, must be call after prepare-build
resume-build target arch=arch: \
    (setup-rootfs target arch) \
    install-rpms \
    install-files \
    install-manual \
    move-etc \
    validate \
    (reset-selinux-labels target arch) \
    (build-erofs target arch)

# List the supported targets for this sysext. To use in CI and scripting
targets:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    if [[ -z "{{base_images}}" ]]; then
        echo "sysexts must explicitely say which base operating system images they support"
        exit 1
    fi

    echo "{{base_images}}" | { grep -v "^$" || test $? = 1; }

# Sanity check that some variables are set
check target arch=arch:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    # Make sure that the sysext lists the base images that it supports
    if [[ -z "{{base_images}}" ]]; then
        echo "sysexts must explicitely say which base operating system images they support"
        exit 1
    fi

    # Make sure that the current target is in the supported list
    found=false
    mapfile -t baseimages <<< "{{base_images}}"
    for base in "${baseimages[@]}"; do
        if [[ -z "${base}" ]]; then
            continue
        fi
        # echo "Checking against: $base"
        # Split on whitespace
        baseimage=($base)
        if [[ "${baseimage[0]}" == {{target}} ]]; then
            # echo "Base image name matched: ${baseimage[0]}"
            # Ignore architecture check if nothing is specified and architecture is x86_64
            # echo "${baseimage[@]} ${#baseimage[@]}"
            if [[ "${#baseimage[@]}" -eq 1 ]]; then
                # echo "No architecture set for base image"
                if [[ "{{arch}}" == "x86_64" ]]; then
                    found=true
                    break
                fi
                # Otherwise skip this entry as we can not be sure it's supported
                # echo "Potentially unsupported arch for this image: {{arch}}"
                break
            fi
            IFS=','
            # Check if the architecture is in the list
            read -ra arches <<< "${baseimage[1]}"
            unset IFS
            # echo "Architectures available: ${arches[@]}"
            for a in "${arches[@]}"; do
                # echo "Looking at: ${a}"
                if [[ "${a}" == "{{arch}}" ]]; then
                    found=true
                    break
                fi
            done
            # Break again out of the loop if found
            if [[ "${found}" == true ]]; then
                break
            fi
        fi
    done
    if [[ ${found} == "false" ]]; then
        echo "{{target}} {{arch}} is not listed as a supported base image for this sysext"
        echo ""
        echo "Valid targets for this sysext:"
        echo "{{base_images}}"
        exit 1
    fi

# Download RPMs to install. Use the following variables:
# - packages: List of packages to download (and later install)
# - enable_repos: List of additional repos to enable
download-rpms target arch=arch:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    # Skip this step if we have not been asked to download packages
    if [[ -z "{{packages}}" ]]; then
        exit 0
    fi

    enablerepos=""
    if [[ -n "{{enable_repos}}" ]]; then
        for r in {{enable_repos}}; do
            echo "➕ Enabling repo: ${r}"
            enablerepos+=" --enablerepo=${r}"
        done
    fi

    disablerepos=""
    if [[ -n "{{disable_repos}}" ]]; then
        for r in {{disable_repos}}; do
            echo "➖ Disabling repo: ${r}"
            disablerepos+=" --disablerepo=${r}"
        done
    fi

    dnf_arch=""
    if [[ -z "{{dnf_arch}}" ]]; then
        dnf_arches="noarch {{arch}}"
    else
        dnf_arches="{{dnf_arch}}"
    fi
    for a in ${dnf_arches}; do
        dnf_arch+="--arch=${a} "
    done

    dnf_opts=""
    if [[ "{{dnf_weak_deps}}" == false ]]; then
        dnf_opts="--setopt=install_weak_deps=False"
    fi
    if [[ -n "{{exclude_packages}}" ]]; then
        excluded_packages="$(echo "{{exclude_packages}}" | xargs)"
        for p in ${excluded_packages}; do
            echo "➖ Excluding package: ${p}"
            dnf_opts+=" --exclude=${p}"
        done
    fi

    packages="$(echo "{{packages}}" | xargs)"

    # Always disable the openh264 repo by default
    pre_commands="dnf5 config-manager setopt fedora-cisco-openh264.enabled=0; "

    if [[ -n "{{pre_commands}}" ]]; then
        pre_commands+="{{pre_commands}} ; "
    fi
    if [[ -n "{{copr_repos}}" ]]; then
        pre_commands+="dnf install -y dnf5-plugins"
        for r in "{{copr_repos}}"; do
            pre_commands+=" ; dnf copr enable -y ${r}"
        done
        pre_commands+=" ; "
    fi
    if [[ -n "{{external_repos}}" ]]; then
        pre_commands+="dnf install -y dnf5-plugins"
        for r in "{{external_repos}}"; do
            pre_commands+=" ; dnf config-manager addrepo --from-repofile=${r}"
        done
        pre_commands+=" ; "
    fi

    if [[ -n "{{rpm_fusion_repos}}" ]]; then
        release=$(podman run {{podman_opts}} "{{target}}" \
            bash -c 'rpm -E %fedora' | tr -d '\n')
        for r in {{rpm_fusion_repos}}; do
            if [[ "${r}" != "free" ]] && [[ "${r}" != "nonfree" ]]; then
                echo "Unrecognized RPM Fusion repo: ${r}"
                exit 1
            fi
            echo "➕ Enabling RPM Fusion repo: '${r}'"
            pre_commands+=" dnf install -y https://mirrors.rpmfusion.org/${r}/fedora/rpmfusion-${r}-release-${release}.noarch.rpm ;"
        done
    fi

    mkdir -p ../.dnf-cache

    mkdir rpms
    cd rpms

    echo "⬇️ Downloading packages (${dnf_arches}): ${packages}"
    # dnf install --downloadonly --downloaddir . ${dnf_arch} ${enablerepos} ${packages}
    podman run -ti {{podman_opts}} \
        --volume "${PWD}:/var/srv" \
        --volume "${PWD}/../../.dnf-cache:/var/cache/libdnf5" \
        --workdir "/var/srv" \
        "{{target}}" \
        bash -xc "export FORCE_COLUMNS=100 && ${pre_commands}dnf download --resolve ${dnf_arch} ${dnf_opts} ${disablerepos} ${enablerepos} ${packages}"

# Manual download step, that can be overridden to dowload non RPM content
download-manual arch=arch:
    #!/bin/bash
    set -euo pipefail
    # set -x
    exit 0

# Recipe to override to set a custom version
version:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    package_version() {
        rpm="${1}"
        epoch="$(rpm -qp --queryformat '%{EPOCH}' ${rpm})"
        version="$(rpm -qp --queryformat '%{VERSION}-%{RELEASE}' ${rpm})"
        if [[ "${epoch}" == "(none)" ]]; then
            epoch=""
        else
            epoch="${epoch}-"
        fi
        echo "${epoch}${version}" > ./version
    }

    echo "🏷️ Writing down version"

    if [[ -n "{{version_package}}" ]]; then
        if [[ $(ls rpms/*.rpm | grep -cE "^rpms/{{version_package}}-[0-9]" ) -ne 1 ]]; then
            echo "More than one package matched: {{version_package}}."
            exit 1
        fi
        rpm="$(ls rpms/*.rpm | sort -h | grep -E "^rpms/{{version_package}}-[0-9]" | head -1)"
        package_version "${rpm}"
        exit 0
    fi

    if [[ -z "{{packages}}" ]]; then
        echo "No package listed. You must define the 'version' recipe in your justfile for this sysext."
        exit 1
    fi

    packages=($(echo "{{packages}}" | xargs))

    if [[ ${#packages[@]} -ne 1 ]]; then
        if [[ $(ls rpms/*.rpm | grep -cE "^rpms/{{name}}-[0-9]") -ne 1 ]]; then
            echo "More that one package listed. Set 'version_package' or define the 'version' recipe in your justfile for this sysext."
            exit 1
        fi
        rpm="$(ls rpms/*.rpm | sort -h | grep -E "^rpms/{{name}}-[0-9]" | head -1)"
        package_version "${rpm}"
        exit 0
    fi

    # Only one package listed, let's use its version
    rpm="$(ls rpms/${packages[0]}*.rpm | sort -h | head -1)"
    package_version "${rpm}"

# Generate 'inputs' files for change detection in CI
inputs target arch=arch:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    echo "🏷️ Writing down inputs"

    # Make sure that we always have a version set
    version=""
    if [[ -f ./version ]]; then
        version="$(cat ./version)"
    else
        version=$(podman run {{podman_opts}} "{{target}}" \
            bash -c 'source /etc/os-release ; echo -n ${OSTREE_VERSION}')
    fi
    # Remove special characters from the version
    version="$(cat ./version | sed "s/\^/_/" | sed "s/:/_/")"
    # Write back version to file
    echo "${version}" > ./version

    # Get and store name, tag and digest for the container image used to build the sysext
    echo "{{target}}@$(podman inspect {{target}} | jq -r '.[0].Digest')" > ./digest

    # Store version_id (Fedora release)
    version_id=$(podman run {{podman_opts}} "{{target}}" \
        bash -c 'source /etc/os-release ; echo -n ${VERSION_ID}')
    echo "${version_id}" > ./version_id

    # Store the hashes of the RPMs used to build the sysext
    if [[ -d ./rpms ]]; then
        cd rpms
        sha256sum *.rpm >> ../inputs
        cd ..
    fi
    # Store the hashes of all the files added to the sysext
    if [[ -n "{{files}}" ]]; then
        for f in {{files}}; do
            find ${f} -type f | sort -h | xargs sha256sum >> ./inputs
        done
    fi
    # Make sure that we have an inputs file in all cases
    touch ./inputs

    # Store the hashes of the scripts used to build the sysext
    sha256sum justfile >> ./scripts
    cd ..
    sha256sum sysext.just >> ./{{name}}/scripts

# Sets up the rootfs directory and creates the extension release config
setup-rootfs target arch=arch:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    version_id="$(cat ./version_id)"

    mkdir rootfs
    cd rootfs

    # Only ask systemd to reload its configuration if we have services to
    # uphold / start on boot
    reload_manager="false"

    # Filter the variable into an array
    upholds=()
    mapfile -t upholds_raw <<< "{{upholds}}"
    for uphold in "${upholds_raw[@]}"; do
        if [[ -z "${uphold}" ]]; then
            continue
        fi
        upholds+=("${uphold}")
    done
    # Setup upholds if there are any
    if [[ "${#upholds[@]}" -ne 0 ]]; then
        # Set now, but will be used later in the extension config file
        reload_manager="true"
        echo "➡️ Setting up upholds for: ${upholds[@]}"
        ${SUDO} install -d -m 0755 -o 0 -g 0 usr/lib/systemd/system/multi-user.target.d
        {
        echo "[Unit]"
        for uphold in "${upholds[@]}"; do
            echo "Upholds=${uphold}"
        done
        } | ${SUDO} tee "usr/lib/systemd/system/multi-user.target.d/10-{{name}}-sysext.conf" > /dev/null
    fi

    # Post process architecture to match systemd architecture list
    if [[ {{arch}} == "x86_64" ]]; then
        arch="x86-64"
    elif [[ {{arch}} == "aarch64" ]]; then
        arch="arm64"
    else
        echo "Unsupported architecture"
        exit 1
    fi

    echo "➡️ Setting up extension config file"
    ${SUDO} install -d -m0755 usr/lib/extension-release.d
    {
    # We can not restict the ID to `fedora` here as it will break support for
    # Universal Blue. See: https://github.com/systemd/systemd/pull/37648
    echo "ID=\"_any\""
    echo "VERSION_ID=\"${version_id}\""
    echo "ARCHITECTURE=\"${arch}\""
    if [[ "${reload_manager}"  == "true" ]]; then
        echo "EXTENSION_RELOAD_MANAGER=1"
    fi
    } | ${SUDO} tee "usr/lib/extension-release.d/extension-release.{{name}}" > /dev/null

# Install (extract) RPM packages download in download-rpms recipe. Uses:
# - packages: List of packages to install
install-rpms:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    # Skip this step if we have not been asked to install packages
    if [[ -z "{{packages}}" ]]; then
        exit 0
    fi

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    cd rootfs

    echo "📦 Extracting packages:"
    for rpm in ../rpms/*.rpm; do
        echo "$(basename ${rpm})"
        rpm2cpio "${rpm}" | ${SUDO} cpio -idmv &> /dev/null
    done

# Install files from the current directory. Uses:
# - files: List of folders or files to copy to `rootfs`. Use either `usr` or
#   `opt` as everything else is ignored. Spaces are not supported.
install-files:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    # Skip this step if we have not been asked to copy files
    if [[ -z "{{files}}" ]]; then
        exit 0
    fi

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    cd rootfs

    echo "📁 Copying additional files from: {{files}}"
    for f in {{files}}; do
        ${SUDO} cp -a ../${f} .
    done

# Manual installation step, that can be overridden to install non RPM content
# or fixup issues after RPM installation.
install-manual:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi
    exit 0

# Move /etc to /usr/etc. Might be converted to a confext generator.
move-etc:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    cd rootfs

    if [[ -d ./etc ]] then
        echo "➡️ Moving /etc to /usr/etc"
        ${SUDO} mv --no-clobber --no-copy ./etc ./usr/etc
    fi

# Validation pass that checks for common errors and will also try to fix some
# common cases:
# - Cleanup files as requested in the justfile
# - Remove all empty directories in /var, /run and /opt
# - Try to merge the content of /usr/sbin with /usr/bin for Fedora 42 and later
# - Run the checks
validate:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    # Some checks vary by Fedora release
    version_id="$(cat ./version_id)"

    failed_checks=0

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    cd rootfs

    # Remove files as requested
    if [[ -n "{{cleanup_files}}" ]]; then
        cleanup=($(echo "{{cleanup_files}}" | xargs))
        for f in "${cleanup[@]}"; do
            echo "🧹 Cleaning up file: ${f}"
            rm ./${f}
        done
    fi

    # Remove all empty directories in /var, /run and /opt
    for d in 'var' 'run' 'opt'; do
        if [[ -d "./${d}" ]]; then
            echo "🧹 Cleaning up empty directories in /${d}"
            ${SUDO} find "./${d}" -type d -empty -delete
        fi
    done

    # Try to merge /lib64 with /usr/lib64
    if [[ -d "lib64" ]]; then
        echo "➡️ Moving /lib64 to /usr/lib64"
        if [[ ! -d "usr/lib64" ]]; then
            install -dm 0755 ./usr/lib64
        fi
        ${SUDO} mv --verbose --no-clobber ./lib64/* ./usr/lib64
        ${SUDO} rmdir lib64
    fi

    # Try to merge /usr/sbin with /usr/bin for Fedora 42+
    if [[ "${version_id}" -ge 42 ]] && [[ -d "usr/sbin" ]]; then
        echo "➡️ Moving /usr/sbin to /usr/bin"
        ${SUDO} mv --verbose --no-clobber ./usr/sbin/* ./usr/bin
        ${SUDO} rmdir usr/sbin
    fi

    # Check sbin/bin merge starting with Fedora 42
    if [[ "${version_id}" -ge 42 ]] && [[ -d "usr/sbin" ]]; then
        failed_checks=$((failed_checks+1))
        echo "❌ Found /usr/sbin directory on Fedora 42+ sysext (see bin/sbin merge change)"
        ls -alh usr/sbin
    fi

    # Check that /var is empty as it will be ignored
    if [[ -d "var" ]]; then
        failed_checks=$((failed_checks+1))
        echo "❌ Found /var directory, which will be ignored: clear it or convert it to a tmpfiles.d config"
        ls -alh var
    fi

    # Check that /run is empty as it will be ignored
    if [[ -d "run" ]]; then
        failed_checks=$((failed_checks+1))
        echo "❌ Found /run directory, which will be ignored: clear it or convert it to a tmpfiles.d config"
        ls -alh run
    fi

    # Check that we don't use /opt as it will not work
    if [[ -d "opt" ]]; then
        failed_checks=$((failed_checks+1))
        echo "❌ Found /opt directory, which will not work: move the content to /usr/lib"
        ls -alh opt
    fi

    # Check that we don't have other directories as they will be ignored
    if [[ "$(ls | grep -cvE "^usr$|^run$|^var$|^opt$")" -ne 0 ]]; then
        failed_checks=$((failed_checks+1))
        echo "❌ Found other directories which will be ignored: move them or clear them"
        ls | grep -vE "^usr$|^run$|^var$|^opt$"
    fi

    if [[ "${failed_checks}" -ne 0 ]]; then
        exit 1
    fi

# Reset SELinux labels to expected values from the policy
reset-selinux-labels target arch=arch:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    # Only install the packages in the container if we have an SELinux policy
    # module in the sysext and might thus need specific labels
    pre_commands=""
    if [[ -d "./rootfs/usr/share/selinux/packages" ]]; then
        dnf_opts=""
        if [[ "{{dnf_weak_deps}}" == false ]]; then
            dnf_opts="--setopt=install_weak_deps=False"
        fi
        if [[ -n "{{exclude_packages}}" ]]; then
            excluded_packages="$(echo "{{exclude_packages}}" | xargs)"
            for p in ${excluded_packages}; do
                echo "➖ Excluding package: ${p}"
                dnf_opts+=" --exclude=${p}"
            done
        fi

        if [[ -n "{{pre_commands}}" ]]; then
            pre_commands+="{{pre_commands}} ; "
        fi

        disablerepos=""
        if [[ -n "{{disable_repos}}" ]]; then
            for r in {{disable_repos}}; do
                echo "➖ Disabling repo: ${r}"
                disablerepos+=" --disablerepo=${r}"
            done
        fi

        if [[ -n "{{packages}}" ]]; then
            pre_commands+="export FORCE_COLUMNS=100 && dnf install -y ${dnf_opts} ${disablerepos} ./rpms/* && "
        fi

        mkdir -p ../.dnf-cache
    fi

    filecontexts="/etc/selinux/targeted/contexts/files/file_contexts"
    echo "🏷️ Resetting SELinux labels"
    podman run -ti {{podman_opts}} \
        --volume "${PWD}:/var/srv" \
        --volume "${PWD}/../.dnf-cache:/var/cache/libdnf5" \
        --workdir "/var/srv" \
        --privileged \
        "{{target}}" \
        bash -c "${pre_commands}cd rootfs && setfiles -r . ${filecontexts} . && chcon --user=system_u --recursive ."

# Creates the EROFS sysext file
build-erofs target arch=arch:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    version="$(cat ./version)"
    version_id="$(cat ./version_id)"
    # Post process architecture to match systemd architecture list
    if [[ {{arch}} == "x86_64" ]]; then
        arch="x86-64"
    elif [[ {{arch}} == "aarch64" ]]; then
        arch="arm64"
    else
        echo "Unsupported architecture"
        exit 1
    fi

    echo "🔒 Creating EROFS sysext ({{compression}})"
    ${SUDO} mkfs.erofs -z{{compression}} {{name}}-${version}-${version_id}-${arch}.raw rootfs > /dev/null

    if [[ "${UID}" != "0" ]]; then
        ${SUDO} chown "${USER}:" {{name}}*.raw
    fi

    echo "🎉 Done!"

# Clean up files from previous builds
clean:
    #!/bin/bash
    set -euo pipefail
    if [[ -n "{{debug}}" ]]; then
      set -x
    fi

    if [[ "${UID}" == "0" ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    echo "🧹 Cleaning up files from previous builds"
    rm -rf inputs scripts digest version version_id
    rm -rf ./rpms
    rm -rf ./binaries
    ${SUDO} rm -rf ./rootfs
    rm -f ./*.raw
