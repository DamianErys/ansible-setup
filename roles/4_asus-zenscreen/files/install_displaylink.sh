#!/bin/bash
# SPDX-License-Identifier: MIT-0
# install_displaylink.sh
# Installs DisplayLink (EVDI + DisplayLinkManager) on Fedora 43
# Usage: install_displaylink.sh <path-to-DisplayLink.rpm>
# Called by roles/asus-zenscreen/tasks/main.yml

set -euo pipefail

RPM_PATH="${1:?Usage: install_displaylink.sh <path-to-DisplayLink.rpm>}"

# ── 1. Check if already installed ────────────────────────────────────────────
if rpm -q displaylink &>/dev/null; then
    echo "already installed"
    exit 0
fi

# ── 2. Install build dependencies ────────────────────────────────────────────
echo "Installing kernel headers and build tools..."
dnf install -y \
    "kernel-devel-$(uname -r)" \
    "kernel-headers-$(uname -r)" \
    gcc make dkms

# ── 3. Install the DisplayLink RPM (triggers DKMS build automatically) ───────
echo "Installing DisplayLink RPM: ${RPM_PATH}..."
rpm -Uvh "${RPM_PATH}" --nodeps

# ── 4. Verify DKMS module built successfully ─────────────────────────────────
echo "Verifying DKMS build..."
if ! dkms status | grep -q "evdi.*installed"; then
    echo "ERROR: EVDI DKMS module did not build successfully." >&2
    dkms status >&2
    exit 1
fi

# ── 5. Enable and start the service ──────────────────────────────────────────
echo "Enabling displaylink-driver.service..."
systemctl enable displaylink-driver.service
systemctl start displaylink-driver.service

echo "DisplayLink installed successfully."
echo "Plug in your ZenScreen and verify with: xrandr --listproviders"