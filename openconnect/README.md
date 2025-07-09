# openconnect

The primary motivation for creating this extension is to address a critical bug
in openconnect-9.12-7 (the version currently available in Fedora 42) that
prevents successful connections to certain VPN configurations. This bug is
tracked here:
<https://gitlab.com/openconnect/openconnect/-/issues/659>

This extension is intended as a temporary solution until the openconnect
package is updated in the official Fedora repositories. The issue is also
tracked in Red Hat Bugzilla here:
<https://bugzilla.redhat.com/show_bug.cgi?id=2376504>

It is built from a COPR:
[dwmw2/openconnect](https://copr.fedorainfracloud.org/coprs/dwmw2/openconnect/).

## Compatibility

This sysext is compatible with Fedora Atomic Desktops.
