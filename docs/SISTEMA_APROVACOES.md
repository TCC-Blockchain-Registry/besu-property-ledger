# Sistema de Aprovações - PropertyTitleTREX

## Visão Geral

O sistema de aprovações está **integrado diretamente no PropertyTitleTREX.sol**.

Antes de executar `transferProperty()`, o contrato verifica automaticamente se as **3 instituições** aprovaram:
1. **Instituição Financeira**
2. **Cartório**
3. **Prefeitura**

Cada instituição pode aprovar de **DUAS formas**:

## Modo 1: Aprovação Manual

A instituição tem uma ROLE e aprova manualmente chamando uma função:

```solidity
// IF aprova
propertyToken.approveTransferAsFinancial(alice, bob, 123456);

// Cartório aprova
propertyToken.approveTransferAsRegistryOffice(alice, bob, 123456);

// Prefeitura aprova
propertyToken.approveTransferAsMunicipality(alice, bob, 123456);
```

## Modo 2: Validador Modular

A instituição deploya um contrato validador e o registra no token:

```solidity
// 1. Deploy do validador
FinancialInstitutionValidator ifValidator = new FinancialInstitutionValidator(admin);

// 2. Registrar no token
propertyToken.setFinancialValidator(address(ifValidator));

// 3. Aprovar no validador
ifValidator.approvePayment(alice, bob, 123456, amount, "PAY-001");

// 4. Transferência - validador é chamado automaticamente
propertyToken.transferProperty(bob, 123456); // ✅
```

## Como Funciona

### Fluxo de transferProperty()

```solidity
function transferProperty(address to, uint256 matricula) external {
    // 1. Verificações básicas
    require(propertyExists[matricula], "Property not issued");
    require(propertyOwner[matricula] == msg.sender, "Not property owner");
    require(!isFrozen(msg.sender), "Sender account is frozen");
    require(!isFrozen(to), "Recipient account is frozen");
    
    // 2. VALIDAR APROVAÇÕES DAS 3 INSTITUIÇÕES
    bytes32 transferHash = keccak256(abi.encode(msg.sender, to, matricula));
    
    // Para cada instituição:
    //   - Se tem validador → chama validateTransfer()
    //   - Se não → verifica aprovação manual
    
    require(_checkApproval(...), "IF: aprovacao necessaria");
    require(_checkApproval(...), "Cartorio: aprovacao necessaria");
    require(_checkApproval(...), "Prefeitura: aprovacao necessaria");
    
    // 3. Executa transferência T-REX
    transfer(to, 1);
    
    // 4. Atualiza rastreamento
    propertyOwner[matricula] = to;
    
    // 5. Limpa aprovações (evita reuso)
    delete financialApprovals[transferHash];
    delete registryOfficeApprovals[transferHash];
    delete municipalityApprovals[transferHash];
}
```

## Exemplo Completo

### Cenário: Alice vende para Bob (Matrícula 123456)

**Setup Inicial**
```solidity
// Deploy do token
PropertyTitleTREX token = new PropertyTitleTREX();
token.initialize(...);

// Conceder roles para as instituições
token.grantRole(token.FINANCIAL_ROLE(), ifOperator);
token.grantRole(token.REGISTRY_OFFICE_ROLE(), cartorioOperator);
token.grantRole(token.MUNICIPALITY_ROLE(), prefeituraOperator);
```

**Opção A: Todas usam aprovação manual**

```solidity
// 1. Bob paga Alice OFF-CHAIN

// 2. IF aprova
token.approveTransferAsFinancial(alice, bob, 123456);

// 3. Cartório aprova
token.approveTransferAsRegistryOffice(alice, bob, 123456);

// 4. Prefeitura aprova
token.approveTransferAsMunicipality(alice, bob, 123456);

// 5. Alice transfere
token.transferProperty(bob, 123456);
// ✅ Sucesso! Todas as 3 instituições aprovaram
```

**Opção B: Todas usam validadores**

