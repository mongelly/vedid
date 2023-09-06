// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IAuthenticationManager {
    function authenticationInfo(bytes32 _did,bytes32 _aid) external view returns (bytes32 _adid,bytes32 _averId);

    function addAuthentication(bytes32 _did,bytes32 _cdid,bytes32 _cverId,bytes32 _ucid,bytes[] memory _args) external returns(bool);
    function delAuthentication(bytes32 _did,bytes32 _aid,bytes32 _ucid,bytes[] memory _args) external returns(bool);

    event AddController(bytes32 indexed _did,bytes32 indexed _aid,bytes32 _adid,bytes32 _averId);
    event DelController(bytes32 indexed _did,bytes32 indexed _aid);
}