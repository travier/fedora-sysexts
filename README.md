# Example sysexts for Fedora image based systems

For Fedora CoreOS, Atomic Desktops, IoT, or other Bootable Container systems.

## Building

See: https://github.com/casey/just

```
$ cd python
$ just
```

Building requires root privileges, but you can run those commands in a
rootless, privileged, non-SELinux confined container, such as a toolbox.

## Available sysexts

Included packages for each sysext:

- debugtools: gdb-minimal and strace
- openh264: OpenH264 library from CISCO and support for Firefox
- python: Python 3
- semanage: Python 3 plus SELinux utilities that require Python
- tools: Various tools that I like to have on my host

## Using

```
$ sudo install -d -m 0755 -o 0 -g 0 /var/lib/extensions/
$ sudo install -m 644 -o 0 -g 0 python.raw /var/lib/extensions/python.raw
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
