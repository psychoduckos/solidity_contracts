// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Proxy {
    address public implemetation;
    uint public x;

    function setImplemementation(address _imp) external {
        implemetation = _imp;
    }

    function _delegate(address _imp) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), _imp, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _delegate(implemetation);
    }
}

contract V1 {
    address public implemetation;
    uint public x;

    function inc() external {
        x +=1;
    }

    function enc() external pure returns(bytes memory){
        return abi.encodeWithSelector(this.inc.selector);
    }

        function encX() external pure returns(bytes memory){
        return abi.encodeWithSelector(this.x.selector);
    }
}

contract V2 {
    address public implemetation;
    uint public x;

    function inc() external {
        x +=1;
    }

    function dec() external {
        x -=1;
    }

    function enc1() external pure returns(bytes memory){
        return abi.encodeWithSelector(this.inc.selector);
    }

    function enc2() external pure returns(bytes memory){
        return abi.encodeWithSelector(this.dec.selector);
    }

    function encX() external pure returns(bytes memory){
        return abi.encodeWithSelector(this.x.selector);
    }
}