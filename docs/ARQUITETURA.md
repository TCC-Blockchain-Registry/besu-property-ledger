# 🏗️ Arquitetura do Sistema

## 📊 Diagrama de Contratos

```
┌─────────────────────────────────────────────────────────────────────┐
│                        HYPERLEDGER BESU (PoA)                       │
│                     4 Validators - QBFT Consensus                   │
│                         Zero Gas (zeroBaseFee)                      │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        │                           │                           │
┌───────▼─────────┐       ┌─────────▼────────┐       ┌─────────▼────────┐
│  IDENTITY LAYER │       │  COMPLIANCE      │       │  TOKEN LAYER     │
│   (On-Chain)    │       │  LAYER           │       │                  │
│                 │       │                  │       │                  │
│ ┌─────────────┐ │       │ ┌──────────────┐ │       │ ┌──────────────┐ │
│ │Identity     │ │       │ │Modular       │ │       │ │SecurityToken │ │
│ │Registry     │ │       │ │Compliance    │ │       │ │(ERC-3643)    │ │
│ │(T-REX)      │ │       │ │              │ │       │ │              │ │
│ │             │ │       │ │• addModule   │ │       │ │• transfer    │ │
│ │• register   │ │       │ │• canTransfer │ │       │ │• mint        │ │
│ │• isVerified │ │◄──────┼─│• transferred │─┼───────┤• balanceOf   │ │
│ └─────────────┘ │       │ └──────┬───────┘ │       │ └──────────────┘ │
│                 │       │        │         │       │                  │
│ ┌─────────────┐ │       │   ┌────▼────┐    │       │                  │
│ │OnchainID    │ │       │   │Modules  │    │       │                  │
│ │(Identity    │ │       │   └────┬────┘    │       │                  │
│ │ Contract)   │ │       │        │         │       │                  │
│ │             │ │       │   ┌────▼────────┐│       │                  │
│ │• addClaim   │ │       │   │Approvals    ││       │                  │
│ └─────────────┘ │       │   │Module       ││       │                  │
│                 │       │   │             ││       │                  │
└─────────────────┘       │   │• approve()  ││       └──────────────────┘
                          │   │• moduleCheck││
        ┌─────────────────┤   └─────────────┘│
        │   BACKEND       │                  │
        │  (Off-Chain)    │   ┌─────────────┐│
        │                 │   │RegistryMD   ││
        │ • PostgreSQL    │   │Compliance   ││
        │ • API REST      │   │             ││
        │ • Worker        │   │• register   ││
        │                 │   │  Property   ││
        │ CPF ↔ Wallet    │   │• moduleCheck││
        └─────────────────┘   └─────────────┘│
                          └──────────────────┘
```

---

## 🔄 Fluxo de Transferência Detalhado

```
┌─────────┐                                                    ┌─────────┐
│ Alice   │                                                    │   Bob   │
│(Seller) │                                                    │ (Buyer) │
└────┬────┘                                                    └────┬────┘
     │                                                              │
     │ 1. Inicia transferência                                     │
     │    securityToken.transfer(bob, amount)                      │
     │                                                              │
     ▼                                                              │
┌─────────────────────────────────────────────────────────────────┴────┐
│                         SecurityToken._beforeTokenTransfer           │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ 1. Verifica identidades                                      │    │
│  │    identityRegistry.isVerified(alice) ✓                      │    │
│  │    identityRegistry.isVerified(bob) ✓                        │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ 2. Valida compliance (chama todos os módulos)               │    │
│  │    compliance.canTransfer(alice, bob, amount)               │    │
│  └───────────────────┬─────────────────────────────────────────┘    │
└────────────────────────┼──────────────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────────────┐
        │      ModularCompliance.canTransfer         │
        │                                            │
        │  Para cada módulo ativo:                  │
        │  • ApprovalsModule.moduleCheck()          │
        │  • RegistryMDCompliance.moduleCheck()     │
        └────────────┬───────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────────┐    ┌──────────────────────┐
│ ApprovalsModule  │    │ RegistryMDCompliance │
│                  │    │                      │
│ ✓ Prefeitura     │    │ ✓ Matrícula existe   │
│ ✓ Cartório       │    │ ✓ isRegular = true   │
│ ✓ IF             │    │                      │
└──────────────────┘    └──────────────────────┘
        │                         │
        └────────────┬────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │  Todas validações OK?  │
        │        SIM ✓           │
        └────────────┬───────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │  Transferência executada           │
        │  balanceOf[alice] -= amount        │
        │  balanceOf[bob] += amount          │
        └────────────┬───────────────────────┘
                     │
                     ▼
        ┌─────────────────────────────────────┐
        │ SecurityToken._afterTokenTransfer   │
        │                                     │
        │ compliance.transferred(alice,bob,amt)│
        └────────────┬────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────────┐    ┌──────────────────────┐
│ ApprovalsModule  │    │ RegistryMDCompliance │
│ .moduleTransfer  │    │ .moduleTransfer      │
│ Action()         │    │ Action()             │
│                  │    │                      │
│ • Limpa          │    │ • (sem ação)         │
│   aprovações     │    │                      │
└──────────────────┘    └──────────────────────┘
        │
        │
        ▼
┌─────────────────────────┐
│  Transferência completa │
│  Bob agora possui token │
└─────────────────────────┘
```

