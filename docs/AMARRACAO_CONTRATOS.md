# 🔗 Amarração dos Contratos (Compliance Flow)

## 📋 Visão Geral

Este documento explica como os contratos estão **amarrados** entre si, garantindo que:
- ✅ Todas transferências passem por validação de compliance
- ✅ Propriedades só sejam transferidas se regulares
- ✅ Aprovações sejam obrigatórias antes da transferência
- ✅ Freeze e Pause bloqueiem operações quando necessário

---

## 🏗️ Arquitetura dos Contratos

```
┌─────────────────────────────────────────────────────────────┐
│                    PropertyTitleTREX.sol                    │
│                  (Token ERC-3643 Full)                      │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ transferProperty(to, matricula)                       │ │
│  │   └─> transfer(to, 1)  ◄── Chama Token.sol (T-REX)  │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      Token.sol (T-REX)                      │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ function transfer(address _to, uint256 _amount)       │ │
│  │   1. require(!_frozen[_to] && !_frozen[msg.sender])  │ │
│  │   2. require(_amount <= balanceOf(msg.sender))       │ │
│  │   3. if (_tokenCompliance.canTransfer(...)) {        │ │ ◄─┐
│  │        _transfer(msg.sender, _to, _amount);          │ │   │
│  │        _tokenCompliance.transferred(...);            │ │   │
│  │      }                                                │ │   │
│  └───────────────────────────────────────────────────────┘ │   │
└─────────────────────────────────────────────────────────────┘   │
                            │                                     │
                            ▼                                     │
┌─────────────────────────────────────────────────────────────┐  │
│               ModularCompliance.sol (T-REX)                 │  │
│                                                             │  │
│  ┌───────────────────────────────────────────────────────┐ │  │
│  │ function canTransfer(from, to, value) returns (bool) │ │  │
│  │   for (uint256 i = 0; i < _modules.length; i++) {    │ │  │
│  │     if (!IModule(_modules[i]).moduleCheck(...)) {    │ │◄─┘
│  │       return false;  // Bloqueia transferência       │ │
│  │     }                                                 │ │
│  │   }                                                   │ │
│  │   return true;  // Libera transferência              │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
              │                            │
              ▼                            ▼
┌──────────────────────────┐  ┌──────────────────────────────┐
│  ApprovalsModule.sol     │  │  RegistryMDCompliance.sol    │
│  (Módulo Customizado)    │  │  (Módulo Customizado)        │
│                          │  │                              │
│  moduleCheck():          │  │  moduleCheck():              │
│  ✅ Config existe?       │  │  ✅ Propriedade existe?      │
│  ✅ Aprovadores OK?      │  │  ✅ Propriedade regular?     │
│  ✅ Comprador aceitou?   │  │  ❌ Bloqueia se irregular    │
│  ❌ Bloqueia se não      │  │                              │
└──────────────────────────┘  └──────────────────────────────┘
```

---

## 🔄 Fluxo Completo de Transferência

### **Passo a Passo**

```
1. USUÁRIO CHAMA:
   propertyTitleTREX.transferProperty(bob, 123456)

2. PropertyTitleTREX VALIDA:
   ✅ propertyExists[123456] == true
   ✅ propertyOwner[123456] == msg.sender
   ✅ !isFrozen(msg.sender)
   ✅ !isFrozen(bob)

3. PropertyTitleTREX CHAMA:
   Token.transfer(bob, 1)  // T-REX

4. Token (T-REX) VALIDA:
   ✅ !paused()
   ✅ !_frozen[bob] && !_frozen[msg.sender]
   ✅ _amount <= balanceOf(msg.sender) - _frozenTokens[msg.sender]
   ✅ _tokenIdentityRegistry.isVerified(bob)
   
5. Token CHAMA:
   ModularCompliance.canTransfer(msg.sender, bob, 1)

6. ModularCompliance ITERA MÓDULOS:
   
   a) ApprovalsModule.moduleCheck(from, to, 1, compliance):
      ✅ transferConfigs[hash].isConfigured == true
      ✅ approvalCount == requiredApprovers.length
      ✅ buyerAccepted == true
      → return true
   
   b) RegistryMDCompliance.moduleCheck(from, to, 1, compliance):
      ✅ properties[123456].matriculaId != 0
      ✅ properties[123456].isRegular == true
      → return true
   
   → ModularCompliance.canTransfer() return true

7. Token EXECUTA:
   _transfer(msg.sender, bob, 1)

8. Token NOTIFICA:
   ModularCompliance.transferred(msg.sender, bob, 1)

9. ModularCompliance ITERA MÓDULOS:
   ApprovalsModule.moduleTransferAction():
     → delete transferConfigs[hash]  // Limpa aprovações

10. PropertyTitleTREX ATUALIZA:
    _removePropertyFromOwner(msg.sender, 123456)
    propertyOwner[123456] = bob
    _addPropertyToOwner(bob, 123456)
    emit PropertyTransferred(123456, msg.sender, bob)

✅ TRANSFERÊNCIA COMPLETA!
```