```solidity
// 1. Deploy dos validadores
FinancialInstitutionValidator ifValidator = new FinancialInstitutionValidator(admin);
RegistryOfficeValidator cartorioValidator = new RegistryOfficeValidator(admin);
MunicipalityValidator prefeituraValidator = new MunicipalityValidator(admin);

// 2. Registrar validadores no token
token.setFinancialValidator(address(ifValidator));
token.setRegistryOfficeValidator(address(cartorioValidator));
token.setMunicipalityValidator(address(prefeituraValidator));

// 3. Bob paga Alice OFF-CHAIN

// 4. Cada instituição aprova em seu validador
ifValidator.approvePayment(alice, bob, 123456, 50000000, "PAY-001");
cartorioValidator.approveTransfer(alice, bob, 123456, "CERT-001");
prefeituraValidator.approveTransfer(alice, bob, 123456, "CND-001");

// 5. Alice transfere - validadores são chamados automaticamente
token.transferProperty(bob, 123456);
// ✅ Sucesso!
```

**Opção C: Misto (algumas manual, outras validador)**

```solidity
// IF usa validador
token.setFinancialValidator(address(ifValidator));
ifValidator.approvePayment(alice, bob, 123456, amount, "PAY-001");

// Cartório usa aprovação manual
token.approveTransferAsRegistryOffice(alice, bob, 123456);

// Prefeitura usa validador
token.setMunicipalityValidator(address(prefeituraValidator));
prefeituraValidator.approveTransfer(alice, bob, 123456, "CND-001");

// Transferência - funciona perfeitamente!
token.transferProperty(bob, 123456);
// ✅ Sucesso!
```

## Interface do Validador

Se uma instituição quer usar validador modular:

```solidity
interface IApproverValidator {
    function validateTransfer(
        address from,
        address to,
        uint256 value
    ) external view returns (bool approved, string memory reason);
}
```

## Validadores de Exemplo

Já existem 3 validadores implementados:

**FinancialInstitutionValidator**
- Valida que pagamento foi confirmado
- Verifica ausência de dívidas
- Funções: `approvePayment()`, `setDebtStatus()`

**RegistryOfficeValidator**
- Valida documentação
- Verifica ausência de ônus
- Funções: `approveTransfer()`, `setEncumbrance()`

**MunicipalityValidator**
- Valida regularidade fiscal (IPTU)
- Verifica débitos municipais
- Funções: `approveTransfer()`, `registerDebt()`

## Benefícios

### ✅ Integração Direta
- Validações acontecem ANTES de chamar `transfer()`
- Garantia de que aprovações são verificadas
- Não depende de módulos externos

### ✅ Flexibilidade Total
- Instituições escolhem entre manual ou validador
- Podem mudar a qualquer momento
- Podem misturar os dois modos

### ✅ Segurança
- Aprovações são limpas após uso (anti-replay)
- Hash único por transferência
- Roles protegem aprovações manuais

### ✅ Simplicidade
- Aprovação manual: uma função
- Validador: deploy e registrar

## Tratamento de Erros

```solidity
// Se IF não aprovou
token.transferProperty(bob, 123456);
// ❌ Reverte: "IF: aprovacao necessaria"

// Se Cartório não aprovou
token.transferProperty(bob, 123456);
// ❌ Reverte: "Cartorio: aprovacao necessaria"

// Se Prefeitura não aprovou
token.transferProperty(bob, 123456);
// ❌ Reverte: "Prefeitura: aprovacao necessaria"
```

## Arquivos

- **Token**: `src/token/PropertyTitleTREX.sol` (MODIFICADO)
- **Validadores** (opcionais):
  - `src/compliance/validators/FinancialInstitutionValidator.sol`
  - `src/compliance/validators/RegistryOfficeValidator.sol`
  - `src/compliance/validators/MunicipalityValidator.sol`

## Próximos Passos

1. ✅ Sistema implementado no token
2. 🔄 Testar transferências
3. 🔄 Deploy em testnet
4. 🔄 Integrar com backend
