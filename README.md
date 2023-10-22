# EscrowNFT

EscrowNFT is a project that allows the ownership of a smart contract to be escrowed into an NFT (Non-Fungible Token).
This enables the transfer of ownership to a new owner, trading on marketplaces, and other usual NFT operations.

## Architecture

The project consists of two main contracts: `Escrow.sol` and `EscrowNFT.sol`.

`Escrow.sol` The Escrow contract is designed to hold the ownership of another contract (the "Escrowed contract") and
facilitate the transfer of ownership to a new owner.

`EscrowNFT.sol` The EscrowNFT contract deploys new Escrow contract instances, mints an NFT for each instance, and
manages the lifecycle of each Escrow contract instance.

The lifecycle includes confirming the Escrow contract instance has ownership over the Escrowed contract and releasing the
Escrowed contract from the Escrow contract instance to a new owner (with burning the NFT).

## Example of Use

Here is a simple example of how to use the EscrowNFT contract:

1. Call the `createEscrow` function on the `EscrowNFT` contract, passing in the parameters for the ownership transfer.
2. The parameters for the `createEscrow` function are stored in an `EscrowParams` struct, which includes the following fields:
   - `escrowedContract`: The address of the Escrowed contract. For example, `0x123...`.
   - `transferOwnershipFunctionSignature`: The function signature of the ownership transfer function in the Escrowed contract. For example, `"transferOwnership(address)"`.
   - `transferOwnershipFunctionParams`: An array of bytes32 representing the parameters for the ownership transfer function. The address of the new owner is empty in this array and should be inserted at the moment when its known. For example, `[bytes32("")]`.
   - `newOwnerIndex`: The position in the parameters array where the address of the new owner should be inserted. For example, `0`.
   - `getOwnerFunctionSignature`: The function signature of the function in the Escrowed contract that checks the owner of the contract. For example, `"owner()"`.
3. The `EscrowNFT` contract will deploy a new `Escrow` contract instance and mint an NFT for this instance, returning its tokenId.
4. Transfer the ownership of the contract you want to escrow to the newly deployed Escrow contract instance (you can get its address by calling `EscrowNFT.escrows(tokenId)`)
5. Confirm that the `Escrow` contract instance has ownership over the Escrowed contract, by calling the `confirmEscrow(tokenId)` function on the `EscrowNFT` contract, passing in the token ID.
6. Transfer, trade and do whatever you like with the NFT - whoever owns the NFT can Release the escrow and transfer ownership of the Escrowed contract to any address.
7. To release the ownership of the Escrowed contract to a new owner, call the `releaseEscrow(tokenId, newOwner)` function on the `EscrowNFT` contract, passing in the token ID and the address of the new owner. The NFT will be burned in the process.
