# 🏠 Real Estate Tokenization Platform (ERC-3643)

Sistema de tokenização e transferência de imóveis usando Hyperledger Besu (PoA) e padrão ERC-3643 (T-REX) com compliance modular.

---

## 📋 Visão Geral

Este projeto implementa um sistema blockchain para:
- **Registro de imóveis** com dados cadastrais on-chain
- **Tokenização** via ERC-3643 (security tokens com compliance)
- **Transferências reguladas** com aprovadores configuráveis por transferência (1, 2, 3+ entidades)
- **Identidade verificada** com associação CPF ↔ endereço Ethereum (off-chain)

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    HYPERLEDGER BESU (PoA)                   │
│                        4 Validators                         │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼────────┐   ┌────────▼────────┐   ┌───────▼────────┐
│  T-REX (ERC3643) │   │ Identity System │   │ Property Reg.  │
│                │   │                 │   │                │
│ • ModularComp. │   │ • CPFRegistry   │   │ • RegistryMD   │
│ • SecurityToken│   │ • OnchainID     │   │   Compliance   │
│ • Approvals    │   │ • IdentityReg.  │   │                │
└────────────────┘   └─────────────────┘   └────────────────┘
```

### **Componentes Principais**

| Componente | Função |
|------------|--------|
| `SecurityToken.sol` | Token ERC-3643 (ERC20 regulado) representando imóveis |
| `RegistryMDCompliance.sol` | Módulo de registro e validação de imóveis |
| `ApprovalsModule.sol` | Módulo de aprovações **configuráveis por transferência** (1 a N aprovadores) |
| `IdentityRegistry` (T-REX) | Registro de identidades verificadas (OnchainID) |
| `ModularCompliance` (T-REX) | Orquestrador de módulos de compliance |
| **Backend (off-chain)** | **Associação CPF ↔ wallet + lógica de aprovadores (banco de dados)** |

---

## 🚀 Quick Start

### **🚀 Opção 1: Setup Automático (Recomendado)**

```bash
# 1. Clonar repositório
git clone <repo>
cd chain_real_state

# 2. Instalar dependências
forge install

