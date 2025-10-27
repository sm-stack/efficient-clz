// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Deploy} from "./utils/Deploy.sol";

contract LibZipTest is Test {
    address public oldLibZip;
    address public newLibZip;

    // The data from example of vectorized - packing 3 uint256 variables. Check https://x.com/optimizoor/status/1914238227386704053
    uint256 private _a = 0x112233;
    uint256 private _b = 0x0102030405060708;
    uint256 private _c = 0xf1f2f3;
    bytes private _bytes;
    
    // Heavy CLZ usage
    bytes private _heavyClz;
    
    // 0xff pattern
    bytes private _mixedPattern;

    function setUp() public {
        // Deploy 2 YulLibZip runtime with wrapper
        bytes memory oldRuntime = hex"600436106102b65760045f80376383a095055f5160e01c036102b657602060045f375f5160208160040181376020518060246040519301833780825281015f60208201526040810190816040528251830190606081019182945b8181036100805750506044810180511990528103605f190182525f81526020016040525190f35b6001019260ff84511680156101fa5760ff8114610166578153600161015b7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f60208701518084860152801982808216011790828082160117161719806f8421084210842108cc6318c6db6d54be1060071b81811c848060401b031060061b177fc0c8c8d0c8e8d0d8c8e8e0e8d0d8e0f0c8d0e8d0e0e0d8f0d0d0e0d8f8f8f8f86f8421084210842108cc6318c6db6d54be83831c66020408102040810260181a1c601f161a1860031c90150186850390818110908218021890565b809201019301610059565b50600290608061019c61018f60208089015119806101ad575b5088870390818110908218021890565b80601f10601f8218021890565b809601951760f01b81520192610059565b6001600160801b03811160071b81811c6001600160401b031060061b1781811c63ffffffff1060051b1781811c61ffff1060041b1790811c60ff1060039190911c17601f1890505f61017f565b935b60208101518015610276576002929190610264906001600160801b03811160071b81811c6001600160401b031060061b1781811c63ffffffff1060051b1781811c61ffff1060041b1790811c60ff1060039190911c17601f1882860390818110908218021890565b80910195015b60f01b81520192610059565b5093601f6102a06102908786038060201060208218021890565b83607f0390818110908218021890565b80809701920195116101fc57939060029161026a565b5f80fd";
        bytes memory newRuntime = hex"600436106102335760045f80376383a095055f5160e01c0361023357602060045f375f516020816004018137604060205180602483519401843780835282015f60208201520160405260405181518201602082019081935b818103610080575050602090600483018051199052828103601f190183525f8152016040525190f35b6001019160ff83511680156101b95760ff8114610166578153600161015b7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f60208601518084860152801982808216011790828082160117161719806f8421084210842108cc6318c6db6d54be1060071b81811c848060401b031060061b177fc0c8c8d0c8e8d0d8c8e8e0e8d0d8e0f0c8d0e8d0e0e0d8f0d0d0e0d8f8f8f8f86f8421084210842108cc6318c6db6d54be83831c66020408102040810260181a1c601f161a1860031c90150185850390818110908218021890565b809201019201610057565b50600290608061019c61018f60208088015119806101ad575b5087870390818110908218021890565b80601f10601f8218021890565b809501941760f01b81520191610057565b90501e60031c5f61017f565b925b602081015180156101f357906101e1600293921e60031c82860390818110908218021890565b80910194015b60f01b81520191610057565b5092601f61021d61020d8686038060201060208218021890565b83607f0390818110908218021890565b80809601920194116101bb5792906002916101e7565b5f80fd";
        
        oldLibZip = Deploy.deployCode(oldRuntime);
        newLibZip = Deploy.deployCode(newRuntime);

        _bytes = abi.encode(_a, _b, _c);
        
        // Data with heavy CLZ usage
        _heavyClz = abi.encode(
            uint256(1), uint256(2), uint256(3), uint256(4), uint256(5),
            uint256(6), uint256(7), uint256(8), uint256(9), uint256(10)
        );

        // Mixed pattern: Alternating 0x00 and 0xff patterns
        _mixedPattern = abi.encode(
            uint256(0xff), uint256(0xff), uint256(0xff), uint256(0xff),
            uint256(0xff), uint256(0xff), uint256(0xff), uint256(0xff),
            uint256(0xff), uint256(0xff), uint256(0xff), uint256(0xff)
        );

    }

    function test_compress_beforeFusaka_bytes() public view {
        bytes4 sel = bytes4(keccak256("cdCompress(bytes)"));
        (bool ok,) = oldLibZip.staticcall(abi.encodeWithSelector(sel, _bytes));
        assertEq(ok, true);
    }

    function test_compress_afterFusaka_bytes() public view {
        bytes4 sel = bytes4(keccak256("cdCompress(bytes)"));
        (bool ok,) = newLibZip.staticcall(abi.encodeWithSelector(sel, _bytes));
        assertEq(ok, true);
    }
    
    // Heavy CLZ test: Maximum advantage for verbatim CLZ
    function test_compress_beforeFusaka_heavyClz() public view {
        bytes4 sel = bytes4(keccak256("cdCompress(bytes)"));
        (bool ok,) = oldLibZip.staticcall(abi.encodeWithSelector(sel, _heavyClz));
        assertEq(ok, true);
    }
    
    function test_compress_afterFusaka_heavyClz() public view {
        bytes4 sel = bytes4(keccak256("cdCompress(bytes)"));
        (bool ok,) = newLibZip.staticcall(abi.encodeWithSelector(sel, _heavyClz));
        assertEq(ok, true);
    }
    
    // Mixed 0xff pattern: Maximum CLZ advantage with 0xff detection
    function test_compress_beforeFusaka_mixedPattern() public view {
        bytes4 sel = bytes4(keccak256("cdCompress(bytes)"));
        (bool ok,) = oldLibZip.staticcall(abi.encodeWithSelector(sel, _mixedPattern));
        assertEq(ok, true);
    }
    
    function test_compress_afterFusaka_mixedPattern() public view {
        bytes4 sel = bytes4(keccak256("cdCompress(bytes)"));
        (bool ok,) = newLibZip.staticcall(abi.encodeWithSelector(sel, _mixedPattern));
        assertEq(ok, true);
    }
}
