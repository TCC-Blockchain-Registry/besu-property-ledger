# 🏠 Real Estate Tokenization Platform (ERC-3643)

Sistema de tokenização e transferência de imóveis usando Hyperledger Besu (PoA) e padrão ERC-3643 (T-REX) com compliance modular.

[![Solidity](https://img.shields.io/badge/Solidity-0.8.17-363636?logo=solidity)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C?logo=foundry)](https://getfoundry.sh/)
[![Hyperledger Besu](https://img.shields.io/badge/Besu-23.10.2-2F3134?logo=hyperledger)](https://besu.hyperledger.org/)
[![Tests](https://img.shields.io/badge/Tests-28%20passing-success)](./test)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

---

## 📑 Índice

- [📋 Visão Geral](#-visão-geral)
- [🏗️ Arquitetura](#️-arquitetura)
- [🚀 Quick Start](#-quick-start)
- [📚 Documentação](#-documentação)
- [🔄 Fluxos Resumidos](#-fluxos-resumidos)
- [🧪 Testes](#-testes)
- [🔍 Consultas e Integração](#-consultas-e-integração)
- [📊 Estrutura do Projeto](#-estrutura-do-projeto)
- [🔒 Segurança e Privacidade](#-segurança-e-privacidade)
- [🌐 Rede Besu](#-rede-besu-poa)
- [✅ Verificações Rápidas](#-verificações-rápidas)
- [📈 Roadmap](#-roadmap)
- [📞 Suporte](#-suporte)

---

## 📋 Visão Geral

Este projeto implementa um sistema blockchain para:
- **Registro de imóveis** com dados cadastrais on-chain
- **Tokenização** via ERC-3643 (security tokens com compliance)
- **Transferências reguladas** com aprovadores configuráveis por transferência (1, 2, 3+ entidades)
- **Identidade verificada** com associação CPF ↔ endereço Ethereum (off-chain)

### **✨ Features Principais**

- ✅ **Tokenização de Imóveis:** Cada propriedade é representada por um token ERC-3643 único e indivisível
- ✅ **Compliance Modular:** Sistema de validação flexível com múltiplos módulos customizáveis
- ✅ **Aprovações Dinâmicas:** Configure aprovadores específicos para cada transferência (1, 2, 3+ entidades)
- ✅ **Identidade Verificada:** OnchainID com associação CPF ↔ Wallet off-chain (privacidade garantida)
- ✅ **Controles de Emergência:** Pause global e freeze de contas específicas
- ✅ **Transferências Forçadas:** Recovery de tokens em casos especiais (por agentes autorizados)
- ✅ **Registro Completo:** Matrícula, comarca, endereço, metragem e tipo do imóvel on-chain
- ✅ **Zero Gas Fees:** Rede privada Besu configurada sem custos de transação
- ✅ **28 Testes Unitários:** Cobertura completa dos contratos principais

### **🛠️ Tecnologias Utilizadas**

| Tecnologia | Versão | Uso |
|------------|--------|-----|
| Hyperledger Besu | 23.10.2 | Blockchain privado PoA (QBFT) |
| Solidity | 0.8.17 | Smart contracts |
| Foundry | Latest | Build, testes e deploy |
| ERC-3643 (T-REX) | Latest | Framework de security tokens |
| OpenZeppelin | Latest | Bibliotecas de contratos seguros |
| Docker | >= 20.10 | Orquestração de rede |

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
│                │   │   (On-Chain)    │   │                │
│ • ModularComp. │   │ • OnchainID     │   │ • RegistryMD   │
│ • PropertyTitle│   │ • IdentityReg.  │   │   Compliance   │
│ • Approvals    │   │ • Verified IDs  │   │                │
└────────────────┘   └─────────────────┘   └────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Backend (Off-Chain) │
                    │                    │
                    │ • CPF ↔ Wallet DB  │
                    │ • KYC Validation   │
                    │ • Event Listener   │
                    └────────────────────┘
```

### **Componentes Principais**

| Componente | Localização | Função |
|------------|-------------|--------|
| `PropertyTitleTREX.sol` | On-Chain | Token ERC-3643 (T-REX Full) representando títulos de propriedade |
| `RegistryMDCompliance.sol` | On-Chain | Módulo de registro e validação de imóveis |
| `ApprovalsModule.sol` | On-Chain | Módulo de aprovações **configuráveis por transferência** (1 a N aprovadores) |
| `IdentityRegistry` (T-REX) | On-Chain | Registro de identidades verificadas (OnchainID) - **sem CPF** |
| `ModularCompliance` (T-REX) | On-Chain | Orquestrador de módulos de compliance |
| **Backend API/DB** | Off-Chain | **Associação CPF ↔ wallet + KYC + eventos blockchain** |

---

## 🚀 Quick Start

### **🚀 Opção 1: Setup Automático (Recomendado)**

```bash
# 1. Clonar repositório
git clone <repo>
cd besu-property-ledger

# 2. Instalar dependências
forge install

# 3. Executar setup completo (rede + build + deploy)
./script/setup/setup-all.sh
```

**Resultado:** Sistema completo rodando em ~3-5 minutos! 🎉

**Pré-requisitos:**
- **Docker** (>= 20.10) & **Docker Compose** (>= 2.0)
- **Foundry** (forge, cast, anvil) - [Instalar](https://getfoundry.sh)
- **Git** para clonar o repositório
- **Sistema Operacional:** Linux, macOS ou WSL2 (Windows)
- **Memória RAM:** Mínimo 4GB recomendado

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
cd besu-property-ledger
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

// 3. Mintar token (amount = matrícula do imóvel)
securityToken.mint(owner, matriculaId);
```

### **Transferência de Imóvel**

```solidity
// 1. Garantir que comprador tem identidade verificada
identityRegistry.registerIdentity(buyer, buyerIdentity, 76);

// 2. Configurar aprovadores para esta transferência (backend/orchestrator)
address[] memory approvers = new address[](3);
approvers[0] = prefeituraAddr;  // Prefeitura
approvers[1] = cartorioAddr;    // Cartório
approvers[2] = IFAddr;          // Instituto Fundiário
approvalsModule.configureTransfer(seller, buyer, matriculaId, compliance, approvers);

// 3. Cada aprovador aprova individualmente
approvalsModule.approve(seller, buyer, matriculaId, compliance); // Prefeitura aprova
approvalsModule.approve(seller, buyer, matriculaId, compliance); // Cartório aprova
approvalsModule.approve(seller, buyer, matriculaId, compliance); // IF aprova

// 4. Comprador ACEITA explicitamente a transferência (proteção)
approvalsModule.acceptTransfer(seller, matriculaId, compliance);

// 5. Vendedor executa a transferência
securityToken.transfer(buyer, matriculaId);
// → Sistema valida AUTOMATICAMENTE:
//   ✓ Ambos têm identidade verificada
//   ✓ Todas as 3 aprovações foram dadas
//   ✓ Comprador aceitou a transferência
//   ✓ Imóvel está regular
// → Configuração é LIMPA automaticamente após sucesso
```

> **💡 Nota:** O `amount` na transferência representa a matrícula do imóvel, não um valor monetário! O pagamento acontece off-chain.

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

**Não há roles fixos de aprovação!** Cada transferência define sua própria lista de aprovadores baseada em regras de negócio:

```solidity
// 📍 Transferência em zona urbana → 3 aprovadores
configureTransfer(alice, bob, 123, [prefeitura, cartorio, institutoFundiario]);

// 🏞️ Transferência simples → 1 aprovador
configureTransfer(carlos, diana, 456, [cartorio]);

// 🏛️ Transferência de imóvel histórico → 5 aprovadores
configureTransfer(eduardo, fernanda, 789, [prefeitura, cartorio, IF, IPHAN, meioAmbiente]);

// 🌳 Transferência em área rural → aprovadores específicos
configureTransfer(gustavo, helena, 999, [INCRA, meioAmbiente, cartorio]);
```

**Como funciona:**
- Backend/Orchestrator analisa o imóvel (tipo, localização, características)
- Define automaticamente quais entidades devem aprovar
- Configura a lista de aprovadores específica para aquela transferência
- Após a transferência, configuração é limpa (não reutilizável)

**Vantagens:**
- ✅ Flexibilidade total por transferência
- ✅ Regras de negócio implementadas off-chain (fácil manutenção)
- ✅ Não requer mudanças nos contratos para adicionar novos aprovadores
- ✅ Segurança: aprovações não são reutilizáveis

---

## 🧪 Testes

### **✅ 28 Testes Unitários Implementados**

```bash
# Rodar todos os testes
forge test -vv

# Resultado:
# ✅ ApprovalsModuleTest (17 testes)
# ✅ RegistryMDComplianceTest (11 testes)
# Total: 28 tests passed, 0 failed

# Gas report
forge test --gas-report

# Cobertura de código
forge coverage

# Teste específico
forge test --match-test test_ModuleCheck_Success -vvv
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

📥 **[Postman_Collection.json](./docs/collections/Postman_Collection.json)**

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
besu-property-ledger/
├── src/
│   ├── token/
│   │   └── PropertyTitleTREX.sol      # Token ERC-3643 Full (freeze/pause)
│   ├── compliance/
│   │   └── modules/
│   │       ├── ApprovalsModule.sol    # Aprovações multi-entidades dinâmicas
│   │       └── RegistryMDCompliance.sol # Registro e validação de imóveis
├── script/
│   ├── DeployPropertyTitleTREX.s.sol  # Deploy Foundry (T-REX Full)
│   ├── queries/                       # Scripts de consulta
│   │   ├── test-queries.sh            # Queries JSON-RPC
│   │   └── test-queries-simple.sh     # Queries simplificadas
│   └── setup/                         # Scripts de automação
│       ├── setup-all.sh               # Setup completo
│       ├── setup-network.sh           # Apenas rede
│       ├── build-contracts.sh         # Apenas build
│       ├── deploy-contracts.sh        # Apenas deploy
│       └── teardown-network.sh        # Teardown
├── test/
│   ├── ApprovalsModule.t.sol          # Testes do módulo de aprovações (17 testes)
│   └── RegistryMDCompliance.t.sol     # Testes do registro de imóveis (11 testes)
├── docs/
│   ├── ARQUITETURA.md                 # Diagrama e arquitetura geral
│   ├── AMARRACAO_CONTRATOS.md         # Como contratos se conectam
│   ├── guias/
│   │   └── FLUXO_COMPLETO.md          # Guia completo: registro + transferência
│   ├── backend/
│   │   └── CPF_WALLET.md              # Backend: CPF ↔ wallet (off-chain)
│   ├── collections/
│   │   └── Postman_Collection.json    # Collection Postman para queries
│   └── referencias/
│       ├── ERC3643_ANALISE.md         # Análise técnica ERC-3643
│       ├── FREEZE_PAUSE.md            # Features freeze/pause
│       ├── TESTES.md                  # Documentação dos testes
│       ├── SCRIPTS.md                 # Documentação dos scripts
│       └── RPC_QUERIES.md             # Guia de queries RPC
├── docker/
│   └── besu/
│       ├── docker-compose.yml         # 4 validators PoA (QBFT)
│       ├── generate.sh                # Gera keys e genesis
│       ├── network/
│       │   └── genesis.json           # Genesis com zeroBaseFee
│       └── operator/                  # Ferramentas auxiliares
├── deployed-addresses.txt             # Endereços dos contratos deployados
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

## ✅ Verificações Rápidas

### **Sistema está funcionando?**

```bash
# 1. Verificar se a rede Besu está rodando
cd docker/besu && docker compose ps

# 2. Verificar se os contratos foram deployados
cat deployed-addresses.txt

# 3. Rodar os testes para validar contratos
forge test -vv

# 4. Fazer uma query simples (verificar se RPC responde)
./script/queries/test-queries-simple.sh
```

### **Resetar Ambiente Completo**

```bash
# 1. Parar e limpar rede
cd docker/besu && docker compose down -v

# 2. Limpar builds e caches
cd ../.. && forge clean

# 3. Recriar tudo do zero
./script/setup/setup-all.sh
```

---

## 📈 Roadmap

### ✅ **Concluído**
- [x] Implementação ERC-3643 (T-REX Full)
- [x] Módulo de registro de imóveis (RegistryMDCompliance)
- [x] Módulo de aprovações dinâmicas (ApprovalsModule - configurável por transferência)
- [x] Sistema de identidade (OnchainID + CPF off-chain)
- [x] Deploy scripts automatizados (setup-all.sh)
- [x] Documentação completa do sistema
- [x] Testes unitários dos módulos (28 testes - 100% passando)
- [x] Rede Besu PoA (QBFT) com 4 validators
- [x] Scripts de queries JSON-RPC
- [x] Collection Postman para testes

### 🚧 **Em Desenvolvimento**
- [ ] Implementar backend completo (Node.js + PostgreSQL)
  - [ ] API REST para registro de usuários
  - [ ] Associação CPF ↔ Wallet
  - [ ] Worker para sincronização de eventos blockchain
  - [ ] Sistema KYC
- [ ] Testes de integração end-to-end
- [ ] Interface web (frontend React/Vue)

### 🔮 **Planejado**
- [ ] Integração com APIs externas (Receita Federal, Cartórios)
- [ ] Sistema de notificações
- [ ] Dashboard administrativo
- [ ] Auditoria de segurança
- [ ] Documentação de APIs
- [ ] Deploy em testnet pública

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Aqui está como você pode ajudar:

### **Como Contribuir**

1. **Fork o projeto** no GitHub
2. **Clone seu fork** localmente
   ```bash
   git clone https://github.com/seu-usuario/besu-property-ledger.git
   cd besu-property-ledger
   ```
3. **Crie uma branch** para sua feature/fix
   ```bash
   git checkout -b feature/minha-nova-funcionalidade
   ```
4. **Faça suas alterações** e teste
   ```bash
   forge test -vv  # Certifique-se que todos os testes passam
   ```
5. **Commit suas mudanças** com mensagens claras
   ```bash
   git commit -m 'feat: adiciona nova funcionalidade X'
   ```
6. **Push para seu fork**
   ```bash
   git push origin feature/minha-nova-funcionalidade
   ```
7. **Abra um Pull Request** com descrição detalhada

### **Áreas para Contribuir**

- 🧪 Adicionar mais testes unitários
- 📝 Melhorar documentação
- 🐛 Corrigir bugs
- ✨ Implementar novas features
- 🔐 Melhorias de segurança
- ⚡ Otimizações de gas
- 🎨 Melhorias de interface (quando o frontend for implementado)

### **Diretrizes**

- Siga o estilo de código existente
- Adicione testes para novas funcionalidades
- Atualize a documentação conforme necessário
- Mantenha commits pequenos e focados
- Use mensagens de commit descritivas

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 📞 Suporte

### **Recursos Disponíveis**

📚 **Documentação:**
- [Arquitetura do Sistema](./docs/ARQUITETURA.md)
- [Fluxo Completo](./docs/guias/FLUXO_COMPLETO.md)
- [Guia de Scripts](./docs/referencias/SCRIPTS.md)
- [Documentação de Testes](./docs/referencias/TESTES.md)

🔍 **Troubleshooting Comum:**

1. **Erro ao conectar na rede Besu:**
   - Verifique: `cd docker/besu && docker compose ps`
   - Solução: `docker compose down && docker compose up -d`

2. **Contratos não deployados:**
   - Verifique: `cat deployed-addresses.txt`
   - Solução: `./script/setup/deploy-contracts.sh`

3. **Testes falhando:**
   - Solução: `forge clean && forge build && forge test`

4. **Erro de compilação:**
   - Verifique: `forge --version`
   - Solução: `foundryup` para atualizar Foundry

📝 **Reportar Problemas:**
- Abra uma [issue](../../issues) com detalhes do erro
- Inclua logs relevantes e versões das ferramentas

---

## 🙏 Agradecimentos

- [T-REX (TokenySolutions)](https://github.com/TokenySolutions/T-REX) - ERC-3643 implementation
- [OpenZeppelin](https://openzeppelin.com/) - Smart contract libraries
- [Hyperledger Besu](https://besu.hyperledger.org/) - Enterprise Ethereum client
- [Foundry](https://getfoundry.sh/) - Ethereum development toolkit