---

## 🔍 Validações em Cada Camada

### **Camada 1: PropertyTitleTREX**

```solidity
function transferProperty(address to, uint256 matricula) external {
    require(propertyExists[matricula], "Property not issued");
    require(propertyOwner[matricula] == msg.sender, "Not property owner");
    require(!this.isFrozen(msg.sender), "Sender account is frozen");
    require(!this.isFrozen(to), "Recipient account is frozen");
    
    transfer(to, 1); // ◄── Chama Token T-REX
    
    // Atualizar mapeamentos...
}
```

**Validações:**
- ✅ Propriedade existe on-chain
- ✅ Remetente é o dono registrado
- ✅ Contas não estão congeladas

---

### **Camada 2: Token (T-REX)**

```solidity
function transfer(address _to, uint256 _amount) public override whenNotPaused returns (bool) {
    require(!_frozen[_to] && !_frozen[msg.sender], "wallet is frozen");
    require(_amount <= balanceOf(msg.sender) - (_frozenTokens[msg.sender]), "Insufficient Balance");
    
    if (_tokenIdentityRegistry.isVerified(_to) && 
        _tokenCompliance.canTransfer(msg.sender, _to, _amount)) { // ◄── Chama Compliance
        _transfer(msg.sender, _to, _amount);
        _tokenCompliance.transferred(msg.sender, _to, _amount);
        return true;
    }
    revert("Transfer not possible");
}
```

**Validações:**
- ✅ Sistema não está pausado (`whenNotPaused`)
- ✅ Carteiras não estão congeladas
- ✅ Saldo suficiente (excluindo tokens congelados)
- ✅ Destinatário tem identidade verificada
- ✅ **Compliance autoriza** (`canTransfer`)

---

### **Camada 3: ModularCompliance**

```solidity
function canTransfer(address _from, address _to, uint256 _value) external view override returns (bool) {
    uint256 length = _modules.length;
    for (uint256 i = 0; i < length; i++) {
        if (!IModule(_modules[i]).moduleCheck(_from, _to, _value, address(this))) {
            return false; // ❌ Um módulo bloqueou
        }
    }
    return true; // ✅ Todos módulos aprovaram
}
```

**Validações:**
- ✅ Itera **todos** os módulos registrados
- ✅ Se **um módulo falhar**, bloqueia transferência
- ✅ Todos módulos devem retornar `true`

---

### **Camada 4a: ApprovalsModule**

```solidity
function moduleCheck(address _from, address _to, uint256 _value, address _compliance)
    external view override returns (bool)
{
    bytes32 h = _getTransferHash(_from, _to, _value, _compliance);
    TransferConfig storage config = transferConfigs[h];
    
    if (!config.isConfigured) return false;
    if (config.approvalCount != config.requiredApprovers.length) return false;
    if (!config.buyerAccepted) return false;
    
    return true;
}
```

**Validações:**
- ✅ Transferência foi configurada (`configureTransfer`)
- ✅ Todos aprovadores aprovaram
- ✅ Comprador aceitou

---

### **Camada 4b: RegistryMDCompliance**

```solidity
function moduleCheck(address, address, uint256 matriculaId, address) 
    external view override returns (bool) 
{
    PropertyInfo storage p = properties[matriculaId];
    if (p.matriculaId == 0) revert PropertyNotRegistered(matriculaId);
    if (!p.isRegular) revert PropertyTransferNotAllowed(matriculaId);
    return true;
}
```

**Validações:**
- ✅ Propriedade está registrada
- ✅ Propriedade está regular (`isRegular == true`)

---

## 🚫 Quando a Transferência é Bloqueada?

| Camada | Motivo do Bloqueio | Mensagem de Erro |
|--------|-------------------|------------------|
| **PropertyTitleTREX** | Propriedade não existe | `"Property not issued"` |
| | Remetente não é dono | `"Not property owner"` |
| | Remetente congelado | `"Sender account is frozen"` |
| | Destinatário congelado | `"Recipient account is frozen"` |
| **Token (T-REX)** | Sistema pausado | `"Pausable: paused"` |
| | Carteira congelada | `"wallet is frozen"` |
| | Saldo insuficiente | `"Insufficient Balance"` |
| | Destinatário não verificado | `"Transfer not possible"` |
| **ApprovalsModule** | Transferência não configurada | `moduleCheck return false` |
| | Faltam aprovações | `moduleCheck return false` |
| | Comprador não aceitou | `moduleCheck return false` |
| **RegistryMDCompliance** | Propriedade não registrada | `PropertyNotRegistered(matriculaId)` |
| | Propriedade irregular | `PropertyTransferNotAllowed(matriculaId)` |

---

## 🎯 Exemplo Prático

### **Cenário: Transferir Imóvel 123456 de Alice para Bob**

#### **Pré-requisitos:**

