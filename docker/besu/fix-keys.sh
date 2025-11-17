#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
KEYS_DIR="$SCRIPT_DIR/network/files/keys"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

echo "🔍 Detectando chaves válidas..."

# Encontra os 4 primeiros diretórios com chave válida (key como arquivo)
VALID_KEYS=()
for dir in "$KEYS_DIR"/*; do
    if [ -d "$dir" ] && [ -f "$dir/key" ]; then
        addr=$(basename "$dir")
        VALID_KEYS+=("$addr")
    fi
done

if [ ${#VALID_KEYS[@]} -lt 4 ]; then
    echo "❌ ERRO: Apenas ${#VALID_KEYS[@]} chaves válidas encontradas (precisamos de 4)"
    echo "   Tente regenerar as chaves: ./generate.sh"
    exit 1
fi

echo "✅ Encontradas ${#VALID_KEYS[@]} chaves válidas:"
for i in "${!VALID_KEYS[@]}"; do
    echo "   Validator$((i+1)): ${VALID_KEYS[$i]}"
done

echo ""
echo "📝 Atualizando docker-compose.yml..."

# Backup do docker-compose.yml
cp "$COMPOSE_FILE" "$COMPOSE_FILE.bak"

# Substituir os endereços no docker-compose.yml
# Encontra as linhas que contêm ./network/files/keys/0x... e substitui pelos endereços válidos
sed -i.tmp "s|./network/files/keys/0x[a-fA-F0-9]\{40\}/key:/keys/key:ro|./network/files/keys/${VALID_KEYS[0]}/key:/keys/key:ro|" "$COMPOSE_FILE"

# Para o validator2, 3 e 4, precisa fazer de forma mais cuidadosa
# Vamos usar uma abordagem diferente: ler o arquivo e substituir linha por linha

# Restaurar o backup e usar perl para substituição mais precisa
mv "$COMPOSE_FILE.bak" "$COMPOSE_FILE"

# Usar perl para substituir cada ocorrência sequencialmente
perl -i -pe '
BEGIN {
    @keys = ("'"${VALID_KEYS[0]}"'", "'"${VALID_KEYS[1]}"'", "'"${VALID_KEYS[2]}"'", "'"${VALID_KEYS[3]}"'");
    $count = 0;
}
if (/\.\/network\/files\/keys\/0x[a-fA-F0-9]{40}\/key:\/keys\/key:ro/) {
    s/(\.\/network\/files\/keys\/)0x[a-fA-F0-9]{40}(\/key:\/keys\/key:ro)/${1}$keys[$count]${2}/;
    $count++;
}
' "$COMPOSE_FILE"

# Remover arquivo temporário se existir
rm -f "$COMPOSE_FILE.tmp"

echo "✅ docker-compose.yml atualizado!"
echo ""
echo "Chaves configuradas:"
echo "  • validator1: ${VALID_KEYS[0]}"
echo "  • validator2: ${VALID_KEYS[1]}"
echo "  • validator3: ${VALID_KEYS[2]}"
echo "  • validator4: ${VALID_KEYS[3]}"

