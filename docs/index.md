---
nav_order: 1
---

# Fedora RPM based sysexts for Fedora image based systems

**NOTE: This project is a work in progress. Make sure to read the [known
limitations section](https://extensions.fcos.fr/known-issues). Use at your own
risk.**

This sub project gathers systemd system extensions (sysexts) made exclusively
from official Fedora packages.

The goal of this repo is to eventually become the source of official Fedora
sysexts built in the Fedora infrastructure.

For sysexts built from community sources, see
[extensions.fcos.fr/community](https://extensions.fcos.fr/community).

For general explainations about systemd system extensions (sysexts) and how to
use them, see the documentation from the parent page:
[extensions.fcos.fr](https://extensions.fcos.fr).

## Compatibility

Those sysexts should work will all Fedora based image mode systems (Atomic
Desktops, CoreOS, IoT, etc.), wether they are Bootable Containers (bootc)
images, or classic ostree/rpm-ostree systems. They should also work with
derivative images such as Bluefin, Aurora or Bazzite from the Universal Blue
project.

Some sysexts are designed for specific variants only (i.e. for Fedora CoreOS
only for example). This is generally detailed on each sysext's page. Make
sure to verify for each sysext for which variant it was made. Feel free to
submit issues or pull-requests if you think there is an error.

## Building, contributing and licenses

See the project's [README](https://github.com/fedora-sysexts/fedora).
