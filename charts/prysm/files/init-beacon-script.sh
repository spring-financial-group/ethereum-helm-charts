#!/bin/sh

echo "running script init-beacon-config"

echo "HOSTNAME: $HOSTNAME"


{{- if .Values.initChownData.freshInit }}
echo "Fresh init requested. Removing existing data directories and StateFiles"
rm -rf /data/network/beacon/$HOSTNAME
mkdir -p /data/network/beacon/$HOSTNAME
rm -rf /data/stateFiles
echo "Removed /data/stateFiles"
{{- else }}
echo "Removing existing data directories"
rm -rf /data/network/beacon/$HOSTNAME
mkdir -p /data/network/beacon/$HOSTNAME
{{- end }}

mkdir -p /data/network/beacon/$HOSTNAME
echo "Created /data/network/beacon/$HOSTNAME"
mkdir -p /data/stateFiles
echo "Created /data/stateFiles"


ls -lrt /data


# Create the genesis state only if it doesn't already exist
if [ ! -f /data/stateFiles/genesis.ssz ] || [ ! -f /data/stateFiles/genesis-out.json ]; then

  echo "Genesis state files not found. Creating..."

  echo "Downloading prysmctl..."
  curl -L https://github.com/prysmaticlabs/prysm/releases/download/v5.3.0/prysmctl-v5.3.0-linux-amd64 -o /usr/local/bin/prysmctl
  chmod +x /usr/local/bin/prysmctl

  # Check if prysmctl is executable
  ls -lrt /usr/local/bin/prysmctl

  echo "Creating the genesis state using the provided genesis.json and config.yml..."

  GENESIS_TIME=$(($(date +%s) + 600))

  # Run prysmctl to generate the genesis state
  /usr/local/bin/prysmctl testnet generate-genesis \
    --num-validators=0 \
    --chain-config-file=/config/config.yml \
    --geth-genesis-json-in=/config/genesis.json \
    --output-ssz=/data/stateFiles/genesis.ssz \
    --geth-genesis-json-out=/data/stateFiles/genesis-out.json \
    --deposit-json-file=./config/deposit_data-1.json \
    --genesis-time="$GENESIS_TIME" \
    --override-eth1data \
    --execution-endpoint=http://geth-node:8545

  echo "Explicitly checking generated files and keys:"
  ls -lrt /data/stateFiles
  ls -lrt /config

  echo "Genesis state files created successfully."

else
  echo "Genesis state files already exist. Skipping creation."
fi

