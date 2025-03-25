#!/bin/sh

echo "running script init-config"

echo "HOSTNAME: $HOSTNAME"

{{- if .Values.initChownData.freshInit }}
echo "Fresh init requested. Removing existing data directories and StateFiles"
rm -rf /data/network/$HOSTNAME
echo "Removed /data/network/$HOSTNAME"
rm -rf /data/stateFiles
echo "Removed /data/stateFiles"
{{- else }}
echo "Removing existing data directories"
rm -rf /data/network/$HOSTNAME
echo "Removed /data/network/$HOSTNAME"
{{- end }}


mkdir -p /data/network/$HOSTNAME
echo "Created /data/network/$HOSTNAME"
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

# Ensure Genesis Time is set to the current timestamp
GENESIS_TIME=$(date +%s)

# Run prysmctl to generate the genesis state
/usr/local/bin/prysmctl testnet generate-genesis \
    --num-validators=1 \
    --chain-config-file=/config/config.yml \
    --geth-genesis-json-in=/config/genesis.json \
    --output-ssz=/data/stateFiles/genesis.ssz \
    --geth-genesis-json-out=/data/stateFiles/genesis-out.json \
    --genesis-time="$GENESIS_TIME"

echo "Genesis state files created successfully."

# Check if jq is installed, if not install it dynamically
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

echo "jq successfully installed."

# Inject Cancun & Deneb activation parameters into genesis-out.json
echo "Injecting Cancun & Deneb parameters into genesis configuration..."

jq '.config.shanghaiTime = '"$GENESIS_TIME"' |
    .config.cancunTime = '"$GENESIS_TIME"' |
    .config.denebTime = '"$GENESIS_TIME"' |  # Ensures Deneb activates at Genesis
    .config.cancunBlock = 0 |
    .config.blobSchedule.cancun = 0 |
    .config.terminalTotalDifficulty = 1 |
    .config.terminalTotalDifficultyPassed = true' \
    /data/stateFiles/genesis-out.json > /data/stateFiles/genesis-final.json

# Replace the final genesis file
mv /data/stateFiles/genesis-final.json /data/stateFiles/genesis-out.json

echo "Cancun & Deneb parameters successfully injected into genesis-out.json."

# Initialize Geth with the updated genesis file
echo "Initializing Geth with the updated genesis..."
geth init --datadir /data/geth /data/stateFiles/genesis-out.json

echo "Geth initialized successfully with Deneb active."

else
  echo "Genesis state files already exist. Skipping creation."
fi

# Output a confirmation that the files are in place
ls -lrt /data/stateFiles/genesis.ssz /data/stateFiles/genesis-out.json

geth init --datadir=/data/network/$HOSTNAME /data/stateFiles/genesis-out.json

