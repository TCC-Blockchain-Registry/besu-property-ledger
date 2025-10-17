# 🔒 Features de Freeze e Pause (T-REX Full)

## 📋 Visão Geral

O **PropertyTitleTREX** herda todas as funcionalidades regulatórias do T-REX Token, incluindo:
- 🔒 **Freeze** - Congelar contas específicas
- ⏸️ **Pause** - Pausar todas as transferências globalmente
- 🚫 **Partial Freeze** - Limitar parcialmente transferências
- ⚡ **Forced Transfer** - Transferências forçadas por agentes
- 📦 **Batch Operations** - Operações em lote

---

## 🔒 **Freeze (Congelamento de Contas)**

### **O Que É?**

Congelar (freeze) uma conta impede que ela realize **qualquer transferência**, seja como remetente ou destinatário.

```
Conta Congelada:
- ❌ Não pode ENVIAR tokens
- ❌ Não pode RECEBER tokens
- ✅ Pode ser consultada (balanceOf)
- ✅ Tokens permanecem na carteira
```

### **Quando Usar?**

| Cenário | Exemplo |
|---------|---------|
| **Disputa Judicial** | Imóvel em litígio - bloquear até decisão judicial |
| **Investigação** | Suspeita de fraude documental |
| **Pendências** | Documentos incompletos ou expirados |
| **Compliance** | Falha em verificação de KYC |
| **Bloqueio Temporário** | Atualizações cadastrais obrigatórias |

### **Como Funciona?**

#### **1. Congelar Conta Individual**

```solidity
// Congelar proprietário de um imóvel
propertyTitle.setAddressFrozen(ownerAddress, true);

// Descongelar
propertyTitle.setAddressFrozen(ownerAddress, false);
```

#### **2. Congelar Propriedade Específica**

```solidity
// Método customizado que congela o dono da propriedade
propertyTitle.freezeProperty(matriculaId, true); // congelar
propertyTitle.freezeProperty(matriculaId, false); // descongelar
```

#### **3. Congelar Múltiplas Propriedades (Batch)**

```solidity
uint256[] memory matriculas = [123456, 789012, 345678];
propertyTitle.batchFreezeProperties(matriculas, true); // congela todas
```

### **Consultar Status de Freeze**

```solidity
// Verificar se uma conta está congelada
bool frozen = propertyTitle.isFrozen(ownerAddress);

// Verificar se uma propriedade está congelada
bool frozen = propertyTitle.isPropertyFrozen(matriculaId);
```

### **Eventos Emitidos**

```solidity
// T-REX nativo
event AddressFrozen(address indexed addr, bool indexed isFrozen, address indexed owner);

// Customizado para propriedades
event PropertyFrozen(uint256 indexed matricula, bool frozen);
```

---

## ⏸️ **Pause (Pausar Sistema Globalmente)**

### **O Que É?**

Pausar (pause) o token interrompe **TODAS** as transferências do sistema, afetando **todos** os usuários.

```
Sistema Pausado:
- ❌ NINGUÉM pode transferir
- ✅ Consultas funcionam normalmente
- ✅ Agentes podem usar forcedTransfer (emergência)
- ✅ Reversível (unpause)
```

### **Quando Usar?**

| Cenário | Exemplo |
|---------|---------|
| **Emergência** | Bug crítico detectado no sistema |
| **Manutenção** | Upgrade de contratos de compliance |
| **Auditoria** | Snapshot para auditoria contábil |
| **Regulação** | Ordem judicial bloqueando o sistema |
| **Migração** | Migrando para nova versão do contrato |

### **Como Funciona?**

#### **1. Pausar o Sistema**

```solidity
// Apenas AGENT_ROLE pode pausar
propertyTitle.pause();
```

#### **2. Despausar o Sistema**

```solidity
// Apenas AGENT_ROLE pode despausar
propertyTitle.unpause();
```

#### **3. Consultar Status**

```solidity
// Verificar se sistema está pausado
bool paused = propertyTitle.paused();
bool paused = propertyTitle.isTransferPaused(); // método customizado
```

### **Eventos Emitidos**

```solidity
event Paused(address account);
event Unpaused(address account);
```

---

## 🚫 **Partial Freeze (Congelamento Parcial)**

### **O Que É?**

Limita a quantidade que uma conta pode transferir, sem bloqueá-la completamente.

```
Conta com Freeze Parcial de 1000 tokens:
- ✅ Pode transferir até 1000 tokens
- ❌ Transferências acima de 1000 bloqueadas
- ✅ Pode receber normalmente
```

### **Como Funciona?**

