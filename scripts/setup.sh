#!/bin/sh
NIX_CONFIG_PATH='/etc/nixos/configuration.nix'

# download config
curl \
  --show-error \
  --fail \
  https://raw.githubusercontent.com/tibtiq/nix-config-public/refs/heads/main/proxmox_lxc_config.nix \
  >${NIX_CONFIG_PATH}

# add ssh keys from github
GITHUB_USERNAME='tibtiq'
SSH_KEYS=$(curl -s https://github.com/${GITHUB_USERNAME}.keys | sed 's/.*/        "&",/')
sed -i '/"SSH_KEYS"/{
    r /dev/stdin
    d
}' ${NIX_CONFIG_PATH} <<EOF
"$SSH_KEYS"
EOF
# fix issues with previous sed
sed -i 's/\"        \"/        \"/' ${NIX_CONFIG_PATH}
sed -i 's/\",\"/\",/' ${NIX_CONFIG_PATH}

printf "Do you want to rebuild nix? (y/N): "
read -r answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
  sudo nix-channel --update && sudo nixos-rebuild switch --upgrade
fi
