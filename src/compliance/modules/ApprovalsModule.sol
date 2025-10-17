// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IModule} from "@trex/compliance/modular/modules/IModule.sol";

/**
 * ApprovalsModule
 * - Blocks transfers until required approvers approve the specific transfer
 * - Configurable per-transfer: define WHO and HOW MANY approvers are needed
 * - Approval scope: (from, to, value, compliance) tuple. Cleared after successful transfer.
 */
contract ApprovalsModule is IModule, AccessControl {
    bytes32 public constant ORCHESTRATOR_ROLE = keccak256("ORCHESTRATOR_ROLE");

    // compliance bindings
    mapping(address => bool) private isComplianceBoundByAddress;

    // Per-transfer configuration: which addresses must approve
    struct TransferConfig {
        address[] requiredApprovers;
        mapping(address => bool) hasApproved;
        uint256 approvalCount;
        bool isConfigured;
        bool buyerAccepted;  // comprador precisa aceitar
    }
    
    mapping(bytes32 => TransferConfig) private transferConfigs;

    event TransferConfigured(
        bytes32 indexed transferHash,
        address indexed from,
        address indexed to,
        uint256 value,
        address[] requiredApprovers
    );
    event Approved(bytes32 indexed transferHash, address indexed approver, uint256 approvalCount, uint256 required);
    event BuyerAccepted(bytes32 indexed transferHash, address indexed buyer);
    event TransferConfigCleared(bytes32 indexed transferHash);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // IModule
    function bindCompliance(address _compliance) external override {
        require(_compliance != address(0), "invalid compliance");
        require(!isComplianceBoundByAddress[_compliance], "already bound");
        isComplianceBoundByAddress[_compliance] = true;
        emit ComplianceBound(_compliance);
    }

    function unbindCompliance(address _compliance) external override {
        require(isComplianceBoundByAddress[_compliance], "not bound");
        isComplianceBoundByAddress[_compliance] = false;
        emit ComplianceUnbound(_compliance);
    }

    function moduleTransferAction(address _from, address _to, uint256 _value) external override {
        // clear config after successful transfer
        bytes32 h = _getTransferHash(_from, _to, _value, msg.sender);
        delete transferConfigs[h];
        emit TransferConfigCleared(h);
    }

    function moduleMintAction(address, uint256) external override {}
    function moduleBurnAction(address, uint256) external override {}

    function moduleCheck(address _from, address _to, uint256 _value, address _compliance)
        external
        view
        override
        returns (bool)
    {
        bytes32 h = _getTransferHash(_from, _to, _value, _compliance);
        TransferConfig storage config = transferConfigs[h];
        
        // If not configured, block transfer
        if (!config.isConfigured) {
            return false;
        }
        
        // Check if all required approvers have approved
        if (config.approvalCount != config.requiredApprovers.length) {
            return false;
        }
        
        // Check if buyer has accepted
        if (!config.buyerAccepted) {
            return false;
        }
        
        return true;
    }

    function isComplianceBound(address _compliance) external view override returns (bool) {
        return isComplianceBoundByAddress[_compliance];
    }

    function canComplianceBind(address) external pure override returns (bool) {
        return true; // plug and play
    }

    function isPlugAndPlay() external pure override returns (bool) { return true; }

    function name() external pure override returns (string memory) { return "ApprovalsModule"; }

    // ========== Public Functions ==========

    /**
     * Configure which addresses must approve a specific transfer
     * @param from Seller address
     * @param to Buyer address
     * @param value Amount/matriculaId
     * @param compliance Compliance contract address
     * @param requiredApprovers Array of addresses that must approve (e.g., [prefeitura, cartorio, IF])
     */
    function configureTransfer(
        address from,
        address to,
        uint256 value,
        address compliance,
        address[] calldata requiredApprovers
    ) external onlyRole(ORCHESTRATOR_ROLE) {
        require(requiredApprovers.length > 0, "empty approvers");
        
        bytes32 h = _getTransferHash(from, to, value, compliance);
        TransferConfig storage config = transferConfigs[h];
        
        require(!config.isConfigured, "already configured");
        
        config.requiredApprovers = requiredApprovers;
        config.isConfigured = true;
        config.approvalCount = 0;
        
        emit TransferConfigured(h, from, to, value, requiredApprovers);
    }

    /**
     * Approve a specific transfer
     * Only callable by addresses in the requiredApprovers list
     */
    function approve(address from, address to, uint256 value, address compliance) external {
        bytes32 h = _getTransferHash(from, to, value, compliance);
        TransferConfig storage config = transferConfigs[h];
        
        require(config.isConfigured, "not configured");
        require(!config.hasApproved[msg.sender], "already approved");
        require(_isRequiredApprover(config, msg.sender), "not required approver");
        
        config.hasApproved[msg.sender] = true;
        config.approvalCount++;
        
        emit Approved(h, msg.sender, config.approvalCount, config.requiredApprovers.length);
    }

    /**
     * Buyer accepts the transfer
     * Only callable by the buyer (to address)
     */
    function acceptTransfer(address from, uint256 value, address compliance) external {
        bytes32 h = _getTransferHash(from, msg.sender, value, compliance);
        TransferConfig storage config = transferConfigs[h];
        
        require(config.isConfigured, "not configured");
        require(!config.buyerAccepted, "already accepted");
        
        config.buyerAccepted = true;
        
        emit BuyerAccepted(h, msg.sender);
    }

    // ========== View Functions ==========

    function getTransferConfig(
        address from,
        address to,
        uint256 value,
        address compliance
    ) external view returns (
        address[] memory requiredApprovers,
        uint256 approvalCount,
        bool isConfigured,
        bool buyerAccepted
    ) {
        bytes32 h = _getTransferHash(from, to, value, compliance);
        TransferConfig storage config = transferConfigs[h];
        return (config.requiredApprovers, config.approvalCount, config.isConfigured, config.buyerAccepted);
    }

    function hasApproved(
        address from,
        address to,
        uint256 value,
        address compliance,
        address approver
    ) external view returns (bool) {
        bytes32 h = _getTransferHash(from, to, value, compliance);
        return transferConfigs[h].hasApproved[approver];
    }

    // ========== Internal Functions ==========

    function _getTransferHash(
        address from,
        address to,
        uint256 value,
        address compliance
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(from, to, value, compliance));
    }

    function _isRequiredApprover(TransferConfig storage config, address approver) internal view returns (bool) {
        for (uint256 i = 0; i < config.requiredApprovers.length; i++) {
            if (config.requiredApprovers[i] == approver) {
                return true;
            }
        }
        return false;
    }
}


