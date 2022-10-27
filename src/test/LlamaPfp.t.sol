// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../LlamaPfp.sol";
import "forge-std/console.sol";

contract llamaPfpTest is Test {
    address constant owner = 0x44C489197133D7076Cd9ecB33682D6Efd271c6F7;

    uint private immutable signerPk = 1;
    address private immutable signer = vm.addr(1);

    address constant alice = 0x9bEF1f52763852A339471f298c6780e158E43A68;
    address constant bob = 0xFFff0BE2f91F2B4a5c22aEBbd928A9565EE92ccb;

    // hardcoded from metabot API
    bytes32 r;
    bytes32 s;
    uint8 v;

    bytes32 r2;
    bytes32 s2;
    uint8 v2;

    llamaPfp llamaPfpContract;

    constructor() {
        vm.prank(owner);
        llamaPfpContract = new llamaPfp(
            "llamaPfp",
            "LLMAPFP",
            "NOT_IMPLEMENTED",
            1,
            "NOT_IMPLEMENTED",
            false,
            signer
        );

        bytes32 DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("Llama PFP"),
                keccak256("1"),
                block.chainid,
                llamaPfpContract.getAddress()
            )
        );

        // Alice
        bytes32 payloadHash = keccak256(abi.encode(DOMAIN_SEPARATOR, alice));
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash)
        );
        (v,r,s) = vm.sign(signerPk, messageHash);

        //Bob
        bytes32 payloadHash2 = keccak256(abi.encode(DOMAIN_SEPARATOR, bob));
        bytes32 messageHash2 = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash2)
        );
        (v2,r2,s2) = vm.sign(signerPk, messageHash2);
        
    }

    function setUp() public {
        vm.prank(owner);
        llamaPfpContract.setMintActive(true);
    }

    function testFailSetActiveByNonOwner() public {
        vm.prank(alice);
        llamaPfpContract.setMintActive(true);
    }

    function testMintWithSignature() public {
        vm.deal(alice, 100000000000000000);
        vm.prank(alice);

        uint256 newTokenId = llamaPfpContract.mintWithSignature{value:0}(alice, v, r, s);
        assertEq(newTokenId, 1);
    }

    function testCannotMintTwice() public {
        vm.deal(alice, 100000000000000000);
        vm.prank(alice);
        llamaPfpContract.mintWithSignature(
            alice,
            v,
            r,
            s
        );
        vm.prank(alice);
        vm.expectRevert(bytes("only 1 mint per wallet address"));
        llamaPfpContract.mintWithSignature(
            alice,
            v,
            r,
            s
        );
    }

    function testMustMintForYourself() public {
        vm.deal(owner, 100000000000000000);
        vm.expectRevert(bytes("you have to mint for yourself"));
        vm.prank(owner);
        llamaPfpContract.mintWithSignature(
            alice,
            v,
            r,
            s
        );
    }

    function testCannotFakeSignature() public {
        address newSigner = owner;
        vm.prank(owner);
        llamaPfpContract.setValidSigner(newSigner);

        vm.deal(alice, 100000000000000000);
        vm.expectRevert(bytes("Invalid signer"));
        vm.prank(alice);
        llamaPfpContract.mintWithSignature(
            alice,
            v,
            r,
            s
        );
    }

    function testMultipleMints() public {
        vm.deal(alice, 100000000000000000);
        vm.prank(alice);
        uint256 newTokenId = llamaPfpContract.mintWithSignature(alice, v, r, s);
        assertEq(newTokenId, 1);

        vm.deal(bob, 100000000000000000);
        vm.prank(bob);
        uint256 newTokenId2 = llamaPfpContract.mintWithSignature(bob, v2, r2, s2);
        assertEq(newTokenId2, 2);
        assertEq(llamaPfpContract.mintedCount(), 2);
    }

    // function testFailWithdrawByNonOwner() public {
    //     vm.prank(alice);
    //     llamaPfpContract.withdraw();
    // }
}
