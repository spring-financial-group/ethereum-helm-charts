#!/bin/sh

echo "Everything in /shared-data"
ls -lrt /shared-data

if [ ! -f /shared-data/genesis.ssz ]; then
  echo "No genesis.ssz found – running full setup"

  rm -rf /shared-data/*
  rm -rf /shared-data/.* 2>/dev/null
  echo "Copy over the original config files"
  cp /config/geth_password.txt /shared-data/geth_password.txt

  # Create some pre funded accounts , at the moment there is only one account pre funded in the genesis and one with Smart Contracts deployed to to run the chain
  CONFIG_GENESIS=/config/genesis.json
  TMP_ALLOC="./alloc.patch.json"
  BALANCE_HEX="0x2863c1f5cdae42f9540000000"
  ACCOUNTS_DIR=/shared-data/accounts
  PASSWORD_FILE="./password.txt"
  NUM_ACCOUNTS=5
  rm -rf $ACCOUNTS_DIR
  mkdir -p "$ACCOUNTS_DIR"
  echo "" > "$PASSWORD_FILE"
  rm -f "$TMP_ALLOC"

  echo "🔐 Generating $NUM_ACCOUNTS new accounts..."

  # Start JSON object for alloc patch
  echo "{" > "$TMP_ALLOC"

  for i in $(seq 1 "$NUM_ACCOUNTS"); do
    geth account new --datadir "$ACCOUNTS_DIR" --password "$PASSWORD_FILE" > /dev/null

    echo "Accounts dir content"
    ls -l $ACCOUNTS_DIR/keystore

    KEYSTORE_FILE=$(ls -t "$ACCOUNTS_DIR/keystore"/* 2>/dev/null | head -n 1)
    if [ ! -f "$KEYSTORE_FILE" ]; then
      echo "❌ No valid keystore file found in $ACCOUNTS_DIR/keystore"
      ls -l "$ACCOUNTS_DIR/keystore"
      exit 1
    fi

    ADDRESS=$(basename "$KEYSTORE_FILE" | awk -F'--' '{print $3}' | tr '[:upper:]' '[:lower:]')

    if [ -z "$ADDRESS" ]; then
      echo "❌ Failed to extract address from geth output:"
      echo "$ACCOUNT_OUTPUT"
      exit 1
    fi

    export NODE_PATH=/usr/lib/node_modules

    node /config/decrypt.js "$KEYSTORE_FILE" "$PASSWORD_FILE"

    echo "  - Injecting 0x$ADDRESS with balance $BALANCE_HEX"

    # Append to alloc patch file
    echo "  \"0x$ADDRESS\": { \"balance\": \"$BALANCE_HEX\" }" >> "$TMP_ALLOC"

    # Add comma unless last item
    if [ "$i" -lt "$NUM_ACCOUNTS" ]; then
      echo "," >> "$TMP_ALLOC"
    fi
  done

  echo "}" >> "$TMP_ALLOC"

  # === Patch genesis.json ===
  PATCHED_GENESIS="/tmp/genesis.patched.json"
  jq ".alloc += $(cat "$TMP_ALLOC")" "$CONFIG_GENESIS" > "$PATCHED_GENESIS"
  echo "✅ Updated $PATCHED_GENESIS with $NUM_ACCOUNTS funded accounts."
  cat "$PATCHED_GENESIS"

  echo "setting up shared-data to be a fresh pair of config and states"

  /usr/local/bin/prysmctl testnet \
        generate-genesis \
        --fork=deneb \
        --num-validators=64 \
        --output-ssz=/shared-data/genesis.ssz \
        --chain-config-file=/config/config.yml \
        --geth-genesis-json-in=$PATCHED_GENESIS \
        --geth-genesis-json-out=/shared-data/genesis.json

  echo "Genesis state files created successfully."

  ls -lrt /shared-data

fi

ls -lrt /config

# Clear the data directory (DB down) if it's been a complete state gen then this will have happened anyway
rm -rf /data/geth/$HOSTNAME

echo "Initializing Geth with the updated genesis..."
geth init --datadir /data/geth/$HOSTNAME /shared-data/genesis.json
cp /config/UTC* /data/geth/$HOSTNAME/keystore/.
echo "Geth initialized successfully with Deneb active."
