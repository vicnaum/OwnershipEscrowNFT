// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/*
 * The Escrow contract is designed to hold the ownership of another contract (the "Escrowed contract") and
 * facilitate the transfer of ownership to a new owner. The Escrow contract instance is deployed by the EscrowNFT
 * contract, which passes the parameters for the ownership transfer to the Escrow contract's initialize function.
 *
 * The parameters for the ownership transfer are stored in an EscrowParams struct, which includes the following fields:
 * - escrowedContract: The address of the Escrowed contract.
 * - transferOwnershipFunctionSignature: The function signature of the ownership transfer function in the Escrowed
 *   contract.
 * - transferOwnershipFunctionParams: An array of bytes32 representing the parameters for the ownership transfer function.
 *   The address of the new owner is empty in this array and should be inserted at the moment when its known.
 * - newOwnerIndex: The position in the parameters array where the address of the new owner should be inserted.
 * - getOwnerFunctionSignature: The function signature of the function in the Escrowed contract that checks the owner of
 *   the contract.
 *
 * The Escrow contract is controlled by the EscrowNFT contract, which has permission to trigger the ownership transfer.
 * It also has the EscrowStatus which works as a one-way state machine and tracks the status of the escrow.
 *
 * The Escrow contract has the following functions:
 * - confirmEscrow: Confirms that the Escrow contract instance has ownership over the Escrowed contract.
 * - releaseEscrow: Transfers the ownership of the Escrowed contract to a new owner. This function can only be called
 *   by the controller - EscrowNFT. It inserts the address of the new owner into the parameters array at the position
 *   specified by newOwnerIndex, then calls the function specified by transferOwnershipFunctionSignature in the Escrowed
 *   contract with the new ownership parameters.
 * - getEscrowedOwnership: Checks who is the owner of the Escrowed contract by calling the function specified by
 *   getOwnerFunctionSignature.
 * - getEscrowParams: Returns the parameters for the ownership transfer.
 * - getEscrowStatus: Returns the status of the Escrow contract (Deployed/Initialized/Confirmed/Released).
 */

/**
 * @dev Struct for the parameters of the ownership transfer
 */
struct EscrowParams {
    address escrowedContract;
    string transferOwnershipFunctionSignature;
    bytes32[] transferOwnershipFunctionParams;
    uint256 newOwnerIndex;
    string getOwnerFunctionSignature;
}

/**
 * @title IEscrow
 * @dev This is the interface for the Escrow contract
 */
interface IEscrow {
    enum EscrowStatus {
        DEPLOYED,
        INITIALISED,
        CONFIRMED,
        RELEASED
    }

    /// @dev Emitted when an Escrow contract instance ownership of Escrowed contract is confirmed.
    /// @param escrowedContract The address of the Escrowed contract
    event EscrowConfirmed(address indexed escrowedContract);

    /// @dev Emitted when an Escrowed contract is released from the Escrow contract instance.
    /// @param escrowedContract The address of the Escrowed contract
    /// @param newOwner The address of the new owner of the Escrowed contract
    event EscrowReleased(address indexed escrowedContract, address indexed newOwner);

    function initialize(EscrowParams memory _escrowParams, address _escrowController) external;

    /**
     * @notice Confirms the Escrow contract is the owner of the Escrowed contract
     */
    function confirmEscrow() external;

    /**
     * @notice Transfers the ownership of the Escrowed contract to a new owner
     * @param newOwner The address of the new owner
     */
    function releaseEscrow(address newOwner) external;

    /**
     * @notice Gets the owner of the Escrowed contract using getOwnerFunctionSignature call
     * @return address of the Owner contract owner
     */
    function getEscrowedOwnership() external view returns (address);

    /**
     * @notice Gets the parameters for the ownership transfer
     * @return EscrowParams struct
     */
    function getEscrowParams() external view returns (EscrowParams memory);

    /**
     * @notice Gets the status of the Escrow contract
     * @return EscrowStatus enum
     */
    function getEscrowStatus() external view returns (EscrowStatus);

    /**
     * @notice Gets the controller of the Escrow contract
     * @return address of the controller
     */
    function getController() external view returns (address);
}