```solidity
// Definir limite de freeze parcial
propertyTitle.setPartialFrozen(userAddress, true);
propertyTitle.setFrozenAmount(userAddress, 1000); // limite em tokens

// Remover freeze parcial
propertyTitle.setPartialFrozen(userAddress, false);
```

### **Use Case Imobiliário**

```
Alice possui 5 propriedades (5 tokens):
- 3 imóveis em disputa (congelados parcialmente)
- 2 imóveis livres

Freeze parcial = 3 tokens
→ Alice só pode transferir 2 imóveis livres
```

---

## ⚡ **Forced Transfer (Transferência Forçada)**

### **O Que É?**

Agentes podem **forçar** transferências que normalmente seriam bloqueadas (freeze, pause, compliance).

```
Forced Transfer:
- ✅ Bypassa freeze
- ✅ Bypassa pause
- ✅ Bypassa compliance (opcional)
- ⚠️ Apenas AGENT_ROLE
```

### **Quando Usar?**

| Cenário | Exemplo |
|---------|---------|
| **Recuperação** | Usuário perdeu chave privada - recuperar tokens |
| **Ordem Judicial** | Tribunal ordena transferência forçada |
| **Herança** | Transferir propriedade de falecido para herdeiros |
| **Correção** | Erro administrativo - corrigir propriedade |
| **Emergência** | Sistema pausado mas transferência crítica necessária |

### **Como Funciona?**

#### **1. Transferência Forçada Padrão**

```solidity
// Forçar transferência (bypassa freeze/pause)
propertyTitle.forcedTransfer(
    fromAddress,
    toAddress,
    amount
);
```

#### **2. Transferência Forçada de Propriedade (Customizado)**

```solidity
// Método específico para propriedades
propertyTitle.forcedTransferProperty(
    fromAddress,
    toAddress,
    matriculaId
);
```

#### **3. Batch Forced Transfer**

```solidity
address[] memory fromAddresses = [0xAAA, 0xBBB, 0xCCC];
address[] memory toAddresses = [0xDDD, 0xEEE, 0xFFF];
uint256[] memory amounts = [1, 1, 1];

propertyTitle.batchForcedTransfer(fromAddresses, toAddresses, amounts);
```

### **Eventos Emitidos**

```solidity
event ForcedTransfer(address indexed from, address indexed to, uint256 value, address indexed agent);
```

---

## 📦 **Batch Operations (Operações em Lote)**

### **Vantagens**

- ⚡ **Eficiência**: Uma transação para N operações
- 💰 **Gas**: Menos overhead de transações
- 🔄 **Atomicidade**: Tudo ou nada (reverte se uma falhar)

### **Operações Disponíveis**

#### **1. Batch Transfer**

```solidity
address[] memory recipients = [alice, bob, carol];
uint256[] memory amounts = [1, 1, 1]; // 1 propriedade cada

propertyTitle.batchTransfer(recipients, amounts);
```

#### **2. Batch Forced Transfer**

```solidity
address[] memory from = [alice, bob];
address[] memory to = [carol, dave];
uint256[] memory amounts = [1, 1];

propertyTitle.batchForcedTransfer(from, to, amounts);
```

#### **3. Batch Freeze**

```solidity
uint256[] memory matriculas = [123456, 789012, 345678];
propertyTitle.batchFreezeProperties(matriculas, true); // congelar todas
```

#### **4. Batch Mint (Emissão em Lote)**

```solidity
address[] memory recipients = [alice, bob, carol];
uint256[] memory amounts = [1, 1, 1];

propertyTitle.batchMint(recipients, amounts);
```

---

## 🎯 **Fluxos Práticos**

### **Cenário 1: Disputa Judicial**

```
1. RECEBIMENTO: Notificação judicial sobre disputa do imóvel 123456

2. AÇÃO: Congelar propriedade
   propertyTitle.freezeProperty(123456, true);
   
3. RESULTADO:
   - Proprietário não pode transferir
   - Propriedade fica "bloqueada" até decisão
   
4. RESOLUÇÃO: Decisão judicial favorável ao proprietário
   propertyTitle.freezeProperty(123456, false);
   
5. ALTERNATIVA: Decisão ordena transferência forçada
   propertyTitle.forcedTransferProperty(alice, bob, 123456);
```

### **Cenário 2: Bug Crítico Detectado**

```
1. DETECÇÃO: Bug crítico em módulo de compliance

2. AÇÃO IMEDIATA: Pausar todo o sistema
   propertyTitle.pause();
   
3. RESULTADO:
   - Todas transferências bloqueadas
   - Usuários não podem mover propriedades
   - Sistema "congelado" temporariamente
   
4. CORREÇÃO: Deploy de compliance corrigido
   (contratos já possuem mecanismo de upgrade)
   
5. RETOMADA: Sistema volta ao normal
   propertyTitle.unpause();
```

