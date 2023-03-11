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

    /**
     * Allows the owner to add a passkey key.
     * @param _keyId the id of the key
     * @param _pubKeyX public key X val from a passkey that will have a full ownership and control of this account.
     * @param _pubKeyY public key X val from a passkey that will have a full ownership and control of this account.
     */
    function addPassKey(string calldata _keyId, uint256 _pubKeyX, uint256 _pubKeyY) external;   

    /**
     * Allows the owner to remove a passkey key.
     * @param _keyId the id of the key to be removed
     */
    function removePassKey(string calldata _keyId) external;
}
