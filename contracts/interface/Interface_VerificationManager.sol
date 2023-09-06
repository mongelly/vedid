// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;
interface IVerificationManager {
    function verificationInfo(bytes32 _did, bytes32 _verId) external view returns(bool active,uint32 _type,string memory controller,bytes[] memory _keyValue);
    function verificationActive(bytes32 _did, bytes32 _verId) external view returns(bool);

    function addVerification(bytes32 _did,bytes32 _ctrlId,bytes[] memory _args,uint32 _type,string memory controller,bytes[] memory _keyvalue) external returns(bool,bytes32);
    function delVerification(bytes32 _did,bytes32 _ctrlId,bytes[] memory _args,bytes32 _delVerId) external returns(bool);

    function verify(bytes32 _did,bytes32 _verid,bytes[] memory _args) external returns(bool passed, string memory error);

    event AddVerification(bytes32 indexed _did,bytes32 indexed _verId);
    event DelVerification(bytes32 indexed _did,bytes32 indexed _verId);
}