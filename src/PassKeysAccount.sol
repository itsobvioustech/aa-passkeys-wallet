// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

import "@account-abstraction/samples/SimpleAccount.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./IPassKeysAccount.sol";
import "./Secp256r1.sol";

import "forge-std/console2.sol";

contract PassKeysAccount is SimpleAccount, IPassKeysAccount {
    using Secp256r1 for uint256[2];
    mapping(uint256 => uint256[2]) private authorisedKeys;
    uint256[] private knownKeys;

    // The constructor is used only for the "implementation" and only sets immutable values.
    // Mutable value slots for proxy accounts are set by the 'initialize' function.
    constructor(IEntryPoint anEntryPoint) SimpleAccount(anEntryPoint)  {
    }

    /**
     * The initializer for the PassKeysAcount instance.
     * @param _keyRawId the raw id of the key
     * @param _publicKey public key from a passkey that will have a full ownership and control of this account.
     */
    function initialize(uint256 _keyRawId, uint256[2] memory _publicKey) public virtual initializer {
        super._initialize(address(0));
        _addPassKey(_keyRawId, _publicKey);
    }

    /**
     * Allows the owner to add a passkey key.
     * @param _keyRawId the raw id of the key
     * @param _publicKey public key from a passkey that will have a full ownership and control of this account.
     */
    function addPassKey(uint256 _keyRawId, uint256[2] memory _publicKey) public onlyOwner {
        _addPassKey(_keyRawId, _publicKey);
    }

    function _addPassKey(uint256 _keyRawId, uint256[2] memory _publicKey) internal {
        emit PublicKeyAdded(_keyRawId, _publicKey);
        authorisedKeys[_keyRawId] = _publicKey;
        knownKeys.push(_keyRawId);
    }

    /// @inheritdoc IPassKeysAccount
    function getAuthorisedKeys() external view override returns (uint256[] memory){
        return knownKeys;
    }

    function removePassKey(uint256 _keyRawId) public onlyOwner {
        uint256[2] memory publicKey = authorisedKeys[_keyRawId];
        if (publicKey[0] == 0 && publicKey[1] == 0) {
            return;
        }
        delete authorisedKeys[_keyRawId];
        for (uint256 i = 0; i < knownKeys.length; i++) {
            if (knownKeys[i] == _keyRawId) {
                knownKeys[i] = knownKeys[knownKeys.length - 1];
                knownKeys.pop();
                break;
            }
        }
        emit PublicKeyRemoved(_keyRawId, publicKey);
    }

    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash, address)
    internal override virtual returns (uint256 deadline) {
        console2.log("validate signature");
        console2.log(userOpHash);
        (uint256 rawKeyId, uint256 sigx, uint256 sigy, bytes memory authenticatorData, string memory clientDataJSONPre, string memory clientDataJSONPost) = 
            abi.decode(userOp.signature, (uint256, uint256, uint256, bytes, string, string));

        string memory opHashBase64 = Base64.encode(bytes.concat(userOpHash)); // do we need the trailing == from base64 encoding?
        bytes32 clientHash = sha256(bytes(string.concat(clientDataJSONPre, opHashBase64, clientDataJSONPost)));
        bytes32 sigHash = sha256(bytes.concat(authenticatorData, clientHash));

        uint256[2] memory publicKey = authorisedKeys[rawKeyId];
        require(publicKey[0] != 0 && publicKey[1] != 0, "Key not found");
        require(publicKey.Verify(sigx, sigy, uint256(sigHash)), "Invalid signature");
        return 0;
    }

}
