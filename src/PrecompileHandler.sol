// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Vm.sol";
import "forge-std/console2.sol";
import "./Precompiles.sol";
import "forge-std/Script.sol";

contract PrecompileHandler is Precompiles, Script {
    // TODO: delete
    // Vm internal constant vm = Vm(VM_ADDRESS);

    bytes4 constant TRANSFER_SIG =
        bytes4(keccak256("transfer(address,address,uint256)"));
    bytes4 constant EPOCH_SIZE_SIG = bytes4(keccak256("epochSize()"));
    bytes4 constant CATCHALL_SIG = bytes4(keccak256("catchAll()"));

    uint256 public epochSize = 17280;
    bool public debug = false;

    struct Mock {
        bool success;
        bytes returnData;
        bool exists;
    }

    mapping(address => mapping(bytes32 => Mock)) private mockedCalls;
    bytes private _empty;
    Mock private successMock = Mock(true, _empty, true);
    Mock private revertMock = Mock(true, _empty, true);

    constructor() {
        vm.etch(TRANSFER, proxyTo(TRANSFER_SIG));
        vm.label(TRANSFER, "TRANSFER");

        vm.etch(EPOCH_SIZE, proxyTo(EPOCH_SIZE_SIG));
        vm.label(EPOCH_SIZE, "EPOCH_SIZE");

        bytes memory catchAllProxy = proxyTo(CATCHALL_SIG);
        vm.etch(FRACTION_MUL, catchAllProxy);
        vm.label(FRACTION_MUL, "FRACTION_MUL");

        vm.etch(PROOF_OF_POSSESSION, catchAllProxy);
        vm.label(PROOF_OF_POSSESSION, "PROOF_OF_POSSESSION");

        vm.etch(GET_VALIDATOR, catchAllProxy);
        vm.label(GET_VALIDATOR, "GET_VALIDATOR");

        vm.etch(NUMBER_VALIDATORS, catchAllProxy);
        vm.label(NUMBER_VALIDATORS, "NUMBER_VALIDATORS");

        vm.etch(BLOCK_NUMBER_FROM_HEADER, catchAllProxy);
        vm.label(BLOCK_NUMBER_FROM_HEADER, "BLOCK_NUMBER_FROM_HEADER");

        vm.etch(HASH_HEADER, catchAllProxy);
        vm.label(HASH_HEADER, "HASH_HEADER");

        vm.etch(GET_PARENT_SEAL_BITMAP, catchAllProxy);
        vm.label(GET_PARENT_SEAL_BITMAP, "GET_PARENT_SEAL_BITMAP");

        vm.etch(GET_VERIFIED_SEAL_BITMAP, catchAllProxy);
        vm.label(GET_VERIFIED_SEAL_BITMAP, "GET_VERIFIED_SEAL_BITMAP");
    }

    function transfer(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        vm.deal(from, from.balance - amount);
        vm.deal(to, to.balance + amount);
        return true;
    }

    function setEpochSize(uint256 epochSize_) public {
        epochSize = epochSize_;
    }

    function setDebug(bool debug_) public {
        debug = debug_;
    }

    function mockSuccess(address prec, bytes32 callHash) public {
        setMock(prec, callHash, successMock);

        if (debug) {
            console2.log("Mock success");
            console2.log(prec);
            console2.logBytes32(callHash);
        }
    }

    function mockRevert(address prec, bytes32 callHash) public {
        setMock(prec, callHash, revertMock);

        if (debug) {
            console2.log("Mock revert");
            console2.log(prec);
            console2.logBytes32(callHash);
        }
    }

    function mockReturn(
        address prec,
        bytes32 callHash,
        bytes memory returnData
    ) public {
        setMock(prec, callHash, Mock(true, returnData, true));

        if (debug) {
            console2.log("Mock success with data");
            console2.log(prec);
            console2.logBytes32(callHash);
            console2.logBytes(returnData);
        }
    }

    function clearMock(address prec, bytes32 callHash) public {
        delete mockedCalls[prec][callHash];
    }

    function setMock(
        address prec,
        bytes32 callHash,
        Mock memory mock
    ) internal {
        require(
            prec >= GET_VERIFIED_SEAL_BITMAP && prec <= TRANSFER,
            "precompile not supported"
        );

        mockedCalls[prec][callHash] = mock;
    }

    function catchAll() public view {
        bytes memory cd;
        assembly {
            cd := mload(0x40)
            let cds := sub(calldatasize(), 0x4)
            mstore(cd, cds)
            calldatacopy(add(cd, 0x20), 0x4, cds)
            mstore(0x40, add(cd, add(cds, 0x20)))
        }

        bytes32 cdh = keccak256(cd);
        Mock memory mock = mockedCalls[msg.sender][cdh];

        if (mock.exists == false) {
            console2.log(msg.sender);
            console2.logBytes(cd);
            console2.logBytes32(cdh);
            revert("mock not defined for call");
        }

        if (mock.success == false) {
            revert();
        }

        if (mock.returnData.length > 0) {
            bytes memory returnData = mock.returnData;
            assembly {
                let rds := mload(returnData)
                return(add(returnData, 0x20), rds)
            }
        }
    }

    function proxyTo(bytes4 sig) internal view returns (bytes memory) {
        address prec = address(this);
        bytes memory ptr;

        assembly {
            ptr := mload(0x40)
            mstore(ptr, 0x60)
            let mc := add(ptr, 0x20)
            let addrPrefix := shl(0xf8, 0x73)
            let addr := shl(0x58, prec)
            let sigPrefix := shl(0x50, 0x63)
            let shiftedSig := shl(0x30, shr(0xe0, sig))
            let suffix := 0x600060043601
            mstore(
                mc,
                or(addrPrefix, or(addr, or(sigPrefix, or(shiftedSig, suffix))))
            )
            mc := add(mc, 0x20)
            mstore(
                mc,
                0x8260e01b82523660006004840137600080828434885af13d6000816000823e82
            )
            mc := add(mc, 0x20)
            mstore(
                mc,
                0x60008114604a578282f35b8282fd000000000000000000000000000000000000
            )
            mstore(0x40, add(ptr, 0x80))
        }

        return ptr;
    }
}
