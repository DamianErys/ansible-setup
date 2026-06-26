# flatpak-packages

Installs Flatpak, adds the Flathub remote, and installs all apps by machine type.

## What it does
- Installs the Flatpak package via DNF
- Adds the Flathub remote if not already present
- Installs shared apps on both laptop and PC
- Installs PC-only apps when `machine_type == 'pc'`

## Variables
| Variable       | Where set          | Purpose                          |
|----------------|--------------------|----------------------------------|
| `machine_type` | passed by RunAnsible.sh | Controls which app set installs |

## Apps installed (both)
VSCode, Spotify, TeXstudio, AnyDesk, ProtonVPN, Proton Mail, Proton Pass,
VLC, Inkscape, Zapzap, Discord, KiCad, PulseView, Raspberry Pi Imager

## Apps installed (PC only)
Steam, Epic Games Launcher, Heroic Games Launcher

## Notes
- Flatpak IDs are case sensitive — if an install fails check the exact ID on flathub.org
- The laptop-only task block is a placeholder for future apps