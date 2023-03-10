// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

import "@account-abstraction/samples/SimpleAccount.sol";
import "./utils/Base64.sol";
import "./IPassKeysAccount.sol";
import "./Secp256r1.sol";

contract PassKeysAccount is SimpleAccount, IPassKeysAccount {
    using Secp256r1 for PassKeyId;
    mapping(bytes32 => PassKeyId) private authorisedKeys;
    bytes32[] private knownKeyHashes;

    // The constructor is used only for the "implementation" and only sets immutable values.
    // Mutable value slots for proxy accounts are set by the 'initialize' function.
    constructor(IEntryPoint anEntryPoint) SimpleAccount(anEntryPoint)  {
    }

    /**
     * The initializer for the PassKeysAcount instance.
     * @param _keyId the id of the key
     * @param _pubKeyX public key X val from a passkey that will have a full ownership and control of this account.
     * @param _pubKeyY public key X val from a passkey that will have a full ownership and control of this account.
     */
    function initialize(string calldata _keyId, uint256 _pubKeyX, uint256 _pubKeyY) public virtual initializer {
        super._initialize(address(0));
        _addPassKey(keccak256(abi.encodePacked(_keyId)), _pubKeyX, _pubKeyY, _keyId);
    }

    /**
     * Allows the owner to add a passkey key.
     * @param _keyId the id of the key
     * @param _pubKeyX public key X val from a passkey that will have a full ownership and control of this account.
     * @param _pubKeyY public key X val from a passkey that will have a full ownership and control of this account.
     */
    function addPassKey(string calldata _keyId, uint256 _pubKeyX, uint256 _pubKeyY) public onlyOwner {
        _addPassKey(keccak256(abi.encodePacked(_keyId)), _pubKeyX, _pubKeyY, _keyId);
    }

    function _addPassKey(bytes32 _keyHash, uint256 _pubKeyX, uint256 _pubKeyY, string calldata _keyId) internal {
        emit PublicKeyAdded(_keyHash, _pubKeyX, _pubKeyY, _keyId);
        authorisedKeys[_keyHash] = PassKeyId(_pubKeyX, _pubKeyY, _keyId);
        knownKeyHashes.push(_keyHash);
    }

    /// @inheritdoc IPassKeysAccount
    function getAuthorisedKeys() external view override returns (string[] memory knownKeys){
        knownKeys = new string[](knownKeyHashes.length);
        for (uint256 i = 0; i < knownKeyHashes.length; i++) {
            knownKeys[i] = authorisedKeys[knownKeyHashes[i]].keyId;
        }
        return knownKeys;
    }

    function removePassKey(bytes32 _keyHash) public onlyOwner {
        PassKeyId memory passKey = authorisedKeys[_keyHash];
        if (passKey.pubKeyX == 0 && passKey.pubKeyY == 0) {
            return;
        }
        delete authorisedKeys[_keyHash];
        for (uint256 i = 0; i < knownKeyHashes.length; i++) {
            if (knownKeyHashes[i] == _keyHash) {
                knownKeyHashes[i] = knownKeyHashes[knownKeyHashes.length - 1];
                knownKeyHashes.pop();
                break;
            }
        }
        emit PublicKeyRemoved(_keyHash, passKey.pubKeyX, passKey.pubKeyY, passKey.keyId);
    }

    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
    internal override virtual returns (uint256 validationData) {
        (bytes32 keyHash, uint256 sigx, uint256 sigy, bytes memory authenticatorData, string memory clientDataJSONPre, string memory clientDataJSONPost) = 
            abi.decode(userOp.signature, (bytes32, uint256, uint256, bytes, string, string));

        string memory opHashBase64 = Base64.encode(bytes.concat(userOpHash));
        string memory clientDataJSON = string.concat(clientDataJSONPre, opHashBase64, clientDataJSONPost);
        bytes32 clientHash = sha256(bytes(clientDataJSON));
        bytes32 sigHash = sha256(bytes.concat(authenticatorData, clientHash));

        PassKeyId memory passKey = authorisedKeys[keyHash];
        require(passKey.pubKeyY != 0 && passKey.pubKeyY != 0, "Key not found");
        require(passKey.Verify(sigx, sigy, uint256(sigHash)), "Invalid signature");
        return 0;
    }

}