---

## 📦 Contratos e Responsabilidades

### **1. SecurityToken (ERC-3643)**

```solidity
contract SecurityToken is ERC20, AccessControl {
    IIdentityRegistry public identityRegistry;
    IModularCompliance public compliance;
    
    // Hooks do ERC20
    _beforeTokenTransfer() {
        // Valida identidades
        // Valida compliance (todos os módulos)
    }
    
    _afterTokenTransfer() {
        // Notifica módulos da transferência
    }
}
```

**Responsabilidades:**
- ✅ Gerenciar balances (ERC20)
- ✅ Validar identidades antes de transferência
- ✅ Orquestrar validação de compliance
- ✅ Notificar módulos após transferência

---

### **2. ModularCompliance (T-REX)**

```solidity
contract ModularCompliance {
    address[] modules;
    
    function canTransfer(from, to, value) returns (bool) {
        for (module in modules) {
            if (!module.moduleCheck(from, to, value, this)) {
                return false;
            }
        }
        return true;
    }
    
    function transferred(from, to, value) {
        for (module in modules) {
            module.moduleTransferAction(from, to, value);
        }
    }
}
```

**Responsabilidades:**
- ✅ Gerenciar lista de módulos ativos
- ✅ Orquestrar chamadas `moduleCheck` (validação)
- ✅ Orquestrar chamadas `moduleTransferAction` (pós-transferência)

---

### **3. ApprovalsModule**

```solidity
contract ApprovalsModule is AbstractModule {
    mapping(bytes32 => uint256) approvals; // bitmask
    bytes32[] groups;
    uint256 requiredMask;
    
    function approve(from, to, value, compliance) {
        bytes32 hash = keccak256(from, to, value, compliance);
        uint256 bits = getGroupBits(msg.sender);
        approvals[hash] |= bits;
    }
    
    function moduleCheck(from, to, value, compliance) returns (bool) {
        bytes32 hash = keccak256(from, to, value, compliance);
        return (approvals[hash] & requiredMask) == requiredMask;
    }
    
    function moduleTransferAction(from, to, value) {
        bytes32 hash = keccak256(from, to, value, msg.sender);
        delete approvals[hash]; // limpa aprovações
    }
}
```

**Responsabilidades:**
- ✅ Armazenar aprovações por transferência específica
- ✅ Validar se todas as aprovações necessárias estão presentes
- ✅ Limpar aprovações após transferência (não reutilizáveis)
- ✅ Gerenciar grupos dinâmicos de aprovadores

---

### **4. RegistryMDCompliance**

```solidity
contract RegistryMDCompliance is AbstractModule {
    struct PropertyInfo {
        uint256 matriculaId;
        // ... outros campos
        bool isRegular;
    }
    
    mapping(uint256 => PropertyInfo) properties;
    
    function registerProperty(PropertyInfo calldata info) {
        properties[info.matriculaId] = info;
    }
    
    function moduleCheck(from, to, matriculaId, compliance) returns (bool) {
        PropertyInfo storage p = properties[matriculaId];
        return p.matriculaId != 0 && p.isRegular;
    }
}
```

**Responsabilidades:**
- ✅ Armazenar dados cadastrais dos imóveis
- ✅ Validar se imóvel existe e está regular
- ✅ Permitir atualização de dados por cartório

---

### **5. IdentityRegistry (T-REX)**

```solidity
contract IdentityRegistry {
    mapping(address => Identity) identities;
    mapping(address => bool) verified;
    
    function registerIdentity(address user, Identity id, uint16 country) {
        identities[user] = id;
        verified[user] = true;
    }
    
    function isVerified(address user) returns (bool) {
        return verified[user];
    }
}
```

**Responsabilidades:**
- ✅ Registrar identidades OnchainID
- ✅ Validar se endereço tem identidade verificada
- ✅ Integrar com claim system

---

### **6. Backend (Off-Chain) - CPF ↔ Wallet**

```javascript
// PostgreSQL Database
TABLE users {
    id: serial,
    cpf: varchar(11) ENCRYPTED,
    wallet_address: varchar(42),
    status: varchar(20),
    onchain_registered: boolean
}

// API REST
POST /api/kyc/register     // Registrar CPF ↔ wallet
GET  /api/kyc/status/:addr // Consultar status
POST /api/kyc/approve      // Aprovar KYC (admin)

// Worker (cron job)
processApprovedUsers() {
    // 1. SELECT users WHERE status='approved' AND onchain_registered=false
    // 2. Deploy Identity contract
    // 3. identityRegistry.registerIdentity()
    // 4. UPDATE users SET onchain_registered=true
}
```

