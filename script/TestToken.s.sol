// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract TestTokenScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        console2.log("deployerKey", vm.addr(deployerPrivateKey));
        vm.startBroadcast(deployerPrivateKey);
        ERC20PresetMinterPauser testToken = new ERC20PresetMinterPauser("Obvious Test Token", "OTT");
        testToken.mint(vm.addr(deployerPrivateKey), 1000000e18);
        vm.stopBroadcast();
        console2.log("Obvious Test Token", address(testToken));
    }
}