### **Cenário 3: Perda de Chave Privada**

```
1. SITUAÇÃO: Alice perdeu acesso à carteira (perda de chave)

2. VALIDAÇÃO OFF-CHAIN:
   - Verificar identidade (documentos)
   - Validar propriedade (matrícula)
   - Nova carteira criada
   
3. AÇÃO: Transferência forçada (recuperação)
   propertyTitle.forcedTransferProperty(
       oldWallet,  // carteira perdida
       newWallet,  // nova carteira da Alice
       matriculaId
   );
   
4. RESULTADO: Alice recupera propriedade na nova carteira
```

### **Cenário 4: Pendências de Compliance**

```
1. DETECÇÃO: 10 proprietários com documentos vencidos

2. AÇÃO: Congelar todas as propriedades
   uint256[] memory matriculas = [123456, 789012, ...]; // 10 imóveis
   propertyTitle.batchFreezeProperties(matriculas, true);
   
3. NOTIFICAÇÃO: Backend notifica proprietários
   
4. REGULARIZAÇÃO: Proprietários atualizam documentos
   
5. LIBERAÇÃO: Descongelar individualmente conforme regularizam
   propertyTitle.freezeProperty(123456, false); // um por um
```

---

## 🔐 **Controle de Acesso (Roles)**

| Função | Role Necessária | Descrição |
|--------|----------------|-----------|
| `pause()` | `AGENT_ROLE` | Pausar sistema |
| `unpause()` | `AGENT_ROLE` | Despausar sistema |
| `setAddressFrozen()` | `AGENT_ROLE` | Congelar/descongelar conta |
| `freezeProperty()` | `AGENT_ROLE` | Congelar/descongelar propriedade |
| `forcedTransfer()` | `AGENT_ROLE` | Transferência forçada |
| `mint()` | `AGENT_ROLE` | Emitir tokens |
| `burn()` | `AGENT_ROLE` | Queimar tokens |
| `addAgent()` | `OWNER` | Adicionar novo agente |
| `removeAgent()` | `OWNER` | Remover agente |

### **Como Gerenciar Roles**

```solidity
// Adicionar agente (apenas owner)
propertyTitle.addAgent(newAgentAddress);

// Verificar se é agente
bool isAgent = propertyTitle.isAgent(address);

// Remover agente (apenas owner)
propertyTitle.removeAgent(agentAddress);
```

---

## 📊 **Comparação: PropertyTitle vs PropertyTitleTREX**

| Feature | PropertyTitle (Simples) | PropertyTitleTREX (Full) |
|---------|------------------------|--------------------------|
| **ERC-20** | ✅ | ✅ |
| **ERC-3643** | ⚠️ Parcial | ✅ 100% |
| **Identity** | ✅ | ✅ |
| **Compliance** | ✅ | ✅ |
| **Pause** | ❌ | ✅ |
| **Freeze** | ❌ | ✅ |
| **Partial Freeze** | ❌ | ✅ |
| **Forced Transfer** | ❌ | ✅ |
| **Batch Operations** | ❌ | ✅ |
| **Recovery** | ❌ | ✅ |
| **Complexidade** | 🟢 Baixa | 🟡 Média |
| **Gas Cost** | 🟢 Baixo | 🟡 Médio |
| **Features Regulatórias** | ❌ Limitadas | ✅ Completas |

---

## 🎓 **Resumo**

```
╔══════════════════════════════════════════════════════╗
║  PropertyTitleTREX = ERC-3643 Full Compliance       ║
║                                                      ║
║  ✅ Freeze - Bloquear contas específicas            ║
║  ✅ Pause - Pausar sistema globalmente              ║
║  ✅ Forced Transfer - Recuperação/emergência        ║
║  ✅ Batch Operations - Eficiência                   ║
║  ✅ Partial Freeze - Limites personalizados         ║
║                                                      ║
║  Use quando precisar de controle regulatório        ║
║  completo sobre as propriedades tokenizadas.        ║
╚══════════════════════════════════════════════════════╝
```

---

## 📚 **Referências**

- [ERC-3643 Specification](https://eips.ethereum.org/EIPS/eip-3643)
- [T-REX Documentation](https://github.com/TokenySolutions/T-REX)
- [T-REX Token Contract](https://github.com/TokenySolutions/T-REX/blob/main/contracts/token/Token.sol)
- [`PropertyTitleTREX.sol`](../src/token/PropertyTitleTREX.sol)

