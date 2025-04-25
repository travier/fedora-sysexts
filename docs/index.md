---
nav_order: 1
---

# systemd system extensions for Fedora image based systems

**NOTE: This is currently an experimental project. Make sure to read the known
limitations section. Use at your own risk.**

This project makes sysexts available for Fedora CoreOS, Fedora Atomic Desktops,
Fedora IoT, and other Fedora Bootable Container (bootc) systems (and classic
ostree/rpm-ostree systems).

## What are sysexts?

systemd system extensions (sysexts) are filesystem images that bundle content
(binaries, libraries and configuration files) that can be overlayed on demand
on image based systems. The content of the sysexts are "merged" with the base
content of the OS using an overlayfs mount.

In the context of this project, the sysexts are
[EROFS](https://erofs.docs.kernel.org/en/latest/index.html) disk images that
include content to overlay on top of `/usr`.

If you want to know more about sysexts, you can watch the
[Waiter, an OS please, with some sysext sprinkled on top](https://cfp.all-systems-go.io/all-systems-go-2024/talk/HJLF3C/)
([video](https://media.ccc.de/v/all-systems-go-2024-313-waiter-an-os-please-with-some-sysext-sprinkled-on-top))
talk at All systems go! Berlin 2024.

For a more general description of sysexts, see the
[Extension Images](https://uapi-group.org/specifications/specs/extension_image/)
specification from the UAPI group.

## Can sysexts replace package layering or container builds?

Sysexts can only modify the content in `/usr` and they are enabled relatively
"late" during the boot process, thus they come with some limitations. They can
not be used to:
- install another kernel
- install kernel modules
- make changes to the initrd
- make changes to `/etc`
- add udev rules

If you need to do one of those, you should use package layering or do a
container build. Otherwise, sysexts might be a good fit.

## Available sysexts

You can find all the available sysexts in the list on the side of this page.
The sysexts are built for the current stable releases of Fedora, for `x86_64`
and `aarch64`, if the software is avaible for it. Some images only target
Fedora CoreOS and are thus only built for the current releases used by Fedora
CoreOS.

## Integration with bootc / Bootable Containers

The planned user experience for using those sysexts is that they are built as
container layers, pushed to a registry as distinct tags, downloaded, managed
and updated in sync with the OS by bootc. See:
[bootc#7](https://github.com/containers/bootc/issues/7) and
[README.containers.md](https://github.com/travier/fedora-sysexts/blob/main/README.containers.md).

This integration is currently still a work in progress. The first step will
likely be a standalone sysext manager / updater application, which will then be
integrated into bootc.

## Installing and updating using `systemd-sysupdate`

You can currently install and update those sysexts using `systemd-sysupdate`.
See the individual pages for instructions.

To update all sysexts on a system:

```
for c in $(/usr/lib/systemd/systemd-sysupdate components --json=short | jq --raw-output '.components[]'); do
    sudo /usr/lib/systemd/systemd-sysupdate update --component "${c}"
done
```

## Installing directly via Ignition

On Fedora CoreOS, you can also directly download the sysexts images as files
via Ignition. Here is an example Butane config:

```
variant: fcos
version: 1.5.0
storage:
  files:
    - path: "/var/lib/extensions/kubernetes-cri-o-1.32.raw"
      contents:
        source: "https://extensions.fcos.fr/extensions/kubernetes-cri-o-1.32/kubernetes-cri-o-1.32-1.32.3-1.fc42-42-x86-64.raw"
systemd:
  units:
    # Enable systemd-sysext.service to merge the sysexts on boot
    - name: systemd-sysext.service
      enabled: true
    # We will use CRI-O
    - name: docker.socket
      enabled: false
      mask: true
```

See
[travier/fedora-coreos-kubernetes](https://github.com/travier/fedora-coreos-kubernetes)
for a more complete example deploying Kubernetes on Fedora CoreOS using
sysexts.

## Know issues

### Use `systemctl restart systemd-sysext.service` to refresh sysexts

Until systemd v257 is released and lands in Fedora, make sure to use `systemctl
restart systemd-sysext.service` instead of `systemd-sysext merge`.
`systemd-sysext unmerge` is safe to use.

See:
- <https://github.com/coreos/fedora-coreos-tracker/issues/1744>
- <https://github.com/systemd/systemd/issues/34387>
- <https://github.com/systemd/systemd/pull/34414>
- <https://github.com/systemd/systemd/pull/35132>

This should be fixed in Fedora 42 based images, but has not been fully verified
yet.

### Current limitation of systemd-sysupdate

While installing and updating via `systemd-sysupdate` works, this also has a
few limitations:
- The sysexts are enabled "statically" for all deplpoyments and if you rebase
  between major Fedora versions, the sysexts will not match the Fedora release
  and will not be loaded until you update again using `systemd-sysupdate`.
- The SELinux policy is currently incomplete for `systemd-importd`, used by
  `systemd-sysupdate`, which thus prevent us from running updates as a service
  in the background for now. See:
  - <https://github.com/fedora-selinux/selinux-policy/pull/2604>
  - <https://github.com/fedora-selinux/selinux-policy/issues/2622>

## Building, contributing and license

See the project [README](https://github.com/travier/fedora-sysexts).
