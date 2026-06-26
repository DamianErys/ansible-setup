# update-system

Performs a full system update on Fedora before any apps or config are applied.

## What it does
- Upgrades all installed packages via DNF
- Installs and updates kernel, kernel headers, and module packages
- Installs fwupd and applies any available firmware updates

## Variables
None — this role uses no custom variables.

## Notes
- Must run before any other role to ensure the system is on a clean baseline
- fwupd will not fail the play if no firmware updates are available
- A reboot may be required after a kernel update for the new kernel to take effect —
  this is left intentional and manual so you control when it happens