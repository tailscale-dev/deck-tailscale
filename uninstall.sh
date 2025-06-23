systemctl stop tailscaled
systemctl disable tailscaled
rm -f /etc/systemd/system/tailscaled.service
rm -rf /etc/systemd/system/tailscaled.service.d
rm -f /etc/default/tailscaled
rm -f /etc/profile.d/tailscale.sh
# Remove symlinks from both possible locations (Steam Deck and other systems)
rm -f /usr/local/bin/tailscale /usr/local/bin/tailscaled
rm -f /home/deck/.local/bin/tailscale /home/deck/.local/bin/tailscaled
# Remove specific Tailscale binaries
rm -f /opt/tailscale/tailscale
rm -f /opt/tailscale/tailscaled
# Remove the directory if it's empty (will fail silently if it contains other files)
rmdir /opt/tailscale 2>/dev/null || true
