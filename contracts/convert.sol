pragma solidity >= 0.4.24;

library Convert{
    function addressToBytes(address _addr) internal pure returns (bytes memory) {
        // execution cost: 6144 gas
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(_addr) / (2**(8*(19 - i)))));
        return b;

        // execution cost: 	715 gas
        return abi.encodePacked(_addr);
    }
}