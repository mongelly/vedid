// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interface/Interface_ControllerManager.sol";
import "./interface/Interface_DIDHub.sol";
import "./interface/Interface_DIDManager.sol";
import "./interface/Interface_VerificationManager.sol";

struct Controller {
    bool active;
    bytes32 did;
    bytes32 verid;
    bytes32 prev;
    bytes32 next;
}

struct ControllerSummary {
    bytes32 firstId;
    bytes32 lastId;
    uint32 count;
}

contract ControllerManager is IControllerManager {
    string public constant name = "ControllerManager";
    bytes32 public constant hubId = bytes32("ControllerManager");

    bytes32 private constant didMagId = bytes32("DIDManager");
    bytes32 private constant verifyMagId = bytes32("VerificationManager");

    IDIDHub private didHub;
    mapping(bytes32 => mapping(bytes32 => Controller)) infoMap;
    mapping(bytes32 => ControllerSummary) summaryMap;

    constructor(address _didHub) {
        didHub = IDIDHub(_didHub);
    }

    function changeDIDHub(address _newHub) external onlyMaster {
        didHub = IDIDHub(_newHub);
    }

    function firstCtrlId(bytes32 _did) external view returns (bytes32) {
        return summaryMap[_did].firstId;
    }

    function lastCtrlId(bytes32 _did) external view returns (bytes32) {
        return summaryMap[_did].lastId;
    }

    function prevCtrlId(
        bytes32 _did,
        bytes32 _ctrlId
    ) external view returns (bytes32) {
        return infoMap[_did][_ctrlId].prev;
    }

    function nextCtrlId(
        bytes32 _did,
        bytes32 _ctrlId
    ) external view returns (bytes32) {
        return infoMap[_did][_ctrlId].next;
    }

    function controllerCount(bytes32 _did) external view returns (uint32) {
        return summaryMap[_did].count;
    }

    function controllerInfo(
        bytes32 _did,
        bytes32 _ctrlId
    )
        external
        view
        override
        returns (bool _active, bytes32 _cdid, bytes32 _cverId)
    {
        Controller memory info = infoMap[_did][_ctrlId];
        return (info.active, info.did, info.verid);
    }

    function controllerActive(
        bytes32 _did,
        bytes32 _ctrlId
    ) external view override returns (bool) {
        Controller memory info = infoMap[_did][_ctrlId];
        return info.active;
    }

    function addController(
        bytes32 _did,
        bytes32 _ctrlId,
        bytes[] memory _args,
        bytes32 _cdid,
        bytes32 _cVerId
    ) external override didActive(_did) returns (bool, bytes32) {
        (bool passed,) = verify(_did,_ctrlId,_args);
        require(passed == true,"Permission denied.");

        bytes32 newCtrlId = add(_did,_cdid,_cVerId);

        return(true,newCtrlId);
    }

    function delController(
        bytes32 _did,
        bytes32 _ctrlId,
        bytes[] memory _args,
        bytes32 _delCtrolId
    ) external override didActive(_did) returns (bool) {
        (bool passed,) = verify(_did,_ctrlId,_args);
        require(passed == true,"Permission denied.");

        bool result = del(_did,_delCtrolId);
        return(result);
    }

    function verify(
        bytes32 _did,
        bytes32 _ctrlId,
        bytes[] memory _args
    )
        public
        override
        didActive(_did)
        returns (bool passed, string memory error)
    {
        address verMagAddr = didHub.hub(verifyMagId);
        if (verMagAddr == address(0)) {
            return (false, "No set VerificationManager");
        }
        IVerificationManager verMag = IVerificationManager(verMagAddr);

        Controller memory info = infoMap[_did][_ctrlId];
        if (info.active == false) {
            return (false, "The controler no exists or no active");
        }
        (bool vpassed, string memory err) = verMag.verify(
            _did,
            info.verid,
            _args
        );

        if (vpassed) {
            return (true, "");
        } else {
            return (false, err);
        }
    }

    function firstAdd(
        bytes32 _did,
        bytes32 _cdid,
        bytes32 _cverId
    ) external didActive(_did) returns (bool, bytes32) {
        address didManager = didHub.hub(didMagId);
        require(didManager != address(0), "DIDManager no set.");
        require(msg.sender == didManager, "Permission denied.");
        require(summaryMap[_did].count == 0, "No first Add");

        bytes32 ctrlId = add(_did, _cdid, _cverId);
        return (true, ctrlId);
    }

    function add(
        bytes32 _did,
        bytes32 _cdid,
        bytes32 _cverId
    ) private returns (bytes32) {
        bytes32 ctrlId = keccak256(
            abi.encodePacked(
                address(this),
                _did,
                uint64(block.timestamp),
                msg.sender
            )
        );
        require(
            infoMap[_did][ctrlId].did == bytes32(0),
            "The verificationId exists."
        );
        address didMagAddr = didHub.hub(didMagId);
        require(didMagAddr != address(0), "No set DIDManager");

        IDIDManager didMag = IDIDManager(didMagAddr);
        require(didMag.status(_cdid) == 1, "The did no active or exists");

        require(
            infoMap[_cdid][_cverId].active == false,
            "The controller exists"
        );

        bytes32 lastId = summaryMap[_did].lastId;
        if (lastId != bytes32(0)) {
            infoMap[_did][lastId].next = ctrlId;
        }

        summaryMap[_did].lastId = ctrlId;
        summaryMap[_did].count += 1;

        if (summaryMap[_did].firstId == bytes32(0)) {
            summaryMap[_did].firstId = ctrlId;
        }

        infoMap[_did][ctrlId] = Controller(
            true,
            _cdid,
            _cverId,
            lastId,
            bytes32(0)
        );

        emit AddController(_did, ctrlId);
        return ctrlId;
    }

    function del(bytes32 _did, bytes32 _ctrlId) private returns (bool) {
        require(summaryMap[_did].count > 1, "The controller is lastone");

        Controller storage delCtrl = infoMap[_did][_ctrlId];
        require(delCtrl.did != bytes32(0), "The controllerId no exists.");

        if (delCtrl.prev != bytes32(0)) {
            infoMap[_did][delCtrl.prev].next = delCtrl.next;
            if (summaryMap[_did].lastId == _ctrlId) {
                summaryMap[_did].lastId = delCtrl.prev;
            }
        }

        if (delCtrl.next != bytes32(0)) {
            infoMap[_did][delCtrl.next].prev = delCtrl.prev;
            if (summaryMap[_did].firstId == _ctrlId) {
                summaryMap[_did].firstId = delCtrl.next;
            }
        }

        delCtrl.active = false;
        summaryMap[_did].count -= 1;

        emit DelController(_did, _ctrlId);
        return true;
    }

    modifier onlyMaster() {
        require(msg.sender == didHub.master(), "Permission denied.");
        _;
    }

    modifier didActive(bytes32 _did) {
        address didManager = didHub.hub(didMagId);
        require(didManager != address(0), "DIDManager no set.");
        IDIDManager idiMag = IDIDManager(didManager);
        require(idiMag.status(_did) == 1, "The did no active");
        _;
    }
}
