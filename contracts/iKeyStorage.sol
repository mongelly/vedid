pragma solidity >= 0.4.24;

interface IKeyStorage {
    function keyVerify(bytes32 _vedid,bytes32 _keyid, bytes calldata _value) external;
    function keyExists(bytes32 _vedid,bytes32 _keyid) external view returns(bool);
    function getKeyInfo(bytes32 _vedid,bytes32 _keyid) external view returns(uint8,bytes,bool);
    function addNewKey(bytes32 _vedid,bytes32 _keyid,uint8 _keytype,bytes calldata _value) external;
    function changeKey(bytes32 _vedid,bytes32 _keyid,uint8 _keytype,bytes calldata _value) external;
    function removeKey(bytes32 _vedid,bytes32 _keyid) external;
}