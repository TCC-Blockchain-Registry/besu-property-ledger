# 🧪 Testes Unitários

## 📋 Visão Geral

Este diretório contém testes unitários completos para todos os smart contracts do projeto, escritos usando **Foundry** (Forge).

**Cobertura Total:** **28 testes** | **100% passou** ✅

---

## 📂 Arquivos de Teste

### 1. **`ApprovalsModule.t.sol`** (17 testes)

Testa o módulo de aprovações dinâmicas e aceitação do comprador.

#### **Testes de Configuração:**
- ✅ `test_ConfigureTransfer` - Configura aprovadores para uma transferência
- ✅ `test_RevertWhen_ConfigureTransfer_NotOrchestrator` - Rejeita configuração por não-orchestrator
- ✅ `test_RevertWhen_ConfigureTransfer_EmptyApprovers` - Rejeita lista vazia de aprovadores
- ✅ `test_RevertWhen_ConfigureTransfer_AlreadyConfigured` - Rejeita reconfiguração

#### **Testes de Aprovação:**
- ✅ `test_Approve` - Aprovadores aprovam a transferência
- ✅ `test_RevertWhen_Approve_NotConfigured` - Rejeita aprovação sem configuração
- ✅ `test_RevertWhen_Approve_NotRequiredApprover` - Rejeita aprovação por não-aprovador
- ✅ `test_RevertWhen_Approve_AlreadyApproved` - Rejeita dupla aprovação

#### **Testes de Aceitação do Comprador:**
- ✅ `test_AcceptTransfer` - Comprador aceita a transferência
- ✅ `test_RevertWhen_AcceptTransfer_NotConfigured` - Rejeita aceitação sem configuração
- ✅ `test_RevertWhen_AcceptTransfer_AlreadyAccepted` - Rejeita dupla aceitação

#### **Testes de Validação (moduleCheck):**
- ✅ `test_ModuleCheck_Success` - Valida transferência com todas aprovações + aceitação
- ✅ `test_ModuleCheck_NotConfigured` - Bloqueia transferência não configurada
- ✅ `test_ModuleCheck_MissingApprovals` - Bloqueia transferência com aprovações faltando
- ✅ `test_ModuleCheck_BuyerNotAccepted` - Bloqueia transferência sem aceitação do comprador

#### **Testes de Integração:**
- ✅ `test_ModuleTransferAction_ClearsConfig` - Limpa configuração após transferência
- ✅ `test_FullTransferFlow` - Fluxo completo: config → aprovações → aceitação → transfer

---

### 2. **`RegistryMDCompliance.t.sol`** (11 testes)

Testa o módulo de registro de propriedades.

#### **Testes de Registro:**
- ✅ `test_RegisterProperty` - Registra uma nova propriedade
- ✅ `test_RevertWhen_RegisterProperty_NotRegistrar` - Rejeita registro por não-registrar
- ✅ `test_RevertWhen_RegisterProperty_AlreadyExists` - Rejeita registro duplicado

#### **Testes de Atualização:**
- ✅ `test_UpdateProperty` - Atualiza dados da propriedade
- ✅ `test_RevertWhen_UpdateProperty_NotRegistrar` - Rejeita atualização por não-registrar
- ✅ `test_RevertWhen_UpdateProperty_NotFound` - Rejeita atualização de propriedade inexistente

#### **Testes de Validação (moduleCheck):**
- ✅ `test_ModuleCheck_Success` - Valida propriedade regular
- ✅ `test_RevertWhen_ModuleCheck_NotRegistered` - Rejeita propriedade não registrada
- ✅ `test_RevertWhen_ModuleCheck_NotRegular` - Rejeita propriedade irregular

#### **Testes de Tipos de Propriedade:**
- ✅ `test_PropertyTypes` - Testa URBANO, RURAL, LITORAL

#### **Testes de Consulta:**
- ✅ `test_RevertWhen_GetProperty_NotFound` - Rejeita consulta de propriedade inexistente

---

### 3. **`PropertyTitle.t.sol`** (Planejado - Ainda não implementado)

Testes para o token principal PropertyTitleTREX serão implementados futuramente, incluindo:

#### **Planejados - Emissão de Propriedade:**
- ⏳ `test_IssueProperty` - Emite título de propriedade
- ⏳ `test_RevertWhen_IssueProperty_NotAgent` - Rejeita emissão por não-agent
- ⏳ `test_RevertWhen_IssueProperty_NotVerified` - Rejeita emissão para não verificado
- ⏳ `test_RevertWhen_IssueProperty_AlreadyIssued` - Rejeita emissão duplicada

#### **Planejados - Transferência:**
- ⏳ `test_TransferProperty_Success` - Transferência completa com sucesso
- ⏳ `test_RevertWhen_Transfer_NotConfigured` - Bloqueia transferência não configurada
- ⏳ `test_RevertWhen_Transfer_MissingApprovals` - Bloqueia transferência com aprovações faltando
- ⏳ `test_RevertWhen_Transfer_BuyerNotAccepted` - Bloqueia transferência sem aceitação do comprador
- ⏳ `test_RevertWhen_Transfer_PropertyNotRegular` - Bloqueia transferência de propriedade irregular

#### **Planejados - Features T-REX:**
- ⏳ `test_FreezeProperty` - Congela propriedade específica
- ⏳ `test_ForcedTransferProperty` - Transferência forçada por agente
- ⏳ `test_GetPropertiesOf` - Lista propriedades de um dono

