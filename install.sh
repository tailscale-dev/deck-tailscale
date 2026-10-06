#!/usr/bin/env bash

# Tailscale on Steam Deck - One-line installer script
# Inspired by decky-installer, this script handles dependencies, sudo elevation,
# downloading, service configuration, and daemon startup in a single command.

set -eu -o pipefail

# Determine target user (for --operator)
if [ -n "${SUDO_USER:-}" ]; then
  TARGET_USER="$SUDO_USER"
elif [ -n "${USER:-}" ] && [ "$USER" != "root" ]; then
  TARGET_USER="$USER"
else
  TARGET_USER="deck"
fi

# Elevation check
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: sudo is required to install Tailscale." >&2
    exit 1
  fi
  echo "Tailscale installer requires root privileges."
  echo "Please enter your sudo password if prompted:"
  sudo -v || { echo "Authentication failed. Exiting." >&2; exit 1; }
  SUDO="sudo"
fi

# Dependency check
for cmd in curl jq tar systemctl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' is not found. Please install it first." >&2
    exit 1
  fi
done

# Prepare clean temporary directory
TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "Fetching latest Tailscale version info..."
tarball="$(curl -s 'https://pkgs.tailscale.com/stable/?mode=json' | jq -r .Tarballs.amd64)"
if [ -z "${tarball}" ] || [ "${tarball}" = "null" ]; then
  echo "Error: Failed to fetch Tailscale package metadata." >&2
  exit 1
fi
version="$(echo "${tarball}" | cut -d_ -f2)"
echo "Found Tailscale version ${version}."

echo "Downloading Tailscale package..."
curl -fL --progress-bar -o "${TMP_DIR}/tailscale.tgz" "https://pkgs.tailscale.com/stable/${tarball}"

echo "Cleaning up any legacy installations..."
if systemctl is-active --quiet tailscaled 2>/dev/null; then
  $SUDO systemctl stop tailscaled &>/dev/null || true
fi
if systemctl is-enabled --quiet tailscaled 2>/dev/null; then
  $SUDO systemctl disable tailscaled &>/dev/null || true
fi

if [ "$(systemd-sysext list 2>/dev/null | grep -c "/var/lib/extensions/tailscale" || true)" -ne 0 ]; then
  $SUDO systemd-sysext unmerge &>/dev/null || true
  $SUDO rm -rf /var/lib/extensions/tailscale
  $SUDO systemd-sysext merge &>/dev/null || true
fi

echo "Extracting and installing binaries to /opt/tailscale..."
tar -xzf "${TMP_DIR}/tailscale.tgz" -C "${TMP_DIR}"
tar_dir="${TMP_DIR}/$(echo "${tarball}" | cut -d. -f1-3)"

$SUDO mkdir -p /opt/tailscale
$SUDO cp -rf "${tar_dir}/tailscale" /opt/tailscale/tailscale
$SUDO cp -rf "${tar_dir}/tailscaled" /opt/tailscale/tailscaled
$SUDO chmod 755 /opt/tailscale/tailscale /opt/tailscale/tailscaled

# Add binaries to PATH via profile.d
if ! test -f /etc/profile.d/tailscale.sh; then
  echo 'PATH="$PATH:/opt/tailscale"' | $SUDO tee /etc/profile.d/tailscale.sh > /dev/null
fi
export PATH="$PATH:/opt/tailscale"

# Copy systemd unit file and defaults
$SUDO cp -rf "${tar_dir}/systemd/tailscaled.service" /etc/systemd/system/tailscaled.service
if ! test -f /etc/default/tailscaled; then
  $SUDO cp -rf "${tar_dir}/systemd/tailscaled.defaults" /etc/default/tailscaled
fi

# Ensure configs survive SteamOS atomic system updates
$SUDO mkdir -p /etc/atomic-update.conf.d
$SUDO tee /etc/atomic-update.conf.d/tailscale.conf > /dev/null <<'EOF'
/etc/default/tailscaled
/etc/profile.d/tailscale.sh
EOF

# Install systemd override file
$SUDO mkdir -p /etc/systemd/system/tailscaled.service.d
if test -f /etc/systemd/system/tailscaled.service.d/override.conf; then
  $SUDO cp -f /etc/systemd/system/tailscaled.service.d/override.conf /etc/systemd/system/tailscaled.service.d/override.conf.bak
fi

$SUDO tee /etc/systemd/system/tailscaled.service.d/override.conf > /dev/null <<'EOF'
[Service]
EnvironmentFile=/etc/default/tailscaled
ExecStartPre=
ExecStartPre=/opt/tailscale/tailscaled --cleanup
ExecStart=
ExecStart=/opt/tailscale/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=${PORT} $FLAGS
ExecStopPost=
ExecStopPost=/opt/tailscale/tailscaled --cleanup
EOF

# Reload and start service
$SUDO systemctl daemon-reload
$SUDO systemctl enable tailscaled &>/dev/null || true
$SUDO systemctl restart tailscaled

# Wait for tailscaled daemon to be active and socket to be ready
echo "Waiting for Tailscale daemon to be ready..."
for i in {1..15}; do
  if [ -S /run/tailscale/tailscaled.sock ] && $SUDO /opt/tailscale/tailscale status --json &>/dev/null; then
    break
  fi
  sleep 1
done

echo "Tailscale daemon (tailscaled) is installed and active."
echo ""
echo "Connecting Tailscale to your network..."
echo "(Scan the QR code with your phone to log in)"
echo ""

$SUDO /opt/tailscale/tailscale up --qr --operator="${TARGET_USER}" --ssh || true

echo ""
echo "========================================="
echo " Tailscale installation complete!"
echo "========================================="
echo "You can manage Tailscale directly as user '${TARGET_USER}' without sudo."
echo "To enable automatic updates, run:"
echo "  tailscale set --auto-update"
echo ""
