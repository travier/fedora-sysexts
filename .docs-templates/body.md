## Versions available

See the [%%SYSEXT%% versions](%%RELEASEURL%%/%%SYSEXT%%).

## Usage instructions

<details markdown="block">
<summary>First time setup</summary>
Run those commands if you have not yet installed any sysext on your system:

```
sudo install -d -m 0755 -o 0 -g 0 /var/lib/extensions /var/lib/extensions.d
sudo restorecon -RFv /var/lib/extensions /var/lib/extensions.d
sudo systemctl enable --now systemd-sysext.service
```
</details>

<details markdown="block">
<summary>Installation</summary>
Define a helper function:

```
install_sysext() {
  SYSEXT="${1}"
  URL="%%EXTENSIONSURL%%"
  sudo install -d -m 0755 -o 0 -g 0 /etc/sysupdate.${SYSEXT}.d
  sudo restorecon -RFv /etc/sysupdate.${SYSEXT}.d
  curl --silent --fail --location "${URL}/${SYSEXT}.conf" \
    | sudo tee "/etc/sysupdate.${SYSEXT}.d/${SYSEXT}.conf"
  sudo /usr/lib/systemd/systemd-sysupdate update --component "${SYSEXT}"
}
```

Install the sysext:

```
install_sysext %%SYSEXT%%
```
</details>

<details markdown="block">
<summary>Merging</summary>
Note that this will merge all installed sysexts unconditionally:

```
sudo systemctl restart systemd-sysext.service
systemd-sysext status
```

You can also reboot the system.
</details>

<details markdown="block">
<summary>Updates</summary>
Update this sysext using:

```
sudo /usr/lib/systemd/systemd-sysupdate update --component %%SYSEXT%%
```

If you want to use the new version immediately, make sure to refresh the merged
sysexts:

```
sudo systemctl restart systemd-sysext.service
systemd-sysext status
```

To update all sysexts on a system:

```
for c in $(/usr/lib/systemd/systemd-sysupdate components --json=short | jq --raw-output '.components[]'); do
    sudo /usr/lib/systemd/systemd-sysupdate update --component "${c}"
done
```
</details>

<details markdown="block">
<summary>Uninstall</summary>
Define a helper function:

```
uninstall_sysext() {
  SYSEXT="${1}"
  sudo rm -i "/var/lib/extensions/${SYSEXT}.raw"
  sudo rm -i "/var/lib/extensions.d/${SYSEXT}-"*".raw"
  sudo rm -i "/etc/sysupdate.${SYSEXT}.d/${SYSEXT}.conf"
  sudo rmdir "/etc/sysupdate.${SYSEXT}.d/"
}
```

Uninstall the sysext:

```
uninstall_sysext %%SYSEXT%%
```

Reboot your system or refresh the merged sysexts:

```
sudo systemctl restart systemd-sysext.service
systemd-sysext status
```
</details>