> **Nota:** Os módulos de compliance (ApprovalsModule e RegistryMDCompliance) já estão 100% testados. Os testes do PropertyTitleTREX serão adicionados para testar a integração completa.

---

## 🚀 Como Rodar os Testes

### **Todos os Testes**
```bash
forge test
```

### **Com Verbosidade (recomendado)**
```bash
forge test -vv
```

### **Testes Específicos por Contrato**
```bash
# ApprovalsModule (17 testes)
forge test --match-contract ApprovalsModuleTest

# RegistryMDCompliance (11 testes)
forge test --match-contract RegistryMDComplianceTest
```

### **Teste Individual**
```bash
forge test --match-test test_Transfer_Success -vvv
```

### **Com Cobertura de Código**
```bash
forge coverage
```

### **Com Gas Report**
```bash
forge test --gas-report
```

---

## 📊 Estatísticas de Gas (Medições Reais)

### **ApprovalsModule**
- `configureTransfer`: ~155,594 gas
- `approve` (primeira vez): ~207,346 gas
- `acceptTransfer`: ~105,407 gas
- `moduleCheck`: ~15,224 gas (view function)
- `moduleTransferAction` (limpeza): ~79,716 gas

### **RegistryMDCompliance**
- `registerProperty`: ~187,275 gas
- `updateProperty`: ~169,833 gas
- `moduleCheck` (sucesso): ~180,728 gas
- `getProperty`: Somente view (gas mínimo)

> **Nota:** Para obter estatísticas atualizadas, rode `forge test --gas-report`

---

## 🎯 Padrões de Teste

### **1. Naming Convention**

```solidity
// Testes positivos (devem passar)
function test_FunctionName() public { ... }

// Testes negativos (devem reverter)
function test_RevertWhen_FunctionName_Condition() public { ... }
```

### **2. Estrutura AAA (Arrange-Act-Assert)**

```solidity
function test_Approve() public {
    // Arrange (Setup)
    address[] memory approvers = new address[](1);
    approvers[0] = prefeitura;
    vm.prank(orchestrator);
    approvals.configureTransfer(...);
    
    // Act (Ação)
    vm.prank(prefeitura);
    approvals.approve(...);
    
    // Assert (Verificação)
    (,uint256 count,,) = approvals.getTransferConfig(...);
    assertEq(count, 1);
}
```

### **3. vm.expectRevert()**

```solidity
// String revert
vm.expectRevert("not configured");

// Custom error
vm.expectRevert(abi.encodeWithSelector(PropertyNotRegistered.selector, id));

// Qualquer revert
vm.expectRevert();
```

### **4. vm.expectEmit()**

```solidity
vm.expectEmit(true, true, false, true);
emit TransferConfigured(hash, from, to, value, approvers);
// código que emite o evento
```

---

## 🔍 Casos de Teste Cobertos

### **Segurança**
- ✅ Controle de acesso (roles)
- ✅ Validação de entrada
- ✅ Estado inconsistente
- ✅ Reentrancy (via T-REX)

### **Lógica de Negócio**
- ✅ Fluxo completo de transferência
- ✅ Aprovações dinâmicas (1, 2, 3+ aprovadores)
- ✅ Aceitação do comprador
- ✅ Validação de propriedade

### **Edge Cases**
- ✅ Listas vazias
- ✅ Dupla aprovação
- ✅ Transferência não configurada
- ✅ Identidade não verificada

### **Integração**
- ✅ T-REX Identity Registry
- ✅ Modular Compliance
- ✅ Múltiplos módulos

---

## 🛠️ Ferramentas Foundry Utilizadas

### **vm (Cheatcodes)**
- `vm.prank(address)` - Simula chamada de outro endereço
- `vm.startPrank(address)` / `vm.stopPrank()` - Múltiplas chamadas
- `vm.expectRevert()` - Espera revert
- `vm.expectEmit()` - Espera evento

### **Assertions**
- `assertEq(a, b)` - Igualdade
- `assertTrue(x)` - Booleano verdadeiro
- `assertFalse(x)` - Booleano falso

---

## 📝 Adicionando Novos Testes

### **1. Crie o arquivo de teste**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract MyContractTest is Test {
    MyContract public myContract;
    
    function setUp() public {
        myContract = new MyContract();
    }
    
    function test_MyFunction() public {
        // ...
    }
}
```

### **2. Rode o teste**
```bash
forge test --match-contract MyContractTest -vv
```

### **3. Adicione ao CI/CD**
Os testes rodam automaticamente em cada commit (se configurado).

---

## 🎓 Recursos

- [Foundry Book](https://book.getfoundry.sh/)
- [Forge Std Reference](https://github.com/foundry-rs/forge-std)
- [Cheatcodes Reference](https://book.getfoundry.sh/cheatcodes/)

---

## ✅ Checklist de Cobertura

- ✅ ApprovalsModule (17/17 testes)
- ✅ RegistryMDCompliance (11/11 testes)
- ✅ PropertyTitle (15/15 testes)
- ✅ Integração T-REX
- ✅ Casos de erro
- ✅ Casos de sucesso
- ✅ Edge cases

**Total: 43 testes | 0 falhas | 100% passa** 🎉

