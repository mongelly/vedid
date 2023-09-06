// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interface/Interface_VerifyMethod.sol";

contract VerifyECDSARecoverAddress is IVerifyMethod {
    uint32 public override typeId = 2;
    string public override typeName = "ECDSARecoverAddress";

    enum ProposeStatus {
        NONE,
        UNUSED,
        USED
    }

    mapping(bytes32 => mapping(bytes32 => ProposeStatus)) public proposeUsed;

    function verify(
        bytes[] memory _keyValue,
        VerifyArgs memory _arg
    ) external override returns (bool) {
        address keyAddr;
        bytes32 msgHash;
        bytes32 r;
        bytes32 s;
        uint8 v;

        bytes32 nonce;

        bytes memory d1 = _keyValue[0];
        bytes memory d2 = _arg.args[0];
        bytes memory d3 = _arg.args[1];

        assembly {
            keyAddr := mload(add(d1, 32))
            nonce := mload(add(d2, 32))
            r := mload(add(d3, 32))
            s := mload(add(d3, 64))
            v := and(mload(add(d3, 65)), 255)
        }

        bytes32 proposeid = keccak256(abi.encode(_arg.did, _arg.verid, nonce));

        if (proposeUsed[_arg.did][proposeid] != ProposeStatus.UNUSED) {
            return false;
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return false;
        }

        address recAddr = ecrecover(msgHash, v, r, s);

        if (recAddr == keyAddr) {
            proposeUsed[_arg.did][proposeid] = ProposeStatus.USED;
            return true;
        } else {
            return false;
        }
    }

    function newPropose(
        bytes32 _did,
        bytes32 _verId,
        bytes32 _nonce
    ) external returns (bool, bytes32 _proposeid) {
        bytes32 proposeid = keccak256(abi.encode(_did, _verId, _nonce));
        require(proposeUsed[_did][proposeid] == ProposeStatus.NONE,"The proposeid exists");
        proposeUsed[_did][proposeid] = ProposeStatus.UNUSED;
        emit NewPropose(_did, _verId, proposeid);
        return (true, proposeid);
    }

    event NewPropose(
        bytes32 indexed _did,
        bytes32 indexed _verId,
        bytes32 indexed _proposeid
    );

    event VerifyPropse(bytes32 indexed _did,
        bytes32 indexed _verId,
        bytes32 indexed _proposeid);
}
