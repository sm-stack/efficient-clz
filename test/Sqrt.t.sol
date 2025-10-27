// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Deploy} from "./utils/Deploy.sol";

contract SqrtTest is Test {
    address public oldSqrt;
    address public newSqrt;
    
    function setUp() public {
        // Use RUNTIME bytecode with Deploy.deployCode wrapper
        bytes memory oldRuntime = hex"3615608857630cce06b65f3560e01c036088575f600435603f811180605c575b15602c575b505f5260205ff35b600f91507f77777777777777766666666666665555555555544444444433333332222211109060021b1c165f6024565b915080600180606984608c565b811c011b5b808211607a575091601f565b9050808204810160011c606e565b5f80fd5b905f91610100811060ce575b61010081101560a45750565b6080805b60af575050565b6001811b82101560c2575b60011c8060a8565b809391811c91179260ba565b5b6001811115609857916001019160011c60cf56";
        bytes memory newRuntime = hex"3615609c57630cce06b65f3560e01c03609c575f600435603f811180605c575b15602c575b505f5260205ff35b600f91507f77777777777777766666666666665555555555544444444433333332222211109060021b1c165f6024565b91508060668260a0565b60ff8111609c5760018091811c011b5f5b610100811082841116608a57505091601f565b90915060018280850401811c91016077565b5f80fd5b905f91801560ba575b8060b05750565b9091501e60ff0390565b5f925060a956";

        // Deploy using Deploy.deployCode (wraps runtime with constructor)
        oldSqrt = Deploy.deployCode(oldRuntime);
        newSqrt = Deploy.deployCode(newRuntime);
    }

    function test_sqrt_beforeFusaka_100() public view {
        // Call with selector: floorSqrt(uint256)
        bytes4 sel = bytes4(keccak256("floorSqrt(uint256)"));
        (bool ok,) = oldSqrt.staticcall(abi.encodeWithSelector(sel, uint256(100)));
        assertEq(ok, true);
    }

    function test_sqrt_afterFusaka_100() public view {
        // Call with selector: floorSqrt(uint256)
        bytes4 sel = bytes4(keccak256("floorSqrt(uint256)"));
        (bool ok,) = newSqrt.staticcall(abi.encodeWithSelector(sel, uint256(100)));
        assertEq(ok, true);
    }
}