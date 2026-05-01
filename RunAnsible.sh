#!/bin/bash

set -euo pipefail

REPO_URL="https://github.com/DamianErys/ansible-setup"
REPO_DIR="$HOME/ansible-setup"
VAULT_PASS_FILE="$REPO_DIR/vault-pass.txt"
VAULT_FILE="$REPO_DIR/vault.yml"
INVENTORY="$REPO_DIR/inventory.ini"
PLAYBOOK="$REPO_DIR/site.yml"
ISO_DIR="$REPO_DIR/isos"
INSTALLERS_DIR="$REPO_DIR/installers"

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

echo ""
echo "======================================="
echo " Machine Setup — Bootstrap & Preflight "
echo "======================================="
echo ""

# -----------------------------------------------
# Machine type selection
# -----------------------------------------------
echo "Which machine is this?"
echo "  1) Laptop"
echo "  2) PC"
echo "  3) Workstation"
echo ""
read -rp "  Enter 1, 2 or 3: " MACHINE_CHOICE

case "$MACHINE_CHOICE" in
  1) MACHINE_TYPE="laptop" ;;
  2) MACHINE_TYPE="pc" ;;
  3) MACHINE_TYPE="workstation" ;;
  *) fail "Invalid choice — enter 1 for Laptop, 2 for PC, or 3 for Workstation" ;;
esac

echo ""
pass "Machine type set to: $MACHINE_TYPE"
echo ""

# -----------------------------------------------
# STAGE 1 — Install git and ansible
# -----------------------------------------------
echo "--- Stage 1: Bootstrap dependencies ---"
echo ""

if ! command -v git &>/dev/null; then
  info "Installing git..."
  sudo dnf install -y git || fail "Could not install git"
fi
pass "git ready"

if ! command -v ansible-playbook &>/dev/null; then
  info "Installing ansible..."
  sudo dnf install -y ansible || fail "Could not install ansible"
fi
pass "ansible ready"

echo ""
# -----------------------------------------------
# STAGE 2 — Clone or update the repo
# -----------------------------------------------
echo "--- Stage 2: Repo ---"
echo ""

if [[ -d "$REPO_DIR/.git" ]]; then
  info "Repo already exists — pulling latest..."
  git -C "$REPO_DIR" pull || warn "Git pull failed — continuing with existing files"
  pass "Repo up to date"
else
  info "Cloning $REPO_URL..."
  git clone "$REPO_URL" "$REPO_DIR" || fail "Could not clone repo — check network connection"
  pass "Repo cloned to $REPO_DIR"
fi

echo ""
# -----------------------------------------------
# STAGE 3 — Preflight checks
# -----------------------------------------------
echo "--- Stage 3: Preflight checks ---"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Vault password file
echo "Checking vault password file..."
SCRIPT_VAULT_PASS="$SCRIPT_DIR/vault-pass.txt"

if [[ -f "$SCRIPT_VAULT_PASS" ]] && [[ ! -f "$VAULT_PASS_FILE" ]]; then
  info "Moving vault-pass.txt from script directory to repo..."
  mv "$SCRIPT_VAULT_PASS" "$VAULT_PASS_FILE"
  chmod 600 "$VAULT_PASS_FILE"
  pass "vault-pass.txt moved to $REPO_DIR"
elif [[ ! -f "$VAULT_PASS_FILE" ]]; then
  echo ""
  echo -e "${YELLOW}  vault-pass.txt not found anywhere${NC}"
  echo -e "${YELLOW}  Open Proton Vault, copy your 50-char Ansible password,${NC}"
  echo -e "${YELLOW}  then paste it below (input hidden):${NC}"
  echo ""
  read -rs -p "  Paste password: " VAULT_PASSWORD
  echo ""
  echo "$VAULT_PASSWORD" > "$VAULT_PASS_FILE"
  chmod 600 "$VAULT_PASS_FILE"
  pass "vault-pass.txt created"
fi
[[ -s "$VAULT_PASS_FILE" ]] || fail "vault-pass.txt is empty"
pass "vault-pass.txt found"

# Password length
PASS_LEN=$(tr -d '\n\r' < "$VAULT_PASS_FILE" | wc -c)
[[ "$PASS_LEN" -eq 50 ]] && pass "Password length OK (50 chars)" \
  || warn "Password is $PASS_LEN chars, expected 50 — continuing anyway"

