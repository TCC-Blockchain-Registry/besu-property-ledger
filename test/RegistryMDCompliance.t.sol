// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {RegistryMDCompliance} from "../src/compliance/modules/RegistryMDCompliance.sol";

// Import custom errors
error PropertyNotRegistered(uint256 matriculaId);
error PropertyTransferNotAllowed(uint256 matriculaId);

contract RegistryMDComplianceTest is Test {
    RegistryMDCompliance public registry;
    
    address admin = address(1);
    address registrar = address(2);
    address alice = address(3);
    address compliance = address(4);
    
    uint256 constant MATRICULA_ID = 123456;
    
    event PropertyRegistered(uint256 indexed matriculaId, address indexed proprietario);
    event PropertyUpdated(uint256 indexed matriculaId);
    
    function setUp() public {
        vm.startPrank(admin);
        registry = new RegistryMDCompliance(admin);
        
        bytes32 REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");
        registry.grantRole(REGISTRAR_ROLE, registrar);
        vm.stopPrank();
    }
    
    // ========== Registration Tests ==========
    
    function test_RegisterProperty() public {
        RegistryMDCompliance.PropertyInfo memory prop = RegistryMDCompliance.PropertyInfo({
            matriculaId: MATRICULA_ID,
            folha: 100,
            comarca: "Sao Paulo",
            endereco: "Rua Exemplo, 123",
            metragem: 150,
            proprietario: alice,
            matriculaOrigem: 0,
            tipo: RegistryMDCompliance.PropertyType.URBANO,
            isRegular: true
        });
        
        vm.prank(registrar);
        vm.expectEmit(true, true, false, false);
        emit PropertyRegistered(MATRICULA_ID, alice);
        registry.registerProperty(prop);
        
        RegistryMDCompliance.PropertyInfo memory retrieved = registry.getProperty(MATRICULA_ID);
        assertEq(retrieved.matriculaId, MATRICULA_ID);
        assertEq(retrieved.folha, 100);
        assertEq(retrieved.comarca, "Sao Paulo");
        assertEq(retrieved.endereco, "Rua Exemplo, 123");
        assertEq(retrieved.metragem, 150);
        assertEq(retrieved.proprietario, alice);
        assertEq(retrieved.matriculaOrigem, 0);
        assertEq(uint(retrieved.tipo), uint(RegistryMDCompliance.PropertyType.URBANO));
        assertTrue(retrieved.isRegular);
    }
    
    function test_RevertWhen_RegisterProperty_NotRegistrar() public {
        RegistryMDCompliance.PropertyInfo memory prop = RegistryMDCompliance.PropertyInfo({
            matriculaId: MATRICULA_ID,
            folha: 100,
            comarca: "Sao Paulo",
            endereco: "Rua Exemplo, 123",
            metragem: 150,
            proprietario: alice,
            matriculaOrigem: 0,
            tipo: RegistryMDCompliance.PropertyType.URBANO,
            isRegular: true
        });
        
        vm.prank(alice);
        vm.expectRevert();
        registry.registerProperty(prop);
    }
    
    function test_RevertWhen_RegisterProperty_AlreadyExists() public {
        RegistryMDCompliance.PropertyInfo memory prop = RegistryMDCompliance.PropertyInfo({
            matriculaId: MATRICULA_ID,
            folha: 100,
            comarca: "Sao Paulo",
            endereco: "Rua Exemplo, 123",
            metragem: 150,
            proprietario: alice,
            matriculaOrigem: 0,
            tipo: RegistryMDCompliance.PropertyType.URBANO,
            isRegular: true
        });
        
        vm.startPrank(registrar);
        registry.registerProperty(prop);
        vm.expectRevert("exists");
        registry.registerProperty(prop); // segunda vez
        vm.stopPrank();
    }
    
    // ========== Update Tests ==========
    
    function test_UpdateProperty() public {
        // Registrar
        RegistryMDCompliance.PropertyInfo memory prop = RegistryMDCompliance.PropertyInfo({
            matriculaId: MATRICULA_ID,
            folha: 100,
            comarca: "Sao Paulo",
            endereco: "Rua Exemplo, 123",
            metragem: 150,
            proprietario: alice,
            matriculaOrigem: 0,
            tipo: RegistryMDCompliance.PropertyType.URBANO,
            isRegular: true
        });
        
        vm.prank(registrar);
        registry.registerProperty(prop);
        
        // Atualizar
        vm.prank(registrar);
        vm.expectEmit(true, false, false, false);
        emit PropertyUpdated(MATRICULA_ID);
        registry.updateProperty(
            MATRICULA_ID,
            "Rua Nova, 456",
            200,
            false
        );
        
        RegistryMDCompliance.PropertyInfo memory updated = registry.getProperty(MATRICULA_ID);
        assertEq(updated.endereco, "Rua Nova, 456");
        assertEq(updated.metragem, 200);
        assertFalse(updated.isRegular);
    }
    
    function test_RevertWhen_UpdateProperty_NotRegistrar() public {
        // Registrar
        RegistryMDCompliance.PropertyInfo memory prop = RegistryMDCompliance.PropertyInfo({
            matriculaId: MATRICULA_ID,
            folha: 100,
            comarca: "Sao Paulo",
            endereco: "Rua Exemplo, 123",
            metragem: 150,
            proprietario: alice,
            matriculaOrigem: 0,
            tipo: RegistryMDCompliance.PropertyType.URBANO,
            isRegular: true
        });
        
        vm.prank(registrar);
        registry.registerProperty(prop);
        
        // Atualizar sem role
        vm.prank(alice);
        vm.expectRevert();
        registry.updateProperty(MATRICULA_ID, "Rua Nova, 456", 200, false);
    }
    
    function test_RevertWhen_UpdateProperty_NotFound() public {
        vm.prank(registrar);
        vm.expectRevert(abi.encodeWithSelector(PropertyNotRegistered.selector, MATRICULA_ID));
        registry.updateProperty(MATRICULA_ID, "Rua Nova, 456", 200, false);
    }
    
    // ========== Module Check Tests ==========
    
    function test_ModuleCheck_Success() public {
        // Registrar imóvel regular
        RegistryMDCompliance.PropertyInfo memory prop = RegistryMDCompliance.PropertyInfo({
            matriculaId: MATRICULA_ID,
            folha: 100,
            comarca: "Sao Paulo",
            endereco: "Rua Exemplo, 123",
            metragem: 150,
            proprietario: alice,
            matriculaOrigem: 0,
            tipo: RegistryMDCompliance.PropertyType.URBANO,
            isRegular: true
        });
        
        vm.prank(registrar);
        registry.registerProperty(prop);
        
        // Deve passar
        bool canTransfer = registry.moduleCheck(alice, address(5), MATRICULA_ID, compliance);
        assertTrue(canTransfer);
    }
    
    function test_RevertWhen_ModuleCheck_NotRegistered() public {
        vm.expectRevert(abi.encodeWithSelector(PropertyNotRegistered.selector, MATRICULA_ID));
        registry.moduleCheck(alice, address(5), MATRICULA_ID, compliance);
    }
    
    function test_RevertWhen_ModuleCheck_NotRegular() public {
        // Registrar imóvel irregular
        RegistryMDCompliance.PropertyInfo memory prop = RegistryMDCompliance.PropertyInfo({
            matriculaId: MATRICULA_ID,
            folha: 100,
            comarca: "Sao Paulo",
            endereco: "Rua Exemplo, 123",
            metragem: 150,
            proprietario: alice,
            matriculaOrigem: 0,
            tipo: RegistryMDCompliance.PropertyType.URBANO,
            isRegular: false
        });
        
        vm.prank(registrar);
        registry.registerProperty(prop);
        
        // Não deve passar
        vm.expectRevert(abi.encodeWithSelector(PropertyTransferNotAllowed.selector, MATRICULA_ID));
        registry.moduleCheck(alice, address(5), MATRICULA_ID, compliance);
    }
    
    // ========== Property Types Tests ==========
    
    function test_PropertyTypes() public {
        // URBANO
        RegistryMDCompliance.PropertyInfo memory urbano = RegistryMDCompliance.PropertyInfo({
            matriculaId: 1,
            folha: 100,
            comarca: "Sao Paulo",
            endereco: "Rua X",
            metragem: 100,
            proprietario: alice,
            matriculaOrigem: 0,
            tipo: RegistryMDCompliance.PropertyType.URBANO,
            isRegular: true
        });
        
        // RURAL
        RegistryMDCompliance.PropertyInfo memory rural = RegistryMDCompliance.PropertyInfo({
            matriculaId: 2,
            folha: 200,
            comarca: "Interior",
            endereco: "Fazenda Y",
            metragem: 10000,
            proprietario: alice,
            matriculaOrigem: 0,
            tipo: RegistryMDCompliance.PropertyType.RURAL,
            isRegular: true
        });
        
        // LITORAL
        RegistryMDCompliance.PropertyInfo memory litoral = RegistryMDCompliance.PropertyInfo({
            matriculaId: 3,
            folha: 300,
            comarca: "Praia",
            endereco: "Beira Mar Z",
            metragem: 500,
            proprietario: alice,
            matriculaOrigem: 0,
            tipo: RegistryMDCompliance.PropertyType.LITORAL,
            isRegular: true
        });
        
        vm.startPrank(registrar);
        registry.registerProperty(urbano);
        registry.registerProperty(rural);
        registry.registerProperty(litoral);
        vm.stopPrank();
        
        assertEq(uint(registry.getProperty(1).tipo), uint(RegistryMDCompliance.PropertyType.URBANO));
        assertEq(uint(registry.getProperty(2).tipo), uint(RegistryMDCompliance.PropertyType.RURAL));
        assertEq(uint(registry.getProperty(3).tipo), uint(RegistryMDCompliance.PropertyType.LITORAL));
    }
    
    // ========== Get Property Tests ==========
    
    function test_RevertWhen_GetProperty_NotFound() public {
        vm.expectRevert(abi.encodeWithSelector(PropertyNotRegistered.selector, 999));
        registry.getProperty(999);
    }
}

