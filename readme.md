# Tailscale on the Steam Deck

This process is derived from the [official guide](https://tailscale.com/blog/steam-deck), but has been
tweaked to make the process smoother and produce an installation that comes up
automatically on boot (no need to enter desktop mode).

## Installing Tailscale

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

## Updating the install script

To benefit from improvements to the install script, consider rerunning it from time to time.

1. Git fetch and pull to make sure you're up to date:
   1. `cd ~/deck-tailscale`
   2. `git pull`
2. Run `sudo bash tailscale.sh` again.

This process overwrites the existing binaries and service file, so it's not
recommended to tweak those files directly. The configuration file at
`/etc/default/tailscaled` is left alone. The configuration file at
`/etc/systemd/system/tailscaled.service.d/override.conf` is reset every time this script is run to ensure the path to the binary is correct, but the preexisting file will be backed up in that directory as `override.conf.bak`. If something goes wrong, copy those files somewhere else and re-run the install script to get back to a working state.

## Common issues

### Broken config file

Symptom: `invalid value "" for flag -port: can't be the empty string`

Resolution: Delete `/etc/default/tailscaled` and re-run installer script.

## How it works

The Tailscale binaries `tailscale` and `tailscaled` are installed in `/opt/tailscale/`. The Tailscale systemd unit file is installed at `/etc/systemd/system/tailscale.service`. The override file to reconfigure the services `Exec` commands is installed at `/etc/systemd/system/tailscaled.service.d/override.conf`. The defaults file for the variables `PORT` and `FLAGS` is installed at `/etc/default/tailscaled`

The service is then started and enabled via `systemctl`.

