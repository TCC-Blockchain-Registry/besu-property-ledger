# 🏠 Guia Completo: Registro e Transferência de Imóveis

## 📋 Índice

1. [Registro de Imóvel](#-1-registro-de-imóvel)
2. [Transferência de Imóvel](#-2-transferência-de-imóvel)
3. [Configuração de Aprovadores](#-3-configuração-de-aprovadores)
4. [Aceitação do Comprador](#-4-aceitação-do-comprador)
5. [Comandos Práticos](#-comandos-práticos)
6. [Roles e Permissões](#-roles-e-permissões)

---

## 🏗️ 1. Registro de Imóvel

### **Pré-requisitos**
- ✅ Proprietário tem wallet criada
- ✅ Proprietário passou por KYC (CPF validado off-chain)
- ✅ Cartório tem `REGISTRAR_ROLE`
- ✅ Admin tem `AGENT_ROLE`

### **Diagrama do Fluxo**

```
┌─────────────────────┐
│  1. Usuário cria    │ ◄── OFF-CHAIN
│     wallet          │     (MetaMask, etc.)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  2. KYC valida CPF  │ ◄── OFF-CHAIN
│     e documentos    │     (Backend + API)
│                     │     CPF ↔ wallet no DB
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  3. Backend/Worker  │ ◄── ON-CHAIN (automático)
│     registra        │     
│     identidade      │     • Identity.deploy()
│                     │     • identityRegistry.register()
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  4. Cartório        │ ◄── ON-CHAIN
│     registra        │
│     imóvel          │     • registryModule.registerProperty()
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  5. Admin emite     │ ◄── ON-CHAIN
│     título          │
│     propriedade     │     • propertyTitleTREX.issueProperty()
└─────────────────────┘
```

### **Passo a Passo Detalhado**

#### **Etapa 1.1: Registrar Identidade**

```solidity
// Executado automaticamente pelo backend worker após KYC aprovado
// (CPF ↔ wallet já está associado no banco de dados off-chain)

// 1. Criar Identity (OnchainID)
Identity ownerIdentity = new Identity(ownerAddress, false);

// 2. Registrar no IdentityRegistry (país 76 = Brasil)
identityRegistry.registerIdentity(ownerAddress, ownerIdentity, 76);
```

**Resultado:** Proprietário habilitado para receber tokens  
**Nota:** A associação CPF ↔ wallet fica no backend (ver `docs/backend/CPF_WALLET.md`)

#### **Etapa 1.2: Registrar Imóvel (Dados Cadastrais)**

```solidity
// Executado por REGISTRAR_ROLE (cartório)

RegistryMDCompliance.PropertyInfo memory property = RegistryMDCompliance.PropertyInfo({
    matriculaId: 123456,                            // ID único da matrícula
    folha: 100,                                     // Número da folha do cartório
    comarca: "São Paulo - 1ª Circunscrição",       // Comarca
    endereco: "Rua Exemplo, 123, Centro, SP",      // Endereço do imóvel
    metragem: 150,                                  // Área em m²
    proprietario: ownerAddress,                     // Endereço do dono (informativo)
    matriculaOrigem: 0,                             // 0 se original, ou ID anterior
    tipo: RegistryMDCompliance.PropertyType.URBANO, // URBANO, RURAL ou LITORAL
    isRegular: true                                 // Se está regular
});

registryModule.registerProperty(property);
```

**Campos Importantes:**
- `matriculaId`: ID único (chave primária)
- `isRegular`: Se pode ser transferido (sem pendências)
- `proprietario`: Informativo (posse real é no token)

#### **Etapa 1.3: Emitir Título de Propriedade (Token)**

```solidity
// Executado por AGENT_ROLE (admin/cartório)

// 1 token = 1 imóvel (indivisível)
propertyTitleTREX.issueProperty(ownerAddress, 123456); // matriculaId
```

**Resultado:** Proprietário possui token que representa o imóvel 123456

---

## 🔄 2. Transferência de Imóvel

### **Cenário:** Alice (vendedora) quer transferir imóvel (matrícula 123456) para Bob (comprador)

### **Diagrama do Fluxo Completo**

```
┌─────────────────────┐
│  1. Bob cria wallet │ ◄── OFF-CHAIN
│     e passa KYC     │     (se ainda não tem)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  2. Orchestrator    │ ◄── ON-CHAIN
│     configura       │     configureTransfer()
│     aprovadores     │     Define: [Pref, Cart, IF]
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  3. Prefeitura      │ ◄── ON-CHAIN
│     aprova          │     approve() ✓
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  4. Cartório        │ ◄── ON-CHAIN
│     aprova          │     approve() ✓
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  5. Instituição     │ ◄── ON-CHAIN
│     Financeira      │     approve() ✓
│     aprova          │     (confirmou pagamento off-chain)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  6. Bob ACEITA      │ ◄── ON-CHAIN
│     receber imóvel  │     acceptTransfer() ✓
│                     │     🔔 Notificação na carteira!
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  7. Alice executa   │ ◄── ON-CHAIN
│     transferência   │     transferProperty()
│                     │
│  Valida:            │
│  ✓ Identidades      │
│  ✓ 3 aprovações     │
│  ✓ Bob aceitou      │
│  ✓ Regularidade     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  8. Aprovações      │ ◄── ON-CHAIN (automático)
│     limpas          │     moduleTransferAction()
└─────────────────────┘
```

### **Passo a Passo Detalhado**

#### **Etapa 2.1: Bob Precisa Ter Identidade (se não tiver)**

```solidity
// Mesmo fluxo da Etapa 1.1
// 1. Backend já associou CPF ↔ wallet de Bob no banco de dados
// 2. Worker executou registro on-chain

Identity bobIdentity = new Identity(bobAddress, false);
identityRegistry.registerIdentity(bobAddress, bobIdentity, 76);
```

#### **Etapa 2.2: Configurar Aprovadores (Backend/Orchestrator)**

```solidity
// Executado por ORCHESTRATOR_ROLE (backend/admin)

// Definir lista de aprovadores necessários
address[] memory requiredApprovers = new address[](3);
requiredApprovers[0] = prefeituraAddress;
requiredApprovers[1] = cartorioAddress;
requiredApprovers[2] = instituicaoFinanceiraAddress;

approvalsModule.configureTransfer(
    aliceAddress,           // from (vendedora)
    bobAddress,             // to (comprador)
    1,                      // value (1 token)
    address(compliance),    // compliance contract
    requiredApprovers       // lista de aprovadores
);
```

**Observações:**
- Cada transferência pode ter aprovadores diferentes!
- Pode ser 1, 2, 3, 5+ aprovadores
- Backend decide baseado em regras de negócio

#### **Etapa 2.3: Cada Aprovador Aprova**

```solidity
// === Prefeitura aprova (libera IPTU) ===
approvalsModule.approve(aliceAddress, bobAddress, 1, address(compliance));
// msg.sender = prefeituraAddress

// === Cartório aprova (valida documentos) ===
approvalsModule.approve(aliceAddress, bobAddress, 1, address(compliance));
// msg.sender = cartorioAddress

// === IF aprova (confirma pagamento off-chain) ===
approvalsModule.approve(aliceAddress, bobAddress, 1, address(compliance));
// msg.sender = instituicaoFinanceiraAddress
```

**Validações automáticas:**
- Apenas endereços na lista `requiredApprovers` podem aprovar
- Cada aprovador pode aprovar apenas uma vez
- Transferência só passa quando TODOS aprovarem

#### **Etapa 2.4: Bob Aceita Receber o Imóvel**

```solidity
// Executado por Bob (comprador)
approvalsModule.acceptTransfer(
    aliceAddress,           // from (vendedora)
    1,                      // value (1 token)
    address(compliance)     // compliance
);
// msg.sender = bobAddress
```

**Como Bob é notificado?**

1. **Frontend monitora eventos:**
```javascript
approvalsModule.on('TransferConfigured', (hash, from, to, value, approvers) => {
    if (to === bobAddress) {
        // 🔔 Mostrar notificação na wallet de Bob
        showNotification({
            title: "Nova Proposta de Transferência",
            message: `${from} quer transferir imóvel (matrícula 123456)`,
            actions: ['Aceitar', 'Rejeitar']
        });
    }
});
```

2. **Backend envia notificação:**
```javascript
const filter = approvalsModule.filters.TransferConfigured(null, null, bobAddress);
approvalsModule.on(filter, async (hash, from, to, value, approvers) => {
    await sendEmail(bob.email, {
        subject: 'Nova Proposta de Transferência',
        body: 'Você recebeu uma proposta de transferência de imóvel...'
    });
});
```

**Resultado:** Bob confirmou que aceita receber o imóvel

#### **Etapa 2.5: Alice Executa a Transferência**

```solidity
// Executado por Alice (proprietária)
propertyTitleTREX.transferProperty(bobAddress, 123456); // matriculaId
```

**O que acontece internamente:**

1. **PropertyTitleTREX valida:**
   ```solidity
   require(propertyExists[123456]);
   require(propertyOwner[123456] == msg.sender);
   require(!isFrozen(alice) && !isFrozen(bob));
   ```

2. **Token.transfer() (T-REX) valida:**
   ```solidity
   require(!paused());
   require(identityRegistry.isVerified(alice) && identityRegistry.isVerified(bob));
   require(compliance.canTransfer(alice, bob, 1)); // ◄── CHAVE
   ```

3. **ModularCompliance.canTransfer() itera módulos:**
   ```solidity
   // a) ApprovalsModule.moduleCheck():
   //    ✓ config.isConfigured == true
   //    ✓ approvalCount == 3 (todos aprovaram)
   //    ✓ buyerAccepted == true (Bob aceitou)
   
   // b) RegistryMDCompliance.moduleCheck():
   //    ✓ properties[123456].matriculaId != 0 (existe)
   //    ✓ properties[123456].isRegular == true
   ```

4. **Transferência ocorre**

5. **ModularCompliance.transferred() executa:**
   ```solidity
   // ApprovalsModule.moduleTransferAction():
   delete transferConfigs[hash]; // Limpa aprovações
   ```

6. **PropertyTitleTREX atualiza:**
   ```solidity
   propertyOwner[123456] = bob;
   emit PropertyTransferred(123456, alice, bob);
   ```

**Resultado:** Bob agora possui o token (imóvel transferido) e a configuração foi limpa

---

## ⚙️ 3. Configuração de Aprovadores

### **Flexibilidade Total**

Cada transferência pode ter aprovadores diferentes, baseado em regras de negócio:

```javascript
// Backend (Node.js) decide dinamicamente:
function getRequiredApprovers(imovel, transacao) {
    let approvers = [CARTORIO]; // sempre cartório
    
    if (imovel.tipo === 'URBANO') {
        approvers.push(PREFEITURA); // IPTU
    }
    
    if (transacao.hasFinancing) {
        approvers.push(INSTITUICAO_FINANCEIRA);
    }
    
    if (imovel.isHistoric) {
        approvers.push(IPHAN); // patrimônio histórico
    }
    
    if (imovel.metragem > 10000) {
        approvers.push(INCRA); // imóvel rural grande
    }
    
    return approvers;
}
```

### **Exemplos de Configuração**

#### **Exemplo 1: Transferência Simples (1 aprovador)**
```solidity
configureTransfer(alice, bob, 1, compliance, [cartorioAddress]);
// Apenas cartório precisa aprovar
```

#### **Exemplo 2: Imóvel Urbano (2 aprovadores)**
```solidity
configureTransfer(alice, bob, 1, compliance, [prefeituraAddress, cartorioAddress]);
// Prefeitura + Cartório
```

#### **Exemplo 3: Imóvel Financiado (3 aprovadores)**
```solidity
configureTransfer(alice, bob, 1, compliance, [prefeituraAddress, cartorioAddress, ifAddress]);
// Prefeitura + Cartório + IF
```

#### **Exemplo 4: Imóvel Histórico (5 aprovadores)**
```solidity
configureTransfer(alice, bob, 1, compliance, 
    [prefeituraAddress, cartorioAddress, ifAddress, iphanAddress, secretariaCulturaAddress]);
```

---

## 🤝 4. Aceitação do Comprador

### **Por Que é Necessário?**

Sem aceitação do comprador:
- ❌ Transferências não solicitadas ("spam" de tokens)
- ❌ Comprador pode não querer o imóvel
- ❌ Problemas legais (transferência sem consentimento)

Com aceitação do comprador:
- ✅ Comprador decide se aceita ou não
- ✅ Notificação na carteira
- ✅ Transparência total
- ✅ Proteção legal

### **Fluxo de Notificação**

```
1. Orchestrator configura transferência
   ↓
   Event: TransferConfigured(hash, alice, bob, value, approvers)

2. Backend escuta evento
   ↓
   if (to === bobAddress) {
       sendNotification(bob, "Nova proposta de transferência");
   }

3. Bob abre a carteira/sistema
   ↓
   "Alice quer transferir imóvel 123456 para você"
   [Aceitar] [Recusar]

4. Bob clica "Aceitar"
   ↓
   approvalsModule.acceptTransfer(alice, 1, compliance)
   ↓
   Event: TransferAccepted(hash, bob)

5. Alice pode executar transferProperty()
```

### **UI Exemplo (Frontend)**

```jsx
// Componente React
function TransferRequest({ from, matricula, approvers, onAccept, onReject }) {
    return (
        <div className="transfer-request">
            <h3>📬 Nova Proposta de Transferência</h3>
            <p><strong>De:</strong> {from}</p>
            <p><strong>Imóvel:</strong> Matrícula {matricula}</p>
            <p><strong>Aprovadores:</strong></p>
            <ul>
                {approvers.map(a => (
                    <li key={a.address}>
                        {a.name} {a.approved ? '✅' : '⏳'}
                    </li>
                ))}
            </ul>
            <button onClick={onAccept}>✅ Aceitar</button>
            <button onClick={onReject}>❌ Recusar</button>
        </div>
    );
}
```

---

## 💻 Comandos Práticos

### **Deploy Inicial**

```bash
cd /home/fabiano/college/tcc/besu-property-ledger

# Iniciar rede Besu
cd docker/besu
docker compose up -d

# Deploy dos contratos
cd ../..
forge script script/DeployPropertyTitleTREX.s.sol:DeployPropertyTitleTREXScript \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x51eba47406fcb3dfa80e9ff02c1a8efe1aa1552bf016e09d454e6a7502ef0c24 \
  --broadcast --legacy --gas-price 0
```

### **Registrar Imóvel**

```bash
# 1. Registrar identidade do proprietário (backend worker)
cast send <IDENTITY_REGISTRY> "registerIdentity(address,address,uint16)" \
  0xOWNER 0xIDENTITY 76 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xWORKER_KEY \
  --legacy --gas-price 0

# 2. Registrar propriedade (cartório)
cast send <REGISTRY_MODULE> \
  "registerProperty((uint256,uint256,string,string,uint256,address,uint256,uint8,bool))" \
  "(123456,100,'São Paulo','Rua X',150,0xOWNER,0,0,true)" \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xCARTORIO_KEY \
  --legacy --gas-price 0

# 3. Emitir título (admin)
cast send <PROPERTY_TITLE_TREX> "issueProperty(address,uint256)" \
  0xOWNER 123456 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xAGENT_KEY \
  --legacy --gas-price 0
```

### **Transferir Imóvel**

```bash
# 1. Configurar aprovadores (orchestrator)
cast send <APPROVALS_MODULE> \
  "configureTransfer(address,address,uint256,address,address[])" \
  0xALICE 0xBOB 1 0xCOMPLIANCE "[0xPREFEITURA,0xCARTORIO,0xIF]" \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xORCHESTRATOR_KEY \
  --legacy --gas-price 0

# 2. Aprovar (cada aprovador)
cast send <APPROVALS_MODULE> "approve(address,address,uint256,address)" \
  0xALICE 0xBOB 1 0xCOMPLIANCE \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xPREFEITURA_KEY \
  --legacy --gas-price 0

cast send <APPROVALS_MODULE> "approve(address,address,uint256,address)" \
  0xALICE 0xBOB 1 0xCOMPLIANCE \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xCARTORIO_KEY \
  --legacy --gas-price 0

cast send <APPROVALS_MODULE> "approve(address,address,uint256,address)" \
  0xALICE 0xBOB 1 0xCOMPLIANCE \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xIF_KEY \
  --legacy --gas-price 0

# 3. Bob aceita receber
cast send <APPROVALS_MODULE> "acceptTransfer(address,uint256,address)" \
  0xALICE 1 0xCOMPLIANCE \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xBOB_KEY \
  --legacy --gas-price 0

# 4. Alice transfere
cast send <PROPERTY_TITLE_TREX> "transferProperty(address,uint256)" \
  0xBOB 123456 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xALICE_KEY \
  --legacy --gas-price 0
```

---

## 🔑 Roles e Permissões

| Contrato | Role | Quem | Permissões |
|----------|------|------|------------|
| `RegistryMDCompliance` | `REGISTRAR_ROLE` | Cartório | `registerProperty()`, `updateProperty()` |
| `PropertyTitleTREX` | `AGENT_ROLE` | Admin/Cartório | `issueProperty()`, `pause()`, `freeze()` |
| `ApprovalsModule` | `ORCHESTRATOR_ROLE` | Backend/Admin | `configureTransfer()` |
| `IdentityRegistry` | Agent | Backend Worker | `registerIdentity()` |

**Nota sobre Aprovadores:**
- **NÃO há roles fixos** de aprovação
- Cada transferência define sua lista específica
- Backend decide baseado em regras de negócio

**Nota sobre CPF:**
- Associação CPF ↔ wallet é 100% off-chain (banco de dados)
- Ver `docs/backend/CPF_WALLET.md`

---

## ⚠️ Validações Automáticas

Durante `propertyTitleTREX.transferProperty()`, o sistema valida:

1. ✅ **Identidades verificadas** (`IdentityRegistry`)
2. ✅ **Contas não congeladas** (`isFrozen`)
3. ✅ **Sistema não pausado** (`paused`)
4. ✅ **Aprovações completas** (`ApprovalsModule.moduleCheck`)
5. ✅ **Comprador aceitou** (`buyerAccepted`)
6. ✅ **Imóvel regular** (`RegistryMDCompliance.moduleCheck`)

Se qualquer validação falhar, a transação reverte.

---

## 🎯 Resumo

### **Registro**
```
1. identityRegistry.registerIdentity(owner, identity, 76)
2. registryModule.registerProperty(propertyInfo)
3. propertyTitleTREX.issueProperty(owner, matricula)
```

### **Transferência**
```
1. approvalsModule.configureTransfer(alice, bob, 1, compliance, [approvers])
2. approvalsModule.approve(alice, bob, 1, compliance) [x3: cada aprovador]
3. approvalsModule.acceptTransfer(alice, 1, compliance) [Bob aceita]
4. propertyTitleTREX.transferProperty(bob, matricula) [Alice executa]
   ↳ Valida: identidades + aprovações + aceitação + regularidade
   ↳ Limpa configuração após sucesso
```

---

## 📚 Referências

- [Amarração dos Contratos](../AMARRACAO_CONTRATOS.md) - Como tudo se conecta
- [Backend CPF ↔ Wallet](../backend/CPF_WALLET.md) - Associação off-chain
- [Features Freeze/Pause](../referencias/FREEZE_PAUSE.md) - Controles regulatórios
- [Análise ERC-3643](../referencias/ERC3643_ANALISE.md) - Por que ERC-20 + Compliance

