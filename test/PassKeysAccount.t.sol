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
        address wallet = factory.getAddress(0, "test", publicKey[0], publicKey[1]);
        PassKeysAccount account = factory.createAccount(0, "test", publicKey[0], publicKey[1]);
        assertEq(address(account), wallet);
        PassKeysAccount account1 = factory.createAccount(1, "test", publicKey[0], publicKey[1]);
        assert(address(account1) != address(account));
    }

    function testBasicWalletOps() public {
        uint256[2] memory publicKey = [0xfbf44f8e2d9d446231d2ee0ac7819c66f7a1c360630ead395c33ddce7d09553b, 
                                       0x05ad53a14271446919a317847f59f8ef322411c95d504467bdaa12ea95344c1d];
        PassKeysAccount account = factory.createAccount(0, "test", publicKey[0], publicKey[1]);
        PassKeysAccount account1 = factory.createAccount(1, "test 1", publicKey[0], publicKey[1]);
        entryPoint.depositTo{value: 1e18}(address(account));
        vm.deal(address(account), 10e18);
        assertEq(address(account).balance, 10e18);
        assertEq(address(account1).balance, 0);

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
                keccak256(abi.encodePacked("test")),
                uint256(0xc89034162e159e8fb36123813d0f1130847ac26be2b3bced86ec2b8fe5c0f8e1),
                uint256(0x9b811c7d9b2bf63edfdc42ef479c2594b7da53f0a580bd082fdca98803d36ba5),
                bytes.concat(bytes32(0xf95bc73828ee210f9fd3bbe72d97908013b0a3759e9aea3d0ae318766cd2e1ad), bytes5(0x0500000000)),
                string('{"type":"webauthn.get","challenge":"'),
                string('","origin":"https://webauthn.me","crossOrigin":false,"other_keys_can_be_added_here":"do not compare clientDataJSON against a template. See https://goo.gl/yabPex"}')
            )
        });
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;
        // console2.logBytes32(entryPoint.getUserOpHash(userOp));
        entryPoint.handleOps(ops, payable(address(account)));
        assertEq(address(account1).balance, 1e18);
        assertEq(account.nonce(), 1);
    }
}
