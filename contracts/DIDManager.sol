// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interface/Interface_DIDManager.sol";
import "./interface/Interface_DIDHub.sol";
import "./interface/Interface_ControllerManager.sol";

interface IVerification {
    function firstAdd(
        bytes32 _did,
        address _applicant
    ) external returns (bool, bytes32);
}

interface IController is IControllerManager {
    function firstAdd(
        bytes32 _did,
        bytes32 _cdid,
        bytes32 _cverId
    ) external returns (bool, bytes32);
}

contract DIDManager is IDIDManager {
    string public constant name = "DIDManager";
    bytes32 public constant hubId = bytes32("DIDManager");

    IDIDHub private didHub;

    bytes32 private constant verifyMagId = bytes32("VerificationManager");
    bytes32 private constant ctrlMagId = bytes32("ControllerManager");

    mapping(bytes32 => uint32) public override status;

    constructor(address _didHub) {
        didHub = IDIDHub(_didHub);
    }

    function register(
        bytes32 _did,
        address _owner
    ) external override returns (bool) {
        require(status[_did] == 0, "The did exists.");
        status[_did] = 1;

        address verifyMagAddr = didHub.hub(verifyMagId);
        require(verifyMagAddr != address(0), "No set verificationManager.");
        IVerification verifyMag = IVerification(verifyMagAddr);

        address ctrlMagAddr = didHub.hub(ctrlMagId);
        require(ctrlMagAddr != address(0), "No set controllerManager.");
        IController ctrlMag = IController(ctrlMagAddr);

        (bool passed1, bytes32 verId) = verifyMag.firstAdd(_did, _owner);
        require(passed1 == true, "Set new verification faild.");

        (bool passed2,) = ctrlMag.firstAdd(_did,_did,verId);
        require(passed2 == true, "Set new controller faild.");

        emit Register(_did);

        return (true);
    }

    function setStatus(
        bytes32 _did,
        bytes32 _ctrlId,
        bytes[] memory _args,
        uint32 _status
    ) external override returns (bool) {
        address ctrlMagAddr = didHub.hub(ctrlMagId);
        require(ctrlMagAddr != address(0),"ControllerManager no set."); 
        IController ctrlMag = IController(ctrlMagAddr);

        (bool passed,) = ctrlMag.verify(_did, _ctrlId, _args);
        require(passed == true,"Permission denied.");

        status[_did] = _status;
        return true;
    }
}
