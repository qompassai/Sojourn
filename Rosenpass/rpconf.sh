#!/bin/bash

# Get the system's hostname
HOSTNAME=$(hostname)

# For IP address instead of hostname (uncomment if preferred):
# HOST=$(hostname -I | awk '{print $1}')

cat <<EOF > qompass.yml
public_key = "rp-public-key"
secret_key = "rp-secret-key"
listen = []
verbosity = "Quiet"

[[peers]]
public_key = "rp-peer-public-key"
endpoint = "${HOSTNAME}:9999"  # Dynamic hostname:port
key_out = "rp-key-out"
exchange_command = [
    "wg",
    "set",
    "wg0",
    "peer",
    "<PEER_ID>",
    "preshared-key",
    "/dev/stdin",
]
EOF

