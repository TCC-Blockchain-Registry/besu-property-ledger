#!/bin/bash
#
# Teardown Network
# Para e remove completamente a rede Besu e dados relacionados
#

set -e  # Exit on error

echo "=================================================="
echo "🛑 Teardown Besu Network"
echo "=================================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Opções
REMOVE_VOLUMES=false
REMOVE_NETWORK_FILES=false
REMOVE_BUILD=false
REMOVE_BROADCAST=false

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            REMOVE_VOLUMES=true
            REMOVE_NETWORK_FILES=true
            REMOVE_BUILD=true
            REMOVE_BROADCAST=true
            shift
            ;;
        --volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
        --network-files)
            REMOVE_NETWORK_FILES=true
            shift
            ;;
        --build)
            REMOVE_BUILD=true
            shift
            ;;
        --broadcast)
            REMOVE_BROADCAST=true
            shift
            ;;
        -h|--help)
            echo "Uso: $0 [OPTIONS]"
            echo ""
            echo "Opções:"
            echo "  --all              Remove tudo (volumes, network files, build, broadcast)"
            echo "  --volumes          Remove volumes Docker (dados da blockchain)"
            echo "  --network-files    Remove arquivos de rede (keys, genesis)"
            echo "  --build            Remove build artifacts (out/, cache/)"
            echo "  --broadcast        Remove logs de deploy (broadcast/)"
            echo "  -h, --help         Mostra esta ajuda"
            echo ""
            echo "Exemplos:"
            echo "  $0                 # Para containers apenas"
            echo "  $0 --volumes       # Para containers e remove dados"
            echo "  $0 --all           # Remove tudo (reset completo)"
            exit 0
            ;;
        *)
            echo -e "${RED}Opção desconhecida: $1${NC}"
            echo "Use --help para ver opções disponíveis"
            exit 1
            ;;
    esac
done

# Confirmação se --all
if [ "$REMOVE_VOLUMES" = true ] && [ "$REMOVE_NETWORK_FILES" = true ]; then
    echo -e "${YELLOW}⚠️  ATENÇÃO: Isso vai remover TUDO!${NC}"
    echo ""
    echo "Será removido:"
    echo "  • Containers Docker"
    if [ "$REMOVE_VOLUMES" = true ]; then
        echo "  • Volumes Docker (dados da blockchain)"
    fi
    if [ "$REMOVE_NETWORK_FILES" = true ]; then
        echo "  • Network files (keys, genesis)"
    fi
    if [ "$REMOVE_BUILD" = true ]; then
        echo "  • Build artifacts"
    fi
    if [ "$REMOVE_BROADCAST" = true ]; then
        echo "  • Logs de deploy"
    fi
    echo ""
    read -p "Tem certeza? Digite 'yes' para confirmar: " -r
    echo ""
    if [ "$REPLY" != "yes" ]; then
        echo "❌ Operação cancelada"
        exit 0
    fi
fi

# Navegar para raiz do projeto
cd "$(dirname "$0")/../.."

# Navegar para diretório do Besu
cd docker/besu

echo "=================================================="
echo "🐳 Parando containers Docker..."
echo "=================================================="
echo ""

# Verificar se há containers rodando
if docker compose ps | grep -q "Up"; then
    echo "🛑 Parando containers..."
    docker compose stop
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Containers parados${NC}"
    else
        echo -e "${RED}❌ Erro ao parar containers${NC}"
        exit 1
    fi
else
    echo "ℹ️  Nenhum container rodando"
fi

echo ""
echo "=================================================="
echo "🗑️  Removendo containers..."
echo "=================================================="
echo ""

docker compose down

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Containers removidos${NC}"
else
    echo -e "${RED}❌ Erro ao remover containers${NC}"
    exit 1
fi

# Remover volumes se solicitado
if [ "$REMOVE_VOLUMES" = true ]; then
    echo ""
    echo "=================================================="
    echo "🗄️  Removendo volumes Docker..."
    echo "=================================================="
    echo ""
    
    docker compose down -v
    
    # Remover volumes órfãos
    ORPHAN_VOLUMES=$(docker volume ls -q | grep "besu-validator" || true)
    if [ ! -z "$ORPHAN_VOLUMES" ]; then
        echo "🗑️  Removendo volumes órfãos..."
        echo "$ORPHAN_VOLUMES" | xargs docker volume rm 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Volumes removidos${NC}"
fi

# Remover network files se solicitado
if [ "$REMOVE_NETWORK_FILES" = true ]; then
    echo ""
    echo "=================================================="
    echo "📁 Removendo network files..."
    echo "=================================================="
    echo ""
    
    if [ -d "network/files" ]; then
        echo "🗑️  Removendo network/files/"
        rm -rf network/files
    fi
    
    if [ -f "network/genesis.json" ]; then
        echo "🗑️  Removendo network/genesis.json"
        rm -f network/genesis.json
    fi
    
    echo -e "${GREEN}✅ Network files removidos${NC}"
fi

# Voltar para raiz do projeto
cd ../..

# Remover build artifacts se solicitado
if [ "$REMOVE_BUILD" = true ]; then
    echo ""
    echo "=================================================="
    echo "🧹 Removendo build artifacts..."
    echo "=================================================="
    echo ""
    
    if [ -d "out" ]; then
        echo "🗑️  Removendo out/"
        rm -rf out
    fi
    
    if [ -d "cache" ]; then
        echo "🗑️  Removendo cache/"
        rm -rf cache
    fi
    
    echo -e "${GREEN}✅ Build artifacts removidos${NC}"
fi

# Remover broadcast logs se solicitado
if [ "$REMOVE_BROADCAST" = true ]; then
    echo ""
    echo "=================================================="
    echo "📋 Removendo logs de deploy..."
    echo "=================================================="
    echo ""
    
    if [ -d "broadcast" ]; then
        echo "🗑️  Removendo broadcast/"
        rm -rf broadcast
    fi
    
    echo -e "${GREEN}✅ Logs de deploy removidos${NC}"
fi

echo ""
echo "=================================================="
echo -e "${GREEN}✅ Teardown concluído!${NC}"
echo "=================================================="
echo ""

# Resumo do que foi feito
echo "Resumo:"
echo "  ✅ Containers Docker parados e removidos"
if [ "$REMOVE_VOLUMES" = true ]; then
    echo "  ✅ Volumes Docker removidos (dados perdidos)"
fi
if [ "$REMOVE_NETWORK_FILES" = true ]; then
    echo "  ✅ Network files removidos (keys, genesis)"
fi
if [ "$REMOVE_BUILD" = true ]; then
    echo "  ✅ Build artifacts removidos"
fi
if [ "$REMOVE_BROADCAST" = true ]; then
    echo "  ✅ Logs de deploy removidos"
fi

echo ""
echo "Para reiniciar a rede:"
echo "  ./script/setup/setup-network.sh"
echo ""

