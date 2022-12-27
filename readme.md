# Tailscale on the Steam Deck

⚠️ This isn't yet working for SteamOS 3.4+. I'm working on it. ⚠️

This process is derived from the [official guide][official-guide], but lightly
tweaked to make the process smoother and produce an installation that comes up
automatically on boot (no need to enter desktop mode) and survives system
updates.

## Installing Tailscale

1. Download the attached `tailscale.sh` and `tailscaled.service` files to your
   Deck.
2. Copy the `tailscaled.service` file to `/etc/systemd/system/`.
3. Run `sudo bash tailscale.sh` to install Tailscale (or update the existing
   installation).
4. Run `sudo tailscale up --qr --operator=deck --ssh` to have Tailscale generate
   a login QR code. Scan the code with your phone and authenticate with
   Tailscale to bring your Deck onto your network.

## How it works

It uses the same system extension method as the official guide, but we put the
`tailscaled.service` file directly in `/etc/systemd/system/` because it's
actually safe to put things there. Changes in `/etc/` are preserved in
`/var/lib/overlays/etc/upper/` via an overlayfs, meaning that they survive
updates.

[official-guide]: https://tailscale.com/blog/steam-deck/
