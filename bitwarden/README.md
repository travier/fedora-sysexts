# Bitwarden

The [Bitwarden](https://bitwarden.com/) password manager.

## Differences from the Flatpak version

While both the packaged version and the Flatpak version are equal in core
functionality, some features (e.g.: biometrics autosetup and the ssh-agent sock
present at `$HOME/.bitwarden-ssh-agent.sock` ) are still only available in the
non-sandboxed version of the app.

## Compatibility

This sysext should be compatible with all Fedora variants (CoreOS, Atomic
Desktops, etc.) but has only been tested on Atomic Desktops.
