systemctl stop tailscaled
systemctl disable tailscaled
rm -f /etc/systemd/system/tailscaled.service
rm -rf /etc/systemd/system/tailscaled.service.d
rm -f /etc/default/tailscaled
rm -f /etc/profile.d/tailscale.sh
rm -f /usr/local/bin/tailscale
rm -f /usr/local/bin/tailscaled
# Remove specific Tailscale binaries
rm -f /opt/tailscale/tailscale
rm -f /opt/tailscale/tailscaled
# Remove the directory if it's empty (will fail silently if it contains other files)
rmdir /opt/tailscale 2>/dev/null || true
