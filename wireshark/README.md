# wireshark

Note: Temporarily not built until we can make per-variant (Silverblue, Kinoite,
CoreOS) builds or we directly duplicate this sysext for each variant.

## How to use

- Install the system extension
- Add users to the `tcpdump` group:
  ```
  $ grep -E '^tcpdump:' /usr/lib/group | sudo tee -a /etc/group
  $ sudo usermod --append --groups=tcpdump $USER
  ```

## Why not use the Flatpak?

It should currently be possible to use the Wireshark Flatpak and connect to the
local system via SSH to a rootful container that has tcpdump installed.

See: https://discussion.fedoraproject.org/t/silverblue-wireshark-does-not-see-network-interfaces/88916/11

This requires some manual setup thus in some cases, using this sysext should be
easier.

## Why not use layering?

See: <https://github.com/fedora-silverblue/issue-tracker/issues/50>
