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



echo "Genesis state files not found. Creating..."

echo "Downloading prysmctl..."
curl -L https://github.com/prysmaticlabs/prysm/releases/download/v5.3.0/prysmctl-v5.3.0-linux-amd64 -o /usr/local/bin/prysmctl
chmod +x /usr/local/bin/prysmctl

# Check if prysmctl is executable
ls -lrt /usr/local/bin/prysmctl

echo "Creating the genesis state using the provided genesis.json and config.yml..."

cp /config/genesis.json /data/stateFiles/genesis-tmp.json

if ! command -v jq >/dev/null; then
    echo "jq not found, installing jq dynamically..."
    if command -v apk >/dev/null; then
        apk update && apk add --no-cache jq
    elif command -v apt-get >/dev/null; then
        apt-get update && apt-get install -y jq
    elif command -v yum >/dev/null; then
        yum install -y jq
    else
        echo "No known package manager found to install jq, aborting."
        exit 1
    fi
fi

GENESIS_TIME=$(($(date +%s) - 10))

jq '.config.shanghaiTime = '"$GENESIS_TIME"' |
    .config.cancunTime = '"$GENESIS_TIME"' |
    .config.denebTime = '"$GENESIS_TIME"' |  # Ensures Deneb activates at Genesis
    .config.cancunBlock = 0 |
    .config.blobSchedule.cancun = 0 |
    .config.terminalTotalDifficulty = 1 |
    .config.terminalTotalDifficultyPassed = true' \
    /data/stateFiles/genesis-tmp.json > /data/stateFiles/genesis-final.json


echo "Cancun & Deneb parameters successfully injected into genesis-out.json."

# Run prysmctl to generate the genesis state
/usr/local/bin/prysmctl testnet generate-genesis \
  --num-validators=1 \
  --chain-config-file=/config/config.yml \
  --geth-genesis-json-in=/data/stateFiles/genesis-final.json \
  --output-ssz=/data/stateFiles/genesis.ssz \
  --geth-genesis-json-out=/data/stateFiles/genesis-out.json \
  --genesis-time="$GENESIS_TIME"

#  --override-eth1data \
#  --execution-endpoint=http://geth-node:8545

#    --deposit-json-file=./config/deposit_data-1.json \

echo "Explicitly checking generated files and keys:"
ls -lrt /data/stateFiles
ls -lrt /config

echo "Genesis state files created successfully."


