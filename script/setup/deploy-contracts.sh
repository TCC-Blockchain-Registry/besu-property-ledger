#!/bin/bash
#
# Deploy Smart Contracts
# Faz deploy de todos os contratos na rede Besu local
#

set -e  # Exit on error

echo "=================================================="
echo "🚀 Deploy Smart Contracts"
echo "=================================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navegar para raiz do projeto
cd "$(dirname "$0")/../.."

echo -e "${GREEN}📂 Diretório do projeto:${NC} $(pwd)"
echo ""

# Configurações
RPC_URL="http://52.67.12.10:8545"
PRIVATE_KEY="0x51eba47406fcb3dfa80e9ff02c1a8efe1aa1552bf016e09d454e6a7502ef0c24"
DEPLOY_SCRIPT="script/DeployPropertyTitleTREX.s.sol:DeployPropertyTitleTREXScript"

# Verificar se RPC está respondendo
echo "=================================================="
echo "🔍 Verificando conexão com a rede..."
echo "=================================================="
echo ""

echo "📡 RPC URL: $RPC_URL"

RPC_RESPONSE=$(curl -s "$RPC_URL" \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' || echo "")

if echo "$RPC_RESPONSE" | grep -q "besu"; then
    echo -e "${GREEN}✅ RPC endpoint respondendo!${NC}"
    CLIENT_VERSION=$(echo "$RPC_RESPONSE" | jq -r '.result' 2>/dev/null || echo "unknown")
    echo "   Cliente: $CLIENT_VERSION"
else
    echo -e "${RED}❌ RPC endpoint não está respondendo!${NC}"
    echo ""
    echo "Certifique-se de que a rede Besu está rodando:"
    echo "  ./scripts/setup-network.sh"
    exit 1
fi

echo ""

# Verificar saldo da conta
echo "=================================================="
echo "💰 Verificando saldo da conta..."
echo "=================================================="
echo ""

# Extrair endereço da private key
ADDRESS=$(cast wallet address "$PRIVATE_KEY" 2>/dev/null || echo "")

if [ -z "$ADDRESS" ]; then
    echo -e "${RED}❌ Erro ao obter endereço da private key${NC}"
    exit 1
fi

echo "📬 Endereço: $ADDRESS"

BALANCE=$(cast balance "$ADDRESS" --rpc-url "$RPC_URL" 2>/dev/null || echo "0")
BALANCE_ETH=$(cast --to-unit "$BALANCE" ether 2>/dev/null || echo "0")

echo "💵 Saldo: $BALANCE_ETH ETH"

if [ "$BALANCE" == "0" ]; then
    echo -e "${RED}⚠️  Saldo zero! A conta pode precisar de fundos.${NC}"
    echo "   (Gas price está em 0, então pode funcionar mesmo assim)"
fi

echo ""

# Verificar se contratos foram compilados
echo "=================================================="
echo "📦 Verificando compilação..."
echo "=================================================="
echo ""

if [ ! -d "out" ]; then
    echo -e "${YELLOW}⚠️  Contratos não compilados. Compilando...${NC}"
    ./script/setup/build-contracts.sh
    echo ""
else
    echo -e "${GREEN}✅ Contratos já compilados${NC}"
fi

echo ""

# Deploy
echo "=================================================="
echo "🚀 Iniciando deploy..."
echo "=================================================="
echo ""

echo "Deploy script: $DEPLOY_SCRIPT"
echo "RPC URL: $RPC_URL"
echo "Gas Price: Auto (determinado pela rede)"
echo ""

read -p "Confirma o deploy? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deploy cancelado"
    exit 0
fi

echo ""
echo "⏳ Executando deploy (isso pode levar alguns minutos)..."
echo ""

# Executar deploy com output detalhado
forge script "$DEPLOY_SCRIPT" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  -vvv

if [ $? -eq 0 ]; then
    echo ""
    echo "=================================================="
    echo -e "${GREEN}✅ Deploy concluído com sucesso!${NC}"
    echo "=================================================="
    echo ""
    
    # Tentar extrair endereços dos logs
    echo "📋 Endereços dos contratos deployados:"
    echo ""
    
    if [ -d "broadcast" ]; then
        LATEST_RUN=$(find broadcast -name "run-latest.json" | head -n 1)
        if [ -f "$LATEST_RUN" ] && command -v jq &> /dev/null; then
            echo "   (Verifique o arquivo de broadcast para endereços completos)"
            echo "   Arquivo: $LATEST_RUN"
        else
            echo "   ⚠️  Arquivo de broadcast não encontrado ou jq não instalado"
        fi
    fi
    
    echo ""
    echo "Contratos deployados:"
    echo "  ✅ ClaimTopicsRegistry"
    echo "  ✅ TrustedIssuersRegistry"
    echo "  ✅ IdentityRegistryStorage"
    echo "  ✅ IdentityRegistry"
    echo "  ✅ ModularCompliance"
    echo "  ✅ ApprovalsModule"
    echo "  ✅ RegistryMDCompliance"
    echo "  ✅ PropertyTitleTREX (Token Principal)"
    echo ""
    
    echo "=================================================="
    echo "📁 Arquivos gerados:"
    echo "=================================================="
    echo ""
    echo "  • broadcast/ - Logs e endereços dos contratos"
    echo "  • out/ - Artifacts compilados"
    echo ""
    
    echo "Próximos passos:"
    echo "  1. Verifique os endereços em broadcast/*/run-latest.json"
    echo "  2. Interaja com os contratos usando cast ou frontend"
    echo "  3. Consulte docs/guias/FLUXO_COMPLETO.md para exemplos"
    echo ""
else
    echo ""
    echo "=================================================="
    echo -e "${RED}❌ Erro no deploy${NC}"
    echo "=================================================="
    echo ""
    echo "Possíveis causas:"
    echo "  • Rede não está rodando"
    echo "  • Problemas de compilação"
    echo "  • Erro nos contratos"
    echo ""
    echo "Verifique os logs acima para mais detalhes."
    exit 1
fi