# 3. Executar setup completo (rede + build + deploy)
./script/setup/setup-all.sh
```

**Resultado:** Sistema completo rodando em ~3-5 minutos! 🎉

**Pré-requisitos:**
- Docker & Docker Compose
- Foundry (forge, cast)

---

### **🔧 Opção 2: Setup Manual (Passo a Passo)**

#### **1. Instalar Foundry**

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

#### **2. Clonar e Instalar Dependências**

```bash
git clone <repo>
cd chain_real_state
forge install
```

#### **3. Iniciar Rede Besu**

```bash
./script/setup/setup-network.sh
```

#### **4. Build dos Contratos**

```bash
./script/setup/build-contracts.sh
```

#### **5. Deploy dos Contratos**

```bash
./script/setup/deploy-contracts.sh
```

---

### **📜 Scripts Disponíveis**

| Script | Descrição | Uso |
|--------|-----------|-----|
| `setup-all.sh` | Setup completo (tudo) | `./script/setup/setup-all.sh` |
| `setup-network.sh` | Apenas rede Besu | `./script/setup/setup-network.sh` |
| `build-contracts.sh` | Apenas compilação | `./script/setup/build-contracts.sh` |
| `deploy-contracts.sh` | Apenas deploy | `./script/setup/deploy-contracts.sh` |
| `teardown-network.sh` | Parar/remover rede | `./script/setup/teardown-network.sh --all` |

📖 **Documentação completa:** [docs/referencias/SCRIPTS.md](./docs/referencias/SCRIPTS.md)

---

## 📚 Documentação

### **📚 Documentação Organizada**

#### **🏗️ Documentos Principais**

- 📖 [**Arquitetura do Sistema**](./docs/ARQUITETURA.md)
  - Diagrama geral dos contratos
  - Componentes e responsabilidades
  - Fluxo de dados on-chain e off-chain

- 📖 [**Amarração dos Contratos**](./docs/AMARRACAO_CONTRATOS.md)
  - Como os contratos estão interligados
  - Fluxo completo de validação (10 camadas)
  - PropertyTitleTREX → Token → ModularCompliance → Módulos
  - Quando transferências são bloqueadas

#### **📖 Guias Práticos** (`docs/guias/`)

- 📖 [**Fluxo Completo: Registro e Transferência**](./docs/guias/FLUXO_COMPLETO.md)
  - Registro de imóvel (passo a passo)
  - Transferência de imóvel (passo a passo)
  - Configuração dinâmica de aprovadores
  - Aceitação do comprador (buyer acceptance)
  - Comandos práticos com `cast`
  - Roles e permissões

#### **💻 Backend** (`docs/backend/`)

- 📖 [**Associação CPF ↔ Wallet (Off-Chain)**](./docs/backend/CPF_WALLET.md)
  - Como criar wallets off-chain
  - Como associar CPF ao endereço (banco de dados)
  - API Backend completa (Node.js + PostgreSQL)
  - Worker para sincronização com blockchain

#### **📚 Referências Técnicas** (`docs/referencias/`)

- 📖 [**ERC-3643: Análise Técnica**](./docs/referencias/ERC3643_ANALISE.md)
  - Por que ERC-20 é necessário?
  - ERC-3643 = ERC-20 + Compliance + Identity
  - Como o token representa o imóvel?
  - Amarração on-chain ↔ off-chain
  - Comparação de arquiteturas

- 📖 [**Freeze e Pause (T-REX Full)**](./docs/referencias/FREEZE_PAUSE.md)
  - Congelar contas e propriedades
  - Pausar sistema globalmente (emergências)
  - Transferências forçadas (recuperação)
  - Operações em lote (batch)
  - Casos de uso práticos

- 📖 [**Testes Unitários**](./docs/referencias/TESTES.md)
  - 28 testes unitários (100% passa)
  - Cobertura completa de todos os contratos
  - Guia de como escrever novos testes

- 📖 [**Scripts de Automação**](./docs/referencias/SCRIPTS.md)
  - Setup completo automatizado
  - Scripts individuais (rede, build, deploy, teardown)
  - Troubleshooting e exemplos de uso
  - Fluxos comuns de desenvolvimento

---

## 🔄 Fluxos Resumidos

### **Registro de Imóvel**

```solidity
// 1. Registrar identidade do proprietário
// (Backend já associou CPF ↔ wallet no banco de dados)
Identity ownerIdentity = new Identity(owner, false);
identityRegistry.registerIdentity(owner, ownerIdentity, 76);

// 2. Registrar imóvel
PropertyInfo memory prop = PropertyInfo({
    matriculaId: 123456,
    folha: 100,
    comarca: "São Paulo",
    endereco: "Rua X, 123",
    metragem: 150,
    proprietario: owner,
    matriculaOrigem: 0,
    tipo: PropertyType.URBANO,
    isRegular: true
});
registryModule.registerProperty(prop);

// 3. Mintar token
securityToken.mint(owner, 1 ether);
```

### **Transferência de Imóvel**

```solidity
// 1. Garantir que comprador tem identidade
identityRegistry.registerIdentity(buyer, buyerIdentity, 76);

// 2. Configurar aprovadores para esta transferência (backend/orchestrator)
address[] memory approvers = new address[](3);
approvers[0] = prefeituraAddr;
approvers[1] = cartorioAddr;
approvers[2] = IFAddr;
approvalsModule.configureTransfer(seller, buyer, matriculaId, compliance, approvers);

// 3. Cada aprovador aprova
approvalsModule.approve(seller, buyer, matriculaId, compliance); // Prefeitura
approvalsModule.approve(seller, buyer, matriculaId, compliance); // Cartório
approvalsModule.approve(seller, buyer, matriculaId, compliance); // IF