```solidity
// 1. Propriedade registrada
registryMDCompliance.registerProperty({
    matriculaId: 123456,
    folha: 1,
    comarca: "São Paulo",
    endereco: "Rua X, 100",
    metragem: 150,
    proprietario: alice,
    matriculaOrigem: 0,
    tipo: PropertyType.URBANO,
    isRegular: true
});

// 2. Propriedade emitida
propertyTitleTREX.issueProperty(alice, 123456);

// 3. Identidades verificadas
identityRegistry.registerIdentity(alice, aliceIdentity, 76);
identityRegistry.registerIdentity(bob, bobIdentity, 76);
```

#### **Configurar Transferência:**

```solidity
// Backend configura aprovadores
address[] memory approvers = [prefeitura, cartorio, instituicaoFinanceira];
approvalsModule.configureTransfer(
    alice,    // from
    bob,      // to
    1,        // value (1 token)
    compliance,
    approvers
);
```

#### **Aprovar Transferência:**

```solidity
// 1. Prefeitura aprova (libera IPTU)
approvalsModule.approve(alice, bob, 1, compliance); // msg.sender = prefeitura

// 2. Cartório aprova (valida documentos)
approvalsModule.approve(alice, bob, 1, compliance); // msg.sender = cartorio

// 3. IF aprova (confirma pagamento off-chain)
approvalsModule.approve(alice, bob, 1, compliance); // msg.sender = IF
```

#### **Comprador Aceita:**

```solidity
// Bob aceita receber o imóvel
approvalsModule.acceptTransfer(alice, 1, compliance); // msg.sender = bob
```

#### **Executar Transferência:**

```solidity
// Alice transfere (agora está autorizado)
propertyTitleTREX.transferProperty(bob, 123456); // msg.sender = alice

// ✅ Fluxo completo executado
// ✅ Todos os módulos validaram
// ✅ Transferência bem-sucedida
```

---

## 🔐 Bypass de Compliance (Forced Transfer)

Em casos de **emergência** ou **recuperação**, agentes podem forçar transferências que **bypassam compliance**:

```solidity
// Agente força transferência (ignora aprovações, freeze)
propertyTitleTREX.forcedTransferProperty(
    alice,   // dono atual
    bob,     // novo dono
    123456   // matrícula
);
```

**Quando usar:**
- 🔑 Perda de chave privada (recuperação)
- ⚖️ Ordem judicial
- 👨‍👩‍👧 Herança (após validação legal)
- 🔧 Correção de erros administrativos

---

## 📊 Resumo da Amarração

```
╔═══════════════════════════════════════════════════════════════╗
║              FLUXO DE VALIDAÇÃO (Top-Down)                   ║
╠═══════════════════════════════════════════════════════════════╣
║                                                              ║
║  1. PropertyTitleTREX.transferProperty()                    ║
║     ├─ Valida: exists, owner, freeze                        ║
║     └─ Chama: Token.transfer()                              ║
║                                                              ║
║  2. Token.transfer() [T-REX]                                ║
║     ├─ Valida: pause, freeze, balance, identity             ║
║     └─ Chama: ModularCompliance.canTransfer()               ║
║                                                              ║
║  3. ModularCompliance.canTransfer()                         ║
║     ├─ Itera: todos módulos                                 ║
║     └─ Chama: cada módulo.moduleCheck()                     ║
║                                                              ║
║  4. ApprovalsModule.moduleCheck()                           ║
║     ├─ Valida: config, approvals, buyer acceptance          ║
║     └─ Return: true/false                                   ║
║                                                              ║
║  5. RegistryMDCompliance.moduleCheck()                      ║
║     ├─ Valida: registered, isRegular                        ║
║     └─ Return: true/false                                   ║
║                                                              ║
║  ✅ SE TODOS = TRUE: Transferência executada                ║
║  ❌ SE UM = FALSE: Transferência bloqueada                  ║
║                                                              ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 📚 Referências

- [`PropertyTitleTREX.sol`](../src/token/PropertyTitleTREX.sol) - Token principal
- [`ApprovalsModule.sol`](../src/compliance/modules/ApprovalsModule.sol) - Módulo de aprovações
- [`RegistryMDCompliance.sol`](../src/compliance/modules/RegistryMDCompliance.sol) - Módulo de registro
- [T-REX Token.sol](https://github.com/TokenySolutions/T-REX/blob/main/contracts/token/Token.sol) - Implementação base
- [T-REX ModularCompliance.sol](https://github.com/TokenySolutions/T-REX/blob/main/contracts/compliance/modular/ModularCompliance.sol) - Sistema modular

---

## ✅ Checklist de Amarração

- ✅ PropertyTitleTREX chama Token.transfer()
- ✅ Token.transfer() chama ModularCompliance.canTransfer()
- ✅ ModularCompliance itera todos os módulos
- ✅ ApprovalsModule valida aprovações
- ✅ RegistryMDCompliance valida regularidade
- ✅ Freeze bloqueia na camada Token
- ✅ Pause bloqueia na camada Token
- ✅ Identity verificada na camada Token
- ✅ Forced Transfer bypassa compliance
- ✅ Eventos emitidos em cada camada

