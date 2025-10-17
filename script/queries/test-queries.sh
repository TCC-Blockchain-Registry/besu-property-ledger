#!/bin/bash

RPC_URL="http://127.0.0.1:8545"
PROPERTY_TITLE="0xd43f6E6A30d00d912791cC314971d2fb028f5AF9"
ADMIN="0x565524f400856766f11562832eb809d889491a01"

echo "=========================================="
echo "🔍 Testando Consultas RPC"
echo "=========================================="
echo ""

echo "1️⃣  Cliente Besu:"
curl -s -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' | jq -r '.result'
echo ""

echo "2️⃣  Último bloco:"
BLOCK=$(curl -s -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')
echo "Hex: $BLOCK"
echo "Decimal: $((16#${BLOCK:2}))"
echo ""

echo "3️⃣  Saldo do admin:"
BALANCE=$(curl -s -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$ADMIN\",\"latest\"],\"id\":1}" | jq -r '.result')
echo "Hex: $BALANCE"
echo "Wei: $((16#${BALANCE:2}))"
echo ""

echo "4️⃣  Nome do Token:"
cast call $PROPERTY_TITLE "name()" --rpc-url $RPC_URL
echo ""

echo "5️⃣  Símbolo do Token:"
cast call $PROPERTY_TITLE "symbol()" --rpc-url $RPC_URL
echo ""

echo "6️⃣  Decimals:"
cast call $PROPERTY_TITLE "decimals()" --rpc-url $RPC_URL
echo ""

echo "7️⃣  Total de tokens do admin:"
cast call $PROPERTY_TITLE "balanceOf(address)" $ADMIN --rpc-url $RPC_URL
echo ""

echo "8️⃣  Propriedades do admin:"
cast call $PROPERTY_TITLE "getPropertiesOf(address)" $ADMIN --rpc-url $RPC_URL
echo ""

echo "9️⃣  Token pausado?"
cast call $PROPERTY_TITLE "paused()" --rpc-url $RPC_URL
echo ""

echo "🔟  Admin congelado?"
cast call $PROPERTY_TITLE "isFrozen(address)" $ADMIN --rpc-url $RPC_URL
echo ""

echo "=========================================="
echo "✅ Testes concluídos!"
echo "=========================================="
