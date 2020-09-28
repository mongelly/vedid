pragma solidity >= 0.4.24;

import { IBaseDataSet } from './iBaseDataSet';
import { VeDID } from './vedid';
import {Equal} from "./equal.sol";

constant KeyStorage is IBaseDataSet,IKeyStorage{

    address internal vedidAddr;
    address internal manager;
    uint256 internal keyCountLimit = 20;

    struct KeyInfo {
        bytes32 keyid;    // the full keyid is <vedid> + "#" +<keyid>
        uint8 keytype;    // example: 1.ethereumaddress 2.ecdsapublic 3.rsa
        bytes value;      // the publickey value or vechain-address
        bool actived;     // the publickey actived
    }

     struct KeysMapInfo {
        mapping(bytes32 => KeyInfo) keys;    // publickey map,map key is keyid.
        uint256 keyCount;
    }

    mapping(bytes32 => KeysMapInfo) internal vedidMap;

    event TransferManager(address indexed _newOwner,address indexed _oldOwner,string action);
    event KeyChange(bytes24 indexed _vedid,bytes32 _keyid,string action);

    constructor() public{
        owner = msg.sender;
    }

    /**  implement  IBaseDataSet */

    function transferManager(address _newManager) public onlyManager{
        require(_newOwner != address(0), "invalid new manager");
        address memory _oldManager = manager;
        manager = _newManager;

        emit TransferManager(_newManager,_oldManager,"vedid:manager changed");
    }

    function getVeDIDHubAddress() external view returns(address) public view returns(address){
        return vedidAddr;
    }

    function getManagerOfAddress() public view returns(address){
        return manager;
    }

    function getManagerOfVeDID() public view returns(bytes32){
        if(vedidAddr == address(0)){
            return bytes32(0);
        }
        return VeDID(vedidAddr).getManagerOfVeDID();
    }

    function registerTovedidHub() public onlyManager {
        vedidAddr = msg.sender;
    }

    /** implement  IKeyStorage */

    function keyVerify(bytes32 _vedid,bytes32 _keyid, bytes calldata _value) public view returns(bool){
        KeyInfo memory keyInfo = vedidMap[_vedid].keys[_vedid];
        return keyInfo.keyid = _keyid && keyInfo.actived && Equal.bytesEqual(keyInfo.value,_value);
        
    }

    function keyExists(bytes32 _vedid,bytes32 _keyid) public view returns(bool){
        KeyInfo memory keyInfo = vedidMap[_vedid].keys[_vedid];
        return keyInfo.keyid == _keyid && keyInfo.actived;
    }

    function addNewKey(bytes32 _vedid,bytes32 _keyid,uint8 _keytype,bytes memory _value) public onlyVeDIDHub{
        require(!keyExists(_vedid,_keyid), "vedid: keyid already exists");
        KeysMapInfo storage mapInfo = vedidMap[_vedid];
        require(mapInfo.keyCount <= keyCountLimit,"vedid: exceed the key maximum limit");

        KeyInfo storage newKeyInfo = mapInfo.keys[_keyid];
        newKeyInfo.keyid = _keyid;
        newKeyInfo.keytype = _keytype;
        newKeyInfo.value = _value;
        newKeyInfo.actived = true;

        mapInfo.keyCount = SafeMath.add(mapInfo.keyCount,1);

        emit KeyChange(_vedid,_keyid,"added");
    }

    function getKeysCount(bytes32 _vedid) public view return (uint256){
        return vedidMap[_vedid].keyCount;
    }

    function getKeyInfo(bytes32 _vedid,bytes32 _keyid) public view returns(uint8,bytes,bool) {
        KeysMapInfo memory mapinfo = vedidMap[_vedid];
        KeyInfo memory keyInfo = mpainfo.keys[_keyid];
        return (keyInfo.keytype, keyInfo.controller, keyInfo.value, keyInfo.actived);
    }

    

    function changeKey(bytes32 _vedid,bytes32 _keyid,uint8 _keytype,bytes memory _value) public onlyVeDIDHub{
        require(!keyExists(_vedid,_keyid), "vedid: keyid existed");
        KeysMapInfo storage mapInfo = vedidMap[_vedid];
        KeyInfo storage newKeyInfo = mapInfo.keys[_keyid];

        newKeyInfo.keytype = _keytype;
        newKeyInfo.value = _value;

        emit KeyChange(_vedid,_keyid,"changed");
    }

    function removeKey(bytes32 _vedid,bytes32 _keyid) public onlyVeDIDHub{
        require(keyExists(_vedid,_keyid), "vedid: keyid not exists");
        require(vedidMap[_vedid].keyCount != 1,"vedid:only one key,can't remove");
        require(vedidMap[_vedid].keys[_keyid].actived,"vedid: keyid already removed");

        KeysMapInfo storage mapInfo = vedidMap[_vedid];
        KeyInfo storage removeKeyInfo = mapInfo.keys[_keyid];

        removeKeyInfo.actived = false;

        mapInfo.keyCount = SafeMath.sub(mapInfo.keyCount,1);

        emit KeyChange(_vedid,_keyid,"deleted");
    }

    function setKeyCountLimit(uint256 _limit) public onlyManager{
        keyCountLimit = _limit;
    }

    modifier onlyManager(){
        if(owner == msg.sender){
            _;
            return;
        }

        if(vedidAddr != address(0) && VeDID(vedidAddr).getDatasetAddress(1) != address(0) && VeDID(vedidAddr).getOwnervedid() != bytes32(0)){
            address ownerManagerAddr = VeDID(vedidAddr).getDatasetAddress(1);
            bytes24 ownervedid = VeDID(vedidHubAddr).getOwnervedid();
            if(IKeyController(ownerManagerAddr).keyVerify(ownervedid,1,Convert.addressToBytes(msg.sender))){
                _;
                return;
            }
        }
        require(false,"vedid: permission denied");
    }

    modifier onlyVeDIDHub(){
        require(vedidAddr != address(0),"vedid: no set vedid hub contract address");
        require(vedidAddr == msg.sender || VeDID(vedidHubAddr).addressExistsInHub(msg.sender),"vedid: permission denied");
        _;
    }

    
}