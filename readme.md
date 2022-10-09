# Tailscale on the Steam Deck

This process is derived from the [official guide][official-guide], but with some
tweaks to make the process smoother and produce an installation that both (1)
comes up automatically on boot and (2) survives system updates.

## Installing Tailscale

1. Download the attached `tailscale.sh` and `tailscaled.service` files to your
   Deck.
2. Copy the `tailscaled.service` file to `/etc/systemd/system/`.
3. Run `sudo bash tailscale.sh` to install Tailscale (or update the existing
   installation).

[official-guide]: https://tailscale.com/blog/steam-deck/
