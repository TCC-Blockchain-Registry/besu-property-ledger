// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";
import {PropertyTitleTREX} from "../src/token/PropertyTitleTREX.sol";
import {ModularCompliance} from "@trex/compliance/modular/ModularCompliance.sol";
import {ApprovalsModule} from "../src/compliance/modules/ApprovalsModule.sol";
import {RegistryMDCompliance} from "../src/compliance/modules/RegistryMDCompliance.sol";
import {IdentityRegistry} from "@trex/registry/implementation/IdentityRegistry.sol";
import {ClaimTopicsRegistry} from "@trex/registry/implementation/ClaimTopicsRegistry.sol";
import {TrustedIssuersRegistry} from "@trex/registry/implementation/TrustedIssuersRegistry.sol";
import {IdentityRegistryStorage} from "@trex/registry/implementation/IdentityRegistryStorage.sol";
import {Identity} from "@onchain-id/solidity/contracts/Identity.sol";

contract DeployPropertyTitleTREXScript is Script {
    function run() external {
        vm.startBroadcast();
        address admin = tx.origin;

        // ========== Deploy T-REX Infrastructure ==========
        
        // 1. Deploy registries
        ClaimTopicsRegistry claimTopics = new ClaimTopicsRegistry();
        TrustedIssuersRegistry trustedIssuers = new TrustedIssuersRegistry();
        IdentityRegistryStorage idStorage = new IdentityRegistryStorage();
        idStorage.init();
        
        // 2. Deploy and init Identity Registry
        IdentityRegistry registry = new IdentityRegistry();
        registry.init(address(trustedIssuers), address(claimTopics), address(idStorage));
        idStorage.bindIdentityRegistry(address(registry));
        registry.addAgent(admin);

        // 3. Create OnchainID for admin and register
        Identity adminIdentity = new Identity(admin, false);
        registry.registerIdentity(admin, adminIdentity, 76); // BR country code

        // ========== Deploy Modular Compliance ==========
        
        ModularCompliance compliance = new ModularCompliance();
        compliance.init();
        
        // Deploy custom compliance modules
        ApprovalsModule approvals = new ApprovalsModule(admin);
        RegistryMDCompliance registryModule = new RegistryMDCompliance(admin);
        
        compliance.addModule(address(approvals));
        compliance.addModule(address(registryModule));
        
        // Grant roles
        bytes32 ORCHESTRATOR_ROLE = keccak256("ORCHESTRATOR_ROLE");
        bytes32 REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");
        approvals.grantRole(ORCHESTRATOR_ROLE, admin);
        registryModule.grantRole(REGISTRAR_ROLE, admin);

        // ========== Deploy PropertyTitleTREX (T-REX Full) ==========
        
        PropertyTitleTREX token = new PropertyTitleTREX();
        
        // Initialize token (upgradeable pattern)
        // Note: init() já faz bindToken automaticamente e define owner como o contrato
        token.initialize(
            address(registry),
            address(compliance),
            "PropertyTitle",
            "TITLE",
            0, // decimals = 0 (indivisível)
            address(0) // onchainID pode ser zero
        );
        
        // Grant AGENT_ROLE to admin (pode emitir propriedades, pause, freeze)
        // Note: O owner é o próprio contrato, então addAgent deve ser chamado pelo contrato
        // O admin já é owner via tx.origin, então pode adicionar agents

        vm.stopBroadcast();
    }
}

