#!/usr/bin/env bash
# setup_nmcli_sudo.sh
# Make user "pi" able to run `nmcli` via sudo without password (inside Docker or host).
# Idempotent. Works on Debian/Raspberry Pi OS–based images.

set -euo pipefail

USER_NAME="${1:-pi}"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root (use sudo)." >&2
    exit 1
  fi
}

ensure_user() {
  if ! id -u "${USER_NAME}" >/dev/null 2>&1; then
    echo "Creating user '${USER_NAME}'..."
    useradd -m -s /bin/bash "${USER_NAME}"
  fi
}

install_tools() {
  # Ensure sudo + nmcli are available
  if ! command -v sudo >/dev/null 2>&1; then
    apt-get update
    apt-get install -y sudo
  fi

  if ! command -v nmcli >/dev/null 2>&1; then
    apt-get update
    # `nmcli` comes from `network-manager`
    apt-get install -y network-manager
  fi
}

write_sudoers_rule() {
  local nmcli_path
  nmcli_path="$(command -v nmcli || echo /usr/bin/nmcli)"

  echo "Writing sudoers rule for ${USER_NAME} → ${nmcli_path}"
  local file="/etc/sudoers.d/nmcli-${USER_NAME}"
  printf '%s ALL=(root) NOPASSWD: %s\n' "${USER_NAME}" "${nmcli_path}" > "${file}"
  chmod 440 "${file}"

  # Validate (ignore failure if visudo missing)
  if command -v visudo >/dev/null 2>&1; then
    visudo -cf "${file}"
  fi
}

quick_tests() {
  echo "Testing sudo -n nmcli as ${USER_NAME}…"
  set +e
  su -s /bin/bash - "${USER_NAME}" -c 'sudo -n nmcli -t -f DEVICE,TYPE,STATE device status' >/tmp/nmcli_test.out 2>/tmp/nmcli_test.err
  rc=$?
  set -e

  if [[ $rc -ne 0 ]]; then
    echo "nmcli test failed (exit ${rc}). stderr:" >&2
    sed 's/^/  /' /tmp/nmcli_test.err >&2
    # Helpful hints for Dockerized setups:
    if grep -qi "Could not connect to NetworkManager" /tmp/nmcli_test.err; then
      cat >&2 <<'HINT'
Hint: In Docker, nmcli needs access to the host NetworkManager (DBus).
Run the container with at least:
  --privileged --network=host \
  -v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket \
  -v /etc/machine-id:/etc/machine-id:ro
HINT
    fi
    exit $rc
  else
    echo "Success. Output:"
    sed 's/^/  /' /tmp/nmcli_test.out
  fi
}

main() {
  require_root
  ensure_user
  #install_tools
  write_sudoers_rule
  quick_tests
  echo "Done."
}

main "$@"
