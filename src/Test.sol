// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test as ForgeTest} from "forge-std/Test.sol";
import "./Precompiles.sol";
import "./PrecompileHandler.sol";

contract Test is ForgeTest, Precompiles {
    PrecompileHandler public ph;
    address currentPrank;

    // TODO delete me
    // event log_named_array(string key, address[] val);
    event log_named_array(string key, bytes32[] val);
    event log_array(string key, address[] val);
    event log_array(string key, bytes32[] val);

    constructor() ForgeTest() {
        ph = new PrecompileHandler();
    }

    /* Utility functions */

    // function changePrank(address who) internal override {
    //     // Record current prank so helper functions can revert
    //     // if they need to prank
    //     currentPrank = who;
    //     super.changePrank(who);
    // }

    function actor(string memory name) public returns (address) {
        uint256 pk = uint256(keccak256(bytes(name)));
        address addr = vm.addr(pk);
        vm.label(addr, name);
        return addr;
    }

    /* Extra assertions, extends forge-std/Test.sol */

    function assertEq(bytes32[] memory a, bytes32[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [bytes32[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }
}
