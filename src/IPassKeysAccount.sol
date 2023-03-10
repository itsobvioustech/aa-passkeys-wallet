// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

import "@account-abstraction/interfaces/IAccount.sol";

/**
 * a PassKey account should expose its own public key.
 */
interface IPassKeysAccount is IAccount {
    event PublicKeyAdded(bytes32 indexed keyHash, uint256 pubKeyX, uint256 pubKeyY, string keyId);
    event PublicKeyRemoved(bytes32 indexed keyHash, uint256 pubKeyX, uint256 pubKeyY, string keyId);

    /**
     * @return public key from a BLS keypair that is used to verify the BLS signature, both separately and aggregated.
     */
    function getAuthorisedKeys() external view returns (string[] memory);
}
