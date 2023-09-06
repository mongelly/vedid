// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interface/Interface_DIDHub.sol";

contract DID is IDIDHub {
    address public override master;
    string public override method = "";

    mapping (bytes32 => address) public override hub;

    constructor(string memory _method){
        method = _method;
        master = msg.sender;
    }

    function setMaster(address _new) external {
        require(
            msg.sender == master,
            "Permission denied"
        );
        emit MasterChanged(master, _new);
        master = _new;
    }

    modifier onlyMaster(){
        require(msg.sender == master,"Permission denied");
        _;
    }

    function setHub(bytes32 _hubid,address _manager) external onlyMaster {
        hub[_hubid] = _manager;
        emit SetHub(_hubid,_manager);
    }

    event MasterChanged(address indexed _prev, address indexed _new);
    event SetHub(bytes32 indexed _hubid,address indexed _manager);
} 