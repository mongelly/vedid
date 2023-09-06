// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interface/Interface_DIDDelegator.sol";
import "./interface/Interface_DIDHub.sol";
import "./interface/Interface_VerificationManager.sol";

contract DIDDelegator is IDIDDelegator {
    IDIDHub private didHub;

    constructor(address _didHub) {
        didHub = IDIDHub(_didHub);
    }

    function changeDIDHub(address _newHub) external onlyMaster {
        didHub = IDIDHub(_newHub);
    }

    function execute(
        bytes32 _did,
        bytes32 _verId,  
        bytes[] memory _verArgs,
        address _to,
        bytes memory _callData
    ) external payable override returns (bool, bytes memory) {
        address verMagAddr = didHub.hub(bytes32("VerificationManager"));
        if(verMagAddr == address(0)){
            return (false,"No set VerificationManager");
        }

        (bool delsuccess,bytes memory delResult) = verMagAddr.delegatecall(abi.encodeWithSignature("verify(bytes32,bytes32,bytes[])",_did,_verId,_verArgs));
        require(delsuccess,"Verify faild.");
        (bool verifyPassed,) = abi.decode(delResult,(bool,string));
        require(verifyPassed,"Permission denied.");
        (bool success,bytes memory callResult) = _to.call{value:msg.value}(_callData);
        return (success,callResult);
    }


    modifier onlyMaster() {
        require(msg.sender == didHub.master(), "Permission denied.");
        _;
    }
}
