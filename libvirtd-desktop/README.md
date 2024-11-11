# libvirtd sysext

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
  $ sudo cp -a /usr/etc/libvirtd /etc/
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
- Enable libvirtd:
  ```
  $ sudo systemctl enable --now libvirtd
  ```
