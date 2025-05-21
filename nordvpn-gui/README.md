# nordvpn-gui

NordVPN (service and GUI) from their official repositories.

## How to use

- Install the sysext
- Create the `nordvpn` group:
  ```
  $ sudo groupadd --system nordvpn
  ```
- Add your user to the group:
  ```
  $ sudo usermod -aG nordvpn $USER
  ```
- Log out of your session user session or reboot your system
- Copy some data:
  ```
  $ sudo cp -a /usr/share/nordvpn /var/lib/
  $ sudo restorecon -RFv /var/lib/nordvpn
  ```
- Restart the socket and service:
  ```
  $ sudo systemctl restart nordvpnd.socket nordvpnd.service
  ```

## Compatibility

This sysext is compatible with Fedora Atomic Desktops.
