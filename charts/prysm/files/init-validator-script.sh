#!/bin/sh

echo "running script init-validator-script"

echo "HOSTNAME: $HOSTNAME"



# Clean validator data directory
echo "Cleaning existing validator DB..."
rm -rf /data/validator/*
rm -rf /data/validator_keys/*
mkdir -p /data/validator_keys
cp -L /config/keystore-m_1.json /data/validator_keys/.
cp -L /config/password.txt /data/validator_keys/.

ls -lrt /data/validator_keys
cat /data/validator_keys/keystore-m_1.json


# Using interlop mode , so runnign the valdiator with interlop num validators rather than a key store
#echo "Downloading Prysm Validator binary..."
#curl -L https://github.com/prysmaticlabs/prysm/releases/download/v5.3.0/validator-v5.3.0-linux-amd64 \
#     -o /usr/local/bin/validator
#chmod +x /usr/local/bin/validator
#chmod 644 /data/validator_keys/password.txt

# Import validator keys freshly
#echo "Importing validator keys..."
#/usr/local/bin/validator accounts import \
#  --keys-dir=/data/validator_keys \
#  --wallet-dir=/data \
#  --wallet-password-file=/data/validator_keys/password.txt \
#  --accept-terms-of-use < /dev/null

echo "Validator keys imported successfully."