// 4. Comprador ACEITA a transferência
approvalsModule.acceptTransfer(seller, matriculaId, compliance); // Bob aceita

// 5. Transferência (executada pelo vendedor)
securityToken.transfer(buyer, amount);
// → Valida: identidades + 3/3 aprovações + aceitação do comprador + regularidade
// → Limpa configuração após sucesso
```

---

## 🔧 Configuração

### **Roles Padrão (Deploy)**

No deploy inicial, o `admin` (deployer) recebe os roles principais:

```solidity
// ApprovalsModule
bytes32 ORCHESTRATOR_ROLE = keccak256("ORCHESTRATOR_ROLE");
approvals.grantRole(ORCHESTRATOR_ROLE, admin); // pode configurar aprovadores

// Roles de registro
registryModule: admin tem REGISTRAR_ROLE (pode registrar imóveis)
securityToken: admin tem ISSUER_ROLE (pode mintar tokens)
identityRegistry: admin é Agent (pode registrar identidades)
```

### **Sistema de Aprovadores Dinâmico**

Não há roles fixos de aprovação! Cada transferência define sua própria lista de aprovadores:

```solidity
// Exemplo: Transferência A requer 3 aprovadores
configureTransfer(alice, bob, 123, [0xPref, 0xCart, 0xIF]);

// Exemplo: Transferência B requer apenas 1 aprovador
configureTransfer(carlos, diana, 456, [0xCart]);

// Exemplo: Transferência C requer 5 aprovadores
configureTransfer(eduardo, fernanda, 789, [0xPref, 0xCart, 0xIF, 0xIPHAN, 0xMeioAmb]);
```

O backend decide quem aprova baseado em regras de negócio (tipo de imóvel, localização, etc.)

---

## 🧪 Testes

### **✅ 41 Testes Unitários Implementados**

```bash
# Rodar todos os testes
forge test -vv

# Resultado:
# ✅ ApprovalsModuleTest (17 testes)
# ✅ RegistryMDComplianceTest (11 testes)  
# ⏳ PropertyTitleTREXTest (a ser implementado)
# Total: 28 tests passed, 0 failed

# Gas report
forge test --gas-report

# Cobertura de código
forge coverage

# Teste específico
forge test --match-test test_Transfer_Success -vvv
```

📖 **[Documentação Completa dos Testes](./docs/referencias/TESTES.md)**

---

## 🔍 Consultas e Integração

### **Consultar Contratos via RPC (cURL, Postman, etc.)**

```bash
# Executar script de testes
./script/queries/test-queries-simple.sh

# Consulta manual (exemplo: nome do token)
curl -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_call",
       "params":[{"to":"0xd43f...","data":"0x06fdde03"},"latest"],"id":1}'
