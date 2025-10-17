# 🔍 Consultas RPC - Exemplos Práticos

Este documento contém exemplos de consultas via JSON-RPC usando `curl` ou Postman para interagir com os contratos deployados.

---

## 📋 Endereços dos Contratos

```bash
PROPERTY_TITLE=0xd43f6E6A30d00d912791cC314971d2fb028f5AF9
REGISTRY_MD=0x4b83B634d349af4689AD42EeC09D2aBC6b496626
APPROVALS_MODULE=0xE009f733D6d53711C8615Ea00c9B5b1291c37Ab0
IDENTITY_REGISTRY=0x351297246a61f9C44e4bD5337D60e04Bb3BFf9Bf
RPC_URL=http://127.0.0.1:8545
```

---

## 1️⃣ Consultas Básicas da Rede

### Verificar versão do cliente

```bash
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"web3_clientVersion",
    "params":[],
    "id":1
  }'
```

**Postman:**
```json
POST http://127.0.0.1:8545
Body (raw JSON):
{
  "jsonrpc":"2.0",
  "method":"web3_clientVersion",
  "params":[],
  "id":1
}
```

### Verificar último bloco

```bash
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_blockNumber",
    "params":[],
    "id":1
  }'
```

### Verificar saldo de uma carteira

```bash
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_getBalance",
    "params":["0x565524f400856766f11562832eB809d889491a01", "latest"],
    "id":1
  }'
```

---

## 2️⃣ Consultas ao `PropertyTitleTREX`

### Verificar nome do token

```bash
# Codificar chamada: name() = 0x06fdde03
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0xd43f6E6A30d00d912791cC314971d2fb028f5AF9",
      "data":"0x06fdde03"
    }, "latest"],
    "id":1
  }'
```

**Decodificar resultado:**
O resultado virá em hexadecimal. Use um decoder online ou:
```bash
cast --to-ascii <RESULTADO>
```

### Verificar símbolo do token

```bash
# symbol() = 0x95d89b41
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0xd43f6E6A30d00d912791cC314971d2fb028f5AF9",
      "data":"0x95d89b41"
    }, "latest"],
    "id":1
  }'
```

### Verificar saldo de tokens de um endereço

```bash
# balanceOf(address) = 0x70a08231 + endereço (32 bytes)
# Exemplo: verificar saldo de 0x565524f400856766f11562832eB809d889491a01
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0xd43f6E6A30d00d912791cC314971d2fb028f5AF9",
      "data":"0x70a08231000000000000000000000000565524f400856766f11562832eb809d889491a01"
    }, "latest"],
    "id":1
  }'
```

### Verificar dono de uma propriedade (matrícula)

```bash
# getPropertyOwner(uint256) = 0x96d4d16e + matrícula (32 bytes)
# Exemplo: matrícula 123456 (0x1e240 em hex)
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0xd43f6E6A30d00d912791cC314971d2fb028f5AF9",
      "data":"0x96d4d16e000000000000000000000000000000000000000000000000000000000001e240"
    }, "latest"],
    "id":1
  }'
```

### Verificar propriedades de um dono

```bash
# getPropertiesOf(address) = 0x5a3b7e42 + endereço (32 bytes)
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0xd43f6E6A30d00d912791cC314971d2fb028f5AF9",
      "data":"0x5a3b7e42000000000000000000000000565524f400856766f11562832eb809d889491a01"
    }, "latest"],
    "id":1
  }'
```

### Verificar se propriedade existe

```bash
# propertyExists(uint256) = 0x74e15f3e + matrícula (32 bytes)
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0xd43f6E6A30d00d912791cC314971d2fb028f5AF9",
      "data":"0x74e15f3e000000000000000000000000000000000000000000000000000000000001e240"
    }, "latest"],
    "id":1
  }'
```

### Verificar se conta está congelada

```bash
# isFrozen(address) = 0x33c356de + endereço (32 bytes)
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0xd43f6E6A30d00d912791cC314971d2fb028f5AF9",
      "data":"0x33c356de000000000000000000000000565524f400856766f11562832eb809d889491a01"
    }, "latest"],
    "id":1
  }'
```

### Verificar se propriedade está congelada

```bash
# isPropertyFrozen(uint256) = 0x8b4c40b0 + matrícula (32 bytes)
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0xd43f6E6A30d00d912791cC314971d2fb028f5AF9",
      "data":"0x8b4c40b0000000000000000000000000000000000000000000000000000000000001e240"
    }, "latest"],
    "id":1
  }'
```

---

## 3️⃣ Consultas ao `RegistryMDCompliance`

### Verificar dados de um imóvel

