# docker-ce

Docker Engine from [community repos](https://docs.docker.com/engine/install/fedora/).

## How to use

- Install the sysext
- Create the `docker` group:
  ```
  $ sudo groupadd --system docker
  ```
- Restart the socket:
  ```
  $ sudo systemctl enable --now docker.socket
  ```

## Compatibility

This sysext should be compatible with all Fedora variants (CoreOS, Atomic
Desktops, etc.) but has not been tested on systems with `moby-engine` installed
such as Fedora CoreOS.
