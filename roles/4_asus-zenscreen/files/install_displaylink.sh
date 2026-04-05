#!/bin/bash
# install_displaylink.sh
# Installs DisplayLink driver for ASUS ZenScreen on Fedora 43
# Fetches kernel-devel/headers from Koji if not available in repos
# Safe to re-run (idempotent)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

pass() { echo -e "${GREEN}  ✓ $1${NC}"; }
fail() { echo -e "${RED}  ✗ $1${NC}"; exit 1; }
warn() { echo -e "${YELLOW}  ! $1${NC}"; }
info() { echo -e "${CYAN}  → $1${NC}"; }

KERNEL=$(uname -r)
# Parse kernel version for koji URL — e.g. 6.17.1-300.fc43.x86_64
# Koji path needs version and release split: kernel/6.17.1/300.fc43/x86_64/
KERNEL_VER=$(echo "$KERNEL" | cut -d- -f1)           # 6.17.1
KERNEL_REL=$(echo "$KERNEL" | cut -d- -f2)           # 300.fc43.x86_64
KERNEL_REL_NOARCH=$(echo "$KERNEL_REL" | sed 's/\.x86_64//')  # 300.fc43
KOJI_BASE="https://kojipkgs.fedoraproject.org/packages/kernel/${KERNEL_VER}/${KERNEL_REL_NOARCH}/x86_64"

RPM_PATH="${1:-}"  # Optional: pass path to DisplayLink.rpm as first argument

echo ""
echo "======================================="
echo "   DisplayLink / ZenScreen Installer"
echo "   Kernel: $KERNEL"
echo "======================================="
echo ""

# -----------------------------------------------
# 1. kernel-devel and kernel-headers
# -----------------------------------------------
info "Checking kernel-devel for $KERNEL..."

if rpm -q "kernel-devel-$KERNEL" &>/dev/null; then
    pass "kernel-devel-$KERNEL already installed"
else
    info "Not in repos — fetching from Koji..."
    sudo dnf install -y \
        "${KOJI_BASE}/kernel-devel-${KERNEL}.rpm" \
        || fail "Could not install kernel-devel from Koji. Check: $KOJI_BASE"
    pass "kernel-devel installed from Koji"
fi

info "Checking kernel-headers for $KERNEL..."
if rpm -q "kernel-headers-$KERNEL" &>/dev/null; then
    pass "kernel-headers-$KERNEL already installed"
else
    info "Not in repos — fetching from Koji..."
    sudo dnf install -y \
        "${KOJI_BASE}/kernel-headers-${KERNEL_VER}-${KERNEL_REL_NOARCH}.x86_64.rpm" \
        || fail "Could not install kernel-headers from Koji. Check: $KOJI_BASE"
    pass "kernel-headers installed from Koji"
fi

# -----------------------------------------------
# 2. Build tools and DKMS
# -----------------------------------------------
info "Installing build tools..."
sudo dnf install -y gcc make dkms
pass "Build tools ready"

# -----------------------------------------------
# 3. DisplayLink RPM
# -----------------------------------------------
if rpm -q displaylink &>/dev/null; then
    pass "DisplayLink already installed — skipping RPM install"
else
    if [[ -z "$RPM_PATH" ]]; then
        fail "DisplayLink not installed and no RPM path provided. Usage: $0 /path/to/DisplayLink.rpm"
    fi
    [[ -f "$RPM_PATH" ]] || fail "RPM not found at: $RPM_PATH"
    info "Installing DisplayLink from $RPM_PATH..."
    sudo dnf install -y "$RPM_PATH"
    pass "DisplayLink RPM installed"
fi

# -----------------------------------------------
# 4. Verify DKMS build
# -----------------------------------------------
info "Checking DKMS evdi build status..."
DKMS_OUT=$(dkms status evdi 2>&1)
if echo "$DKMS_OUT" | grep -q "installed"; then
    pass "DKMS evdi module built and installed"
else
    fail "DKMS evdi module did not build correctly.\nRun: dkms status\nCheck: /var/lib/dkms/evdi/\nOutput was: $DKMS_OUT"
fi

# -----------------------------------------------
# 5. Load module
# -----------------------------------------------
info "Loading evdi module..."
if lsmod | grep -q "^evdi"; then
    pass "evdi module already loaded"
else
    sudo modprobe evdi
    pass "evdi module loaded"
fi

# -----------------------------------------------
# 6. Enable and start service
# -----------------------------------------------
info "Enabling displaylink-driver service..."
sudo systemctl enable displaylink-driver.service
sudo systemctl start displaylink-driver.service
pass "displaylink-driver service running"

echo ""
echo "======================================="
echo -e "${GREEN}   ZenScreen install complete!${NC}"
echo "   Plug in your ZenScreen now."
echo "   Then run: xrandr --listproviders"
echo "======================================="
echo ""
