#!/bin/sh
systemctl stop tailscaled
systemctl disable tailscaled
rm /etc/systemd/system/tailscaled.service
rm /etc/default/tailscaled
rm /etc/profile.d/tailscale.sh
rm -rf /opt/tailscale/tailscale
