#!/bin/bash
#
# Grant Institutional Roles
# Concede as roles institucionais (Financial, Registry Office, Municipality)
# para endereços específicos no contrato PropertyTitleTREX
#

set -e  # Exit on error

echo "=========================================================="
echo "🔐 Grant Institutional Roles to PropertyTitleTREX"
echo "=========================================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Navegar para raiz do projeto
cd "$(dirname "$0")/../.."

echo -e "${GREEN}📂 Diretório do projeto:${NC} $(pwd)"
echo ""

# Configurações
RPC_URL="${RPC_URL:-http://localhost:8545}"
PRIVATE_KEY="${PRIVATE_KEY:-0x51eba47406fcb3dfa80e9ff02c1a8efe1aa1552bf016e09d454e6a7502ef0c24}"
DEPLOYED_ADDRESSES_FILE="deployed-addresses.txt"

# Verificar se arquivo de endereços existe
if [ ! -f "$DEPLOYED_ADDRESSES_FILE" ]; then
    echo -e "${RED}❌ Arquivo $DEPLOYED_ADDRESSES_FILE não encontrado!${NC}"
    echo ""
    echo "Execute o deploy primeiro:"
    echo "  ./script/setup/deploy-contracts.sh"
    exit 1
fi

# Extrair endereço do PropertyTitleTREX
TOKEN_ADDRESS=$(grep "PropertyTitleTREX=" "$DEPLOYED_ADDRESSES_FILE" | cut -d'=' -f2)

if [ -z "$TOKEN_ADDRESS" ]; then
    echo -e "${RED}❌ Endereço do PropertyTitleTREX não encontrado em $DEPLOYED_ADDRESSES_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}📄 Contrato PropertyTitleTREX:${NC} $TOKEN_ADDRESS"
echo ""

# Verificar RPC
echo "=========================================================="
echo "🔍 Verificando conexão com a rede..."
echo "=========================================================="
echo ""

