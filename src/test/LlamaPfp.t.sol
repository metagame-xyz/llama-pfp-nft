// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../LlamaPfp.sol";
import "forge-std/console.sol";

contract llamaPfpTest is Test {
    address constant owner = 0x44C489197133D7076Cd9ecB33682D6Efd271c6F7;
    address constant llamaMultisig = 0xcb33682d6EFd271c6f744C489197133d7076CD9e;
    address constant llamaMultisig2 = 0xD271c6F744c489197133D7076Cd9Ecb33682d6EF;

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
            signer,
            llamaMultisig
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
        vm.expectRevert("only 1 mint per wallet address");
        llamaPfpContract.mintWithSignature(
            alice,
            v,
            r,
            s
        );
    }

    function testCannotMintTwiceAfterTransfer() public {
        vm.deal(alice, 100000000000000000);
        vm.prank(alice);
        llamaPfpContract.mintWithSignature(
            alice,
            v,
            r,
            s
        );
        vm.prank(llamaMultisig);
        llamaPfpContract.transferFrom(alice, bob, 1);
        vm.prank(bob);
        vm.expectRevert("only 1 mint per wallet address");
        llamaPfpContract.mintWithSignature(
            bob,
            v2,
            r2,
            s2
        );
    }

    function testMustMintForYourself() public {
        vm.deal(owner, 100000000000000000);
        vm.expectRevert("you have to mint for yourself");
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
    
    function testLlamaManualTransfer() public {
        vm.deal(alice, 100000000000000000);
        vm.prank(alice);
        llamaPfpContract.mintWithSignature(alice, v, r, s);
        vm.prank(llamaMultisig);
        llamaPfpContract.transferFrom(alice, bob, 1);
        assertEq(llamaPfpContract.ownerOf(1), bob);
    }

    function testFailOwnerManualTransfer() public {
        vm.deal(alice, 100000000000000000);
        vm.prank(alice);
        llamaPfpContract.mintWithSignature(alice, v, r, s);
        vm.prank(owner);
        llamaPfpContract.transferFrom(alice, bob, 1);

    }
    
    function testNormalTransfer() public {
        vm.deal(alice, 100000000000000000);
        vm.prank(alice);
        llamaPfpContract.mintWithSignature(alice, v, r, s);
        vm.prank(alice);
        vm.expectRevert("only transfers by recovery address allowed, or mints");
        llamaPfpContract.transferFrom(alice, bob, 1);
    }

    function testNewManualAddressTransfer() public {
        vm.deal(alice, 100000000000000000);
        vm.prank(alice);
        llamaPfpContract.mintWithSignature(alice, v, r, s);
        vm.prank(owner);
        llamaPfpContract.setManualTransfersAddress(llamaMultisig2);
        vm.prank(llamaMultisig2);
        llamaPfpContract.transferFrom(alice, bob, 1);
        assertEq(llamaPfpContract.ownerOf(1), bob);
    }

    function testOldManualAddressTransferFails() public {
        vm.deal(alice, 100000000000000000);
        vm.prank(alice);
        llamaPfpContract.mintWithSignature(alice, v, r, s);
        vm.prank(owner);
        llamaPfpContract.setManualTransfersAddress(llamaMultisig2);
        vm.prank(llamaMultisig);
        vm.expectRevert("ERC721: caller is not token owner or approved");
        llamaPfpContract.transferFrom(alice, bob, 1);
        vm.prank(owner);
        vm.expectRevert("ERC721: caller is not token owner or approved");
        llamaPfpContract.transferFrom(alice, bob, 1);
    }

    function testOwnerTransferFails() public {
        vm.deal(alice, 100000000000000000);
        vm.prank(alice);
        llamaPfpContract.mintWithSignature(alice, v, r, s);
        vm.prank(owner);
        vm.expectRevert("ERC721: caller is not token owner or approved");
        llamaPfpContract.transferFrom(alice, bob, 1);
    }
}
