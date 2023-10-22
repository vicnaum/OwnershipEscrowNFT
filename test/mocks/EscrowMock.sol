// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {EscrowParams, IEscrow} from "src/interfaces/IEscrow.sol";

contract EscrowMock is IEscrow {
    EscrowParams internal escrowParams;
    EscrowStatus internal escrowStatus;

    function initialize(EscrowParams memory _escrowParams, address _escrowController) public {}

    function releaseEscrow(address newOwner) external override {}

    function confirmEscrow() external {}

    function getEscrowedOwnership() external view override returns (address) {}

    function getEscrowParams() external view override returns (EscrowParams memory) {
        return escrowParams;
    }

    function getEscrowStatus() external view returns (EscrowStatus) {
        return escrowStatus;
    }

    function getController() external view returns (address) {}

    // Mock functions
    function setEscrowParams(EscrowParams memory _escrowParams) public {
        escrowParams = _escrowParams;
    }

    function setEscrowStatus(EscrowStatus _escrowStatus) public {
        escrowStatus = _escrowStatus;
    }
}
