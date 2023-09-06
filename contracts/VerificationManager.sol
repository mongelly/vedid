// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interface/Interface_VerificationManager.sol";
import "./interface/Interface_DIDManager.sol";
import "./interface/Interface_ControllerManager.sol";
import "./interface/Interface_DIDHub.sol";
import "./interface/Interface_VerifyMethod.sol";

struct Verification {
    bool active;
    uint32 vtype;
    string controller;
    bytes[] keyValue;
    bytes32 prev;
    bytes32 next;
}

struct VerificationSummary {
    bytes32 firstId;
    bytes32 lastId;
    uint32 count;
}

contract VerificationManager is IVerificationManager {

    string public constant name = "VerificationManager";
    bytes32 public constant hubId = bytes32("VerificationManager");

    bytes32 private constant didMagId = bytes32("DIDManager");
    bytes32 private constant ctrlMagId = bytes32("ControllerManager");

    IDIDHub private didHub;
    mapping(uint32 => address) methodLibMap;
    mapping(bytes32 => mapping(bytes32 => Verification)) infoMap;
    mapping(bytes32 => VerificationSummary) summaryMap;

    constructor(address _didHub) {
        didHub = IDIDHub(_didHub);
    }

    function changeDIDHub(address _newHub) external onlyMaster {
        didHub = IDIDHub(_newHub);
    }

    function setMethodLib(uint32 _type,address _method) external onlyMaster {
        address _old = methodLibMap[_type];
        methodLibMap[_type] = _method;
        emit SetMethodLib(_type,_method,_old);
    }

    function firstVerId(bytes32 _did) external view returns(bytes32) {
        return summaryMap[_did].firstId;
    }

    function lastVerId(bytes32 _did) external view returns(bytes32) {
        return summaryMap[_did].lastId;
    }

    function prevVerId(bytes32 _did,bytes32 _verId) external view returns(bytes32) {
        return infoMap[_did][_verId].prev;
    }
    
    function nextVerId(bytes32 _did,bytes32 _verId) external view returns(bytes32) {
        return infoMap[_did][_verId].next;
    }

    function verificationCount(bytes32 _did) external view returns(uint32) {
        return summaryMap[_did].count;
    }

    function verificationInfo(bytes32 _did, bytes32 _verId) override public view returns(bool active,uint32 _type,string memory controller,bytes[] memory _keyValue) {
        Verification memory info = infoMap[_did][_verId];
        return (info.active,info.vtype,info.controller,info.keyValue);
    }

    function verificationActive(bytes32 _did, bytes32 _verId) override external view returns(bool) {
        Verification memory info = infoMap[_did][_verId];
        return info.active;
    }

    function addVerification(bytes32 _did,bytes32 _ctrlId,bytes[] memory _args,uint32 _type,string memory _controller,bytes[] memory _keyvalue) override external didActive(_did) returns(bool,bytes32) {
        address ctrlMagAddr = didHub.hub(ctrlMagId);
        require(ctrlMagAddr != address(0),"ControllerManager no set."); 
        IControllerManager ctrlMag = IControllerManager(ctrlMagAddr);

        (bool passed,) = ctrlMag.verify(_did, _ctrlId, _args);
        require(passed == true,"Permission denied.");

        bytes32 newVerId = add(_did,_type,_controller,_keyvalue);
        return (true,newVerId);
    }

    function delVerification(bytes32 _did,bytes32 _ctrlId,bytes[] memory _args,bytes32 _delVerId) override external didActive(_did) returns(bool) {
        address ctrlMagAddr = didHub.hub(ctrlMagId);
        require(ctrlMagAddr != address(0),"ControllerManager no set."); 
        IControllerManager ctrlMag = IControllerManager(ctrlMagAddr);

        (bool passed,) = ctrlMag.verify(_did, _ctrlId, _args);
        require(passed == true,"Permission denied.");

        bool result = del(_did,_delVerId);
        return (result);
    }

    function firstAdd(bytes32 _did,address _owner) public didActive(_did) returns(bool,bytes32) {
        address didMagAddr = didHub.hub(didMagId);
        require(didMagAddr != address(0),"DIDManager no set.");
        require(msg.sender == didMagAddr,"Permission denied.");
        require(summaryMap[_did].count == 0,"No first Add");

        bytes[] memory key = new bytes[](1);
        key[0] = abi.encodePacked(_owner);
        bytes32 verId = add(_did,1,"",key);
        return (true,verId);
    }

    function add(bytes32 _did,uint32 _type,string memory _controler,bytes[] memory _keyvalue) private returns(bytes32) {
        bytes32 verId = keccak256(abi.encodePacked(address(this),_did,uint64(block.timestamp),msg.sender));
        require(infoMap[_did][verId].vtype == 0,"The verificationId exists.");

        bytes32 lastId = summaryMap[_did].lastId;
        if(lastId != bytes32(0)) {
            infoMap[_did][lastId].next = verId;
        }

        summaryMap[_did].lastId = verId;
        summaryMap[_did].count += 1;

        if(summaryMap[_did].firstId == bytes32(0)){
            summaryMap[_did].firstId = verId;
        }

        infoMap[_did][verId] = Verification(
            true,
            _type,
            _controler,
            _keyvalue,
            lastId,
            bytes32(0)
        );

        emit AddVerification(_did,verId);
        return verId;
    }

    function del(bytes32 _did,bytes32 _verId) private returns(bool) {
        require(summaryMap[_did].count > 1,"The verification is lastone");

        Verification storage delVer = infoMap[_did][_verId];
        require(delVer.vtype != 0,"The verificationId no exists.");
        
        if(delVer.prev != bytes32(0)){
            infoMap[_did][delVer.prev].next = delVer.next;
            if(summaryMap[_did].lastId == _verId){
                summaryMap[_did].lastId = delVer.prev;
            }
        }

        if(delVer.next != bytes32(0)) {
            infoMap[_did][delVer.next].prev = delVer.prev;
            if(summaryMap[_did].firstId == _verId){
                summaryMap[_did].firstId = delVer.next;
            }
        }

        delVer.active = false;
        summaryMap[_did].count -= 1;

        emit DelVerification(_did,_verId);
        return true;
    }

    function verify(bytes32 _did,bytes32 _verid,bytes[] memory _args) override public returns(bool passed, string memory error) {
        address didMagAddr = didHub.hub(bytes32("DIDManager"));
        if(didMagAddr == address(0)){
            return (false,"No set DIDManager");
        }

        IDIDManager didMag = IDIDManager(didMagAddr);
        if(didMag.status(_did) != 1){
            return (false, "The did no active or exists");
        }

        (bool active,uint32 _type,,bytes[] memory _value) = verificationInfo(_did,_verid);
        if(active == false){
            return (false, "The verification no active or exists");
        }
        address methodAddr = methodLibMap[_type];
        if(methodAddr == address(0)){
            return (false, "The verification no support verify on blockchain");
        }

        bytes[] memory keyValue = _value;
        IVerifyMethod method = IVerifyMethod(methodAddr);
        VerifyArgs memory verArgs = VerifyArgs(_did,_verid,msg.sender,tx.origin,_args);
        bool reVerify = method.verify(keyValue, verArgs);
        if(reVerify){
            return (true,"");
        } else {
            return (false,"Permission denied.");
        }
    }

    function didIsActive(bytes32 _did) private view returns(bool) {
        address didManager = didHub.hub(bytes32("DIDManager"));
        require(didManager != address(0),"DIDManager no set.");
        IDIDManager idiMag = IDIDManager(didManager);
        return idiMag.status(_did) == 1;
    }

    modifier onlyMaster(){
        require(msg.sender == didHub.master(),"Permission denied.");
        _;
    }

    modifier didActive(bytes32 _did) {
        require(didIsActive(_did),"The did no active");
        _;
    }

    event DIDHubChanged(address indexed _newHub,address indexed _oldHub);
    event SetMethodLib(uint32 indexed _type,address indexed _newAddr,address _oldAddr);
}