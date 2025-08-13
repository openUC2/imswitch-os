#!/bin/bash
# This script adds a sudoers rule allowing the 'pi' user to run firewall-cmd without a password

# Ensure we are running as root
if [[ $EUID -ne 0 ]]; then
   echo "Please run this script as root: sudo $0"
   exit 1
fi

SUDOERS_FILE="/etc/sudoers.d/imswitch-firewall"

# Create the sudoers entry
cat << 'EOF' > "$SUDOERS_FILE"
# Allow pi user to run firewall-cmd without password for ImSwitch
pi ALL=(ALL) NOPASSWD: /usr/bin/firewall-cmd
EOF

# Set correct permissions
chmod 440 "$SUDOERS_FILE"

echo "Sudoers rule added for 'pi' to run /usr/bin/firewall-cmd without password."
