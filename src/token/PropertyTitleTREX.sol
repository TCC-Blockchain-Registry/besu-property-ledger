// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Token} from "@trex/token/Token.sol";

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
contract PropertyTitleTREX is Token {
    
    // ========== Amarração Token ↔ Imóvel ==========
    
    /// @notice Mapeamento: matrícula → endereço do proprietário atual
    mapping(uint256 => address) public propertyOwner;
    
    /// @notice Mapeamento: endereço → lista de matrículas que possui
    mapping(address => uint256[]) private _ownedProperties;
    
    /// @notice Mapeamento: matrícula → índice na lista _ownedProperties do dono
    mapping(uint256 => uint256) private _ownedPropertiesIndex;
    
    /// @notice Verificar se uma matrícula já foi emitida
    mapping(uint256 => bool) public propertyExists;
    
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
     * Validações automáticas pelo T-REX:
     * - Identidade verificada (from e to)
     * - Compliance rules (aprovações, regularidade)
     * - Não congelado (freeze)
     * - Não pausado (pause)
     * 
     * Amarração com Backend:
     * 1. Backend configura aprovadores (IF confirma pagamento off-chain)
     * 2. Aprovadores aprovam on-chain
     * 3. Comprador aceita on-chain
     * 4. Esta função é chamada
     * 5. Backend escuta PropertyTransferred
     * 6. Backend atualiza DB: matricula → novo dono
     */
    function transferProperty(address to, uint256 matricula) external {
        require(propertyExists[matricula], "Property not issued");
        require(propertyOwner[matricula] == msg.sender, "Not property owner");
        require(!this.isFrozen(msg.sender), "Sender account is frozen");
        require(!this.isFrozen(to), "Recipient account is frozen");
        
        // Transfer usa função do Token T-REX (valida compliance, identity, etc)
        transfer(to, 1);
        
        // Atualizar rastreamento de propriedade
        _removePropertyFromOwner(msg.sender, matricula);
        propertyOwner[matricula] = to;
        _addPropertyToOwner(to, matricula);
        
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
    
    // Nota: decimals() é definido no init() do Token T-REX
    // Passar _decimals = 0 para propriedades indivisíveis
}

