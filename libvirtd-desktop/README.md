# libvirtd-desktop

`libvirtd`, `qemu`, `swtpm`, `virt-install` and `guestfs-tools` for desktop
usage.

See the [Virtual Machine Manager Flatpak](https://flathub.org/apps/org.virt_manager.virt-manager).

## How to use

- Install the sysext
- Create the `qemu` user:
  ```
  $ sudo systemd-sysusers /usr/lib/sysusers.d/libvirt-qemu.conf
  ```
- Copy the some default config:
  ```
  $ sudo cp -a /usr/etc/mdevctl.d /etc/
  ```
- Optional: Copy the default libvirtd config (note that it won't be updated automatically):
  ```
  $ sudo cp -a /usr/etc/libvirt /etc/
  ```
- Optional: Setup auth via polkit (example):
  ```
  $ sudo cat /etc/polkit-1/rules.d/50-libvirt.rules
  polkit.addRule(function(action, subject) {
      if (action.id == "org.libvirt.unix.manage" &&
          subject.isInGroup("wheel")) {
              return polkit.Result.YES;
      }
  });
  ```
- Enable libvirtd (via virtqemud & virtnetworkd):
  ```
  $ sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket
  ```
- For an unknown reason yet, you will have to start them manually on each boot.
