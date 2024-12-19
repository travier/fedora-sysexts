# docker-ce

Docker Engine from [community repos](https://docs.docker.com/engine/install/fedora/).

## How to use

- Install the sysext
- Create the `docker` group:
  ```
  $ sudo groupadd --system docker
  ```
- Enable and start the daemon:
  ```
  $ sudo systemctl enable --now docker
  ```
- For an unknown reason yet, you will have to start it manually on each boot.
