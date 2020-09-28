pragma solidity >= 0.4.24;

library Equal{
    function bytesEqual(bytes memory lf,bytes memory rt) internal pure returns (bool) {
        if(lf.length != rt.length){
            return false;
        }
        return keccak256(lf) == keccak256(rt);
    }

    function stringEqual(string memory lf,string memory rt) internal pure returns (bool) {
        if(bytes(lf).length != bytes(rt).length) {
            return false;
        }
        return keccak256(bytes(lf)) == keccak256(bytes(rt));
    }
}