```bash
# getProperty(uint256) = 0x836a10d6 + matrícula (32 bytes)
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0x4b83B634d349af4689AD42EeC09D2aBC6b496626",
      "data":"0x836a10d6000000000000000000000000000000000000000000000000000000000001e240"
    }, "latest"],
    "id":1
  }'
```

---

## 4️⃣ Consultas ao `IdentityRegistry`

### Verificar se endereço está verificado (tem identidade)

```bash
# isVerified(address) = 0x3b239a7f + endereço (32 bytes)
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0x351297246a61f9C44e4bD5337D60e04Bb3BFf9Bf",
      "data":"0x3b239a7f000000000000000000000000565524f400856766f11562832eb809d889491a01"
    }, "latest"],
    "id":1
  }'
```

### Verificar OnchainID de um endereço

```bash
# identity(address) = 0x828b88ed + endereço (32 bytes)
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0x351297246a61f9C44e4bD5337D60e04Bb3BFf9Bf",
      "data":"0x828b88ed000000000000000000000000565524f400856766f11562832eb809d889491a01"
    }, "latest"],
    "id":1
  }'
```

---

## 5️⃣ Consultas ao `ApprovalsModule`

### Verificar configuração de uma transferência

```bash
# getTransferConfig(bytes32) = 0x6e8f6c5d + hash da transferência (32 bytes)
# Hash = keccak256(abi.encode(from, to, value, compliance))
# Você precisa calcular esse hash off-chain primeiro

curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0xE009f733D6d53711C8615Ea00c9B5b1291c37Ab0",
      "data":"0x6e8f6c5d<TRANSFER_HASH_32_BYTES>"
    }, "latest"],
    "id":1
  }'
```

---

## 🛠️ Ferramentas Úteis

### Usando `cast` (Foundry)

```bash
# Mais fácil com cast:
cast call $PROPERTY_TITLE "name()" --rpc-url $RPC_URL
cast call $PROPERTY_TITLE "symbol()" --rpc-url $RPC_URL
cast call $PROPERTY_TITLE "balanceOf(address)" 0x565524f400856766f11562832eB809d889491a01 --rpc-url $RPC_URL
cast call $PROPERTY_TITLE "getPropertiesOf(address)" 0x565524f400856766f11562832eB809d889491a01 --rpc-url $RPC_URL
cast call $PROPERTY_TITLE "getPropertyOwner(uint256)" 123456 --rpc-url $RPC_URL
```

### Usando `web3.py` (Python)

```python
from web3 import Web3

w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))

# ABI mínimo para leitura
property_title_abi = [
    {"inputs": [], "name": "name", "outputs": [{"type": "string"}], "stateMutability": "view", "type": "function"},
    {"inputs": [{"type": "address"}], "name": "balanceOf", "outputs": [{"type": "uint256"}], "stateMutability": "view", "type": "function"},
    {"inputs": [{"type": "address"}], "name": "getPropertiesOf", "outputs": [{"type": "uint256[]"}], "stateMutability": "view", "type": "function"}
]

contract = w3.eth.contract(address='0xd43f6E6A30d00d912791cC314971d2fb028f5AF9', abi=property_title_abi)

print(contract.functions.name().call())
print(contract.functions.balanceOf('0x565524f400856766f11562832eB809d889491a01').call())
print(contract.functions.getPropertiesOf('0x565524f400856766f11562832eB809d889491a01').call())
```

---

## 📊 Exemplos de Respostas

### Sucesso (true/false)
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x0000000000000000000000000000000000000000000000000000000000000001"
}
```
- `0x...01` = true
- `0x...00` = false

### Endereço
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x000000000000000000000000565524f400856766f11562832eb809d889491a01"
}
```
- Remover os primeiros 24 zeros: `0x565524f400856766f11562832eb809d889491a01`

### Número (uint256)
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x0000000000000000000000000000000000000000000000000000000000000005"
}
```
- `0x05` = 5 em decimal

### String
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000005..."
}
```
- Decodificar usando `cast --to-ascii` ou biblioteca web3

---

## 🔗 Links Úteis

- **Ethereum JSON-RPC Spec**: https://ethereum.org/en/developers/docs/apis/json-rpc/
- **Function Selector Calculator**: https://www.4byte.directory/
- **ABI Encoder**: https://abi.hashex.org/
- **Foundry Cast**: https://book.getfoundry.sh/reference/cast/

---

## 💡 Dicas

1. **Postman Collection**: Crie uma collection no Postman com todas essas queries para reutilizar
2. **Environment Variables**: Configure `{{RPC_URL}}`, `{{PROPERTY_TITLE}}` etc. no Postman
3. **Scripts**: Para automatizar consultas frequentes, crie scripts bash com os comandos `curl` ou `cast`
4. **Eventos**: Para consultar eventos históricos (ex: propriedades emitidas), use `eth_getLogs`

