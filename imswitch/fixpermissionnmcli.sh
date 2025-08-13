#!/usr/bin/env bash
# setup_nmcli_sudo.sh
# Make user "pi" able to run `nmcli` via sudo without password (inside Docker or host).
# Idempotent. Works on Debian/Raspberry Pi OS–based images.

set -euo pipefail
sudo apt-get update
# `nmcli` comes from `network-manager`
sudo apt-get install -y network-manager
  
local nmcli_path
nmcli_path="$(command -v nmcli || echo /usr/bin/nmcli)"

echo "Writing sudoers rule for ${USER_NAME} → ${nmcli_path}"
local file="/etc/sudoers.d/nmcli-${USER_NAME}"
printf '%s ALL=(root) NOPASSWD: %s\n' "${USER_NAME}" "${nmcli_path}" > "${file}"
sudo chmod 440 "${file}"

# Validate (ignore failure if visudo missing)
if command -v visudo >/dev/null 2>&1; then
visudo -cf "${file}"
fi
