pragma solidity >= 0.4.24;

interface IKeyController{
    function keyVerify(bytes32 _vedid,uint8 _keytype,bytes calldata _value) external view returns(bool);
    function keyExists(bytes32 _vedid,bytes32 _keyid) external view returns(bool);
    function addNewKey(bytes32 _vedid,bytes32 _keyid) external;
    function removeKey(bytes32 _vedid,bytes32 _keyid) external;
}