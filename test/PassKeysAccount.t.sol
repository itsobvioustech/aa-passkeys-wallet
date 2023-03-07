// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

import "forge-std/Test.sol";
import "../src/PassKeysAccount.sol";
import "../src/PassKeysAccountFactory.sol";
import "@account-abstraction/core/EntryPoint.sol";
import "@account-abstraction/interfaces/UserOperation.sol";

contract PassKeysAccountTest is Test {
    using UserOperationLib for UserOperation;

    PassKeysAccountFactory public factory;
    EntryPoint public entryPoint;
    
    function setUp() public {
        entryPoint = new EntryPoint();
        factory = new PassKeysAccountFactory(entryPoint);
    }

    function testWalletDeployment() public {
        uint256[2] memory publicKey = [uint256(0x1), uint256(0x2)];
        address wallet = factory.getAddress(0, 0, publicKey);
        PassKeysAccount account = factory.createAccount(0, 0, publicKey);
        assertEq(address(account), wallet);
        PassKeysAccount account1 = factory.createAccount(1, 0, publicKey);
        assert(address(account1) != address(account));
    }

    function testBasicWalletOps() public {
        uint256[2] memory publicKey = [0x1b2b38be0987ec6cdb257eae91c00c7b3405e2bff0f56d60449da65347889c6d, 0x5569d27640ac65c77da042a9f47e6ac604d829970600663daf9d411636ba4c65];
        PassKeysAccount account = factory.createAccount(0, 0x5cb950c17eb77b4a94a7ce72a610d9066c1b0da1e4c0f3866699c34a5edb2168, publicKey);
        UserOperation memory userOp = UserOperation({
            sender: address(account),
            nonce: 0,
            initCode: bytes(""),
            callData: bytes(""),
            callGasLimit: 2e6,
            verificationGasLimit: 2e6,
            preVerificationGas: 2e6,
            maxFeePerGas: 1,
            maxPriorityFeePerGas: 1,
            paymasterAndData: bytes(""),
            signature: abi.encode(
                uint256(0x5cb950c17eb77b4a94a7ce72a610d9066c1b0da1e4c0f3866699c34a5edb2168),
                uint256(0x1b2b38be0987ec6cdb257eae91c00c7b3405e2bff0f56d60449da65347889c6d),
                uint256(0x5569d27640ac65c77da042a9f47e6ac604d829970600663daf9d411636ba4c65),
                bytes(""),
                string("hello world"),
                string("")
            )
        });
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;
        entryPoint.handleOps(ops, payable(address(account)));
        // account.validateUserOp(userOp, userOp.hash(), 0);
    }
}
