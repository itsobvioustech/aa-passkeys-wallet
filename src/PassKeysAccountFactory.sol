// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "@account-abstraction/interfaces/IEntryPoint.sol";
import "./PassKeysAccount.sol";

/* solhint-disable no-inline-assembly */

/**
 * Based on SimpleAccountFactory.
 * Cannot be a subclass since both constructor and createAccount depend on the
 * constructor and initializer of the actual account contract.
 */
contract PassKeysAccountFactory {
    PassKeysAccount public immutable accountImplementation;

    constructor(IEntryPoint entryPoint){
        accountImplementation = new PassKeysAccount(entryPoint);
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(uint256 salt, string calldata keyId, uint256 pubKeyX, uint256 pubKeyY) public returns (PassKeysAccount) {
        address addr = getAddress(salt, keyId, pubKeyX, pubKeyY);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return PassKeysAccount(payable(addr));
        }
        return PassKeysAccount(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                address(accountImplementation),
                abi.encodeCall(PassKeysAccount.initialize, (keyId, pubKeyX, pubKeyY))
            )));
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(uint256 salt, string calldata keyId, uint256 pubKeyX, uint256 pubKeyY) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    address(accountImplementation),
                    abi.encodeCall(PassKeysAccount.initialize, (keyId, pubKeyX, pubKeyY))
                )
            )));
    }
}
