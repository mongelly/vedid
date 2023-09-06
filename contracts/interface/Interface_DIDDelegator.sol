// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IDIDDelegator {
    function execute(
        bytes32 _did,
        bytes32 _verId,
        bytes[] memory _verArgs,
        address _to,
        bytes memory _callData
    ) external payable returns (bool, bytes memory);
}
