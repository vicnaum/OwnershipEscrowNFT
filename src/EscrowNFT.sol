// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Escrow} from "src/Escrow.sol";
import {EscrowParams, IEscrow} from "src/interfaces/IEscrow.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IEscrowNFT} from "src/interfaces/IEscrowNFT.sol";

/**
 * @title IEscrowNFT
 * @notice EscrowNFT allows to Escrow smart contract ownership into an NFT, which allows to transfer it to a new owner,
 * trading, etc.
 * @dev An EscrowNFT contract deploys new Escrow contract instances, mints an NFT for each instance, and manages the
 * lifecycle of each Escrow contract instance.
 * The lifecycle includes confirming the Escrow contract instance has ownership over the Escrowed contract and
 * releasing the Escrowed contract from the Escrow contract instance to a new owner (burning the NFT).
 */
contract EscrowNFT is ERC721, IEscrowNFT {
    address public immutable escrowImplementation;

    uint256 internal _lastTokenId;

    uint256 public totalSupply;

    mapping(uint256 tokenId => IEscrow escrow) public escrows;

    modifier onlyTokenHolder(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token holder");
        _;
    }

    constructor() ERC721("EscrowNFT", "ESCROW") {
        escrowImplementation = address(new Escrow());
    }

    /// @inheritdoc IEscrowNFT
    function createEscrow(EscrowParams memory _escrowParams, address _to) public returns (uint256) {
        IEscrow escrowInstance = IEscrow(Clones.clone(escrowImplementation));
        uint256 tokenId = ++_lastTokenId;
        ++totalSupply;
        escrowInstance.initialize(_escrowParams, address(this));
        escrows[tokenId] = escrowInstance;
        _safeMint(_to, tokenId);
        emit EscrowCreated(_escrowParams.escrowedContract, address(escrowInstance), _escrowParams, tokenId, _to);
        return (tokenId);
    }

    /// @inheritdoc IEscrowNFT
    function confirmEscrow(uint256 tokenId) public {
        IEscrow escrowInstance = escrows[tokenId];
        escrowInstance.confirmEscrow();
        emit EscrowConfirmed(escrowInstance.getEscrowParams().escrowedContract, tokenId);
    }

    /// @inheritdoc IEscrowNFT
    function releaseEscrow(uint256 tokenId, address newOwner) public onlyTokenHolder(tokenId) {
        IEscrow escrowInstance = escrows[tokenId];
        escrowInstance.releaseEscrow(newOwner);
        --totalSupply;
        _burn(tokenId);
        emit EscrowReleased(escrowInstance.getEscrowParams().escrowedContract, tokenId, newOwner);
    }

    /// @inheritdoc IEscrowNFT
    function isConfirmed(uint256 tokenId) public view returns (bool) {
        return escrows[tokenId].getEscrowStatus() == IEscrow.EscrowStatus.CONFIRMED;
    }
}
