# 🔍 Scripts de Consultas RPC

Esta pasta contém scripts para testar e consultar os smart contracts deployados via JSON-RPC.

---

## 📄 Scripts Disponíveis

### `test-queries-simple.sh`

Script bash com consultas básicas usando `curl` puro.

**Uso:**
```bash
./script/queries/test-queries-simple.sh
```

**O que testa:**
- ✅ Versão do cliente Besu
- ✅ Último número de bloco
- ✅ Verificar se contrato está deployado
- ✅ Nome do token (`PropertyTitle`)
- ✅ Símbolo do token (`TITLE`)
- ✅ Decimals (0 = indivisível)
- ✅ Balance do admin
- ✅ Status de pause

**Exemplo de saída:**
```
==========================================
🔍 Testando Consultas RPC (cURL puro)
==========================================

1️⃣  Cliente Besu:
{"jsonrpc":"2.0","id":1,"result":"besu/v23.10.2/linux-x86_64/openjdk-java-17"}

2️⃣  Último bloco:
{"jsonrpc":"2.0","id":1,"result":"0x3fdd"}

4️⃣  Nome do token (name() = 0x06fdde03):
{"jsonrpc":"2.0","id":1,"result":"0x0000...50726f70657274795469746c65..."}

...
```

---

### `test-queries.sh`

Script mais avançado usando `cast` (Foundry) e `jq` para decodificar resultados automaticamente.

**Pré-requisitos:**
- `jq` instalado (`sudo apt install jq`)
- `cast` (Foundry)

**Uso:**
```bash
./script/queries/test-queries.sh
```

---

## 🔗 Links Úteis

📖 **[Documentação Completa de Queries RPC](../../docs/referencias/RPC_QUERIES.md)**
- Todos os exemplos de `curl`
- Funções disponíveis
- Como decodificar resultados

📥 **[Postman Collection](../../docs/collections/Postman_Collection.json)**
- Importe no Postman
- Queries pré-configuradas
- Variáveis de ambiente

---

## 💡 Dicas

### Decodificar Strings

Strings retornadas em hexadecimal podem ser decodificadas com:

```bash
cast --to-ascii 0x0000000000...50726f70657274795469746c65...
# Output: PropertyTitle
```

### Converter Hex para Decimal

```bash
# Usando bash
echo $((16#3fdd))  # Output: 16349

# Usando cast
cast --to-dec 0x3fdd  # Output: 16349
```

### Consultar Funções Customizadas

Para funções não incluídas nos scripts:

1. Obter o function selector:
   ```bash
   cast sig "getPropertyOwner(uint256)"
   # Output: 0x96d4d16e
   ```

2. Codificar parâmetros:
   ```bash
   cast calldata "getPropertyOwner(uint256)" 123456
   # Output: 0x96d4d16e000000000000000000000000000000000000000000000000000000000001e240
   ```

3. Fazer a chamada:
   ```bash
   curl -X POST http://127.0.0.1:8545 \
     -H "Content-Type: application/json" \
     -d '{
       "jsonrpc":"2.0",
       "method":"eth_call",
       "params":[{
         "to":"0xd43f6E6A30d00d912791cC314971d2fb028f5AF9",
         "data":"0x96d4d16e000000000000000000000000000000000000000000000000000000000001e240"
       },"latest"],
       "id":1
     }'
   ```

---

## 🛠️ Troubleshooting

### RPC não responde

```bash
# Verificar se containers estão rodando
docker compose -f docker/besu/docker-compose.yml ps

# Verificar logs
docker compose -f docker/besu/docker-compose.yml logs validator1

# Testar conexão
curl http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}'
```

### Contrato não existe

Se receber `result: "0x"`, o contrato não está deployado:

```bash
# Fazer deploy novamente
./script/setup/deploy-contracts.sh
```

### Resultado em hex ilegível

Use `cast` para decodificar:

```bash
# Para strings
cast --to-ascii <HEX>

# Para números
cast --to-dec <HEX>

# Para endereços (remover zeros à esquerda)
# 0x000000000000000000000000565524f400856766f11562832eb809d889491a01
# → 0x565524f400856766f11562832eb809d889491a01
```

---

## 📚 Documentação Relacionada

- [RPC_QUERIES.md](../../docs/referencias/RPC_QUERIES.md) - Guia completo de consultas
- [SCRIPTS.md](../../docs/referencias/SCRIPTS.md) - Documentação de scripts de setup
- [Postman Collection](../../docs/collections/Postman_Collection.json) - Collection para importar
- [README.md](../../README.md) - Documentação principal do projeto

