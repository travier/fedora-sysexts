# nordvpn

NordVPN (service only) from their official repositories.

## How to use

- Install the sysext
- Create the `nordvpn` group:
  ```
  $ sudo groupadd --system nordvpn
  ```
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

This sysext is compatible with all Fedora variants (CoreOS, Atomic Desktops,
etc.).
