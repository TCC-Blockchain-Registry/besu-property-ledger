#!/bin/bash

RPC_URL="http://127.0.0.1:8545"
PROPERTY_TITLE="0xd43f6E6A30d00d912791cC314971d2fb028f5AF9"
ADMIN="0x565524f400856766f11562832eb809d889491a01"

echo "=========================================="
echo "🔍 Testando Consultas RPC (cURL puro)"
echo "=========================================="
echo ""

echo "1️⃣  Cliente Besu:"
curl -s -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}'
echo -e "\n"

echo "2️⃣  Último bloco:"
curl -s -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
echo -e "\n"

echo "3️⃣  Código do contrato PropertyTitle (primeiros 20 chars):"
curl -s -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$PROPERTY_TITLE\",\"latest\"],\"id\":1}" | grep -o '"result":"0x[0-9a-f]*"' | cut -c1-40
echo -e "\n"

echo "4️⃣  Nome do token (name() = 0x06fdde03):"
curl -s -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$PROPERTY_TITLE\",\"data\":\"0x06fdde03\"},\"latest\"],\"id\":1}"
echo -e "\n"

echo "5️⃣  Símbolo do token (symbol() = 0x95d89b41):"
curl -s -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$PROPERTY_TITLE\",\"data\":\"0x95d89b41\"},\"latest\"],\"id\":1}"
echo -e "\n"

echo "6️⃣  Decimals (decimals() = 0x313ce567):"
curl -s -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$PROPERTY_TITLE\",\"data\":\"0x313ce567\"},\"latest\"],\"id\":1}"
echo -e "\n"

echo "7️⃣  Balance do admin (balanceOf() = 0x70a08231 + address):"
# Remover 0x do endereço e pad para 32 bytes
ADMIN_PADDED=$(echo $ADMIN | sed 's/0x//' | awk '{printf "000000000000000000000000%s", $0}')
curl -s -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$PROPERTY_TITLE\",\"data\":\"0x70a08231$ADMIN_PADDED\"},\"latest\"],\"id\":1}"
echo -e "\n"

echo "8️⃣  Token pausado? (paused() = 0x5c975abb):"
curl -s -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$PROPERTY_TITLE\",\"data\":\"0x5c975abb\"},\"latest\"],\"id\":1}"
echo -e "\n"

echo "=========================================="
echo "✅ Testes concluídos!"
echo "=========================================="
echo ""
echo "💡 Dica: Use 'cast --to-ascii <HEX>' para decodificar strings"
echo "💡 Exemplo: cast --to-ascii 0x0000002000...0a"
