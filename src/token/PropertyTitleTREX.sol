// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Token} from "@trex/token/Token.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title IApproverValidator
 * @notice Interface genérica para validadores modulares
 */
interface IApproverValidator {
    function validateTransfer(address from, address to, uint256 value)
        external view returns (bool approved, string memory reason);
}

/**
 * @title PropertyTitleTREX
 * @notice Security token (ERC-3643 T-REX Full) que representa títulos de propriedade de imóveis.
 * 
 * Herda TODAS as features do T-REX Token:
 * - ✅ ERC-20 completo
 * - ✅ Identity Registry (OnchainID)
 * - ✅ Modular Compliance
 * - ✅ Pause/Unpause (global)
 * - ✅ Freeze/Unfreeze (contas específicas)
 * - ✅ Partial Freeze (limitar transferências)
 * - ✅ Forced Transfer (agentes podem forçar)
 * - ✅ Batch Transfers (eficiência)
 * - ✅ Recovery (recuperar tokens perdidos)
 * - ✅ Upgradeable pattern
 * 
 * IMPORTANTE: Este token NÃO representa valor monetário!
 * - Cada unidade de token = 1 título de propriedade de um imóvel específico
 * - O "amount" em transfers = matrícula do imóvel (não quantidade de dinheiro)
 * - Pagamentos são realizados OFF-CHAIN
 * 
 * Amarração Token ↔ Imóvel:
 * - Cada matrícula é única e identifica o imóvel
 * - propertyOwner[matricula] = endereço do dono
 * - O holder do token é o proprietário legal on-chain
 * 
 * Integração com Backend:
 * - Backend escuta eventos PropertyIssued e PropertyTransferred
 * - Backend mantém banco de dados: matricula → dados do imóvel
 * - Backend sincroniza: blockchain (quem é dono) ↔ DB (dados do imóvel)
 * 
 * Features de Regulação:
 * - Agentes podem pausar todo o sistema (emergência)
 * - Agentes podem congelar contas específicas (compliance)
 * - Agentes podem forçar transferências (recuperação/correção)
 */
