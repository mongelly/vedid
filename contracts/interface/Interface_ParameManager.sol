// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IParameManager {
    function get(bytes32 _did,bytes32 _pid) external view returns(bytes memory _value);
    
    function set(bytes32 _did,bytes32 _pid,bytes memory _value,bytes32 _uctrlid,bytes[] memory _args) external returns(bool);
    function del(bytes32 _did,bytes32 _pid,bytes32 _ucid,bytes[] memory _args) external returns(bool);

    event ParameChanged(bytes32 indexed _did, bytes32 indexed _pid, bytes _old, bytes _new,uint32 _prevChanged);
    event DelParame(bytes32 indexed _did, bytes32 indexed _pid);
}