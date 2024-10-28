# Experimental sysexts builds as container layers

In each sysext sub directory, there is also a Containerfile that is used to
build a layer that is pushed to a container registry and that can be later
converted into a sysext.

In the end, this could be converted to a plain EROFS or a composefs EROFS using
bootc.

## How to get just the layer

We will use the [deprecated `skopeo layers` command](https://github.com/containers/skopeo/issues/481):

```
# Pick the sysext for the image that you are targeting
$ SYSEXT=iwd
$ IMAGE=quay.io/travier/fedora-kinoite/sysexts:41

# Pull down just thus layer
$ layerhash="$(skopeo inspect docker://${IMAGE}.${SYSEXT} | jq -r '.Layers[-1] | sub ("^sha256:"; "")')"
$ skopeo layers docker://${IMAGE}.${SYSEXT} ${layerhash}

# Extract just the parts that we want / can actually use from the layer
$ cd layers-...
$ tar xvf 0e68a7d3d7i... usr
```

## How to use that?

The next steps would then be to:
- Cleanup the files that we don't need:
  - We can not include the updated RPM database for example as that would not
    make sense (there can only be one so if you have multiple sysexts, the last
    one mounted will win).
  - Running `dnf install` will create local state in `/etc` that we don't want.
  - We then need to move the default content from `/etc` to `/usr/etc`.
- Relabel the files with the SELinux policy (would have to run from the context
  of the container to use the SELinux policy from the layered image).
  - We will also have to make sure that the SELinux policy is rebuilt and
    reloaded after the sysexts are set up on the system. Ideally this should
    probably happen every time we refresh the sysexts.
- Package that into an EROFS image / composefs EROFS.

## Example container layers for sysexts in this repo

- Fedora Kinoite 41: <https://quay.io/repository/travier/fedora-kinoite-sysexts?tab=tags>
- Fedora CoreOS next: <https://quay.io/repository/travier/fedora-coreos-sysexts?tab=tags>

The images are signed with cosign with the public key in
`quay.io-travier-fedora-sysexts.pub` in this repo.
