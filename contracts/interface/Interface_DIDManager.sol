// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IDIDManager {
    function register(bytes32 _did,address owner) external returns (bool);

    function setStatus(
        bytes32 _did,
        bytes32 _ctrlId,
        bytes[] memory _args,
        uint32 _status
    ) external returns (bool);

    function status(bytes32 _did) external view returns (uint32);

    event Register(bytes32 indexed _did);
    event StatusChanged(
        bytes32 indexed _did,
        uint32 _old,
        uint32 _new,
        uint32 _prevChanged
    );
}
