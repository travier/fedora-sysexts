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
- Create the `libvirtdbus` user and group:
  ```
  $ sudo bash -c 'getent group libvirtdbus >/dev/null || groupadd -r libvirtdbus'
  $ sudo bash -c 'getent passwd libvirtdbus >/dev/null || \
      useradd -r -g libvirtdbus -d / -s /sbin/nologin \
      -c "Libvirt D-Bus bridge" libvirtdbus'
  ```
- Create the `libvirt` group to allow password-less polkit access to libvirt deamons:
  ```
  $ sudo bash -c 'getent group libvirt >/dev/null || groupadd -r libvirt'
  ```
- Optional: Add your UID to the libvirt group
  ```
  $ sudo usermod -G -a libvirt $YOUR-UID-HERE
  ```
- Copy the default libvirt dbus config and fix the selinux label
  ```
  $ sudo cp -a /usr/share/dbus-1/system.d/org.libvirt.conf /etc/dbus-1/system.d/
  $ sudo restorecon -Fv /etc/dbus-1/system.d/org.libvirt.conf
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
- Restart libvirtd (via virtqemud, virtnetworkd & virtstoraged):
  ```
  $ sudo systemctl restart virtqemud.socket virtnetworkd.socket virtstoraged.socket
  ```
- Enable virtqemud:
  ```
  $ sudo systemctl enable --now virtqemud
  ```
