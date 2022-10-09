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
4. Run `sudo tailscale up --qr --operator=deck --ssh` to have Tailscale generate
   a login QR code. Scan the code with your phone and authenticate with
   Tailscale to bring your Deck onto your network.

[official-guide]: https://tailscale.com/blog/steam-deck/

## How it works

The Deck runs SteamOS 3, which is derived from Arch and thus uses a software
suite called systemd to manage services.
