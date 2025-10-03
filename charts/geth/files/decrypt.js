const keythereum = require('keythereum');
const fs = require('fs');

// Use CLI args for input
const KEYSTORE = process.argv[2];
const PASSWORD_FILE = process.argv[3];

const password = new TextEncoder().encode(
    fs.readFileSync(PASSWORD_FILE, { encoding: 'utf8' }).trim()
);

// Read and parse keystore file
const keystore = JSON.parse(fs.readFileSync(KEYSTORE, { encoding: "utf8" }));

// Convert `salt` and `iv` to Buffers
keystore.crypto.kdfparams.salt = Buffer.from(keystore.crypto.kdfparams.salt, 'hex');
keystore.crypto.cipherparams.iv = Buffer.from(keystore.crypto.cipherparams.iv, 'hex');

try {
    const privateKey = keythereum.recover(password, keystore);
    console.log(`✅ Address:     0x${keystore.address}`);
    console.log(`🔐 Private Key: 0x${privateKey.toString("hex")}`);
} catch (error) {
    console.error("❌ Failed to decrypt private key:", error);
}
