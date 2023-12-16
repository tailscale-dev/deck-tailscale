#!/usr/bin/env bash

# make system configuration vars available
source /etc/os-release

# set invocation settings for this script:
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error when substituting.
# -o pipefail: the return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if no command exited with a non-zero status
set -eu -o pipefail

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

echo -n "Downloading..."

# download the Tailscale package itself
curl -s "https://pkgs.tailscale.com/stable/${tarball}" -o tailscale.tgz

echo "done."

echo -n "Installing..."

# extract the tailscale binaries
tar xzf tailscale.tgz
tar_dir="$(echo ${tarball} | cut -d. -f1-3)"
test -d $tar_dir

# Create binaries directory in home
mkdir -p /home/deck/.bin

# pull binaries
cp -rf $tar_dir/tailscale /home/deck/.bin/tailscale
cp -rf $tar_dir/tailscaled /home/deck/.bin/tailscaled

# add binaries to path via bashrc if not already there
if [ $(cat /home/deck/.bashrc | grep -c "/home/deck/.bin") -eq 0 ]; then
  echo "/home/deck/.bin" >> /home/deck/.bashrc
fi

# copy in the defaults file if it doesn't already exist
if ! test -f /home/deck/.config/tailscaled.defaults; then
  cp -rf $tar_dir/systemd/tailscaled.defaults /home/deck/.config/tailscaled.defaults
fi

# copy the systemd file into place
cp -rf $tar_dir/systemd/tailscaled.service /etc/systemd/system

sed -i 's@/etc/default/tailscaled@/home/deck/.config/tailscaled.defaults@g' /etc/systemd/system/tailscaled.service
sed -i 's@/usr/sbin/tailscaled@/home/deck/.bin/tailscaled@g' /etc/systemd/system/tailscaled.service

# return to our original directory (silently) and clean up
popd > /dev/null
rm -rf "${dir}"

echo "Starting required services..."

# tailscaled - the tailscale daemon
systemctl enable tailscaled
if systemctl is-active --quiet tailscaled; then
  echo "Upgrade complete. Restarting tailscaled..."
else
  echo "Install complete. Starting tailscaled..."
fi
systemctl restart tailscaled # This needs to be the last thing we do in case the user's running this over Tailscale SSH.

echo "Done."
