systemctl stop tailscaled
systemctl disable tailscaled
rm /etc/systemd/system/tailscaled.service
rm /etc/default/tailscaled
rm /etc/profile.d/tailscale.sh
rm /etc/atomic-update.conf.d/tailscale.conf
rm -rf /opt/tailscale/tailscale
