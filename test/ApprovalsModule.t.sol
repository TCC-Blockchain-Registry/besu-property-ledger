// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ApprovalsModule} from "../src/compliance/modules/ApprovalsModule.sol";

contract ApprovalsModuleTest is Test {
    ApprovalsModule public approvals;
    
    address admin = address(1);
    address orchestrator = address(2);
    address alice = address(3); // vendedora
    address bob = address(4); // comprador
    address prefeitura = address(5);
    address cartorio = address(6);
    address instituicaoFinanceira = address(7);
    address compliance = address(8);
    
    uint256 constant MATRICULA_ID = 123456;
    
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
    
    function setUp() public {
        vm.startPrank(admin);
        approvals = new ApprovalsModule(admin);
        
        // Grant ORCHESTRATOR_ROLE
        bytes32 ORCHESTRATOR_ROLE = keccak256("ORCHESTRATOR_ROLE");
        approvals.grantRole(ORCHESTRATOR_ROLE, orchestrator);
        vm.stopPrank();
    }
    
    // ========== Configuration Tests ==========
    
    function test_ConfigureTransfer() public {
        address[] memory requiredApprovers = new address[](3);
        requiredApprovers[0] = prefeitura;
        requiredApprovers[1] = cartorio;
        requiredApprovers[2] = instituicaoFinanceira;
        
        vm.prank(orchestrator);
        vm.expectEmit(true, true, true, true);
        emit TransferConfigured(
            keccak256(abi.encode(alice, bob, MATRICULA_ID, compliance)),
            alice,
            bob,
            MATRICULA_ID,
            requiredApprovers
        );
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        
        (
            address[] memory approvers,
            uint256 approvalCount,
            bool isConfigured,
            bool buyerAccepted
        ) = approvals.getTransferConfig(alice, bob, MATRICULA_ID, compliance);
        
        assertEq(approvers.length, 3);
        assertEq(approvers[0], prefeitura);
        assertEq(approvers[1], cartorio);
        assertEq(approvers[2], instituicaoFinanceira);
        assertEq(approvalCount, 0);
        assertTrue(isConfigured);
        assertFalse(buyerAccepted);
    }
    
    function test_RevertWhen_ConfigureTransfer_NotOrchestrator() public {
        address[] memory requiredApprovers = new address[](1);
        requiredApprovers[0] = prefeitura;
        
        vm.prank(alice);
        vm.expectRevert();
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
    }
    
    function test_RevertWhen_ConfigureTransfer_EmptyApprovers() public {
        address[] memory requiredApprovers = new address[](0);
        
        vm.prank(orchestrator);
        vm.expectRevert("empty approvers");
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
    }
    
    function test_RevertWhen_ConfigureTransfer_AlreadyConfigured() public {
        address[] memory requiredApprovers = new address[](1);
        requiredApprovers[0] = prefeitura;
        
        vm.startPrank(orchestrator);
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        vm.expectRevert("already configured");
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        vm.stopPrank();
    }
    
    // ========== Approval Tests ==========
    
    function test_Approve() public {
        // Configure
        address[] memory requiredApprovers = new address[](2);
        requiredApprovers[0] = prefeitura;
        requiredApprovers[1] = cartorio;
        
        vm.prank(orchestrator);
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        
        // Prefeitura aprova
        vm.prank(prefeitura);
        vm.expectEmit(true, true, false, true);
        emit Approved(
            keccak256(abi.encode(alice, bob, MATRICULA_ID, compliance)),
            prefeitura,
            1,
            2
        );
        approvals.approve(alice, bob, MATRICULA_ID, compliance);
        
        (,uint256 approvalCount,,) = approvals.getTransferConfig(alice, bob, MATRICULA_ID, compliance);
        assertEq(approvalCount, 1);
        
        // Cartório aprova
        vm.prank(cartorio);
        approvals.approve(alice, bob, MATRICULA_ID, compliance);
        
        (,approvalCount,,) = approvals.getTransferConfig(alice, bob, MATRICULA_ID, compliance);
        assertEq(approvalCount, 2);
    }
    
    function test_RevertWhen_Approve_NotConfigured() public {
        vm.prank(prefeitura);
        vm.expectRevert("not configured");
        approvals.approve(alice, bob, MATRICULA_ID, compliance);
    }
    
    function test_RevertWhen_Approve_NotRequiredApprover() public {
        address[] memory requiredApprovers = new address[](1);
        requiredApprovers[0] = prefeitura;
        
        vm.prank(orchestrator);
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        
        vm.prank(cartorio); // não está na lista
        vm.expectRevert("not required approver");
        approvals.approve(alice, bob, MATRICULA_ID, compliance);
    }
    
    function test_RevertWhen_Approve_AlreadyApproved() public {
        address[] memory requiredApprovers = new address[](1);
        requiredApprovers[0] = prefeitura;
        
        vm.prank(orchestrator);
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        
        vm.startPrank(prefeitura);
        approvals.approve(alice, bob, MATRICULA_ID, compliance);
        vm.expectRevert("already approved");
        approvals.approve(alice, bob, MATRICULA_ID, compliance); // segunda vez
        vm.stopPrank();
    }
    
    // ========== Buyer Acceptance Tests ==========
    
    function test_AcceptTransfer() public {
        address[] memory requiredApprovers = new address[](1);
        requiredApprovers[0] = prefeitura;
        
        vm.prank(orchestrator);
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        
        vm.prank(bob);
        vm.expectEmit(true, true, false, false);
        emit BuyerAccepted(
            keccak256(abi.encode(alice, bob, MATRICULA_ID, compliance)),
            bob
        );
        approvals.acceptTransfer(alice, MATRICULA_ID, compliance);
        
        (,,,bool buyerAccepted) = approvals.getTransferConfig(alice, bob, MATRICULA_ID, compliance);
        assertTrue(buyerAccepted);
    }
    
    function test_RevertWhen_AcceptTransfer_NotConfigured() public {
        vm.prank(bob);
        vm.expectRevert("not configured");
        approvals.acceptTransfer(alice, MATRICULA_ID, compliance);
    }
    
    function test_RevertWhen_AcceptTransfer_AlreadyAccepted() public {
        address[] memory requiredApprovers = new address[](1);
        requiredApprovers[0] = prefeitura;
        
        vm.prank(orchestrator);
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        
        vm.startPrank(bob);
        approvals.acceptTransfer(alice, MATRICULA_ID, compliance);
        vm.expectRevert("already accepted");
        approvals.acceptTransfer(alice, MATRICULA_ID, compliance); // segunda vez
        vm.stopPrank();
    }
    
    // ========== Module Check Tests ==========
    
    function test_ModuleCheck_Success() public {
        address[] memory requiredApprovers = new address[](2);
        requiredApprovers[0] = prefeitura;
        requiredApprovers[1] = cartorio;
        
        vm.prank(orchestrator);
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        
        // Aprovações
        vm.prank(prefeitura);
        approvals.approve(alice, bob, MATRICULA_ID, compliance);
        
        vm.prank(cartorio);
        approvals.approve(alice, bob, MATRICULA_ID, compliance);
        
        // Aceitação do comprador
        vm.prank(bob);
        approvals.acceptTransfer(alice, MATRICULA_ID, compliance);
        
        // Deve passar
        bool canTransfer = approvals.moduleCheck(alice, bob, MATRICULA_ID, compliance);
        assertTrue(canTransfer);
    }
    
    function test_ModuleCheck_NotConfigured() public {
        bool canTransfer = approvals.moduleCheck(alice, bob, MATRICULA_ID, compliance);
        assertFalse(canTransfer);
    }
    
    function test_ModuleCheck_MissingApprovals() public {
        address[] memory requiredApprovers = new address[](2);
        requiredApprovers[0] = prefeitura;
        requiredApprovers[1] = cartorio;
        
        vm.prank(orchestrator);
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        
        // Apenas 1 de 2 aprovações
        vm.prank(prefeitura);
        approvals.approve(alice, bob, MATRICULA_ID, compliance);
        
        // Comprador aceitou
        vm.prank(bob);
        approvals.acceptTransfer(alice, MATRICULA_ID, compliance);
        
        // Não deve passar (falta cartório)
        bool canTransfer = approvals.moduleCheck(alice, bob, MATRICULA_ID, compliance);
        assertFalse(canTransfer);
    }
    
    function test_ModuleCheck_BuyerNotAccepted() public {
        address[] memory requiredApprovers = new address[](1);
        requiredApprovers[0] = prefeitura;
        
        vm.prank(orchestrator);
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        
        // Aprovação
        vm.prank(prefeitura);
        approvals.approve(alice, bob, MATRICULA_ID, compliance);
        
        // Comprador NÃO aceitou
        
        // Não deve passar
        bool canTransfer = approvals.moduleCheck(alice, bob, MATRICULA_ID, compliance);
        assertFalse(canTransfer);
    }
    
    // ========== Module Transfer Action Tests ==========
    
    function test_ModuleTransferAction_ClearsConfig() public {
        address[] memory requiredApprovers = new address[](1);
        requiredApprovers[0] = prefeitura;
        
        vm.prank(orchestrator);
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        
        vm.prank(compliance);
        vm.expectEmit(true, false, false, false);
        emit TransferConfigCleared(keccak256(abi.encode(alice, bob, MATRICULA_ID, compliance)));
        approvals.moduleTransferAction(alice, bob, MATRICULA_ID);
        
        // Config deve estar limpa
        (,,bool isConfigured,) = approvals.getTransferConfig(alice, bob, MATRICULA_ID, compliance);
        assertFalse(isConfigured);
    }
    
    // ========== Integration Test ==========
    
    function test_FullTransferFlow() public {
        // 1. Configure
        address[] memory requiredApprovers = new address[](3);
        requiredApprovers[0] = prefeitura;
        requiredApprovers[1] = cartorio;
        requiredApprovers[2] = instituicaoFinanceira;
        
        vm.prank(orchestrator);
        approvals.configureTransfer(alice, bob, MATRICULA_ID, compliance, requiredApprovers);
        
        // 2. Aprovações
        vm.prank(prefeitura);
        approvals.approve(alice, bob, MATRICULA_ID, compliance);
        
        vm.prank(cartorio);
        approvals.approve(alice, bob, MATRICULA_ID, compliance);
        
        vm.prank(instituicaoFinanceira);
        approvals.approve(alice, bob, MATRICULA_ID, compliance);
        
        // 3. Comprador aceita
        vm.prank(bob);
        approvals.acceptTransfer(alice, MATRICULA_ID, compliance);
        
        // 4. Verifica se pode transferir
        bool canTransfer = approvals.moduleCheck(alice, bob, MATRICULA_ID, compliance);
        assertTrue(canTransfer);
        
        // 5. Simula transferência
        vm.prank(compliance);
        approvals.moduleTransferAction(alice, bob, MATRICULA_ID);
        
        // 6. Verifica limpeza
        (,,bool isConfigured,) = approvals.getTransferConfig(alice, bob, MATRICULA_ID, compliance);
        assertFalse(isConfigured);
    }
}

