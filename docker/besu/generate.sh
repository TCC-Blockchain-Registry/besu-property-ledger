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
echo "Generated network files in $FILES_DIR and genesis at $OUT_DIR/genesis.json"


