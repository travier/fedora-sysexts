# Fedora RPM based systemd system extensions for Fedora image based systems

**NOTE: This project is a work in progress. Make sure to read the [known
limitations section](https://extensions.fcos.fr). Use at your own risk.**

This repo gathers sysexts made exclusively from official Fedora packages.

The goal of this repo is to eventually become the source of official Fedora
sysexts built in the Fedora infrastructure.

For sysexts built from community provided sources, see
[extensions.fcos.fr/community](https://extensions.fcos.fr/community).

For general explainations about systemd system extensions (sysexts) and how
to use them, see the documentation from the main page:
[extensions.fcos.fr](https://extensions.fcos.fr).

## Building

Building those images currently require `root` privileges. The currently
supported options for building those sysexts are:
- using a rootless, privileged, non-SELinux confined container (such as a
  toolbox/distrobox container), redirecting `podman` commands to run them on
  the host:
  ```
  [toolbox]$ cat /usr/local/bin/podman
  #!/bin/bash
  executable="$(basename ${0})"
  exec flatpak-spawn --host "${executable}" "${@}"
  ```
- Using nested podman containers (current path in CI).

Make sure that you have the following packages installed:
- `cpio`
- `erofs-utils`
- `jq`
- [`just`](https://github.com/casey/just)
- `podman` (only when not using the host redirection script above)
- `wget`

To build the `python` sysext:

```
$ cd python
```

List the supported target images:

```
$ just targets
```

Build the sysext for Fedora CoreOS *next*:

```
$ just build "quay.io/fedora/fedora-coreos:next"
```

## `extensions.fcos.fr` redirector

A Caddy based redirector is hosted at `extensions.fcos.fr`. The configutation
is available in the parent project's Caddyfile. It redirects URLs queried by
`systemd-sysupdate` to GitHub releases where the sysexts are hosted in this
repo.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for details about the CI setup specific to
this repo.

## Credits

This project is heavily inspired by the work done by
[Thilo](https://github.com/t-lo) on the
[Flatcar sysext bakery](https://flatcar.github.io/sysext-bakery/).

## Licenses

See [LICENSES](LICENSES).
