// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Token} from "@trex/token/Token.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title IApproverValidator
 * @notice Interface genérica para validadores modulares
 */
interface IApproverValidator {
    function validateTransfer(address from, address to, uint256 value)
        external view returns (bool approved, string memory reason);
}

/**
 * @title PropertyTitleTREX v2
 * @notice Security token (ERC-3643 T-REX) com sistema de aprovações para registros e transferências
 * 
 * NOVA FUNCIONALIDADE v2:
 * - ✅ Sistema de Pending Registrations (registros aguardam aprovação)
 * - ✅ Sistema de Pending Transfers melhorado
 * - ✅ Fluxo completo: Request → Approve → Execute
 * - ✅ Eventos detalhados para tracking
 */
contract PropertyTitleTREX is Token, AccessControlUpgradeable {
    
    // ========== Roles das Instituições ==========
    
    bytes32 public constant FINANCIAL_ROLE = keccak256("FINANCIAL_ROLE");
    bytes32 public constant REGISTRY_OFFICE_ROLE = keccak256("REGISTRY_OFFICE_ROLE");
    bytes32 public constant MUNICIPALITY_ROLE = keccak256("MUNICIPALITY_ROLE");
    
    // ========== Structs para Pending Operations ==========
    
    /// @notice Estrutura para registros pendentes
    struct PendingRegistration {
        uint256 matricula;
        address beneficiary;
        address requester;
        uint256 requestedAt;
        bool exists;
        bool financialApproved;
        bool registryOfficeApproved;
        bool municipalityApproved;
        bool executed;
    }
    
    /// @notice Estrutura para transferências pendentes
    struct PendingTransfer {
        uint256 matricula;
        address from;
        address to;
        address requester;
        uint256 requestedAt;
        bool exists;
        bool financialApproved;
        bool registryOfficeApproved;
        bool municipalityApproved;
        bool executed;
    }
    
    // ========== Storage para Pending Operations ==========
    
    /// @notice Registros pendentes: hash => PendingRegistration
    /// hash = keccak256(abi.encode(matricula, beneficiary))
    mapping(bytes32 => PendingRegistration) public pendingRegistrations;
    
    /// @notice Transferências pendentes: hash => PendingTransfer
    /// hash = keccak256(abi.encode(from, to, matricula))
    mapping(bytes32 => PendingTransfer) public pendingTransfers;
    
    // ========== Amarração Token ↔ Imóvel ==========
    
    /// @notice Mapeamento: matrícula → endereço do proprietário atual
    mapping(uint256 => address) public propertyOwner;
    
    /// @notice Mapeamento: endereço → lista de matrículas que possui
    mapping(address => uint256[]) private _ownedProperties;
    
    /// @notice Mapeamento: matrícula → índice na lista _ownedProperties do dono
    mapping(uint256 => uint256) private _ownedPropertiesIndex;
    
    /// @notice Verificar se uma matrícula já foi emitida
    mapping(uint256 => bool) public propertyExists;
    
    // ========== Sistema de Aprovações (Legacy - mantido para compatibilidade) ==========
    
    /// @notice Contratos validadores opcionais (endereço 0 = não usa validador)
    address public financialValidator;
    address public registryOfficeValidator;
    address public municipalityValidator;
    
    // ========== Eventos ==========
    
    /// @notice Emitido quando um registro é solicitado
    event RegistrationRequested(
        bytes32 indexed requestHash,
        uint256 indexed matricula,
        address indexed beneficiary,
        address requester
    );
    
    /// @notice Emitido quando um registro é aprovado por uma instituição
    event RegistrationApproved(
        bytes32 indexed requestHash,
        string institution,
        address approver
    );
    
    /// @notice Emitido quando um registro é executado (mint final)
    event RegistrationExecuted(
        bytes32 indexed requestHash,
        uint256 indexed matricula,
        address indexed beneficiary
    );
    
    /// @notice Emitido quando uma transferência é solicitada
    event TransferRequested(
        bytes32 indexed requestHash,
        uint256 indexed matricula,
        address indexed from,
        address to,
        address requester
    );
    
    /// @notice Emitido quando uma transferência é aprovada por uma instituição
    event TransferApproved(
        bytes32 indexed requestHash,
        string institution,
        address approver
    );
    
    /// @notice Emitido quando uma transferência é executada
    event TransferExecuted(
        bytes32 indexed requestHash,
        uint256 indexed matricula,
        address indexed from,
        address to
    );
    
    /// @notice Emitido quando um novo título de propriedade é emitido (legacy)
    event PropertyIssued(uint256 indexed matricula, address indexed owner);
    
    /// @notice Emitido quando um título é transferido (legacy)
    event PropertyTransferred(uint256 indexed matricula, address indexed from, address indexed to);
    
    /// @notice Emitido quando uma propriedade é congelada
    event PropertyFrozen(uint256 indexed matricula);
    
    /// @notice Emitido quando uma propriedade é descongelada
    event PropertyUnfrozen(uint256 indexed matricula);
    
    /// @notice Emitido quando configuração de validador é alterada
    event ValidatorSet(string institution, address validator);
    
    // ========== Initialization ==========
    
    function initialize(
        address identityRegistry_,
        address compliance_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address onchainID_
    ) external {
        this.init(identityRegistry_, compliance_, name_, symbol_, decimals_, onchainID_);
        // Grant admin role to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    // ========== NOVO: Sistema de Pending Registrations ==========
    
    /**
     * @notice Solicita registro de uma nova propriedade (ficará pendente até aprovações)
     * @param matricula ID único do imóvel
     * @param beneficiary Endereço que receberá o título quando aprovado
     * @return requestHash Hash único da solicitação
     */
    function requestPropertyRegistration(
        uint256 matricula,
        address beneficiary
    ) external returns (bytes32) {
        require(this.identityRegistry().isVerified(beneficiary), "Beneficiary not verified");
        require(!propertyExists[matricula], "Property already issued");
        
        bytes32 requestHash = keccak256(abi.encode(matricula, beneficiary));
        require(!pendingRegistrations[requestHash].exists, "Registration already pending");
        
        pendingRegistrations[requestHash] = PendingRegistration({
            matricula: matricula,
            beneficiary: beneficiary,
            requester: msg.sender,
            requestedAt: block.timestamp,
            exists: true,
            financialApproved: false,
            registryOfficeApproved: false,
            municipalityApproved: false,
            executed: false
        });
        
        emit RegistrationRequested(requestHash, matricula, beneficiary, msg.sender);
        
        return requestHash;
    }
    
    /**
     * @notice Instituição Financeira aprova um registro pendente
     * @dev Executa automaticamente se todas as aprovações forem concedidas
     */
    function approveRegistrationAsFinancial(bytes32 requestHash) external onlyRole(FINANCIAL_ROLE) {
        PendingRegistration storage reg = pendingRegistrations[requestHash];
        require(reg.exists, "Registration not found");
        require(!reg.executed, "Registration already executed");
        require(!reg.financialApproved, "Already approved by financial");
        
        reg.financialApproved = true;
        emit RegistrationApproved(requestHash, "FINANCIAL", msg.sender);
        
        // Auto-executa se todas as aprovações foram concedidas
        _tryExecuteRegistration(requestHash);
    }
    
    /**
     * @notice Cartório aprova um registro pendente
     * @dev Executa automaticamente se todas as aprovações forem concedidas
     */
    function approveRegistrationAsRegistryOffice(bytes32 requestHash) external onlyRole(REGISTRY_OFFICE_ROLE) {
        PendingRegistration storage reg = pendingRegistrations[requestHash];
        require(reg.exists, "Registration not found");
        require(!reg.executed, "Registration already executed");
        require(!reg.registryOfficeApproved, "Already approved by registry office");
        
        reg.registryOfficeApproved = true;
        emit RegistrationApproved(requestHash, "REGISTRY_OFFICE", msg.sender);
        
        // Auto-executa se todas as aprovações foram concedidas
        _tryExecuteRegistration(requestHash);
    }
    
    /**
     * @notice Prefeitura aprova um registro pendente
     * @dev Executa automaticamente se todas as aprovações forem concedidas
     */
    function approveRegistrationAsMunicipality(bytes32 requestHash) external onlyRole(MUNICIPALITY_ROLE) {
        PendingRegistration storage reg = pendingRegistrations[requestHash];
        require(reg.exists, "Registration not found");
        require(!reg.executed, "Registration already executed");
        require(!reg.municipalityApproved, "Already approved by municipality");
        
        reg.municipalityApproved = true;
        emit RegistrationApproved(requestHash, "MUNICIPALITY", msg.sender);
        
        // Auto-executa se todas as aprovações foram concedidas
        _tryExecuteRegistration(requestHash);
    }
    
    /**
     * @notice Tenta executar o registro se todas as aprovações foram concedidas
     * @dev Função interna chamada automaticamente após cada aprovação
     */
    function _tryExecuteRegistration(bytes32 requestHash) private {
        PendingRegistration storage reg = pendingRegistrations[requestHash];
        
        // Verifica se todas as aprovações foram concedidas
        if (reg.financialApproved && reg.registryOfficeApproved && reg.municipalityApproved && !reg.executed) {
            // Marcar como executado
            reg.executed = true;
            
            // Emitir o título (mint)
            _issueProperty(reg.beneficiary, reg.matricula);
            
            emit RegistrationExecuted(requestHash, reg.matricula, reg.beneficiary);
        }
    }
    
    // ========== NOVO: Sistema de Pending Transfers ==========
    
    /**
     * @notice Solicita transferência de propriedade (ficará pendente até aprovações)
     * @param from Vendedor (proprietário atual)
     * @param to Comprador
     * @param matricula ID do imóvel
     * @return requestHash Hash único da solicitação
     */
    function requestPropertyTransfer(
        address from,
        address to,
        uint256 matricula
    ) external returns (bytes32) {
        require(propertyExists[matricula], "Property not issued");
        require(propertyOwner[matricula] == from, "Incorrect owner");
        require(this.identityRegistry().isVerified(to), "Recipient not verified");
        
        bytes32 requestHash = keccak256(abi.encode(from, to, matricula));
        require(!pendingTransfers[requestHash].exists, "Transfer already pending");
        
        pendingTransfers[requestHash] = PendingTransfer({
            matricula: matricula,
            from: from,
            to: to,
            requester: msg.sender,
            requestedAt: block.timestamp,
            exists: true,
            financialApproved: false,
            registryOfficeApproved: false,
            municipalityApproved: false,
            executed: false
        });
        
        emit TransferRequested(requestHash, matricula, from, to, msg.sender);
        
        return requestHash;
    }
    
    /**
     * @notice Instituição Financeira aprova uma transferência pendente
     * @dev Executa automaticamente se todas as aprovações forem concedidas
     */
    function approveTransferAsFinancial(bytes32 requestHash) external onlyRole(FINANCIAL_ROLE) {
        PendingTransfer storage transfer = pendingTransfers[requestHash];
        require(transfer.exists, "Transfer not found");
        require(!transfer.executed, "Transfer already executed");
        require(!transfer.financialApproved, "Already approved by financial");
        
        transfer.financialApproved = true;
        emit TransferApproved(requestHash, "FINANCIAL", msg.sender);
        
        // Auto-executa se todas as aprovações foram concedidas
        _tryExecuteTransfer(requestHash);
    }
    
    /**
     * @notice Cartório aprova uma transferência pendente
     * @dev Executa automaticamente se todas as aprovações forem concedidas
     */
    function approveTransferAsRegistryOffice(bytes32 requestHash) external onlyRole(REGISTRY_OFFICE_ROLE) {
        PendingTransfer storage transfer = pendingTransfers[requestHash];
        require(transfer.exists, "Transfer not found");
        require(!transfer.executed, "Transfer already executed");
        require(!transfer.registryOfficeApproved, "Already approved by registry office");
        
        transfer.registryOfficeApproved = true;
        emit TransferApproved(requestHash, "REGISTRY_OFFICE", msg.sender);
        
        // Auto-executa se todas as aprovações foram concedidas
        _tryExecuteTransfer(requestHash);
    }
    
    /**
     * @notice Prefeitura aprova uma transferência pendente
     * @dev Executa automaticamente se todas as aprovações forem concedidas
     */
    function approveTransferAsMunicipality(bytes32 requestHash) external onlyRole(MUNICIPALITY_ROLE) {
        PendingTransfer storage transfer = pendingTransfers[requestHash];
        require(transfer.exists, "Transfer not found");
        require(!transfer.executed, "Transfer already executed");
        require(!transfer.municipalityApproved, "Already approved by municipality");
        
        transfer.municipalityApproved = true;
        emit TransferApproved(requestHash, "MUNICIPALITY", msg.sender);
        
        // Auto-executa se todas as aprovações foram concedidas
        _tryExecuteTransfer(requestHash);
    }
    
    /**
     * @notice Tenta executar a transferência se todas as aprovações foram concedidas
     * @dev Função interna chamada automaticamente após cada aprovação
     */
    function _tryExecuteTransfer(bytes32 requestHash) private {
        PendingTransfer storage transfer = pendingTransfers[requestHash];
        
        // Verifica se todas as aprovações foram concedidas
        if (transfer.financialApproved && transfer.registryOfficeApproved && transfer.municipalityApproved && !transfer.executed) {
            // Marcar como executado
            transfer.executed = true;
            
            // Executar transferência
            _transferProperty(transfer.from, transfer.to, transfer.matricula);
            
            emit TransferExecuted(requestHash, transfer.matricula, transfer.from, transfer.to);
        }
    }
    
    // ========== Query Functions ==========
    // NOTA: Funções de listagem foram removidas para reduzir tamanho do contrato
    // Use eventos (RegistrationRequested, TransferRequested) para tracking off-chain
    
    // ========== LEGACY: Direct Issue/Transfer (mantido para compatibilidade V1) ==========
    
    /**
     * @notice Emite um título diretamente (SEM aprovações - para agentes/sistema interno)
     * @dev LEGACY V1: Sistema de registro direto usado pelo Core Orchestrator
     */
    function issueProperty(address to, uint256 matricula) external {
        require(isAgent(msg.sender), "Only agents can issue properties");
        require(this.identityRegistry().isVerified(to), "Recipient not verified");
        require(!propertyExists[matricula], "Property already issued");
        
        _issueProperty(to, matricula);
    }
    
    /**
     * @notice Transfere propriedade diretamente (SEM aprovações - para agentes)
     * @dev LEGACY V1: Sistema de transferência direta
     */
    function transferProperty(address from, address to, uint256 matricula) external {
        require(isAgent(msg.sender), "Only agents can transfer");
        require(propertyExists[matricula], "Property not issued");
        require(propertyOwner[matricula] == from, "Incorrect owner");
        require(this.identityRegistry().isVerified(to), "Recipient not verified");
        
        _transferProperty(from, to, matricula);
    }
    
    // ========== Internal Implementation ==========
    
    function _issueProperty(address to, uint256 matricula) private {
        propertyExists[matricula] = true;
        propertyOwner[matricula] = to;
        _addPropertyToOwner(to, matricula);
        _mint(to, matricula);
        emit PropertyIssued(matricula, to);
    }
    
    function _transferProperty(address from, address to, uint256 matricula) private {
        _removePropertyFromOwner(from, matricula);
        _addPropertyToOwner(to, matricula);
        propertyOwner[matricula] = to;
        _transfer(from, to, matricula);
        emit PropertyTransferred(matricula, from, to);
    }
    
    // ========== Helper Functions ==========
    
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
     * @notice Retorna lista de propriedades de um endereço
     */
    function getPropertiesOf(address owner) external view returns (uint256[] memory) {
        return _ownedProperties[owner];
    }
    
    /**
     * @notice Retorna quantidade de propriedades de um endereço
     */
    function balanceOfProperties(address owner) external view returns (uint256) {
        return _ownedProperties[owner].length;
    }
}

