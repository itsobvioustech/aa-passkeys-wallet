// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

import "forge-std/Script.sol";
import "../src/PassKeysAccountFactory.sol";
import "@account-abstraction/core/EntryPoint.sol";

contract AnvilScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        Deployer deployer = new Deployer();
        deployer.deploy(deployerPrivateKey);
    }
}

contract ExternalScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        console2.log("deployerKey", vm.addr(deployerPrivateKey));
        Deployer deployer = new Deployer();
        deployer.deploy(deployerPrivateKey);
    }
}

contract Deployer is Script {
    function deploy(uint256 _pkey) public {
        vm.startBroadcast(_pkey);
        EntryPoint entryPoint = new EntryPoint{salt: bytes32("1")}();
        PassKeysAccountFactory factory = new PassKeysAccountFactory{salt: bytes32("1")}(entryPoint);
        vm.stopBroadcast();
        console2.log("EntryPoint", address(entryPoint));
        console2.log("PassKeysAccountFactory", address(factory));
    }
}