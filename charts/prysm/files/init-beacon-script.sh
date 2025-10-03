#!/bin/sh

echo "running script init-beacon-script"

echo "HOSTNAME: $HOSTNAME"
echo "Everything in /shared-data"
ls -lrt /shared-data

if [ ! -f /shared-data/genesis.ssz ]; then
  echo "No genesis.ssz found – running full setup"

  rm -rf /shared-data/*
  rm -rf /shared-data/.* 2>/dev/null
  echo "Copy over the original config files"
  cp /config/geth_password.txt /shared-data/geth_password.txt

  echo "setting up shared-data to be a fresh pair of config and states"

  /usr/local/bin/prysmctl testnet \
        generate-genesis \
        --fork=deneb \
        --num-validators=64 \
        --output-ssz=/shared-data/genesis.ssz \
        --chain-config-file=/config/config.yml \
        --geth-genesis-json-in=/config/genesis.json \
        --geth-genesis-json-out=/shared-data/genesis.json

  echo "Genesis state files created successfully."

  ls -lrt /shared-data

fi

ls -lrt /config

rm -rf /data/beacon/$HOSTNAME