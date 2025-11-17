#!/bin/bash
#
# Build Smart Contracts
# Compila todos os contratos Solidity usando Foundry
#

set -e  # Exit on error

echo "=================================================="
echo "🔨 Build Smart Contracts"
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

# Verificar se Foundry está instalado
if ! command -v forge &> /dev/null; then
    echo -e "${RED}❌ Foundry não está instalado!${NC}"
    echo ""
    echo "Instale o Foundry:"
    echo "  curl -L https://foundry.paradigm.xyz | bash"
    echo "  foundryup"
    exit 1
fi

echo -e "${GREEN}✅ Foundry instalado${NC}"
echo "   Versão: $(forge --version | head -n 1)"
echo ""

# Verificar dependências
echo "=================================================="
echo "📦 Verificando dependências..."
echo "=================================================="
echo ""

if [ ! -d "lib/openzeppelin-contracts" ] || [ ! -d "lib/T-REX" ]; then
    echo -e "${YELLOW}⚠️  Dependências não encontradas. Instalando...${NC}"
    forge install
    echo ""
else
    echo -e "${GREEN}✅ Dependências já instaladas${NC}"
    echo "   • OpenZeppelin Contracts"
    echo "   • OpenZeppelin Contracts Upgradeable"
    echo "   • T-REX (ERC-3643)"
    echo "   • OnchainID"
    echo ""
fi

# Limpar build anterior
echo "=================================================="
echo "🧹 Limpando build anterior..."
echo "=================================================="
echo ""

if [ -d "out" ]; then
    echo "🗑️  Removendo diretório out/"
    rm -rf out
fi

if [ -d "cache" ]; then
    echo "🗑️  Removendo diretório cache/"
    rm -rf cache
fi

echo -e "${GREEN}✅ Limpeza concluída${NC}"
echo ""

# Compilar contratos
echo "=================================================="
echo "⚙️  Compilando contratos..."
echo "=================================================="
echo ""

forge build

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Compilação bem-sucedida!${NC}"
else
    echo ""
    echo -e "${RED}❌ Erro na compilação${NC}"
    exit 1
fi

echo ""
echo "=================================================="
echo "📊 Resumo da compilação:"
echo "=================================================="
echo ""

# Contar arquivos compilados
CONTRACTS_COUNT=$(find out -name "*.json" -type f | wc -l)
echo "  • Contratos compilados: $CONTRACTS_COUNT"

echo ""
echo "Contratos principais:"
echo "  ✅ PropertyTitleTREX"
echo "  ✅ ApprovalsModule"
echo "  ✅ RegistryMDCompliance"
echo "  ✅ ModularCompliance (T-REX)"
echo "  ✅ IdentityRegistry (T-REX)"
echo ""

# Verificar tamanho dos contratos
echo "=================================================="
echo "📏 Tamanho dos contratos:"
echo "=================================================="
echo ""

if command -v jq &> /dev/null; then
    for contract in PropertyTitleTREX ApprovalsModule RegistryMDCompliance; do
        JSON_FILE=$(find out -name "${contract}.json" -type f | head -n 1)
        if [ -f "$JSON_FILE" ]; then
            BYTECODE=$(jq -r '.bytecode.object' "$JSON_FILE" 2>/dev/null || echo "")
            if [ ! -z "$BYTECODE" ] && [ "$BYTECODE" != "null" ]; then
                SIZE=$((${#BYTECODE} / 2))
                SIZE_KB=$(echo "scale=2; $SIZE / 1024" | bc)
                
                # Verificar se está abaixo do limite (24 KB)
                if [ $SIZE -lt 24576 ]; then
                    echo -e "  ${GREEN}✅${NC} $contract: ${SIZE_KB} KB ($SIZE bytes)"
                else
                    echo -e "  ${RED}⚠️${NC} $contract: ${SIZE_KB} KB ($SIZE bytes) - ACIMA DO LIMITE!"
                fi
            fi
        fi
    done
else
    echo "  ⚠️  jq não instalado - não é possível verificar tamanho"
fi

echo ""
echo "=================================================="
echo -e "${GREEN}✅ Build concluído com sucesso!${NC}"
echo "=================================================="
echo ""
echo "Próximo passo:"
echo "  Execute: ./script/setup/deploy-contracts.sh"
echo ""

