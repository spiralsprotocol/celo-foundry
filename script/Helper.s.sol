// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// import "forge-std/Script.sol";
import "../src/PrecompileHandler.sol";

contract Helper is PrecompileHandler {
    function run() public {
        console.log("Precompiles Address");
        console.log(address(this));
        string memory transferSig = "transfer(address,address,uint256)";
        bytes4 sig = bytes4(keccak256(abi.encodePacked(transferSig)));
        console.log(transferSig);
        console.logBytes4(sig);

        console.log("transfer ProxyCode");
        bytes memory resp = proxyTo(sig);
        console.logBytes(resp);
        vm.etch(address(0xff - 2), resp);
    }
}
