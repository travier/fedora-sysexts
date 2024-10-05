# Example sysexts for Fedora image based systems

For Fedora CoreOS, Atomic Desktops, IoT, or other Bootable Container systems
(and classic otree/rpm-ostree systems).

## Building

Make sure that you have the following packages installed:
- `erofs-utils`
- [`just`](https://github.com/casey/just)
- `selinux-policy-targeted`

```
$ SYSEXT=python
$ cd ${SYSEXT}
$ just
```

Building requires root privileges, but you can run those commands in a
rootless, privileged, non-SELinux confined container, such as a toolbox.

## Available sysexts

See each sysext's justfile for the exact list of packages included.

### Built from Fedora repos

- debugtools: `gdb-minimal` and `strace`
- python: Python 3
- semanage: Python 3 plus SELinux utilities that require Python
- tools: Various tools that I like to have on my host
- iwd: `iwd` WiFi daemon and config for NetworkManager

### Built from Cisco's OpenH264 repo

- openh264: OpenH264 library and support for Firefox

### Built from RPM Fusion repos

Install either `fedora-workstation-repositories` or RPM Fusion repositories:

- steam-devices: `steam-device` package only

## Using

```
$ SYSEXT=python
$ sudo install -d -m 0755 -o 0 -g 0 /var/lib/extensions/
$ sudo install -m 644 -o 0 -g 0 ${SYSEXT}/${SYSEXT}.raw /var/lib/extensions/${SYSEXT}.raw
$ sudo restorecon -RFv /var/lib/extensions/
$ sudo systemctl restart systemd-sysext.service
$ systemd-sysext status
$ python -c 'print("Hello sysext!")'
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
