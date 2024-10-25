# Example sysexts for Fedora image based systems

For Fedora CoreOS, Atomic Desktops, IoT, or other Bootable Container systems
(and classic otree/rpm-ostree systems).

## Download

See the [GitHub release](https://github.com/travier/fedora-sysexts/releases)
for your version of Fedora.

## Available sysexts

See each sysext's justfile for the exact list of packages included.

### Built from Fedora's repos

| Name | Notes |
|-|-|
| btop | `btop` and `rocm-smi` dependency for AMD GPU support |
| compsize | |
| distrobox | |
| fuse2 | The `fuse` tools and library, version 2, for AppImage compatibility |
| gdb | |
| git-tools | `git-absorb` and `git-delta` |
| htop | |
| iwd | Better WiFi daemon and config for NetworkManager to use it by default |
| just | |
| krb5-workstation | Kerberos support |
| libvirtd | `libvirtd`, `qemu`, `swtpm`, `virt-install` and `guestfs-tools` |
| monitoring | Collection of monitoring tools: `bandwhich`, `bwm-ng`, `igt-gpu-tools`, `iotop` |
| python | Core Python 3 packages |
| ripgrep | |
| semanage | SELinux utilities, including those that require Python |
| strace | |
| tree | |
| wireguard-tools | |
| zoxide | `zoxide` and `fzf` |
| zsh | |

### Built from Cisco's OpenH264 repo

| Name | Notes |
|-|-|
| openh264 | OpenH264 library and support for Firefox |

### Built from RPM Fusion repos

| Name | Notes |
|-|-|
| steam-devices | `steam-device` package only (work in progress) |
| steam | Steam and its dependencies (work in progress) |

## Building

Make sure that you have the following packages installed:
- `cpio`
- `erofs-utils`
- [`just`](https://github.com/casey/just)
- `podman`
- `wget`

To build the `python` sysext:

```
$ cd python
```

List the supported target images:

```
$ just targets
```

Build the sysext for Fedora CoreOS next:

```
$ just build "quay.io/fedora/fedora-coreos:next"
```

I recommend building those from a toolbox as it requires `root` privileges. It
should work with any rootless, privileged, non-SELinux confined container.

## Using

Setup the `extensions` directory:

```
$ sudo install -d -m 0755 -o 0 -g 0 /var/lib/extensions/
$ sudo restorecon -RFv /var/lib/extensions/
```

Install the extensions:

```
$ SYSEXT=python
$ sudo install -m 644 -o 0 -g 0 ${SYSEXT}/${SYSEXT}.raw -t /var/lib/extensions/
```

Enable them (see known issue below for details):

```
$ sudo systemctl restart systemd-sysext.service
$ systemd-sysext status
```

Try it out:

```
$ python -c 'print("Hello from a sysext!")'
```

## Know issues

Make sure to use `systemctl restart systemd-sysext.service` instead of
`systemd-sysext merge` until the issue below is resolved. `systemd-sysext
unmerge` is safe to use.

See:
- https://github.com/coreos/fedora-coreos-tracker/issues/1744
- https://github.com/systemd/systemd/issues/34387
- https://github.com/systemd/systemd/pull/34414

## License

[MIT](LICENSE)
