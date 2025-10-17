# 🛠️ Scripts de Automação

Scripts shell para facilitar o setup, build, deploy e teardown do projeto.

**Localização:** `script/setup/`

---

## 📋 Scripts Disponíveis

### **🚀 Setup Completo**

#### `setup-all.sh`
Executa **tudo** de uma vez: setup da rede + build + deploy.

```bash
./script/setup/setup-all.sh
```

**O que faz:**
1. ✅ Inicia rede Besu (4 validadores PoA)
2. ✅ Compila todos os contratos
3. ✅ Faz deploy na rede

**Tempo estimado:** ~3-5 minutos

---

### **🌐 Setup da Rede**

#### `setup-network.sh`
Configura e inicia a rede Besu.

```bash
./script/setup/setup-network.sh
```

**O que faz:**
- Gera network files (keys, genesis) se não existirem
- Inicia 4 validadores QBFT (PoA)
- Verifica se RPC está respondendo
- Configura zero-gas

**Resultado:**
- RPC endpoint: `http://127.0.0.1:8545`
- Network ID: `1337`
- Consensus: QBFT (PoA)

---

### **🔨 Build dos Contratos**

#### `build-contracts.sh`
Compila todos os contratos Solidity.

```bash
./script/setup/build-contracts.sh
```

**O que faz:**
- Verifica dependências (OpenZeppelin, T-REX)
- Limpa build anterior
- Compila contratos com Foundry
- Mostra tamanho dos contratos

**Resultado:**
- Artifacts em `out/`
- Cache em `cache/`

---

### **🚀 Deploy dos Contratos**

#### `deploy-contracts.sh`
Faz deploy de todos os contratos na rede.

```bash
./script/setup/deploy-contracts.sh
```

**O que faz:**
- Verifica se rede está rodando
- Verifica saldo da conta
- Faz deploy de toda a stack T-REX
- Salva endereços em `broadcast/`

**Resultado:**
- Contratos deployados na rede
- Logs em `broadcast/*/run-latest.json`

---

### **🛑 Teardown da Rede**

#### `teardown-network.sh`
Para e remove a rede Besu (com opções).

```bash
# Apenas parar containers
./script/setup/teardown-network.sh

# Parar e remover volumes (dados da blockchain)
./script/setup/teardown-network.sh --volumes

# Remover network files (keys, genesis)
./script/setup/teardown-network.sh --network-files

# Remover build artifacts
./script/setup/teardown-network.sh --build

# Remover logs de deploy
./script/setup/teardown-network.sh --broadcast

# RESET COMPLETO (remove tudo)
./script/setup/teardown-network.sh --all
```

**Opções:**
- `--volumes`: Remove dados da blockchain
- `--network-files`: Remove keys e genesis
- `--build`: Remove `out/` e `cache/`
- `--broadcast`: Remove logs de deploy
- `--all`: Remove **TUDO** (reset completo)

---

## 🔄 Fluxos Comuns

### **Primeira Vez (Setup Completo)**

```bash
# Executar tudo de uma vez
./script/setup/setup-all.sh
```

---

### **Desenvolvimento Iterativo**

```bash
# 1. Modificar contratos
# 2. Recompilar
./script/setup/build-contracts.sh

# 3. Fazer deploy (se rede já está rodando)
./script/setup/deploy-contracts.sh
```

---

### **Reiniciar Rede (Manter Dados)**

```bash
# Parar containers
cd docker/besu && docker compose down

# Iniciar novamente
cd ../../scripts && ./script/setup/setup-network.sh
```

---

### **Reset Completo (Limpar Tudo)**

```bash
# Remove rede, dados, build, tudo
./script/setup/teardown-network.sh --all

# Recomeçar do zero
./script/setup/setup-all.sh
```

---

### **Apenas Testar Contratos (Sem Deploy)**

```bash
# Compilar
./script/setup/build-contracts.sh

# Rodar testes
forge test -vv
```

---

## 🐛 Troubleshooting

### **Erro: "Docker não está rodando"**

```bash
# Iniciar Docker
sudo systemctl start docker

# OU (macOS/Windows)
# Abrir Docker Desktop
```

---

### **Erro: "RPC endpoint não está respondendo"**

```bash
# Verificar logs dos validadores
cd docker/besu
docker compose logs validator1

# Reiniciar rede
docker compose down
docker compose up -d
```

---

### **Erro: "Foundry não está instalado"**

```bash
# Instalar Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

---

### **Erro: "Supplied genesis block does not match"**

```bash
# Rede desatualizada - reset completo
./script/setup/teardown-network.sh --all
./script/setup/setup-all.sh
```

---

### **Erro: "Permission denied" ao executar scripts**

```bash
# Dar permissão de execução
chmod +x scripts/*.sh
```

---

## ⚙️ Variáveis de Ambiente

### **RPC URL**
```bash
# Padrão: http://127.0.0.1:8545
# Customizar no script se necessário
```

### **Private Key**
```bash
# Padrão: key do validator1
# Customizar em deploy-contracts.sh se necessário
PRIVATE_KEY="0x51eba47406fcb3dfa80e9ff02c1a8efe1aa1552bf016e09d454e6a7502ef0c24"
```

---

## 📊 Estrutura Após Execução

```
chain_real_state/
├── script/
│   ├── DeployPropertyTitleTREX.s.sol  # Deploy Foundry
│   └── setup/
│       ├── setup-all.sh            # ✅ Executado
│       ├── setup-network.sh        # ✅ Executado
│       ├── build-contracts.sh      # ✅ Executado
│       ├── deploy-contracts.sh     # ✅ Executado
│       └── teardown-network.sh     # Disponível
├── docker/besu/
│   └── network/
│       ├── files/              # ✅ Keys geradas
│       └── genesis.json        # ✅ Genesis gerado
├── out/                        # ✅ Contratos compilados
├── cache/                      # ✅ Cache do Foundry
└── broadcast/                  # ✅ Logs de deploy
    └── DeployPropertyTitleTREX.s.sol/
        └── 1337/
            └── run-latest.json # 📋 Endereços dos contratos
```

---

## 🎯 Próximos Passos Após Setup

1. **Verificar Endereços dos Contratos**
   ```bash
   cat broadcast/*/1337/run-latest.json | jq '.transactions[].contractAddress'
   ```

2. **Interagir com Contratos**
   ```bash
   # Ver guia completo
   cat docs/guias/FLUXO_COMPLETO.md
   ```

3. **Rodar Testes**
   ```bash
   forge test -vv
   ```

4. **Ver Logs da Rede**
   ```bash
   cd docker/besu
   docker compose logs -f validator1
   ```

---

## 📚 Documentação Relacionada

- [Fluxo Completo](../docs/guias/FLUXO_COMPLETO.md) - Como registrar e transferir imóveis
- [Arquitetura](../docs/ARQUITETURA.md) - Diagrama dos contratos
- [Amarração](../docs/AMARRACAO_CONTRATOS.md) - Como tudo se conecta

---

## ✅ Checklist de Setup Bem-Sucedido

Após executar `./script/setup/setup-all.sh`, verifique:

- [ ] Docker containers rodando (4 validadores)
- [ ] RPC respondendo em `http://127.0.0.1:8545`
- [ ] Contratos compilados em `out/`
- [ ] Contratos deployados (check `broadcast/`)
- [ ] Logs sem erros

**Se todos os itens estiverem OK, o sistema está pronto! 🎉**

