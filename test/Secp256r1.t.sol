// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

import "forge-std/Test.sol";
import "../src/Secp256r1.sol";

contract Secp256r1Test is Test {
    bytes32 messageHash = 0xa591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e;
    uint[2] rs = [0x912177ddfa310e5daf1a0d53c567b3c19261cda206bf788eaa4a3a708f090856, 0x1bd0b92ff302efae4782e16c1b3eeb32b05df7cca4c84d74535bd4fb613e02bb];
    PassKeyId Q = PassKeyId(0xa6ad1deeababc22e1eeba4bc93f6535ff95391a1981d9276bbe39b1ce473d6ed, 0x688c2d5b0231d21e9f6ad264cfcdcf09aec15ea8c5c354f38b2fae95e82959e4, "test");

    function setUp() public {
    }


    function testCheckSignature() public {
        bool validate = Secp256r1.Verify(Q, rs[0], rs[1], uint256(messageHash));
        assertTrue(validate);

        messageHash = 0xf5a9b843ef6ed11fecc9170bd861512f56b342dd7270325228015d821925d915;
        rs = [0x8efa9b1e7bc5ecf43cbaccf2205daf40f60b19b88912d5d2b7dc63db2ecfdde9,0x044a33ff15f58ebcdf978a46bd930e2ad054f8412b4eca55ae61297d24d72a2a];
        Q = PassKeyId(0xba5fcb538285326ed0e6fcdd2e95331d49029495d07840088b6919a379b17c89,0x874391cc36d7336ecaa23658e0b0aaf64212e9445eb241b0b81517276aea0b68, "test");
        validate = Secp256r1.Verify(Q, rs[0], rs[1], uint256(messageHash));
        assertTrue(validate);
    }

    function testSingleSignatureVerify() public {
        bool validate = Secp256r1.Verify(Q, rs[0], rs[1], uint256(messageHash));
        assertTrue(validate);
    }

    function testCheckSigWithPrecompute() public {
        JPoint[] memory points = Secp256r1._preComputeJacobianPoints(Q);
        bool validate = Secp256r1.VerifyWithPrecompute(points, rs[0], rs[1], uint256(messageHash));
        assertTrue(validate);
    }

}
