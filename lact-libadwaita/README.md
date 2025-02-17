# lact-libadwaita

Upstream: https://github.com/ilya-zlobintsev/LACT

Meant for GNOME images (see lact for KDE)

## Add kernel parameters so you can actually overclock

```
sudo rpm-ostree kargs --append-if-missing=$(printf 'amdgpu.ppfeaturemask=0x%x\n' "$(($(cat /sys/module/amdgpu/parameters/ppfeaturemask) | 0x4000))")
```

Reboot afterwards

## Autostart the service

```
sudo systemctl enable --now lactd
```
