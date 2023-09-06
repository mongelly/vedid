// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IDIDHub {
    function method() external view returns(string memory);
    function hub(bytes32 _hubid) external view returns (address _manager);
    function master() external view returns(address);
}