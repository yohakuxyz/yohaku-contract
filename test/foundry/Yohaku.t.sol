// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "erc6551/interfaces/IERC6551Executable.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {IEAS, Attestation, AttestationRequest, AttestationRequestData} from "eas-contracts/IEAS.sol";
import {ISchemaRegistry} from "eas-contracts/ISchemaRegistry.sol";

import "../../contracts/ContributionNFT.sol";
import "../../contracts/TBA/Registry.sol";
import "../../contracts/TBA/TokenBoundAccount.sol";
import "../../contracts/Yohaku.sol";
import "../../contracts/YohakuV2.sol";
import "../../contracts/NFTFactory.sol";
import {AttesterResolver} from "../../contracts/EAS/AttesterResolver.sol";

contract YohakuTest is Test {
    ContributionNFT public mockERC721;
    TokenBoundAccount public implementation;
    Registry public registry;
    NFTFactory public factory;
    AttesterResolver public attesterResolver;
    IEAS public eas;
    ISchemaRegistry public schemaRegistry;
    Yohaku public yohaku;
    bytes32 public schemaUID;

    address public currentPrankee;
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    string schema =
        "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string Description";

    event Minted(address indexed to, address indexed account, bytes32 indexed attestationUID);
    event AttesterAdded(address indexed NewAttester);
    event Attested(address indexed recipient, address indexed attester, bytes32 uid, bytes32 indexed schemaUID);

    function setUp() external {
        configureChain();
        vm.startPrank(owner);
        registry = new Registry();
        factory = factory = new NFTFactory(owner, eas, schemaRegistry);
        schemaUID = factory.schemaUID();
        attesterResolver = factory.resolver();
        mockERC721 = factory.createERC721("Mock721", "MOCK", 5, "defaultImage", owner);

        address proxy = Upgrades.deployTransparentProxy(
            "Yohaku.sol",
            owner,
            abi.encodeCall(Yohaku.initialize, (owner, "Yohaku NFT is built for community", "defaultImage"))
        );
        yohaku = Yohaku(proxy);

        implementation = new TokenBoundAccount();
        vm.stopPrank();
    }
    /* -------------- Upgrade Test ----------------- */

    function testUpgrade() external {
        address account = _createTBA(alice);

        vm.startPrank(owner);
        mockERC721.safeMint(alice, account, "mint and attest");
        vm.stopPrank();

        // upgrade contract
        _upgradeContract(address(yohaku));
        ContributionNFT newERC721 = factory.createERC721("NEWERC721", "NEW", 10, "defaultImage", owner);

        vm.startPrank(owner);
        newERC721.safeMint(alice, account, "mint and attest for upgraded");
        vm.stopPrank();

        assertEq(mockERC721.ownerOf(0), alice);
        assertEq(newERC721.ownerOf(0), alice);
        assertEq(mockERC721.balanceOf(alice), 1);
        assertEq(newERC721.balanceOf(alice), 1);
        assertEq(yohaku.ownerOf(0), alice);
    }

    /* -------------- EAS Test ----------------- */

    function testAttestManual() external {
        address account = _createTBA(alice);
        vm.startPrank(owner);
        bytes memory _data = abi.encode(account, alice, mockERC721, 0, 5, "test");

        AttestationRequestData memory attestationRequestData = AttestationRequestData({
            recipient: account,
            expirationTime: uint64(block.timestamp + 100),
            revocable: true,
            refUID: 0x0,
            data: _data,
            value: 0
        });
        AttestationRequest memory request = AttestationRequest({schema: schemaUID, data: attestationRequestData});

        vm.expectEmit(true, true, true, false);
        emit Attested(account, owner, 0x0, schemaUID);
        bytes32 uid = eas.attest(request);
        bytes memory attestationData = eas.getAttestation(uid).data;

        (
            address tokenBoundAccount,
            address currentOwner,
            address tokenAddress,
            uint256 tokenId,
            uint8 score,
            string memory description
        ) = abi.decode(attestationData, (address, address, address, uint256, uint8, string));

        assertEq(tokenBoundAccount, account);
        assertEq(currentOwner, alice);
        assertEq(tokenAddress, address(mockERC721));
        assertEq(tokenId, 0);
        assertEq(score, 5);
        assertEq(description, "test");
        vm.stopPrank();
    }

    function testMintERC721() external {
        address account = _createTBA(alice);

        vm.startPrank(owner);
        vm.expectEmit(true, true, false, false);
        emit Minted(alice, account, 0x0);
        bytes32 uid = mockERC721.safeMint(alice, account, "mint and attest");

        bytes memory attestationData = eas.getAttestation(uid).data;
        (
            address tokenBoundAccount,
            address currentOwner,
            address tokenAddress,
            uint256 tokenId,
            uint8 score,
            string memory description
        ) = abi.decode(attestationData, (address, address, address, uint256, uint8, string));

        assertEq(tokenBoundAccount, account);
        assertEq(currentOwner, alice);
        assertEq(tokenAddress, address(mockERC721));
        assertEq(tokenId, 0);
        assertEq(score, mockERC721.basePoints());
        assertEq(description, "mint and attest");

        vm.stopPrank();
    }

    function testAttestedEvent() external {
        address account = _createTBA(alice);

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Attested(account, address(mockERC721), 0x0, schemaUID);
        mockERC721.safeMint(alice, account, "mint and attest");

        vm.stopPrank();
    }

    function testAddAttester() external {
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, true);
        emit AttesterAdded(alice);
        attesterResolver.addAttester(alice);
        vm.stopPrank();
    }

    /* -------------- TBA Test ----------------- */
    function testCreateAccount() external {
        address account = _createTBA(alice);

        assertEq(
            account,
            registry.account(
                address(implementation), //implementation
                0, //salt,
                block.chainid, //chainId,
                address(yohaku), //tokenContract
                0 //tokenId
            )
        );
    }

    function testSendTransaction() external {
        address recipient = makeAddr("recipient");
        address account = _createTBA(alice);

        IERC6551Account accountInstance = IERC6551Account(payable(account));
        IERC6551Executable executableAccountInstance = IERC6551Executable(account);
        assertEq(TokenBoundAccount(payable(account)).owner(), alice);

        assertEq(accountInstance.isValidSigner(alice, ""), IERC6551Account.isValidSigner.selector);
        vm.deal(account, 1 ether);
        vm.startPrank(alice);

        executableAccountInstance.execute(payable(recipient), 0.5 ether, "", 0);
        assertEq(accountInstance.state(), 1);
        vm.stopPrank();
    }

    /* -------------- Revert Test ----------------- */

    function testRevertInvalidAttester() external {
        address account = _createTBA(alice);
        vm.startPrank(alice);
        bytes memory _data = abi.encode(account, owner, mockERC721, 0, 5, "test");

        AttestationRequestData memory attestationRequestData = AttestationRequestData({
            recipient: owner,
            expirationTime: uint64(block.timestamp + 100),
            revocable: true,
            refUID: 0x0,
            data: _data,
            value: 0
        });
        AttestationRequest memory request = AttestationRequest({schema: schemaUID, data: attestationRequestData});

        vm.expectRevert(abi.encodeWithSelector(CallerNotAttester.selector, alice));
        eas.attest(request);

        vm.stopPrank();
    }

    function testRevertInvalidSigner() external {
        vm.startPrank(owner);
        address account = _createTBA(alice);
        address recipient = makeAddr("recipient");
        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        assertEq(tba.owner(), alice);
        _transferYohaku(alice, recipient, 0);
        assertEq(tba.owner(), recipient);

        vm.deal(address(tba), 1 ether);
        vm.expectRevert("Invalid signer");
        tba.execute(payable(address(0)), 0.5 ether, "", 0);
    }

    function testRevertCallerIsNotYohakuMinter() external {
        vm.startPrank(alice);

        assertEq(yohaku.hasRole(yohaku.MINTER_ROLE(), owner), true);
        assertEq(yohaku.hasRole(yohaku.MINTER_ROLE(), alice), false);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, alice, yohaku.MINTER_ROLE()
            )
        );
        yohaku.safeMint(alice, "");
        vm.stopPrank();
    }

    function testRevertCallerIsNotMockERC721Minter() external {
        address account = _createTBA(alice);
        vm.startPrank(alice);

        assertEq(mockERC721.hasRole(mockERC721.MINTER_ROLE(), owner), true);
        assertEq(mockERC721.hasRole(mockERC721.MINTER_ROLE(), alice), false);

        vm.expectRevert("Caller is not a minter");
        mockERC721.safeMint(alice, account, "");
        vm.stopPrank();
    }

    function testRevertCannotHoldMoreThanOneToken() external {
        address aliceAccount = _createTBA(alice);

        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = alice;

        address[] memory accounts = new address[](2);
        accounts[0] = aliceAccount;
        accounts[1] = aliceAccount;

        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSelector(CannotHoldMoreThanOneToken.selector, alice));
        mockERC721.batchMint(recipients, accounts, "batchmint");

        vm.stopPrank();
    }

    function testRevertCannotHoldMoreThanOneYohakuNFT() external {
        _mintYohaku(alice, "");
        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSelector(Yohaku.CannnotHoldMoreThanOneYohakuNFT.selector, alice));
        _mintYohaku(alice, "");

        vm.stopPrank();
    }

    /* -------------- Yohaku Test ----------------- */

    function testImageUrl() external {
        vm.startPrank(owner);
        Yohaku.TokenData memory aliceToken = yohaku.safeMint(alice, "Image");
        Yohaku.TokenData memory beforeBobToken = yohaku.safeMint(bob, "");

        assertEq(aliceToken.owner, alice);
        assertEq(aliceToken.description, "Yohaku NFT is built for community");

        assertEq(aliceToken.imageUrl, "Image");
        assertEq(beforeBobToken.imageUrl, "");

        yohaku.setDefaultImageUrl("newImage");
        Yohaku.TokenData memory afterBobToken = yohaku.getTokenData(1);
        assertEq(aliceToken.imageUrl, "Image");
        assertEq(afterBobToken.imageUrl, "");

        vm.stopPrank();
    }

    function testTransferOwnership() external {
        _mintYohaku(alice, "");

        vm.prank(alice);
        yohaku.approve(address(this), 0);
        yohaku.safeTransferFrom(alice, bob, 0);

        address[] memory owners = new address[](2);
        owners[0] = alice;
        owners[1] = bob;

        assertEq(yohaku.getOwners(0), owners);
        assertEq(yohaku.ownerOf(0), bob);
    }

    function testSafeMint() external {
        _mintYohaku(alice, "");
        assertEq(yohaku.ownerOf(0), alice);
    }

    function testBatchMint() external {
        address aliceAccount = _createTBA(alice);
        address bobAccount = _createTBA(bob);

        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;

        address[] memory accounts = new address[](2);
        accounts[0] = aliceAccount;
        accounts[1] = bobAccount;

        vm.startPrank(owner);

        mockERC721.batchMint(recipients, accounts, "batchmint");

        assertEq(mockERC721.ownerOf(0), alice);
        assertEq(mockERC721.ownerOf(1), bob);

        vm.stopPrank();
    }

    /* -------------- Internal Functions ----------------- */

    function _createTBA(address recipient) internal returns (address) {
        _mintYohaku(recipient, "");
        vm.startPrank(recipient);
        address account = registry.createAccount(
            address(implementation), //implementation
            0, //salt,
            block.chainid, //chainId,
            address(yohaku), //tokenContract
            0 //tokenId
        );
        assertTrue(account != address(0));
        return account;
    }

    function _mintYohaku(address to, string memory imageUrl) internal prankception(owner) {
        yohaku.safeMint(to, imageUrl);
    }

    function _transferYohaku(address from, address to, uint256 tokenId) internal prankception(from) {
        yohaku.safeTransferFrom(from, to, tokenId);
    }

    function _upgradeContract(address proxy) internal prankception(owner) {
        Upgrades.upgradeProxy(proxy, "YohakuV2.sol", "");
    }

    function configureChain() public {
        if (block.chainid == 80001) {
            eas = IEAS(0xaEF4103A04090071165F78D45D83A0C0782c2B2a);
            schemaRegistry = ISchemaRegistry(0x55D26f9ae0203EF95494AE4C170eD35f4Cf77797);
        } else if (block.chainid == 137) {
            eas = IEAS(0x5E634ef5355f45A855d02D66eCD687b1502AF790);
            schemaRegistry = ISchemaRegistry(0x7876EEF51A891E737AF8ba5A5E0f0Fd29073D5a7);
        } else if (block.chainid == 10) {
            eas = IEAS(0x4200000000000000000000000000000000000021);
            schemaRegistry = ISchemaRegistry(0x4200000000000000000000000000000000000020);
        } else {
            revert("Unsupported chain");
        }
    }

    modifier prankception(address prankee) {
        address prankBefore = currentPrankee;
        vm.stopPrank();
        vm.startPrank(prankee);
        _;
        vm.stopPrank();
        if (prankBefore != address(0)) {
            vm.startPrank(prankBefore);
        }
    }
}
