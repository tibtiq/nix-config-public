#!/bin/sh
set -e

NIX_CONFIG_PATH='/etc/nixos/configuration.nix'

# Download config
curl --show-error --fail \
  https://raw.githubusercontent.com/tibtiq/nix-config-public/refs/heads/main/proxmox_lxc_config.nix \
  >"$NIX_CONFIG_PATH"

# Add SSH keys from GitHub
GITHUB_USERNAME='tibtiq'
SSH_KEYS=$(curl -s "https://github.com/${GITHUB_USERNAME}.keys" | sed 's/.*/        "&"/')

# Replace the "SSH_KEYS" line with the actual keys
# We write a temporary file to insert cleanly
TMPFILE=$(mktemp)

# Copy everything up to the match
awk '/"SSH_KEYS"/ { exit } { print }' "$NIX_CONFIG_PATH" >"$TMPFILE"
# Add the SSH keys
printf "%s\n" "$SSH_KEYS" >>"$TMPFILE"
# Copy everything after the match
awk '/"SSH_KEYS"/ { found=1; next } found { print }' "$NIX_CONFIG_PATH" >>"$TMPFILE"

# Move back
mv "$TMPFILE" "$NIX_CONFIG_PATH"

# Prompt user for rebuild
printf "Do you want to rebuild Nix? (y/N): "
read -r answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
  sudo nix-channel --update && sudo nixos-rebuild switch --upgrade
fi
