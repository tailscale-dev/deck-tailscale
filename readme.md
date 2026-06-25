# Tailscale on the Steam Deck

## Installing Tailscale

> Quick installer (convenient):
>
> curl -fsSL https://raw.githubusercontent.com/thatsthequy/deck-tailscale/main/tailscale.sh | sudo bash
>
> Security note: piping remote scripts into sudo is convenient but risky. Consider inspecting the script first or verifying a checksum before running.

1. Clone this repo to your Deck, switch to root and enter the directory:
   1. `git clone https://github.com/tailscale-dev/deck-tailscale.git ~/deck-tailscale`
   2. `sudo -i`
   3. `cd ~deck/deck-tailscale` 
2. Run `bash tailscale.sh` to install Tailscale (or update the existing
   installation).
3. Run `source /etc/profile.d/tailscale.sh` to put the binaries in your path
4. Run `tailscale up --qr --operator=deck --ssh` to have Tailscale generate
   a login QR code. Scan the code with your phone and authenticate with
   Tailscale to bring your Deck onto your network.

## Updating Tailscale

Tailscale should be able to update itself now! Try running
`sudo tailscale update`, and if that works, `sudo tailscale set --auto-update`.
If it doesn't, keep reading.

> ⚠️ This process will most likely fail if you are accessing the terminal over
> Tailscale SSH, as it seems to be locked in a chroot jail. You should start and
> connect through the standard SSH server instead, but remember to stop it when
> you're done.
> [Suggestions for how to fix this are welcomed.](https://github.com/tailscale-dev/deck-tailscale/issues/2)

## Optional automatic updates

If you'd like Tailscale to be updated automatically, this repository includes
an optional updater script and a systemd timer. The updater runs as root and
will try `tailscale update` (falling back to re-running this install script if
needed). To enable it on your Deck:

1. Copy the updater script to `/usr/local/bin` and the systemd units to
   `/etc/systemd/system/` (run as root):

```sh
sudo install -m 755 scripts/tailscale-deck-update /usr/local/bin/tailscale-deck-update
sudo cp systemd/tailscale-deck-update.service /etc/systemd/system/
sudo cp systemd/tailscale-deck-update.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now tailscale-deck-update.timer
```

2. The timer runs daily by default. To check status or run immediately:

```sh
sudo systemctl status tailscale-deck-update.timer
sudo systemctl start --no-block tailscale-deck-update.service
```

This timer runs the updater as root, which avoids the Tailscale SSH chroot
issue mentioned above.

## Updating the install script

To benefit from improvements to the install script, consider rerunning it from time to time.

1. Git fetch and pull to make sure you're up to date:
   1. `cd ~/deck-tailscale`
   2. `git pull`
2. Run `sudo bash tailscale.sh` again.

This process overwrites the existing binaries and service file, so it's not
recommended to tweak those files directly. The configuration file at
`/etc/default/tailscaled` is left alone. The configuration file at
`/etc/systemd/system/tailscaled.service.d/override.conf` is reset every time this script is run to ensure the path to the binary is correct, but the preexisting file will be backed up in that dire[...]

## Common issues

### Broken config file

Symptom: `invalid value "" for flag -port: can't be the empty string`

Resolution: Delete `/etc/default/tailscaled` and re-run installer script.

## How it works

This script is derived from the [original guide](https://tailscale.com/blog/steam-deck), but has been
tweaked to make the process smoother and produce an installation that comes up
automatically on boot (no need to enter desktop mode).

The Tailscale binaries `tailscale` and `tailscaled` are installed in `/opt/tailscale/`. The Tailscale systemd unit file is installed at `/etc/systemd/system/tailscale.service`. The override file t[...]

The service is then started and enabled via `systemctl`.
