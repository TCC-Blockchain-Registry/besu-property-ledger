#!/usr/bin/env bash
set -euo pipefail

# Requires: besu installed locally
# Generates QBFT network files under ./network/files and genesis.json under ./network

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
OUT_DIR="$SCRIPT_DIR/network"
FILES_DIR="$OUT_DIR/files"
mkdir -p "$FILES_DIR"

# Use Besu Docker image to generate QBFT config to avoid local besu dependency
docker run --rm \
  -v "$SCRIPT_DIR":/work \
  -w /work \
  hyperledger/besu:23.10.2 \
  operator generate-blockchain-config \
  --config-file=/work/operator/qbftConfig.json \
  --to=/work/network/files \
  --private-key-file-name=key \
  --public-key-file-name=key.pub \
  --genesis-file-name=genesis.json

cp "$FILES_DIR"/genesis.json "$OUT_DIR"/genesis.json

# Adicionar conta pré-financiada ao genesis (necessário para deploys)
echo "Adding pre-funded account to genesis..."
DEPLOYER_ADDRESS="0x565524f400856766f11562832eB809d889491a01"
BALANCE="0x200000000000000000000000000000000000000000000000000000000000000"

# Usar jq se disponível, senão usar sed
if command -v jq &> /dev/null; then
    # Backup do genesis original
    cp "$OUT_DIR/genesis.json" "$OUT_DIR/genesis.json.bak"
    
    # Adicionar alloc com jq
    jq --arg addr "$DEPLOYER_ADDRESS" --arg bal "$BALANCE" \
       '.alloc = {($addr): {"balance": $bal}}' \
       "$OUT_DIR/genesis.json.bak" > "$OUT_DIR/genesis.json"
    
    rm "$OUT_DIR/genesis.json.bak"
    echo "✅ Pre-funded account added: $DEPLOYER_ADDRESS"
else
    # Fallback: usar sed (menos confiável mas funciona)
    sed -i.bak 's/\(.*"extraData".*\)/\1,\n  "alloc" : {\n    "'"$DEPLOYER_ADDRESS"'" : {\n      "balance" : "'"$BALANCE"'"\n    }\n  }/' "$OUT_DIR/genesis.json"
    rm "$OUT_DIR/genesis.json.bak"
    echo "✅ Pre-funded account added (via sed): $DEPLOYER_ADDRESS"
fi

echo "Generated network files in $FILES_DIR and genesis at $OUT_DIR/genesis.json"


