pragma solidity >= 0.4.24;

import {IKeyController} from "./iKeyController.sol";
import {Convert} from "./convert.sol";
import {SafeMath} from "./safeMath.sol";
import {IBaseDataSet} from "./iBaseDataSet.sol";

contract VeDID
{
    address internal owner_address;

    bytes32 internal owner_vedid;

    enum VeDIDStatus { NOT_EXISTS, ACTIVE, REVOKED }

    mapping(bytes32 => string) internal _vedidmapping;

    struct HubInfo{
        mapping(uint8 => address) didControllerHub;
        uint8 count;
    }

    struct VeDIDInfo{
        VeDIDStatus status;
        bytes32 lastChangeBlock;
    }

    HubInfo internal _dataHub;

    mapping(bytes32 => VeDIDInfo) internal _vedids;

    constructor() public{
        owner_address = msg.sender;
    }

    // Contract Owner Controller

    function getManagerOfAddress() public view returns(address){
        return owner_address;
    }

    function getManagerOfVeDID() public view returns (bytes32){
        return owner_vedid;
    }

    function transferOwnerToAddress(address _newOwner) public onlyManager{
        owner_address = _newOwner;
    }

    function transferOwnerToVeDID(bytes32  _vedid) public onlyManager{
      owner_vedid = _vedid;
    }

    function addDataset(address _datasetAddr) public onlyManager{
        require(_datasetAddr != address(0),"vedid: dataset address is empty");

        _dataHub.dataset[_dataHub.count] = _datasetAddr;
        _dataHub.count = SafeMath.add(_dataHub.count,1);

        IBaseDataSet(_datasetAddr).registryToHub();

        emit DataSetChanged(_dataHub.count,_datasetAddr,"added");
    }

    function getDatasetAddress(uint8 _index) public view returns(address){
        return _dataHub.dataset[_index];
    }

    function addressExistsInHub(address _addr) public view returns(bool){
        for(uint256 index = 0; index < _dataHub.count;index++){
            if(_dataHub.dataSet[index] == _addr){
                return true;
            }
        }
        return false;
    }

    modifier onlyManager() {
        require(
            msg.sender == owner_address || IKeyController(_dataHub.didControllerHub[1]).keyVerify(owner_vedid,1,Convert.addressToBytes(msg.sender)),
            "vedid:permission denied"
        );
        _;
    }

    // User Functions

    function veDIDExisted(bytes32 _vedid) public view returns(bool){
        return _vedids[_vedid].status == VeDIDStatus.ACTIVE;
    }

    function getVeDIDStatus(bytes32 _vedid) public view returns(VeDIDStatus,bytes32){
        if(_vedids[_vedid].status == VeDIDStatus.NOT_EXISTS){
            return (VeDIDStatus.NOT_EXISTS,0x00);
        }
        else{
            return (_vedids[_vedid].status,_vedids[_vedid].lastChangeBlock);
        }
    }

    function register(bytes32 _vedid) public{
        require(!veDIDExisted(_vedid),"vedid:vedid is existed");
        require(_dataHub.dataSet[0] != address(0) && _dataHub.dataSet[1] != address(0),"vedid:no set dataset contract");

        


    }

}