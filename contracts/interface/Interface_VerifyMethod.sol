// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

struct VerifyArgs {
    bytes32 did;
    bytes32 verid;
    address sender;
    address origin;
    bytes[] args;
}

interface IVerifyMethod {
    function verify(
        bytes[] memory _keyValue,
        VerifyArgs memory _verArgs
    ) external returns (bool);

    function typeId() external view returns (uint32);

    function typeName() external view returns (string memory);
}
