// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {EscrowParams, IEscrow} from "src/interfaces/IEscrow.sol";

interface IEscrowNFT {
    /// @dev Emitted when a new Escrow contract instance is deployed. NFT is minted.
    /// @param escrowedContract The address of the Escrowed contract
    /// @param escrowInstance The address of the new Escrow contract instance
    /// @param escrowParams The parameters for the ownership transfer
    /// @param tokenId The token ID of the EscrowNFT
    /// @param owner The address where the EscrowNFT is initially minted to
    event EscrowCreated(
        address indexed escrowedContract,
        address escrowInstance,
        EscrowParams escrowParams,
        uint256 indexed tokenId,
        address indexed owner
    );

    /// @dev Emitted when an Escrow contract instance is confirmed
    /// @param escrowedContract The address of the Escrowed contract
    /// @param tokenId The token ID of the EscrowNFT
    event EscrowConfirmed(address indexed escrowedContract, uint256 indexed tokenId);

    /// @dev Emitted when an Escrowed contract is released from the Escrow contract instance. NFT is burnt.
    /// @param escrowedContract The address of the Escrowed contract
    /// @param tokenId The token ID of the EscrowNFT
    /// @param newOwner The address of the new owner of the Escrowed contract
    event EscrowReleased(address indexed escrowedContract, uint256 indexed tokenId, address indexed newOwner);

    /// @notice Deploys a new Escrow contract instance and mints an EscrowNFT
    /// @param _escrowParams The parameters for the ownership transfer
    /// @param _to The address of the Owner of the Escrow contract
    /// @return address of the new Escrow contract instance
    function createEscrow(EscrowParams memory _escrowParams, address _to) external returns (uint256);

    /// @notice Confirms the Escrow contract instance has ownership over the Escrowed contract
    /// @dev This function can be called by anyone once the ownership of the Escrowed contract is transferred to the
    /// Escrow contract instance
    /// @param tokenId The token ID of the EscrowNFT
    function confirmEscrow(uint256 tokenId) external;

    /// @notice Releases the Escrowed contract from the Escrow contract instance to a new owner
    /// @dev This function can only be called by the Owner of the EscrowNFT tokenId
    /// @param tokenId The token ID of the EscrowNFT
    /// @param newOwner The address of the new owner of the Escrowed contract
    function releaseEscrow(uint256 tokenId, address newOwner) external;

    /// @notice Checks if the Escrow contract instance is confirmed (has ownership over the Escrowed contract)
    /// @param tokenId The token ID of the EscrowNFT
    /// @return true if the Escrow contract instance is confirmed
    function isConfirmed(uint256 tokenId) external view returns (bool);
}
