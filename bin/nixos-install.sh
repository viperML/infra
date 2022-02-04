#!/usr/bin/env bash
set -eux -o pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root for mount permissions!"
    exit 0
fi

nix-shell --packages nixFlakes --packages git --run "nixos-install --root /mnt --flake .#cloud"
