// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "../src/LlamaPfp.sol";

contract DeployLlamaPfp is Script {
    function run() external {
        vm.startBroadcast();

        // use a different address if the chain is mainnet
        address validSigner = block.chainid == 1 ? 0xF04284F4470230b4f19C1dCa4FC9cd0f93170Ba6 : 0x3EDfd44082A87CF1b4cbB68D6Cf61F0A40d0b68f;
        address llamaMultisig = 0Xa519A7Ce7B24333055781133B13532Aeabfac81B; // TODO Update this address

         llamaPfp llamaPfpInstance = new llamaPfp(
            "Llama Avatar", // name
            "LLMAVTR", // symbol
            "https://core.themetagame.xyz/api/metadata/llamaPfp/", // metadata folder uri
            1, // mints per address
            "https://core.themetagame.xyz/api/contract-metadata/llamaPfp", // opensea contract metadata url
            false, // is mint active?
            validSigner,
            llamaMultisig
        );

        vm.stopBroadcast();
    }
}