**Responsabilidades:**
- ✅ Associar CPF ↔ endereço (banco de dados privado)
- ✅ Validar KYC (API Receita Federal, documentos)
- ✅ Sincronizar com blockchain (worker automático)
- ✅ LGPD compliance (dados podem ser deletados)

---

## 🔐 Camadas de Segurança

### **Layer 1: Network (Besu PoA)**
```
✓ Consenso QBFT (Byzantine Fault Tolerant)
✓ Validators autorizados
✓ Imutabilidade da blockchain
```

### **Layer 2: Identity (ERC-3643)**
```
✓ OnchainID (identidade verificada)
✓ Claims assinadas por trusted issuers
✓ CPF off-chain (máxima privacidade)
```

### **Layer 3: Compliance (Modular)**
```
✓ Aprovações multi-entidades (3 de 3)
✓ Validação de regularidade do imóvel
✓ Módulos auditáveis e extensíveis
```

### **Layer 4: Access Control (Roles)**
```
✓ REGISTRAR_ROLE → apenas cartório
✓ ISSUER_ROLE → apenas admin
✓ GRUPO_ROLE → prefeitura/cartório/IF separados
```

---

## 📈 Escalabilidade

### **Modular Compliance**
- ✅ **Adicionar novos módulos** sem alterar contratos existentes
- ✅ **Habilitar/desabilitar** módulos dinamicamente
- ✅ **Validações paralelas** (cada módulo é independente)

### **Grupos de Aprovação Dinâmicos**
- ✅ **Adicionar novos grupos** (ex: Receita Federal, Meio Ambiente)
- ✅ **Configurar máscaras** (ex: exigir 2 de 4, 3 de 5)
- ✅ **Roles flexíveis** (um endereço pode ter múltiplos grupos)

### **Off-chain + On-chain**
- ✅ **KYC off-chain** (escala infinita, privado)
- ✅ **Registro on-chain** (apenas hash, imutável)
- ✅ **Backend orquestra** aprovações e notificações

---

## 🎯 Pontos de Extensão

### **1. Novos Módulos de Compliance**
```solidity
contract MeioAmbienteModule is AbstractModule {
    // Validar licenças ambientais antes de transferência
    function moduleCheck(...) returns (bool) {
        return hasEnvironmentalLicense(matriculaId);
    }
}
```

### **2. Tokenização Fracionada**
```solidity
// Permitir múltiplos proprietários (cotas)
securityToken.mint(owner1, 0.3 ether); // 30%
securityToken.mint(owner2, 0.7 ether); // 70%
```

### **3. Histórico On-Chain**
```solidity
contract TransferHistory {
    struct Transfer {
        address from;
        address to;
        uint256 value;
        uint256 timestamp;
    }
    
    Transfer[] public history;
}
```

### **4. Integração Oracle**
```solidity
// Validar IPTU em dia via Chainlink
contract IPTUOracle {
    function isIPTUPaid(matriculaId) returns (bool);
}
```

---

## 🔄 Ciclo de Vida de uma Transferência

| Fase | Ator | Ação | Resultado |
|------|------|------|-----------|
| 1. Negociação | Alice + Bob | Off-chain | Acordo de venda |
| 2. Solicitação | Alice/Bob | Solicita aprovações | Prefeitura/Cartório/IF notificados |
| 3. Análise | Entidades | Verifica documentos off-chain | Aprovado/Rejeitado |
| 4. Aprovação On-Chain | Entidades | `approve(alice,bob,matricula,compliance)` | Bitmask atualizado |
| 5. Execução | Alice | `transfer(bob, amount)` | Token transferido |
| 6. Pós-Transferência | Sistema | Limpa aprovações | Estado resetado |
| 7. Atualização Cadastral | Cartório | `updateProperty()` (opcional) | Proprietário atualizado |

---

## 📊 Métricas e Auditoria

### **On-Chain (público)**
- ✅ Transferências (eventos `Transfer`)
- ✅ Aprovações (eventos `Approved`)
- ✅ Registros (eventos `PropertyRegistered`)

### **Consultas**
```solidity
// Histórico de transferências
eventos = securityToken.getPastEvents('Transfer', {fromBlock: 0})

// Status de aprovações
mask = approvalsModule.approvalsByTransferHash(hash)

// Dados do imóvel
property = registryModule.getProperty(matriculaId)
```

---

## 🚀 Performance

### **Gas Otimizado**
- ✅ `via-ir` habilitado (Foundry)
- ✅ Optimizer ativo (200 runs)
- ✅ Zero gas price (Besu zeroBaseFee)

### **Escalabilidade Vertical**
- ✅ Módulos independentes (paralelizável)
- ✅ Storage otimizado (bitmasks, packed structs)
- ✅ Eventos para indexação off-chain

### **Escalabilidade Horizontal**
- ✅ Layer 2 (Polygon, Optimism) compatível
- ✅ Sidechain (Besu privada) isolada
- ✅ Cross-chain bridges (futuro)

