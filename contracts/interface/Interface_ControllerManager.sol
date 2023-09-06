// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IControllerManager {
    function controllerInfo(bytes32 _did,bytes32 _ctrlId) external view returns (bool active,bytes32 _cdid,bytes32 _cVerId);
    function controllerActive(bytes32 _did,bytes32 _ctrlId) external view returns(bool);

    function addController(bytes32 _did,bytes32 _ctrlId,bytes[] memory _args,bytes32 _cdid,bytes32 _cVerId) external returns(bool, bytes32);
    function delController(bytes32 _did,bytes32 _ctrlId,bytes[] memory _args,bytes32 _delCtrlId) external returns(bool);
    function verify(bytes32 _did,bytes32 _ctrlId,bytes[] memory _args) external returns(bool passed, string memory error);

    event AddController(bytes32 indexed _did,bytes32 indexed _cid);
    event DelController(bytes32 indexed _did,bytes32 indexed _cid);
}