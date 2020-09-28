pragma solidity >= 0.4.24;

import {IKeyController} from "./iKeyController.sol";
import {IBaseDataSet} from "./iBaseDataSet.sol";

contract OwnerManage is IBaseDataSet,IRegistry,IKeyController {
    bytes32 createKeyID = 0x0e00016b6579732d310000000000000000000000000000000000000000000000;

    address internal vedidHubAddr;
    address internal manager;

    struct KeyInfo {
        bytes32 keyid;    // the full keyid is <vedid> + "#" +<keyid>
        bytes32 prev;   // it's use for through the map
        bytes32 next;   // it's use for through the map
    }

    struct IndexInfo {
        mapping(bytes32 => KeyInfo) keys;
        bytes32 headKey;
        bytes32 tailKey;
    }

    mapping(bytes32 => IndexInfo) internal owners;

    event KeyChange(bytes24 indexed _vedid,bytes32 _keyid,string action);

    constructor() public{
        owner = msg.sender;
    }

    function transferManager(address _newManager) public onlyManager{
        require(_newOwner != address(0), "invalid new manager");
        address memory _oldManager = manager;
        manager = _newManager;

        emit TransferManager(_newManager,_oldManager,"vedid:manager changed");
    }

    function getvedidHubAddress() public view returns(address){
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

    function keyExists(bytes32 _vedid,bytes32 _keyid) public view returns(bool){


        return vedidMap[_vedid].keys[_keyid].keyid == _keyid;
    }

    function addNewKey(bytes32 _vedid,bytes32 _keyid) {
        
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