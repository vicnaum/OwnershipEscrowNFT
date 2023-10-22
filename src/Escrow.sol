// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {EscrowParams, IEscrow} from "src/interfaces/IEscrow.sol";

/**
 * @title Escrow
 * @notice The Escrow contract is responsible for escrowing the ownership of a contract.
 * It is controlled by an EscrowController contract that is responsible for starting and finalizing the sale of the
 * contract whose ownership is being escrowed.
 * @dev This contract is meant to be deployed with EIP-1167 clone pattern by EscrowFactory contract.
 */
contract Escrow is IEscrow {
    /// @dev The parameters for the ownership transfer
    EscrowParams internal escrowParams;

    /// @notice The status of the Escrow contract
    EscrowStatus internal escrowStatus;

    /// @notice The address of the Controller (EscrowNFT) for this Escrow contract
    address internal controller;

    modifier onlyController() {
        require(msg.sender == controller, "Caller is not the controller");
        _;
    }

    constructor() {
        escrowStatus = EscrowStatus.INITIALISED;
    }

    function initialize(EscrowParams memory _escrowParams, address _escrowController) public {
        require(escrowStatus == EscrowStatus.DEPLOYED, "Escrow can only be initialised in DEPLOYED status");
        escrowParams = _escrowParams;
        controller = _escrowController;
        escrowStatus = EscrowStatus.INITIALISED;
    }

    /// @inheritdoc IEscrow
    function releaseEscrow(address newOwner) external override onlyController {
        require(escrowStatus == EscrowStatus.CONFIRMED, "Escrow is not in confirmed status");

        bytes32[] memory params = escrowParams.transferOwnershipFunctionParams;
        params[escrowParams.newOwnerIndex] = bytes32(uint256(uint160(newOwner)));

        // Convert transferOwnershipFunctionSignature to bytes4 selector
        bytes4 transferOwnershipFunctionSelector =
            bytes4(keccak256(bytes(escrowParams.transferOwnershipFunctionSignature)));

        (bool success,) =
            escrowParams.escrowedContract.call(abi.encodePacked(transferOwnershipFunctionSelector, params));
        require(success, "Failed to transfer ownership"); // TODO: check if this is needed
        require(_getEscrowedOwnership() == newOwner, "Ownership transfer failed"); // TODO: check if this is needed

        escrowStatus = EscrowStatus.RELEASED;
        emit EscrowReleased(escrowParams.escrowedContract, newOwner);
    }

    /// @inheritdoc IEscrow
    function confirmEscrow() external onlyController {
        require(escrowStatus == EscrowStatus.INITIALISED, "Escrow is not in INITIALISED status");
        require(_getEscrowedOwnership() == address(this), "Escrow contract is not the owner of Escrowed contract");
        escrowStatus = EscrowStatus.CONFIRMED;
        emit EscrowConfirmed(escrowParams.escrowedContract);
    }

    /// @inheritdoc IEscrow
    function getEscrowedOwnership() external view override returns (address) {
        return _getEscrowedOwnership();
    }

    /// @inheritdoc IEscrow
    function getEscrowParams() external view override returns (EscrowParams memory) {
        return escrowParams;
    }

    /// @inheritdoc IEscrow
    function getEscrowStatus() external view returns (EscrowStatus) {
        return escrowStatus;
    }

    /// @inheritdoc IEscrow
    function getController() external view returns (address) {
        return controller;
    }

    /// @dev Gets the owner of the Escrowed contract using getOwnerFunctionSignature call
    /// @return address of the Escrowed contract owner
    function _getEscrowedOwnership() internal view returns (address) {
        // Convert getOwnerFunctionSignature to bytes4 selector
        bytes4 getOwnerFunctionSelector = bytes4(keccak256(bytes(escrowParams.getOwnerFunctionSignature)));

        (bool success, bytes memory data) =
            escrowParams.escrowedContract.staticcall(abi.encodeWithSelector(getOwnerFunctionSelector));
        require(success, "Failed to get ownership");
        return abi.decode(data, (address));
    }
}