contract PropertyTitleTREX is Token, AccessControl {
    
    // ========== Roles das Instituições ==========
    
    bytes32 public constant FINANCIAL_ROLE = keccak256("FINANCIAL_ROLE");
    bytes32 public constant REGISTRY_OFFICE_ROLE = keccak256("REGISTRY_OFFICE_ROLE");
    bytes32 public constant MUNICIPALITY_ROLE = keccak256("MUNICIPALITY_ROLE");
    
    // ========== Amarração Token ↔ Imóvel ==========
    
    /// @notice Mapeamento: matrícula → endereço do proprietário atual
    mapping(uint256 => address) public propertyOwner;
    
    /// @notice Mapeamento: endereço → lista de matrículas que possui
    mapping(address => uint256[]) private _ownedProperties;
    
    /// @notice Mapeamento: matrícula → índice na lista _ownedProperties do dono
    mapping(uint256 => uint256) private _ownedPropertiesIndex;
    
    /// @notice Verificar se uma matrícula já foi emitida
    mapping(uint256 => bool) public propertyExists;
    
    // ========== Sistema de Aprovações ==========
    
    /// @notice Contratos validadores opcionais (endereço 0 = não usa validador)
    address public financialValidator;
    address public registryOfficeValidator;
    address public municipalityValidator;
    
    /// @notice Aprovações manuais: hash da transferência → instituição → aprovado
    /// hash = keccak256(abi.encode(from, to, matriculaId))
    mapping(bytes32 => bool) private financialApprovals;
    mapping(bytes32 => bool) private registryOfficeApprovals;
    mapping(bytes32 => bool) private municipalityApprovals;
    
    // ========== Eventos Customizados ==========
    
    /// @notice Emitido quando um novo título de propriedade é emitido (mint)
    /// @param matricula ID único do imóvel (matrícula do cartório)
    /// @param owner Primeiro proprietário on-chain
    event PropertyIssued(uint256 indexed matricula, address indexed owner);
    
    /// @notice Emitido quando um título é transferido
    /// @param matricula ID do imóvel transferido
    /// @param from Proprietário anterior
    /// @param to Novo proprietário
    event PropertyTransferred(uint256 indexed matricula, address indexed from, address indexed to);
    
    /// @notice Emitido quando uma propriedade é congelada
    /// @param matricula ID do imóvel
    /// @param frozen Status de congelamento
    event PropertyFrozen(uint256 indexed matricula, bool frozen);
    
    /// @notice Emitido quando uma instituição aprova uma transferência
    event TransferApprovalGranted(
        bytes32 indexed transferHash,
        string indexed institution,
        address indexed approver,
        address from,
        address to,
        uint256 matricula
    );
    
    /// @notice Emitido quando um validador é configurado
    event ValidatorSet(string indexed institution, address indexed validator);
    
    // ========== Inicialização (Upgradeable Pattern) ==========
    
    /**
     * @notice Inicializa o contrato (proxy pattern)
     * @dev Deve ser chamado apenas uma vez após deploy do proxy
     * @param _identityRegistry Endereço do Identity Registry
     * @param _compliance Endereço do Modular Compliance
     * @param _name Nome do token
     * @param _symbol Símbolo do token
     * @param _decimals Decimais (0 = indivisível)
     * @param _onchainID Endereço do OnchainID do emissor (pode ser zero)
     */
    function initialize(
        address _identityRegistry,
        address _compliance,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _onchainID
    ) external {
        // Inicializar Token T-REX base (chamada direta, não super)
        this.init(_identityRegistry, _compliance, _name, _symbol, _decimals, _onchainID);
    }
    
    // ========== Core Functions (Property Management) ==========
    
    /**
     * @notice Emite um novo título de propriedade (registra imóvel on-chain)
     * @param to Proprietário inicial (deve ter identidade verificada)
     * @param matricula ID único do imóvel (matrícula do cartório)
     * 
     * Requisitos:
     * - Apenas AGENT_ROLE pode chamar
     * - Destinatário deve estar verificado no Identity Registry
     * - Matrícula deve ser única (não pode duplicar)
     * - Matrícula deve ser > 0
     * 
     * Amarração com Backend:
     * 1. Backend chama esta função após validar documentos off-chain
     * 2. Backend escuta evento PropertyIssued
     * 3. Backend atualiza DB: matricula → to, status = "emitido"
     */
    function issueProperty(address to, uint256 matricula) external {
        require(isAgent(msg.sender), "Only agents can issue properties");
        require(this.identityRegistry().isVerified(to), "Recipient not verified");
        require(!propertyExists[matricula], "Property already issued");
        require(matricula > 0, "Invalid matricula");
        
        // Emitir 1 unidade de token (1 título = 1 propriedade)
        mint(to, 1);
        
        // Registrar propriedade
        propertyExists[matricula] = true;
        propertyOwner[matricula] = to;
        _addPropertyToOwner(to, matricula);
        
        emit PropertyIssued(matricula, to);
    }
    
    /**
     * @notice Transfere título de propriedade
     * @param to Novo proprietário
     * @param matricula ID do imóvel a transferir
     * 
     * IMPORTANTE: matricula NÃO é "quantidade" de tokens, é o ID do imóvel!
     * 
     * Validações necessárias:
     * - Propriedade existe e pertence ao vendedor
     * - Contas não estão congeladas
     * - APROVAÇÃO DA INSTITUIÇÃO FINANCEIRA (manual OU validador)
     * - APROVAÇÃO DO CARTÓRIO (manual OU validador)
     * - APROVAÇÃO DA PREFEITURA (manual OU validador)
     * - Identidade verificada (T-REX)
     * - Compliance rules (T-REX)
     */
    function transferProperty(address to, uint256 matricula) external {
        require(propertyExists[matricula], "Property not issued");
        require(propertyOwner[matricula] == msg.sender, "Not property owner");
        require(!this.isFrozen(msg.sender), "Sender account is frozen");
        require(!this.isFrozen(to), "Recipient account is frozen");
        
        // ========== VALIDAR APROVAÇÕES DAS 3 INSTITUIÇÕES ==========
        bytes32 transferHash = _getTransferHash(msg.sender, to, matricula);
        
        // 1. Instituição Financeira
        require(
            _checkApproval(transferHash, financialValidator, financialApprovals, msg.sender, to, matricula),
            "IF: aprovacao necessaria"
        );
        
        // 2. Cartório
        require(
            _checkApproval(transferHash, registryOfficeValidator, registryOfficeApprovals, msg.sender, to, matricula),
            "Cartorio: aprovacao necessaria"
        );
        
        // 3. Prefeitura
        require(
            _checkApproval(transferHash, municipalityValidator, municipalityApprovals, msg.sender, to, matricula),
            "Prefeitura: aprovacao necessaria"
        );
        
        // Transfer usa função do Token T-REX (valida compliance, identity, etc)
        transfer(to, 1);
        
        // Atualizar rastreamento de propriedade
        _removePropertyFromOwner(msg.sender, matricula);
        propertyOwner[matricula] = to;
        _addPropertyToOwner(to, matricula);
        
        // Limpar aprovações (evita reuso)
        delete financialApprovals[transferHash];
        delete registryOfficeApprovals[transferHash];
        delete municipalityApprovals[transferHash];
        
        emit PropertyTransferred(matricula, msg.sender, to);
    }
    
    // ========== Regulatory Functions (Freeze/Pause) ==========
    
    /**
     * @notice Congela uma propriedade específica
     * @dev Apenas agentes podem chamar
     * @param matricula ID do imóvel
     * @param freeze true = congelar, false = descongelar
     * 
     * Use cases:
     * - Disputas judiciais
     * - Suspeita de fraude
     * - Bloqueio temporário durante investigação
     * - Pendências de compliance
     */
    function freezeProperty(uint256 matricula, bool freeze) external {
        require(isAgent(msg.sender), "Only agents can freeze properties");
        require(propertyExists[matricula], "Property not issued");
        
        address owner = propertyOwner[matricula];
        
        if (freeze) {
            setAddressFrozen(owner, true);
        } else {
            setAddressFrozen(owner, false);
        }
        
        emit PropertyFrozen(matricula, freeze);
    }
    
    /**
     * @notice Congela múltiplas propriedades em batch
     * @param matriculas Array de IDs de imóveis
     * @param freeze true = congelar, false = descongelar
     */
    function batchFreezeProperties(uint256[] calldata matriculas, bool freeze) external {
        require(isAgent(msg.sender), "Only agents can freeze properties");
        
        for (uint256 i = 0; i < matriculas.length; i++) {
            uint256 matricula = matriculas[i];
            if (propertyExists[matricula]) {
                address owner = propertyOwner[matricula];
                setAddressFrozen(owner, freeze);
                emit PropertyFrozen(matricula, freeze);
            }
        }
    }
    
    /**
     * @notice Transferência forçada por agente (recuperação/correção)
     * @param from Dono atual
     * @param to Novo dono
     * @param matricula ID do imóvel
     * 
     * Use cases:
     * - Recuperação de tokens perdidos (perda de chave privada)
     * - Correção de erros administrativos
     * - Ordem judicial
     * - Herança (após aprovação legal)
     */
    function forcedTransferProperty(address from, address to, uint256 matricula) external {
        require(isAgent(msg.sender), "Only agents can force transfer");
        require(propertyExists[matricula], "Property not issued");
        require(propertyOwner[matricula] == from, "Invalid current owner");
        
        // Forced transfer bypassa compliance (T-REX feature)
        forcedTransfer(from, to, 1);
        
        // Atualizar rastreamento
        _removePropertyFromOwner(from, matricula);
        propertyOwner[matricula] = to;
        _addPropertyToOwner(to, matricula);
        
        emit PropertyTransferred(matricula, from, to);
    }
    
    // ========== View Functions (Amarração Token ↔ Imóvel) ==========
    
    /**
     * @notice Retorna todas as propriedades de um dono
     * @param owner Endereço do proprietário
     * @return Array de matrículas
     * 
     * Backend usa isso para:
     * - Sincronizar lista de imóveis do usuário
     * - Exibir "Meus Imóveis" no frontend
     */
    function getPropertiesOf(address owner) external view returns (uint256[] memory) {
        return _ownedProperties[owner];
    }
    
    /**
     * @notice Verifica quem é o dono de um imóvel específico
     * @param matricula ID do imóvel
     * @return Endereço do proprietário atual
     * 
     * Backend usa isso para:
     * - Validar quem pode vender
     * - Exibir "Proprietário Atual" no frontend
     */
    function getPropertyOwner(uint256 matricula) external view returns (address) {
        require(propertyExists[matricula], "Property not issued");
        return propertyOwner[matricula];
    }
    
    /**
     * @notice Quantidade de propriedades de um dono
     */
    function propertyCountOf(address owner) external view returns (uint256) {
        return _ownedProperties[owner].length;
    }
    
    /**
     * @notice Verifica se uma propriedade está congelada
     * @param matricula ID do imóvel
     * @return true se congelada
     */
    function isPropertyFrozen(uint256 matricula) external view returns (bool) {
        require(propertyExists[matricula], "Property not issued");
        address owner = propertyOwner[matricula];
        return this.isFrozen(owner);
    }
    
    /**
     * @notice Verifica se transferências estão globalmente pausadas
     * @return true se pausado
     */
    function isTransferPaused() external view returns (bool) {
        return this.paused();
    }
    
    // ========== Funções de Aprovação ==========
    
    /**
     * @notice Instituição Financeira aprova uma transferência manualmente
     * @param from Vendedor
     * @param to Comprador
     * @param matricula Matrícula
     */
    function approveTransferAsFinancial(
        address from,
        address to,
        uint256 matricula
    ) external onlyRole(FINANCIAL_ROLE) {
        bytes32 h = _getTransferHash(from, to, matricula);
        financialApprovals[h] = true;
        emit TransferApprovalGranted(h, "FINANCIAL", msg.sender, from, to, matricula);
    }
    
    /**
     * @notice Cartório aprova uma transferência manualmente
     */
    function approveTransferAsRegistryOffice(
        address from,
        address to,
        uint256 matricula
    ) external onlyRole(REGISTRY_OFFICE_ROLE) {
        bytes32 h = _getTransferHash(from, to, matricula);
        registryOfficeApprovals[h] = true;
        emit TransferApprovalGranted(h, "REGISTRY_OFFICE", msg.sender, from, to, matricula);
    }
    
    /**
     * @notice Prefeitura aprova uma transferência manualmente
     */
    function approveTransferAsMunicipality(
        address from,
        address to,
        uint256 matricula
    ) external onlyRole(MUNICIPALITY_ROLE) {
        bytes32 h = _getTransferHash(from, to, matricula);
        municipalityApprovals[h] = true;
        emit TransferApprovalGranted(h, "MUNICIPALITY", msg.sender, from, to, matricula);
    }
    
    /**
     * @notice Configura validador da IF (opcional)
     * @param validator Endereço do contrato validador (0 = desabilita)
     */
    function setFinancialValidator(address validator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        financialValidator = validator;
        emit ValidatorSet("FINANCIAL", validator);
    }
    
    /**
     * @notice Configura validador do Cartório (opcional)
     */
    function setRegistryOfficeValidator(address validator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        registryOfficeValidator = validator;
        emit ValidatorSet("REGISTRY_OFFICE", validator);
    }
    
    /**
     * @notice Configura validador da Prefeitura (opcional)
     */
    function setMunicipalityValidator(address validator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        municipalityValidator = validator;
        emit ValidatorSet("MUNICIPALITY", validator);
    }
    
    // ========== Internal Helper Functions ==========
    
    function _addPropertyToOwner(address owner, uint256 matricula) private {
        _ownedPropertiesIndex[matricula] = _ownedProperties[owner].length;
        _ownedProperties[owner].push(matricula);
    }
    
    function _removePropertyFromOwner(address owner, uint256 matricula) private {
        uint256 lastIndex = _ownedProperties[owner].length - 1;
        uint256 propertyIndex = _ownedPropertiesIndex[matricula];

        if (propertyIndex != lastIndex) {
            uint256 lastMatricula = _ownedProperties[owner][lastIndex];
            _ownedProperties[owner][propertyIndex] = lastMatricula;
            _ownedPropertiesIndex[lastMatricula] = propertyIndex;
        }

        _ownedProperties[owner].pop();
        delete _ownedPropertiesIndex[matricula];
    }
    
    /**
     * @notice Gera hash único da transferência
     */
    function _getTransferHash(
        address from,
        address to,
        uint256 matricula
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(from, to, matricula));
    }
    
    /**
     * @notice Verifica aprovação (manual OU via validador)
     * @param transferHash Hash da transferência
     * @param validator Endereço do validador (0 = não usa validador)
     * @param manualApprovals Mapeamento de aprovações manuais
     * @param from Vendedor
     * @param to Comprador
     * @param matricula Matrícula
     * @return True se aprovado (manual ou via validador)
     */
    function _checkApproval(
        bytes32 transferHash,
        address validator,
        mapping(bytes32 => bool) storage manualApprovals,
        address from,
        address to,
        uint256 matricula
    ) private view returns (bool) {
        // Se tem validador configurado → chama validateTransfer
        if (validator != address(0)) {
            try IApproverValidator(validator).validateTransfer(from, to, matricula) returns (bool approved, string memory) {
                return approved;
            } catch {
                return false; // Erro ao chamar validador
            }
        }
        
        // Se não tem validador → verifica aprovação manual
        return manualApprovals[transferHash];
    }
    
    // Nota: decimals() é definido no init() do Token T-REX
    // Passar _decimals = 0 para propriedades indivisíveis
}