```

### **Postman Collection**

Importe a collection pronta para testar todas as queries:

📥 **[docs/collections/Postman_Collection.json](./docs/collections/Postman_Collection.json)**

Queries disponíveis:
- ✅ Token info (name, symbol, decimals)
- ✅ Balance de endereço
- ✅ Propriedades de um dono
- ✅ Verificar se endereço tem identidade
- ✅ Status de pause/freeze
- ✅ E muito mais...

📖 **[Guia Completo de Queries RPC](./docs/referencias/RPC_QUERIES.md)**

---

## 📊 Estrutura do Projeto

```
chain_real_state/
├── src/
│   ├── token/
│   │   └── PropertyTitleTREX.sol      # Token ERC-3643 Full (freeze/pause)
│   ├── compliance/
│   │   └── modules/
│   │       ├── ApprovalsModule.sol    # Aprovações multi-entidades dinâmicas
│   │       └── RegistryMDCompliance.sol # Registro e validação de imóveis
├── script/
│   ├── DeployPropertyTitleTREX.s.sol  # Deploy Foundry (T-REX Full)
│   └── setup/                         # Scripts de automação
│       ├── setup-all.sh               # Setup completo
│       ├── setup-network.sh           # Apenas rede
│       ├── build-contracts.sh         # Apenas build
│       ├── deploy-contracts.sh        # Apenas deploy
│       └── teardown-network.sh        # Teardown
├── docs/
│   ├── ARQUITETURA.md                 # Diagrama e arquitetura geral
│   ├── AMARRACAO_CONTRATOS.md         # Como contratos se conectam
│   ├── guias/
│   │   └── FLUXO_COMPLETO.md          # Guia completo: registro + transferência
│   ├── backend/
│   │   └── CPF_WALLET.md              # Backend: CPF ↔ wallet (off-chain)
│   └── referencias/
│       ├── ERC3643_ANALISE.md         # Análise técnica ERC-3643
│       ├── FREEZE_PAUSE.md            # Features freeze/pause
│       └── TESTES.md                  # Documentação dos testes
├── docker/
│   └── besu/
│       ├── docker-compose.yml         # 4 validators PoA (QBFT)
│       ├── generate.sh                # Gera keys e genesis
│       └── network/
│           └── genesis.json           # Genesis com zeroBaseFee
└── foundry.toml                       # Config Foundry (via-ir, optimizer)
```

---

## 🔒 Segurança e Privacidade

### **Boas Práticas Implementadas**

✅ **CPF nunca vai para blockchain**
- Associação CPF ↔ wallet fica no backend (banco de dados privado)
- Blockchain só sabe que endereço foi verificado (não sabe qual CPF)

✅ **Identidade verificada (OnchainID)**
- Claims assinadas por trusted issuers
- Integração com T-REX IdentityRegistry

✅ **Aprovações flexíveis e específicas**
- Cada transferência define seus próprios aprovadores (1, 2, 3+)
- Aprovações limpas após uso (não reutilizáveis)
- Backend decide regras de negócio (quem e quantos)

✅ **Roles segregados**
- `ORCHESTRATOR_ROLE` → configura aprovadores por transferência
- `REGISTRAR_ROLE` → registra imóveis
- `ISSUER_ROLE` → minta tokens
- Aprovadores sem roles fixos (definidos por transferência)

✅ **Validação modular**
- Compliance via AbstractModule (T-REX)
- Fácil adicionar novos módulos de validação

---

## 🌐 Rede Besu (PoA)

### **Características**

- **Consenso:** QBFT (Istanbul BFT)
- **Validators:** 4 nós
- **Gas:** Zero (zeroBaseFee habilitado)
- **Network ID:** 1337
- **RPC Endpoint:** http://127.0.0.1:8545

### **Gerenciamento**

```bash
cd docker/besu

# Iniciar
docker compose up -d

# Logs
docker compose logs -f validator1

# Parar
docker compose down

# Resetar (apaga dados)
docker compose down -v
```

---

## 📈 Roadmap

- [x] Implementação ERC-3643 (T-REX)
- [x] Módulo de registro de imóveis
- [x] Módulo de aprovações dinâmicas (configurável por transferência)
- [x] Sistema de identidade (OnchainID + CPF off-chain)
- [x] Deploy scripts
- [x] Documentação completa (incluindo backend off-chain e aprovadores dinâmicos)
- [ ] Implementar backend (Node.js + PostgreSQL)
- [ ] Testes unitários (smart contracts)
- [ ] Testes de integração
- [ ] Interface web (frontend)
- [ ] Integração com APIs externas (Receita Federal, etc.)
- [ ] Auditoria de segurança

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -m 'Add nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 📞 Suporte

Para dúvidas ou problemas:
- Abra uma [issue](../../issues)
- Consulte a [documentação](./docs/)
- Contato: [seu-email]

---

## 🙏 Agradecimentos

- [T-REX (TokenySolutions)](https://github.com/TokenySolutions/T-REX) - ERC-3643 implementation
- [OpenZeppelin](https://openzeppelin.com/) - Smart contract libraries
- [Hyperledger Besu](https://besu.hyperledger.org/) - Enterprise Ethereum client
- [Foundry](https://getfoundry.sh/) - Ethereum development toolkit
