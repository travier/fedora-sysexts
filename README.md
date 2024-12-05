# Example sysexts for Fedora image based systems

For Fedora CoreOS, Atomic Desktops, IoT, or other Bootable Container systems
(and classic ostree/rpm-ostree systems).

Currently only built for:
- Fedora Silverblue 41
- Fedora Kinoite 41
- Fedora CoreOS (stable stream)

While not build for the testing and next stream for Fedora CoreOS, it is likely
that the sysexts built for the stable one work for all of them. The only
exception would be during Fedora major version rebases when next and finally
testing moves to Fedora N+1 while stable stays on Fedora N.

## How does this fit with bootc and Bootable Containers?

The planned user experience for using those sysexts is that they are built as
container layers, pushed to a registry as distinct tags, downloaded, managed
and updated in sync with the OS by bootc. See:
[bootc#7](https://github.com/containers/bootc/issues/7) and
[README.containers.md](README.containers.md).

## Installing and updating using systemd-sysupdate

In the meantime, you can use systemd-sysupdate to manually install and update
them:

```
$ sudo install -d -m 0755 -o 0 -g 0 /var/lib/extensions /var/lib/extensions.d /etc/sysupdate.d
$ sudo restorecon -RFv /var/lib/extensions /var/lib/extensions.d /etc/sysupdate.d
$ SYSEXT="btop"
$ RELEASE_TAG="fedora-kinoite-41"
$ URL="https://github.com/travier/fedora-sysexts/releases/download/${RELEASE_TAG}/${SYSEXT}.conf"
$ curl --silent --location "${URL}" | sudo tee "/etc/sysupdate.d/${SYSEXT}.conf"
$ sudo /usr/lib/systemd/systemd-sysupdate list
$ sudo /usr/lib/systemd/systemd-sysupdate update
$ sudo systemctl restart systemd-sysext.service
$ systemd-sysext status
```

Then any further updates can be done with:

```
$ sudo /usr/lib/systemd/systemd-sysupdate update
$ sudo systemctl restart systemd-sysext.service
$ systemd-sysext status
```

I recommend updating them at the same time as you update your system with
bootc/rpm-ostree so that the content of the sysexts matches what is on your
base system as right now there are no guarantees there. We should fix that when
integrating with bootc.

## Know issues

Until systemd v257 is released and lands in Fedora, make sure to use `systemctl
restart systemd-sysext.service` instead of `systemd-sysext merge`.
`systemd-sysext unmerge` is safe to use.

See:
- https://github.com/coreos/fedora-coreos-tracker/issues/1744
- https://github.com/systemd/systemd/issues/34387
- https://github.com/systemd/systemd/pull/34414
- https://github.com/systemd/systemd/pull/35132

## Available sysexts

See each sysext's `README.md` for notes and usage instructions. See the
`justfile` or `Containerfile` for the exact list of packages or content
included.

All sysexts are built from RPMs downloaded from the repos included in the base
images (i.e. Fedora's repos), unless explicitely overriden.

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

## Manual download

See the [GitHub release](https://github.com/travier/fedora-sysexts/releases)
for your version of Fedora.

## Manual setup without systemd-sysupdate

Setup the `extensions` directory:

```
$ sudo install -d -m 0755 -o 0 -g 0 /var/lib/extensions/
$ sudo restorecon -RFv /var/lib/extensions/
```

Install the extensions:

```
$ SYSEXT=python
$ sudo install -m 644 -o 0 -g 0 ${SYSEXT}/${SYSEXT}*.raw /var/lib/extensions/${SYSEXT}.raw
```

Enable them (see known issue for details):

```
$ sudo systemctl restart systemd-sysext.service
$ systemd-sysext status
```

Try it out:

```
$ python -c 'print("Hello from a sysext!")'
```

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for details about the CI setup specific to
this repo.

## License

[MIT](LICENSE)
