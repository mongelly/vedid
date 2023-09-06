// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interface/Interface_VerifyMethod.sol";

contract VerifySender is IVerifyMethod {
    uint32 public override typeId = 1;
    string public override typeName = "Sender";

    function verify(
        bytes[] memory _keyValue,
        VerifyArgs memory _args
    ) external pure override returns (bool) {
        address keyAddr;
        bytes memory d1 = _keyValue[0];

        assembly {
            keyAddr := mload(add(d1, 32))
        }
        return keyAddr == _args.sender;
    }
}
