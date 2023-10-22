// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {OwnableMock} from "test/mocks/OwnableMock.sol";
import {IEscrow} from "src/interfaces/IEscrow.sol";
import {Escrow} from "src/Escrow.sol";
import {EscrowParams} from "src/interfaces/IEscrow.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract EscrowTest is Test {
    address oldOwner = makeAddr("oldOwner");
    OwnableMock escrowedContract;
    EscrowParams defaultEscrowParams;
    Escrow escrow;
    IEscrow escrowInstance;

    event EscrowConfirmed(address indexed escrowedContract);
    event EscrowReleased(address indexed escrowedContract, address indexed newOwner);

    function setUp() public {
        escrowedContract = new OwnableMock(oldOwner);

        defaultEscrowParams = EscrowParams({
            escrowedContract: address(escrowedContract),
            transferOwnershipFunctionSignature: "transferOwnership(address)",
            transferOwnershipFunctionParams: new bytes32[](1),
            newOwnerIndex: 0,
            getOwnerFunctionSignature: "owner()"
        });

        escrow = new Escrow();

        escrowInstance = IEscrow(Clones.clone(address(escrow)));
    }

    // Negatives - Flow

    function testCannotInitializeAgain() public {
        escrowInstance.initialize(defaultEscrowParams, address(this));

        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.INITIALISED));

        vm.expectRevert("Escrow can only be initialised in DEPLOYED status");
        escrowInstance.initialize(defaultEscrowParams, address(this));
    }

    function testCannotConfirmEscrow_ifNotInitialized() public {
        vm.expectRevert("Caller is not the controller");
        escrowInstance.confirmEscrow();
    }

    function testCannotReleaseEscrow_ifNotInitialized() public {
        vm.expectRevert("Caller is not the controller");
        escrowInstance.releaseEscrow(address(this));
    }

    function testCannotConfirmEscrow_ifOwnershipNotTransferred() public {
        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.expectRevert("Escrow contract is not the owner of Escrowed contract");
        escrowInstance.confirmEscrow();
    }

    function testCannotReleaseEscrow_ifNotConfirmed() public {
        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.prank(oldOwner);
        escrowedContract.transferOwnership(address(escrowInstance));

        vm.expectRevert("Escrow is not in confirmed status");
        escrowInstance.releaseEscrow(address(this));
    }

    function testCannotConfirmEscrow_ifAlreadyReleased() public {
        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.prank(oldOwner);
        escrowedContract.transferOwnership(address(escrowInstance));

        escrowInstance.confirmEscrow();
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.CONFIRMED));

        vm.expectRevert("Escrow is not in INITIALISED status");
        escrowInstance.confirmEscrow();
    }

    function testCannotInitialize_afterConfirmed() public {
        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.prank(oldOwner);
        escrowedContract.transferOwnership(address(escrowInstance));

        escrowInstance.confirmEscrow();
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.CONFIRMED));

        vm.expectRevert("Escrow can only be initialised in DEPLOYED status");
        escrowInstance.initialize(defaultEscrowParams, address(this));
    }

    function testCannotInitialize_afterReleased() public {
        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.prank(oldOwner);
        escrowedContract.transferOwnership(address(escrowInstance));

        escrowInstance.confirmEscrow();
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.CONFIRMED));

        escrowInstance.releaseEscrow(address(this));
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.RELEASED));

        vm.expectRevert("Escrow can only be initialised in DEPLOYED status");
        escrowInstance.initialize(defaultEscrowParams, address(this));
    }

    // Negatives - Access Control

    function testCannotConfirmEscrow_ifNotController(address notController) public {
        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.assume(notController != escrowInstance.getController());

        vm.expectRevert("Caller is not the controller");
        vm.prank(notController);
        escrowInstance.confirmEscrow();
    }

    function testCannotReleaseEscrow_ifNotController(address notController) public {
        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.assume(notController != escrowInstance.getController());

        vm.prank(oldOwner);
        escrowedContract.transferOwnership(address(escrowInstance));

        escrowInstance.confirmEscrow();
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.CONFIRMED));

        vm.expectRevert("Caller is not the controller");
        vm.prank(notController);
        escrowInstance.releaseEscrow(address(this));
    }

    // Negatives

    function testCannotReleaseEscrow_toZeroAddress() public {
        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.prank(oldOwner);
        escrowedContract.transferOwnership(address(escrowInstance));

        escrowInstance.confirmEscrow();
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.CONFIRMED));

        vm.expectRevert("Failed to transfer ownership");
        escrowInstance.releaseEscrow(address(0));
    }

    function testCannotReleaseEscrow_ifOwnershipTransferFailed() public {
        defaultEscrowParams.transferOwnershipFunctionSignature = "transfer(address)";
        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.prank(oldOwner);
        escrowedContract.transferOwnership(address(escrowInstance));

        escrowInstance.confirmEscrow();
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.CONFIRMED));

        vm.expectRevert("Failed to transfer ownership");
        escrowInstance.releaseEscrow(address(this));
    }

    function testCannotGetOwnership_ifFunctionIsWrong() public {
        defaultEscrowParams.getOwnerFunctionSignature = "owner123()";
        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.expectRevert("Failed to get ownership");
        escrowInstance.getEscrowedOwnership();
    }

    // Scenarios

    function testConstructor() public {
        assertEq(uint8(escrow.getEscrowStatus()), uint8(IEscrow.EscrowStatus.INITIALISED));
    }

    function testInitializeAndGetEscrowParams(address controller) public {
        escrowInstance.initialize(defaultEscrowParams, controller);

        assertEq(escrowInstance.getEscrowParams().escrowedContract, defaultEscrowParams.escrowedContract);
        assertEq(
            escrowInstance.getEscrowParams().transferOwnershipFunctionSignature,
            defaultEscrowParams.transferOwnershipFunctionSignature
        );
        assertEq(
            escrowInstance.getEscrowParams().transferOwnershipFunctionParams.length,
            defaultEscrowParams.transferOwnershipFunctionParams.length
        );
        assertEq(escrowInstance.getEscrowParams().newOwnerIndex, defaultEscrowParams.newOwnerIndex);
        assertEq(
            escrowInstance.getEscrowParams().getOwnerFunctionSignature, defaultEscrowParams.getOwnerFunctionSignature
        );
        assertEq(escrowInstance.getController(), controller);
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.INITIALISED));
    }

    function testConfirmEscrow() public {
        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.prank(oldOwner);
        escrowedContract.transferOwnership(address(escrowInstance));

        assertEq(escrowedContract.owner(), address(escrowInstance));

        vm.expectEmit(true, true, true, true, address(escrowInstance));
        emit EscrowConfirmed(defaultEscrowParams.escrowedContract);
        escrowInstance.confirmEscrow();

        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.CONFIRMED));
    }

    function testGetEscrowedOwnership(address randomOwner) public {
        vm.assume(randomOwner != address(0));

        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.prank(oldOwner);
        escrowedContract.transferOwnership(randomOwner);

        assertEq(escrowInstance.getEscrowedOwnership(), randomOwner);
    }

    function testReleaseEscrow(address randomOwner) public {
        vm.assume(randomOwner != address(0));

        escrowInstance.initialize(defaultEscrowParams, address(this));

        vm.prank(oldOwner);
        escrowedContract.transferOwnership(address(escrowInstance));

        assertEq(escrowedContract.owner(), address(escrowInstance));
        escrowInstance.confirmEscrow();

        vm.expectEmit(true, true, true, true, address(escrowInstance));
        emit EscrowReleased(defaultEscrowParams.escrowedContract, randomOwner);
        escrowInstance.releaseEscrow(randomOwner);

        assertEq(escrowedContract.owner(), randomOwner);
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.RELEASED));
    }

    function testGetEscrowStatus() public {
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.DEPLOYED));

        escrowInstance.initialize(defaultEscrowParams, address(this));
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.INITIALISED));

        vm.prank(oldOwner);
        escrowedContract.transferOwnership(address(escrowInstance));

        escrowInstance.confirmEscrow();
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.CONFIRMED));

        escrowInstance.releaseEscrow(address(this));
        assertEq(uint8(escrowInstance.getEscrowStatus()), uint8(IEscrow.EscrowStatus.RELEASED));
    }
}
