# remove-packages

Removes Fedora default bloat and permanently prevents it from returning.

## What it does
- Removes bloat dependants first to avoid DNF conflicts
- Removes main bloat packages with autoremove to clean orphaned deps
- Adds all removed packages to DNF `excludepkgs` so they can never
  be reinstalled by GNOME Software or a system update
- Removes orphaned `.desktop` files left behind after uninstall
- Masks Flatpak versions from GNOME Software so they don't appear
  as suggested installs from Flathub

## Variables
None

## Bringing a package back
To undo the DNF exclusion for a specific package, edit `/etc/dnf/dnf.conf`
and remove it from the `excludepkgs=` line, then reinstall manually.

To undo a Flatpak mask: `flatpak mask --remove <app-id>`

## Notes
- `ignore_errors: true` is intentional — if a package isn't installed
  DNF will error without it, which would fail the whole play
- Run this after `update-system` and before `flatpak-packages`