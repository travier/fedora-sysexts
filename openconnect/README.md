# openconnect

The primary motivation for creating this extension is to address a critical bug in openconnect-9.12-7 (the version currently available in Fedora 42) that prevents successful connections to certain VPN configurations. This bug is tracked here:
<https://gitlab.com/openconnect/openconnect/-/issues/659>

This sysextension is intended as a temporary solution until the openconnect package is updated in the official Fedora repositories. The issue is also tracked in Red Hat Bugzilla here:
<https://bugzilla.redhat.com/show_bug.cgi?id=2376504>

## Compatibility

This extension has been tested exclusively on Fedora Kinoite 42. It targets the Fedora Atomic Desktops. Compatibility with other Fedora variants or older versions should be verified independently.