# ISO check — laptop only
if [[ "$MACHINE_TYPE" == "laptop" ]]; then
  echo "Checking for tiny11.iso..."
  SCRIPT_ISO="$SCRIPT_DIR/tiny11.iso"
  REPO_ISO="$ISO_DIR/tiny11.iso"

  mkdir -p "$ISO_DIR"

  if [[ -f "$SCRIPT_ISO" ]] && [[ ! -f "$REPO_ISO" ]]; then
    info "Moving tiny11.iso from USB to repo isos folder..."
    mv "$SCRIPT_ISO" "$REPO_ISO"
    pass "tiny11.iso moved to $ISO_DIR"
  elif [[ -f "$REPO_ISO" ]]; then
    pass "tiny11.iso already in place"
  else
    warn "tiny11.iso not found on USB or in repo — VM setup will be skipped"
    warn "Copy tiny11.iso next to RunAnsible.sh and re-run to set up the VM"
  fi
fi

# Helper: move installer file into repo if found next to the script
move_installer() {
  local label="$1" src="$SCRIPT_DIR/$2" dest="$INSTALLERS_DIR/$2"
  echo "Checking for $label..."
  if [[ -f "$src" ]] && [[ ! -f "$dest" ]]; then
    info "Moving $label from script directory to repo installers folder..."
    mv "$src" "$dest"
    pass "$label moved to $INSTALLERS_DIR"
  elif [[ -f "$dest" ]]; then
    pass "$label already in place"
  else
    warn "$label not found — dependent role will fail if run"
    warn "Copy $2 next to RunAnsible.sh and re-run"
  fi
}

mkdir -p "$INSTALLERS_DIR"
move_installer "DisplayLink.rpm" "DisplayLink.rpm"
move_installer "ReqView.deb"     "ReqView.deb"
move_installer "XPPen.tar.gz"    "XPPen.tar.gz"

# Required repo files
echo "Checking required files..."
[[ -f "$VAULT_FILE" ]] || fail "vault.yml not found in repo"
pass "vault.yml found"
[[ -f "$INVENTORY" ]]  || fail "inventory.ini not found in repo"
pass "inventory.ini found"
[[ -f "$PLAYBOOK" ]]   || fail "site.yml not found in repo"
pass "site.yml found"

# Vault decryption
echo "Testing vault decryption..."
ansible-vault view "$VAULT_FILE" --vault-password-file "$VAULT_PASS_FILE" &>/dev/null \
  || fail "Could not decrypt vault — wrong password or corrupted vault file"
pass "Vault decrypts successfully"

# community.general collection
echo "Checking Ansible collections..."
if ! ansible-galaxy collection list 2>/dev/null | grep -q "community.general"; then
  info "Installing community.general collection..."
  ansible-galaxy collection install community.general
fi
pass "community.general collection OK"

echo ""
echo "======================================="
echo -e "${GREEN}   All checks passed — launching Ansible${NC}"
echo "======================================="
echo "   Machine type: $MACHINE_TYPE"
echo "======================================="
echo ""

# -----------------------------------------------
# STAGE 3.5 — Temporary system tweaks
# -----------------------------------------------
echo "--- Stage 3.5: Inhibiting sleep & disabling IPv6 ---"
echo ""

if command -v gsettings &>/dev/null; then
  info "Disabling sleep and screen dimming..."
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
  gsettings set org.gnome.desktop.session idle-delay 0
  pass "Power management inhibited"
fi

info "Disabling IPv6..."
if sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null && \
   sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null; then
  pass "IPv6 disabled"
else
  warn "Failed to disable IPv6 via sysctl"
fi

echo ""

# -----------------------------------------------
# STAGE 4 — Run Ansible
# -----------------------------------------------
ansible-playbook "$PLAYBOOK" \
  -i "$INVENTORY" \
  --vault-password-file "$VAULT_PASS_FILE" \
  -e "machine_type=$MACHINE_TYPE" \
  -e "ansible_become_password=$(ansible-vault view "$VAULT_FILE" --vault-password-file "$VAULT_PASS_FILE" | grep vault_ssh_password | awk '{print $2}')"