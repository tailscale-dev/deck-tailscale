# Tailscale on the Steam Deck

This process is derived from the [official guide][official-guide], but with some
tweaks to make the process smoother and produce an installation that both (1)
comes up automatically on boot and (2) survives system updates.

Some key points:

- The Steam Deck uses an immutable system partition with an A/B update system.
  If you don't work within the writable lines, your changes will be lost on the
  next update.

- The Deck's SteamOS 3.0 is based on Arch Linux,

[official-guide]: https://tailscale.com/blog/steam-deck/
