#!/bin/bash
#
# Setup All
# Executa setup completo: rede + build + deploy
#

set -e  # Exit on error

echo "=================================================="
echo "🚀 Setup Completo - Chain Real State"
echo "=================================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${BLUE}Este script vai executar:${NC}"
echo "  1️⃣  Setup da rede Besu (4 validadores PoA)"
echo "  2️⃣  Build dos contratos (Foundry)"
echo "  3️⃣  Deploy dos contratos na rede"
echo ""

read -p "Continuar? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Setup cancelado"
    exit 0
fi

echo ""
START_TIME=$(date +%s)

# ==========================================
# 1. Setup Network
# ==========================================

echo ""
echo "=================================================="
echo -e "${BLUE}[1/3] 🌐 Setup da Rede Besu${NC}"
echo "=================================================="
echo ""

"$SCRIPT_DIR/setup-network.sh"

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}❌ Erro no setup da rede!${NC}"
    exit 1
fi

# ==========================================
# 2. Build Contracts
# ==========================================

echo ""
echo "=================================================="
echo -e "${BLUE}[2/3] 🔨 Build dos Contratos${NC}"
echo "=================================================="
echo ""

"$SCRIPT_DIR/build-contracts.sh"

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}❌ Erro no build dos contratos!${NC}"
    exit 1
fi

# ==========================================
# 3. Deploy Contracts
# ==========================================

echo ""
echo "=================================================="
echo -e "${BLUE}[3/3] 🚀 Deploy dos Contratos${NC}"
echo "=================================================="
echo ""

"$SCRIPT_DIR/deploy-contracts.sh"

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}❌ Erro no deploy dos contratos!${NC}"
    exit 1
fi

# ==========================================
# Fim
# ==========================================

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo ""
echo "=================================================="
echo -e "${GREEN}✅ Setup Completo Concluído!${NC}"
echo "=================================================="
echo ""
echo "⏱️  Tempo total: ${MINUTES}m ${SECONDS}s"
echo ""

echo "📊 Status Final:"
echo ""

# Verificar containers
echo "🐳 Containers Docker:"
cd docker/besu
docker compose ps | grep -E "NAME|validator" || echo "  Nenhum container rodando"
cd ../..

echo ""

# Verificar RPC
echo "📡 RPC Endpoint:"
RPC_RESPONSE=$(curl -s http://127.0.0.1:8545 \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' 2>/dev/null || echo "")

if echo "$RPC_RESPONSE" | grep -q "besu"; then
    echo -e "  ${GREEN}✅ RPC respondendo em http://127.0.0.1:8545${NC}"
else
    echo -e "  ${RED}❌ RPC não está respondendo${NC}"
fi

echo ""

# Informações úteis
echo "=================================================="
echo "📋 Informações Úteis"
echo "=================================================="
echo ""

echo "Rede Besu:"
echo "  • RPC URL: http://127.0.0.1:8545"
echo "  • Network ID: 1337"
echo "  • Consensus: QBFT (PoA)"
echo "  • Validators: 4"
echo "  • Gas Price: 0"
echo ""

echo "Contratos Deployados:"
echo "  • PropertyTitleTREX (Token Principal)"
echo "  • ApprovalsModule"
echo "  • RegistryMDCompliance"
echo "  • ModularCompliance"
echo "  • IdentityRegistry"
echo "  • + Outros contratos T-REX"
echo ""

echo "Endereços dos Contratos:"
echo "  📁 Verifique: broadcast/*/run-latest.json"
echo ""

echo "Próximos Passos:"
echo "  1. Consulte: docs/guias/FLUXO_COMPLETO.md"
echo "  2. Interaja com contratos usando cast ou frontend"
echo "  3. Veja exemplos de comandos no guia"
echo ""

echo "Comandos Úteis:"
echo "  • Ver logs:      cd docker/besu && docker compose logs -f validator1"
echo "  • Parar rede:    ./scripts/teardown-network.sh"
echo "  • Reset total:   ./scripts/teardown-network.sh --all"
echo ""

echo -e "${GREEN}🎉 Sistema pronto para uso!${NC}"
echo ""