RPC_RESPONSE=$(curl -s "$RPC_URL" \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' || echo "")

if echo "$RPC_RESPONSE" | grep -q "besu"; then
    echo -e "${GREEN}✅ RPC endpoint respondendo!${NC}"
else
    echo -e "${RED}❌ RPC endpoint não está respondendo!${NC}"
    echo "   RPC URL: $RPC_URL"
    exit 1
fi

echo ""

# Extrair endereço do admin (da private key)
ADMIN_ADDRESS=$(cast wallet address "$PRIVATE_KEY" 2>/dev/null || echo "")

if [ -z "$ADMIN_ADDRESS" ]; then
    echo -e "${RED}❌ Erro ao obter endereço da private key${NC}"
    exit 1
fi

echo -e "${BLUE}👤 Admin Address:${NC} $ADMIN_ADDRESS"
echo ""

# Parâmetros de role
# Pode passar endereços específicos como argumentos, senão usa o admin para todos
FINANCIAL_ADDRESS="${1:-$ADMIN_ADDRESS}"
REGISTRY_OFFICE_ADDRESS="${2:-$ADMIN_ADDRESS}"
MUNICIPALITY_ADDRESS="${3:-$ADMIN_ADDRESS}"

echo "=========================================================="
echo "📋 Roles a serem concedidas:"
echo "=========================================================="
echo ""
echo -e "${YELLOW}FINANCIAL_ROLE${NC}         → $FINANCIAL_ADDRESS"
echo -e "${YELLOW}REGISTRY_OFFICE_ROLE${NC}   → $REGISTRY_OFFICE_ADDRESS"
echo -e "${YELLOW}MUNICIPALITY_ROLE${NC}      → $MUNICIPALITY_ADDRESS"
echo ""

# Calcular hashes das roles
FINANCIAL_ROLE=$(cast keccak "FINANCIAL_ROLE")
REGISTRY_OFFICE_ROLE=$(cast keccak "REGISTRY_OFFICE_ROLE")
MUNICIPALITY_ROLE=$(cast keccak "MUNICIPALITY_ROLE")

echo "Role hashes:"
echo "  FINANCIAL_ROLE:       $FINANCIAL_ROLE"
echo "  REGISTRY_OFFICE_ROLE: $REGISTRY_OFFICE_ROLE"
echo "  MUNICIPALITY_ROLE:    $MUNICIPALITY_ROLE"
echo ""

# Confirmação
read -p "Confirma a concessão das roles? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operação cancelada"
    exit 0
fi

echo ""
echo "=========================================================="
echo "⏳ Concedendo roles..."
echo "=========================================================="
echo ""

# Função para conceder role
grant_role() {
    local ROLE_NAME=$1
    local ROLE_HASH=$2
    local TARGET_ADDRESS=$3

    echo -e "${BLUE}Concedendo $ROLE_NAME para $TARGET_ADDRESS...${NC}"

    # Verificar se já tem a role
    HAS_ROLE=$(cast call "$TOKEN_ADDRESS" \
        "hasRole(bytes32,address)(bool)" \
        "$ROLE_HASH" \
        "$TARGET_ADDRESS" \
        --rpc-url "$RPC_URL" 2>/dev/null || echo "false")

    if [ "$HAS_ROLE" == "true" ]; then
        echo -e "${YELLOW}⚠️  $TARGET_ADDRESS já possui $ROLE_NAME${NC}"
        echo ""
        return 0
    fi

    # Conceder role
    TX_HASH=$(cast send "$TOKEN_ADDRESS" \
        "grantRole(bytes32,address)" \
        "$ROLE_HASH" \
        "$TARGET_ADDRESS" \
        --private-key "$PRIVATE_KEY" \
        --rpc-url "$RPC_URL" \
        --gas-limit 100000 \
        --gas-price 1000 \
        2>&1 | grep "transactionHash" | awk '{print $2}')

    if [ -n "$TX_HASH" ]; then
        echo -e "${GREEN}✅ Role concedida com sucesso!${NC}"
        echo "   Transaction: $TX_HASH"
    else
        echo -e "${RED}❌ Erro ao conceder role${NC}"
        return 1
    fi

    echo ""
}

# Conceder cada role
grant_role "FINANCIAL_ROLE" "$FINANCIAL_ROLE" "$FINANCIAL_ADDRESS"
grant_role "REGISTRY_OFFICE_ROLE" "$REGISTRY_OFFICE_ROLE" "$REGISTRY_OFFICE_ADDRESS"
grant_role "MUNICIPALITY_ROLE" "$MUNICIPALITY_ROLE" "$MUNICIPALITY_ADDRESS"

echo "=========================================================="
echo -e "${GREEN}✅ Todas as roles concedidas com sucesso!${NC}"
echo "=========================================================="
echo ""

# Verificar roles finais
echo "🔍 Verificando roles concedidas..."
echo ""

verify_role() {
    local ROLE_NAME=$1
    local ROLE_HASH=$2
    local TARGET_ADDRESS=$3

    HAS_ROLE=$(cast call "$TOKEN_ADDRESS" \
        "hasRole(bytes32,address)(bool)" \
        "$ROLE_HASH" \
        "$TARGET_ADDRESS" \
        --rpc-url "$RPC_URL" 2>/dev/null || echo "false")

    if [ "$HAS_ROLE" == "true" ]; then
        echo -e "${GREEN}✅${NC} $ROLE_NAME: $TARGET_ADDRESS"
    else
        echo -e "${RED}❌${NC} $ROLE_NAME: $TARGET_ADDRESS"
    fi
}

verify_role "FINANCIAL_ROLE" "$FINANCIAL_ROLE" "$FINANCIAL_ADDRESS"
verify_role "REGISTRY_OFFICE_ROLE" "$REGISTRY_OFFICE_ROLE" "$REGISTRY_OFFICE_ADDRESS"
verify_role "MUNICIPALITY_ROLE" "$MUNICIPALITY_ROLE" "$MUNICIPALITY_ADDRESS"

echo ""
echo "=========================================================="
echo "📖 Uso:"
echo "=========================================================="
echo ""
echo "Para conceder roles para endereços diferentes:"
echo "  ./script/setup/grant-institutional-roles.sh \\"
echo "    <FINANCIAL_ADDRESS> \\"
echo "    <REGISTRY_OFFICE_ADDRESS> \\"
echo "    <MUNICIPALITY_ADDRESS>"
echo ""
echo "Exemplo:"
echo "  ./script/setup/grant-institutional-roles.sh \\"
echo "    0x1234...abcd \\"
echo "    0x5678...efgh \\"
echo "    0x9012...ijkl"
echo ""
