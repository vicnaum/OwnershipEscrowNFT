// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {EscrowMock} from "test/mocks/EscrowMock.sol";
import {EscrowNFT} from "src/EscrowNFT.sol";
import {EscrowParams} from "src/interfaces/IEscrow.sol";
import {OwnableMock} from "test/mocks/OwnableMock.sol";
import {IEscrowNFT} from "src/interfaces/IEscrowNFT.sol";
import {IEscrow} from "src/interfaces/IEscrow.sol";

contract EscrowNFTTest is Test {
    address oldOwner = makeAddr("oldOwner");
    EscrowMock escrowMock;
    EscrowNFT escrowNFT;
    EscrowParams defaultEscrowParams;
    OwnableMock escrowedContract;

    event EscrowCreated(
        address indexed escrowedContract,
        address escrowInstance,
        EscrowParams escrowParams,
        uint256 indexed tokenId,
        address indexed owner
    );
    event EscrowConfirmed(address indexed escrowedContract, uint256 indexed tokenId);
    event EscrowReleased(address indexed escrowedContract, uint256 indexed tokenId, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public {
        escrowNFT = new EscrowNFT();
        escrowMock = new EscrowMock();

        // vm.etch the escrowImplementation with EscrowMock code
        vm.etch(escrowNFT.escrowImplementation(), address(escrowMock).code);

        escrowedContract = new OwnableMock(oldOwner);

        defaultEscrowParams = EscrowParams({
            escrowedContract: address(escrowedContract),
            transferOwnershipFunctionSignature: "transferOwnership(address)",
            transferOwnershipFunctionParams: new bytes32[](1),
            newOwnerIndex: 0,
            getOwnerFunctionSignature: "owner()"
        });
    }

    // Negative - Access control

    function testCannotReleaseEscrow_ifNotTokenHolder(address notTokenHolder) public {
        address to = makeAddr("to");
        uint256 tokenId = escrowNFT.createEscrow(defaultEscrowParams, to);
        vm.assume(notTokenHolder != to);

        vm.expectRevert("Caller is not the token holder");
        vm.prank(notTokenHolder);
        escrowNFT.releaseEscrow(tokenId, to);
    }

    // Scenarios
    function testCreateEscrow() public {
        uint256 nonce = vm.getNonce(address(escrowNFT));
        address escrowInstance = computeCreateAddress(address(escrowNFT), nonce);
        address to = makeAddr("to");
        uint256 lastTokenId = _getLastTokenId(address(escrowNFT));

        uint256 totalSupplyBefore = escrowNFT.totalSupply();

        vm.expectEmit(true, true, true, true, address(escrowNFT));
        emit Transfer(address(0), to, lastTokenId + 1);

        vm.expectEmit(true, true, true, true, address(escrowNFT));
        emit EscrowCreated(
            defaultEscrowParams.escrowedContract, address(escrowInstance), defaultEscrowParams, lastTokenId + 1, to
        );

        vm.expectCall(
            address(escrowInstance), abi.encodeCall(EscrowMock.initialize, (defaultEscrowParams, address(escrowNFT))), 1
        );

        uint256 tokenId = escrowNFT.createEscrow(defaultEscrowParams, to);

        assertEq(lastTokenId + 1, tokenId, "tokenId mismatch");
        assertEq(escrowNFT.totalSupply(), totalSupplyBefore + 1, "totalSupply mismatch");
        assertEq(address(escrowNFT.escrows(tokenId)), address(escrowInstance), "escrow instance mismatch");
        assertEq(escrowNFT.ownerOf(tokenId), to, "owner mismatch");
        assertEq(_getLastTokenId(address(escrowNFT)), lastTokenId + 1, "lastTokenId mismatch");
    }

    function testConfirmEscrow() public {
        address to = makeAddr("to");
        uint256 tokenId = escrowNFT.createEscrow(defaultEscrowParams, to);
        address escrowInstance = address(escrowNFT.escrows(tokenId));

        EscrowMock(escrowInstance).setEscrowParams(defaultEscrowParams);

        vm.expectCall(address(escrowInstance), abi.encodeCall(EscrowMock.confirmEscrow, ()), 1);

        vm.expectEmit(true, true, true, true, address(escrowNFT));
        emit EscrowConfirmed(defaultEscrowParams.escrowedContract, tokenId);

        escrowNFT.confirmEscrow(tokenId);
    }

    function testIsConfirmed() public {
        address to = makeAddr("to");
        uint256 tokenId = escrowNFT.createEscrow(defaultEscrowParams, to);
        address escrowInstance = address(escrowNFT.escrows(tokenId));

        EscrowMock(escrowInstance).setEscrowStatus(IEscrow.EscrowStatus.DEPLOYED);
        assertFalse(escrowNFT.isConfirmed(tokenId), "isConfirmed mismatch");

        EscrowMock(escrowInstance).setEscrowStatus(IEscrow.EscrowStatus.INITIALISED);
        assertFalse(escrowNFT.isConfirmed(tokenId), "isConfirmed mismatch");

        EscrowMock(escrowInstance).setEscrowStatus(IEscrow.EscrowStatus.CONFIRMED);
        assertTrue(escrowNFT.isConfirmed(tokenId), "isConfirmed mismatch");

        EscrowMock(escrowInstance).setEscrowStatus(IEscrow.EscrowStatus.RELEASED);
        assertFalse(escrowNFT.isConfirmed(tokenId), "isConfirmed mismatch");
    }

    function testReleaseEscrow(address newOwner) public {
        address to = makeAddr("to");
        uint256 tokenId = escrowNFT.createEscrow(defaultEscrowParams, to);
        address escrowInstance = address(escrowNFT.escrows(tokenId));

        uint256 totalSupplyBefore = escrowNFT.totalSupply();
        console.log("totalSupplyBefore: %d", totalSupplyBefore);

        EscrowMock(escrowInstance).setEscrowParams(defaultEscrowParams);

        vm.expectCall(address(escrowInstance), abi.encodeCall(EscrowMock.releaseEscrow, (newOwner)), 1);

        vm.expectEmit(true, true, true, true, address(escrowNFT));
        emit Transfer(to, address(0), tokenId);

        vm.expectEmit(true, true, true, true, address(escrowNFT));
        emit EscrowReleased(defaultEscrowParams.escrowedContract, tokenId, newOwner);

        vm.prank(to);
        escrowNFT.releaseEscrow(tokenId, newOwner);

        assertEq(escrowNFT.totalSupply(), totalSupplyBefore - 1, "totalSupply mismatch");
    }

    function _getLastTokenId(address _escrowNFT) internal view returns (uint256) {
        return uint256(vm.load(address(_escrowNFT), bytes32(uint256(7))));
    }
}
