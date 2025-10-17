// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AbstractModule} from "@trex/compliance/modular/modules/AbstractModule.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

error PropertyNotRegistered(uint256 matriculaId);
error PropertyTransferNotAllowed(uint256 matriculaId);

/**
 * RegistryMDCompliance
 * - Registro on-chain de imóveis por matricula.
 * - Valida transferências via moduleCheck (compliance modular ERC-3643).
 * - Dados: apenas identificação e regularidade. Nada de tributos/cartório.
 */
contract RegistryMDCompliance is AbstractModule, AccessControl {
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    enum PropertyType { URBANO, RURAL, LITORAL }

    struct PropertyInfo {
        uint256 matriculaId;
        uint256 folha;
        string comarca;
        string endereco;
        uint256 metragem;
        address proprietario;  // informativo; transferência real é no token
        uint256 matriculaOrigem;
        PropertyType tipo;
        bool isRegular;
    }

    mapping(uint256 => PropertyInfo) private properties;

    event PropertyRegistered(uint256 indexed matriculaId, address indexed proprietario);
    event PropertyUpdated(uint256 indexed matriculaId);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REGISTRAR_ROLE, admin);
    }

    function name() external pure returns (string memory) { return "RegistryMDCompliance"; }
    function isPlugAndPlay() external pure returns (bool) { return true; }
    function canComplianceBind(address) external pure returns (bool) { return true; }

    // AbstractModule hooks
    function moduleMintAction(address, uint256) external override {}
    function moduleBurnAction(address, uint256) external override {}
    function moduleTransferAction(address, address, uint256) external override {}

    function moduleCheck(address, address, uint256 matriculaId, address) external view override returns (bool) {
        PropertyInfo storage p = properties[matriculaId];
        if (p.matriculaId == 0) revert PropertyNotRegistered(matriculaId);
        if (!p.isRegular) revert PropertyTransferNotAllowed(matriculaId);
        return true;
    }

    // Registro (cartório/orquestrador)
    function registerProperty(PropertyInfo calldata info) external onlyRole(REGISTRAR_ROLE) {
        require(properties[info.matriculaId].matriculaId == 0, "exists");
        properties[info.matriculaId] = info;
        emit PropertyRegistered(info.matriculaId, info.proprietario);
    }

    // Atualização cadastral (endereço, metragem, regularidade)
    function updateProperty(
        uint256 matriculaId,
        string calldata endereco,
        uint256 metragem,
        bool isRegular
    ) external onlyRole(REGISTRAR_ROLE) {
        PropertyInfo storage p = properties[matriculaId];
        if (p.matriculaId == 0) revert PropertyNotRegistered(matriculaId);
        p.endereco = endereco;
        p.metragem = metragem;
        p.isRegular = isRegular;
        emit PropertyUpdated(matriculaId);
    }

    // Consulta
    function getProperty(uint256 matriculaId) external view returns (PropertyInfo memory) {
        if (properties[matriculaId].matriculaId == 0) revert PropertyNotRegistered(matriculaId);
        return properties[matriculaId];
    }
}


