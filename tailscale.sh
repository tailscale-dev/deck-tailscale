#!/usr/bin/env bash

# set invocation settings for this script:
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error when substituting.
# -o pipefail: the return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if no command exited with a non-zero status
set -eu -o pipefail

# save the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# save the current directory silently
pushd . > /dev/null

# make a temporary directory, save the name, and move into it
dir="$(mktemp -d)"
cd "${dir}"

echo -n "Getting version..."

# get info for the latest version of Tailscale
tarball="$(curl -s 'https://pkgs.tailscale.com/stable/?mode=json' | jq -r .Tarballs.amd64)"
version="$(echo ${tarball} | cut -d_ -f2)"

echo "got ${version}."

echo "Downloading:"

# download the Tailscale package itself
wget -q --show-progress -O tailscale.tgz "https://pkgs.tailscale.com/stable/${tarball}"

echo -n "Removing Legacy Installations..."

# Stop and disable the systemd service
if systemctl is-active --quiet tailscaled; then
  systemctl stop tailscaled &>/dev/null || echo "ERROR: could not stop tailscaled"
fi
if systemctl is-enabled --quiet tailscaled; then
  systemctl disable tailscaled &>/dev/null || echo "ERROR: could not disable tailscaled"
fi

# Remove the systemd system extension
if [ $(systemd-sysext list 2>/dev/null | grep -c "/var/lib/extensions/tailscale") -ne 0 ]; then
  systemd-sysext unmerge &>/dev/null || echo "ERROR: could not unmerge system extensions"
  rm -rf /var/lib/extensions/tailscale
  systemd-sysext merge &>/dev/null || echo "ERROR: could not merge system extensions"
fi

echo "done."

echo -n "Installing..."

# extract the tailscale binaries
tar xzf tailscale.tgz
tar_dir="$(echo ${tarball} | cut -d. -f1-3)"
test -d $tar_dir

# Create binaries directory in home
mkdir -p /opt/tailscale

# pull binaries
cp -rf $tar_dir/tailscale /opt/tailscale/tailscale
cp -rf $tar_dir/tailscaled /opt/tailscale/tailscaled

# add binaries to path via profile.d
if ! test -f /etc/profile.d/tailscale.sh; then
  echo 'PATH="$PATH:/opt/tailscale"' >> /etc/profile.d/tailscale.sh
  source /etc/profile.d/tailscale.sh
fi

# copy the systemd file into place
cp -rf $tar_dir/systemd/tailscaled.service /etc/systemd/system/tailscaled.service

# copy in the defaults file if it doesn't already exist
if ! test -f /etc/default/tailscaled; then
  cp -rf $tar_dir/systemd/tailscaled.defaults /etc/default/tailscaled
fi

# return to our original directory (silently) and clean up
popd > /dev/null
rm -rf "${dir}"

# if an override file already exists, back up and remove
if test -f /etc/systemd/system/tailscaled.service.d/override.conf; then
  echo
  echo
  echo "Warning: An existing Tailscaled systemd override file was detected. It must be replaced."
  echo "A backup of the existing file is being placed at /etc/systemd/system/tailscaled.service.d/override.conf.bak"
  echo
  cp -f /etc/systemd/system/tailscaled.service.d/override.conf /etc/systemd/system/tailscaled.service.d/override.conf.bak
  rm /etc/systemd/system/tailscaled.service.d/override.conf
fi

# copy our override file in
mkdir -p /etc/systemd/system/tailscaled.service.d
cp -f "${SCRIPT_DIR}/override.conf" /etc/systemd/system/tailscaled.service.d/override.conf

# capture the above override file in systemd
systemctl daemon-reload

echo "done."

echo -n "Starting required services..."

# tailscaled - the tailscale daemon
# Note: enable and start/restart must be run because the legacy installation stops and disables
# any existing installations.
systemctl enable tailscaled &>/dev/null || echo "ERROR: Could not enable tailscaled service"
if systemctl is-active --quiet tailscaled; then
  echo "Upgrade complete."
  echo -n "Restarting tailscaled..."
else
  echo "Install complete."
  echo -n "Starting tailscaled..."
fi

# This needs to be the last thing we do in case the user's running this over Tailscale SSH.
systemctl restart tailscaled &>/dev/null || echo "ERROR: Could not start tailscaled service"

echo "done."

if ! command -v tailscale &> /dev/null; then
  echo
  echo "Tailscale is installed and running but the binaries are not in your path yet."
  echo "Restart your session or run the following command to add them:"
  echo
  echo "source /etc/profile.d/tailscale.sh"
  echo
fi

echo "Installation Complete."
