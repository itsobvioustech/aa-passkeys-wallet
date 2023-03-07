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
        PassKeysAccount account1 = factory.createAccount(1, 0x5cb950c17eb77b4a94a7ce72a610d9066c1b0da1e4c0f3866699c34a5edb2168, publicKey);
        entryPoint.depositTo{value: 1e18}(address(account));
        vm.deal(address(account), 10e18);
        assertEq(address(account).balance, 10e18);

        UserOperation memory userOp = UserOperation({
            sender: address(account),
            nonce: 0,
            initCode: bytes(""),
            callData: abi.encodeCall(account.execute, (address(account1), 1 ether, bytes(""))),
            callGasLimit: 2e6,
            verificationGasLimit: 2e6,
            preVerificationGas: 2e6,
            maxFeePerGas: 1,
            maxPriorityFeePerGas: 1,
            paymasterAndData: bytes(""),
            signature: abi.encode(
                uint256(0x5cb950c17eb77b4a94a7ce72a610d9066c1b0da1e4c0f3866699c34a5edb2168),
                uint256(0xd0860b14cff05bb244323ec118fd3110fd429993088f0e498945f1408a2f7700),
                uint256(0x6d22541b920136ff5b2c59b4541890c2a402bae4e4db23ada3049393cd35bfdf),
                bytes.concat(bytes32(0xf95bc73828ee210f9fd3bbe72d97908013b0a3759e9aea3d0ae318766cd2e1ad), bytes5(0x0500000000)),
                string('{"type":"webauthn.get","challenge":"'),
                string('","origin":"https://webauthn.me\","crossOrigin":false}')
            )
        });
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;
        console2.logBytes32(entryPoint.getUserOpHash(userOp));
        entryPoint.handleOps(ops, payable(address(account)));
        assert(address(account).balance < 10e18);
        assertEq(address(account1).balance, 1e18);
        // account.validateUserOp(userOp, userOp.hash(), 0);
    }
}
