#!/bin/bash
#
# Setup Besu Network
# Inicializa a rede Besu PoA (4 validadores QBFT)
#

set -e  # Exit on error

echo "=================================================="
echo "🚀 Setup Besu Network (PoA - QBFT)"
echo "=================================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker não está rodando!${NC}"
    echo "Inicie o Docker e tente novamente."
    exit 1
fi

echo -e "${GREEN}✅ Docker está rodando${NC}"
echo ""

# Navegar para raiz do projeto
cd "$(dirname "$0")/../.."

# Navegar para diretório do Besu
cd docker/besu

echo "=================================================="
echo "📁 Verificando arquivos de rede..."
echo "=================================================="
echo ""

# Flag para rastrear se genesis foi regenerado
GENESIS_REGENERATED=false

# Verificar se network files já existem
if [ -d "network/files" ]; then
    echo -e "${YELLOW}⚠️  Network files já existem!${NC}"
    read -p "Deseja regenerar? Isso vai apagar a rede existente. (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removendo network files antigos..."
        rm -rf network/files
        rm -f network/genesis.json
        echo -e "${GREEN}✅ Removido${NC}"
        GENESIS_REGENERATED=true
    else
        echo "⏩ Mantendo network files existentes"
    fi
fi

# Gerar network files se não existirem
if [ ! -d "network/files" ]; then
    echo "=================================================="
    echo "🔧 Gerando network files (keys, genesis)..."
    echo "=================================================="
    echo ""
    
    ./generate.sh
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Network files gerados com sucesso!${NC}"
        
        # Corrigir chaves (Besu às vezes gera key como diretório)
        echo ""
        echo "🔧 Corrigindo configuração de chaves..."
        ./fix-keys.sh
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Erro ao corrigir chaves${NC}"
            exit 1
        fi
    else
        echo ""
        echo -e "${RED}❌ Erro ao gerar network files${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Network files já existem${NC}"
fi

echo ""
echo "=================================================="
echo "🐳 Iniciando containers Docker..."
echo "=================================================="
echo ""

# Verificar se containers já estão rodando
if docker compose ps | grep -q "Up"; then
    echo -e "${YELLOW}⚠️  Containers já estão rodando!${NC}"
    read -p "Deseja reiniciar? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 Reiniciando containers..."
        # Se genesis foi regenerado, limpar volumes também
        if [ "$GENESIS_REGENERATED" = true ]; then
            echo "   (Limpando volumes devido ao novo genesis)"
            docker compose down -v
        else
            docker compose down
        fi
        docker compose up -d
    else
        echo "⏩ Mantendo containers existentes"
    fi
else
    docker compose up -d
fi

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Containers iniciados com sucesso!${NC}"
else
    echo ""
    echo -e "${RED}❌ Erro ao iniciar containers${NC}"
    exit 1
fi

echo ""
echo "=================================================="
echo "⏳ Aguardando validadores iniciarem..."
echo "=================================================="
echo ""

# Aguardar 15 segundos para os validadores iniciarem
for i in {15..1}; do
    echo -ne "⏱️  Aguardando $i segundos...\r"
    sleep 1
done
echo ""

echo ""
echo "=================================================="
echo "🔍 Verificando status da rede..."
echo "=================================================="
echo ""

# Verificar RPC
echo "📡 Testando RPC endpoint..."
RPC_RESPONSE=$(curl -s http://127.0.0.1:8545 \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}')

if echo "$RPC_RESPONSE" | grep -q "besu"; then
    echo -e "${GREEN}✅ RPC endpoint respondendo!${NC}"
    echo "   Response: $RPC_RESPONSE"
else
    echo -e "${RED}❌ RPC endpoint não está respondendo${NC}"
    echo "   Response: $RPC_RESPONSE"
    echo ""
    echo "Verifique os logs:"
    echo "  docker compose logs validator1"
    exit 1
fi

echo ""
echo "📊 Status dos validadores:"
docker compose ps

echo ""
echo "=================================================="
echo -e "${GREEN}✅ Setup concluído com sucesso!${NC}"
echo "=================================================="
echo ""
echo "Informações da rede:"
echo "  • RPC URL: http://127.0.0.1:8545"
echo "  • Network ID: 1337"
echo "  • Consensus: QBFT (PoA)"
echo "  • Validators: 4"
echo "  • Gas Price: 0 (zero-gas enabled)"
echo ""
echo "Comandos úteis:"
echo "  • Ver logs:    docker compose logs -f validator1"
echo "  • Parar rede:  docker compose down"
echo "  • Status:      docker compose ps"
echo ""
echo "Próximo passo:"
echo "  Execute: ./script/setup/build-contracts.sh"
echo ""

