# Contributing to this repo

## Adding a new sysext

- Create a new folder
- Add a `justfile` and `Containerfile`
  - See `sysext.just` for all options and other sysexts for examples
- Add a README.md with any notes about the sysext, its setup, etc.
- Commit your changes
- Then see the CI setup section below

## CI setup

To ensure that the dependencies are in sync, the sysexts are built from the
base images that they are targetting. Thus to reduce the number of times each
base OS container images have to be pulled and make the CI faster in general,
the GitHub workflows use manual templating instead of the classic matrix
feature.

When making changes to the base image list for a sysext (in the justfile only
for now), adding a new sysext, renaming or removing one, you need to also
re-generate the workflows using the `update_workflows.sh` script.

Note that this script only takes into account commited files thus when adding a
new sysext, you should commit the content first, then run the script and
finally amend the commit with the updated workflows.
