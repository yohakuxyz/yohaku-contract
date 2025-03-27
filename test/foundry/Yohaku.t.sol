// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC6551Account } from "erc6551/interfaces/IERC6551Account.sol";
import { IERC6551Executable } from "erc6551/interfaces/IERC6551Executable.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { IEAS, Attestation, AttestationRequest, AttestationRequestData } from "eas-contracts/IEAS.sol";
import { ISchemaRegistry } from "eas-contracts/ISchemaRegistry.sol";

import { Registry } from "../mock/TBA/Registry.sol";
import { TokenBoundAccount } from "../mock/TBA/TokenBoundAccount.sol";
import { ContributionNFT } from "../../contracts/ContributionNFT.sol";
import { Yohaku } from "../../contracts/Yohaku.sol";
import { NFTFactory } from "../../contracts/NFTFactory.sol";
import { AttesterResolver } from "../../contracts/EAS/AttesterResolver.sol";
import { YohakuV2 } from "../mock/YohakuV2.sol";

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
    bytes4 constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 constant INTERFACE_ID_ACCESS_CONTROL = 0x7965db0b;

    string schema =
        "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string Description";

    event Minted(address indexed to, address indexed account, bytes32 indexed attestationUID);
    event AttesterAdded(address indexed NewAttester);
    event Attested(address indexed recipient, address indexed attester, bytes32 uid, bytes32 indexed schemaUID);
    event PointUpdated(uint8 point);
    event NFTCreated(address nftAddress);

    function setUp() external {
        configureChain();
        vm.startPrank(owner);
        registry = new Registry();
        factory = factory = new NFTFactory(owner, eas, schemaRegistry);
        schemaUID = factory.schemaUID();
        attesterResolver = factory.resolver();

        address deployedERC721 = factory.createERC721("Mock721", "MOCK", 5, "defaultImage", owner);
        mockERC721 = ContributionNFT(deployedERC721);

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
        mockERC721.safeMint(alice, account, "mint and attest", "imageUrl");
        vm.stopPrank();

        // upgrade contract
        _upgradeContract(address(yohaku));
        address newERC721 = factory.createERC721("NEWERC721", "NEW", 10, "defaultImage", owner);

        vm.startPrank(owner);
        ContributionNFT(newERC721).safeMint(alice, account, "mint and attest for upgraded", "imageUrl");
        vm.stopPrank();

        assertEq(mockERC721.ownerOf(0), alice);
        assertEq(ContributionNFT(newERC721).ownerOf(0), alice);
        assertEq(mockERC721.balanceOf(alice), 1);
        assertEq(ContributionNFT(newERC721).balanceOf(alice), 1);
        assertEq(yohaku.ownerOf(0), alice);
    }

    /* -------------- EAS Resolver Test ----------------- */

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
        AttestationRequest memory request = AttestationRequest({ schema: schemaUID, data: attestationRequestData });

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

    function testAddAttester() external {
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, true);
        emit AttesterAdded(alice);
        attesterResolver.addAttester(alice);
        vm.stopPrank();
    }

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
        AttestationRequest memory request = AttestationRequest({ schema: schemaUID, data: attestationRequestData });

        vm.expectRevert(abi.encodeWithSelector(AttesterResolver.INVALID_ATTESTER.selector, alice));
        eas.attest(request);

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

    /* -------------- Factory Test ----------------- */

    // TODO: test addAttester
    function testCreateERC721() external {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, false);
        emit NFTCreated(factory.computeERC721Address("Mock721", "MOCK", 10, "defaultImage", owner));
        address deployedERC721 = factory.createERC721("Mock721", "MOCK", 10, "defaultImage", owner);
        assertEq(factory.checkIsAddressDeployed("Mock721", "MOCK", 10, "defaultImage", owner), true);
        assertEq(factory.computeERC721Address("Mock721", "MOCK", 10, "defaultImage", owner), deployedERC721);
        vm.stopPrank();
    }

    function testRevertAlreadyDeployed() external {
        vm.startPrank(owner);
        assertEq(factory.checkIsAddressDeployed("Mock721", "MOCK", 5, "defaultImage", owner), true);
        vm.expectRevert(abi.encodeWithSelector(NFTFactory.ALREADY_DEPLOYED.selector));
        factory.createERC721("Mock721", "MOCK", 5, "defaultImage", owner);
        vm.stopPrank();
    }

    function testGetCreatedERC721() external {
        vm.startPrank(owner);
        address deployedERC721_1 = factory.createERC721("Mock721_1", "MOCK", 10, "defaultImage", owner);
        address deployedERC721_2 = factory.createERC721("Mock721_2", "MOCK", 10, "defaultImage", owner);
        vm.stopPrank();

        address[] memory erc721s = new address[](3);
        erc721s[0] = address(mockERC721);
        erc721s[1] = deployedERC721_1;
        erc721s[2] = deployedERC721_2;

        assertEq(factory.getCreatedERC721s().length, 3);
        assertEq(factory.erc721s(0), address(mockERC721));
        assertEq(factory.erc721s(1), deployedERC721_1);
        assertEq(factory.erc721s(2), deployedERC721_2);
        assertEq(factory.getCreatedERC721s(), erc721s);
        assertEq(factory.checkIsAddressDeployed("Mock721_1", "MOCK", 10, "defaultImage", owner), true);
        assertEq(factory.computeERC721Address("Mock721_1", "MOCK", 10, "defaultImage", owner), deployedERC721_1);
        assertEq(factory.checkIsAddressDeployed("Mock721_2", "MOCK", 10, "defaultImage", owner), true);
        assertEq(factory.computeERC721Address("Mock721_2", "MOCK", 10, "defaultImage", owner), deployedERC721_2);
    }

    /* -------------- ContributionNFT Test ----------------- */
    function testMockSupportsInterface() external view {
        assertEq(mockERC721.supportsInterface(INTERFACE_ID_ERC721), true);
        assertEq(mockERC721.supportsInterface(INTERFACE_ID_ACCESS_CONTROL), true);
    }

    function testMockGetTokenData() external {
        address account = _createTBA(alice);
        vm.startPrank(owner);
        mockERC721.safeMint(alice, account, "mint and attest", "imageUrl");
        ContributionNFT.TokenData memory data = mockERC721.getTokenData(0);
        assertEq(data.owner, alice);
        assertEq(data.description, "mint and attest");
        assertEq(data.imageUrl, "imageUrl");
        vm.stopPrank();
    }

    function testMockTokenURI() external {
        address account = _createTBA(alice);
        vm.startPrank(owner);
        mockERC721.safeMint(alice, account, "mint and attest", "imageUrl");
        ContributionNFT.TokenData memory data = mockERC721.getTokenData(0);
        assertNotEq(data.imageUrl, "defaultImage");
        assertEq(data.imageUrl, "imageUrl");
        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "',
            "0",
            '"},',
            '{"trait_type": "name", "value": "',
            "Mock721",
            '"}',
            '{"trait_type": "description", "value": "',
            "mint and attest",
            '"}',
            '{"trait_type": "points", "value": "',
            uint8(5),
            '"}'
        );
        bytes memory metadata = abi.encodePacked(
            '{"name": "',
            "Mock721",
            " #",
            "0",
            '", "description": "',
            "mint and attest",
            '", "image": "',
            "imageUrl",
            '", "attributes": [',
            attributes,
            "]}"
        );
        string memory expected = string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
        assertEq(mockERC721.tokenURI(0), expected);
        vm.stopPrank();
    }

    function testMockTokenURIAfterSetDefaultImage() external {
        address account = _createTBA(alice);
        vm.startPrank(owner);
        mockERC721.safeMint(alice, account, "mint and attest", "");
        vm.stopPrank();
        ContributionNFT.TokenData memory data = mockERC721.getTokenData(0);
        assertNotEq(data.imageUrl, "defaultImage");
        assertEq(data.imageUrl, "");
        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "',
            "0",
            '"},',
            '{"trait_type": "name", "value": "',
            "Mock721",
            '"}',
            '{"trait_type": "description", "value": "',
            "mint and attest",
            '"}',
            '{"trait_type": "points", "value": "',
            uint8(5),
            '"}'
        );
        bytes memory metadata = abi.encodePacked(
            '{"name": "',
            "Mock721",
            " #",
            "0",
            '", "description": "',
            "mint and attest",
            '", "image": "',
            "defaultImage",
            '", "attributes": [',
            attributes,
            "]}"
        );
        string memory expected = string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
        assertEq(mockERC721.tokenURI(0), expected);

        vm.startPrank(owner);
        mockERC721.setDefaultImageUrl("newImage");
        vm.stopPrank();
        bytes memory newMetadata = abi.encodePacked(
            '{"name": "',
            "Mock721",
            " #",
            "0",
            '", "description": "',
            "mint and attest",
            '", "image": "',
            "newImage",
            '", "attributes": [',
            attributes,
            "]}"
        );
        string memory newExpected =
            string(abi.encodePacked("data:application/json;base64,", Base64.encode(newMetadata)));
        assertEq(mockERC721.tokenURI(0), newExpected);

        vm.startPrank(owner);
        mockERC721.setImageURL(0, "newImageURL");
        vm.stopPrank();
        bytes memory newMetadata2 = abi.encodePacked(
            '{"name": "',
            "Mock721",
            " #",
            "0",
            '", "description": "',
            "mint and attest",
            '", "image": "',
            "newImageURL",
            '", "attributes": [',
            attributes,
            "]}"
        );
        string memory newExpected2 =
            string(abi.encodePacked("data:application/json;base64,", Base64.encode(newMetadata2)));
        assertEq(mockERC721.tokenURI(0), newExpected2);
    }

    function testMintERC721() external {
        address account = _createTBA(alice);

        vm.startPrank(owner);
        vm.expectEmit(true, true, false, false);
        emit Minted(alice, account, 0x0);
        bytes32 uid = mockERC721.safeMint(alice, account, "mint and attest", "imageUrl");

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

    function testBatchMint() external {
        address aliceAccount = _createTBA(alice);
        address bobAccount = _createTBA(bob);

        vm.startPrank(owner);
        vm.expectEmit(true, true, false, false);
        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;

        address[] memory accounts = new address[](2);
        accounts[0] = aliceAccount;
        accounts[1] = bobAccount;
        mockERC721.batchMint(recipients, accounts, "batchmint", "imageUrl");

        assertEq(mockERC721.ownerOf(0), alice);
        assertEq(mockERC721.ownerOf(1), bob);

        vm.stopPrank();
    }

    function testRevertBatchMint() external {
        address aliceAccount = _createTBA(alice);

        vm.startPrank(owner);
        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = alice;

        address[] memory accounts = new address[](1);
        accounts[0] = aliceAccount;

        vm.expectRevert(
            abi.encodeWithSelector(ContributionNFT.LENGTH_MISMATCH.selector, recipients.length, accounts.length)
        );
        mockERC721.batchMint(recipients, accounts, "batchmint", "imageUrl");

        vm.stopPrank();
    }

    function testAttestedEvent() external {
        address account = _createTBA(alice);

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit Attested(account, address(mockERC721), 0x0, schemaUID);
        mockERC721.safeMint(alice, account, "mint and attest", "imageUrl");

        vm.stopPrank();
    }

    function testBasePoints() external view {
        assertEq(mockERC721.basePoints(), 5);
        assertEq(mockERC721.getPoints(), 5);
    }

    function testUpdatePoints() external {
        address account = _createTBA(alice);

        vm.startPrank(owner);
        mockERC721.safeMint(alice, account, "mint and attest", "imageUrl");

        assertEq(mockERC721.getPoints(), 5);

        vm.expectEmit(true, true, false, false);
        emit PointUpdated(10);
        mockERC721.updatePoints(10);
        assertEq(mockERC721.getPoints(), 10);

        vm.stopPrank();
    }

    function testMockSetImageURL() external {
        address account = _createTBA(alice);

        vm.startPrank(owner);
        mockERC721.safeMint(alice, account, "mint and attest", "imageUrl");

        mockERC721.setImageURL(0, "newImage");
        assertEq(mockERC721.getTokenData(0).imageUrl, "newImage");

        vm.stopPrank();
    }

    function testMockSetDefaultImageUrl() external {
        assertEq(mockERC721.defaultImageUrl(), "defaultImage");
        vm.startPrank(owner);

        mockERC721.setDefaultImageUrl("newImage");
        assertEq(mockERC721.defaultImageUrl(), "newImage");
        vm.stopPrank();
    }

    function testRevertINVALID_MINTER() external {
        address account = _createTBA(alice);
        vm.startPrank(alice);

        assertEq(mockERC721.hasRole(mockERC721.MINTER_ROLE(), owner), true);
        assertEq(mockERC721.hasRole(mockERC721.MINTER_ROLE(), alice), false);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, alice, mockERC721.MINTER_ROLE()
            )
        );
        mockERC721.safeMint(alice, account, "", "imageURL");
        vm.stopPrank();
    }

    function testRevertInvalidAdmin() external {
        address account = _createTBA(alice);

        vm.startPrank(owner);
        mockERC721.safeMint(alice, account, "mint and attest", "imageUrl");

        assertEq(mockERC721.getPoints(), 5);

        vm.stopPrank();
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, alice, mockERC721.DEFAULT_ADMIN_ROLE()
            )
        );
        mockERC721.updatePoints(10);
        vm.stopPrank();
    }

    function testRevertALREADY_HAVE_TOKEN() external {
        address aliceAccount = _createTBA(alice);

        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = alice;

        address[] memory accounts = new address[](2);
        accounts[0] = aliceAccount;
        accounts[1] = aliceAccount;

        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSelector(ContributionNFT.ALREADY_HAVE_TOKEN.selector, alice));
        mockERC721.batchMint(recipients, accounts, "batchmint", "imageUrl");

        vm.stopPrank();
    }

    /* -------------- Yohaku Test ----------------- */

    function testTokenURI() external {
        _mintYohaku(alice, "image");
        Yohaku.TokenData memory data = yohaku.getTokenData(0);

        assertNotEq(data.imageUrl, "defaultImage");
        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "', "0", '"},', '{"trait_type": "name", "value": "', "[]Yohaku", '"}'
        );

        bytes memory metadata = abi.encodePacked(
            '{"name": "[]Yohaku #',
            "0",
            '", "description": "',
            data.description,
            '", "image": "',
            data.imageUrl,
            '", "attributes": [',
            attributes,
            "]}"
        );

        string memory expected = string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
        assertEq(yohaku.tokenURI(0), expected);
    }

    function testTokenURIAfterSetDefaultImage() external {
        _mintYohaku(alice, "");
        _mintYohaku(bob, "image");
        Yohaku.TokenData memory data = yohaku.getTokenData(0);
        Yohaku.TokenData memory data2 = yohaku.getTokenData(1);
        assertEq(data.imageUrl, "");
        assertEq(data2.imageUrl, "image");
        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "', "0", '"},', '{"trait_type": "name", "value": "', "[]Yohaku", '"}'
        );

        bytes memory metadata = abi.encodePacked(
            '{"name": "[]Yohaku #',
            "0",
            '", "description": "',
            data.description,
            '", "image": "',
            "defaultImage",
            '", "attributes": [',
            attributes,
            "]}"
        );

        string memory expected = string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
        assertEq(yohaku.tokenURI(0), expected);

        vm.startPrank(owner);
        yohaku.setDefaultImageUrl("newImage");
        vm.stopPrank();
        bytes memory newMetadata = abi.encodePacked(
            '{"name": "[]Yohaku #',
            "0",
            '", "description": "',
            data.description,
            '", "image": "',
            "newImage",
            '", "attributes": [',
            attributes,
            "]}"
        );
        bytes memory bobAttributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "', "1", '"},', '{"trait_type": "name", "value": "', "[]Yohaku", '"}'
        );
        bytes memory bobMetadata = abi.encodePacked(
            '{"name": "[]Yohaku #',
            "1",
            '", "description": "',
            data2.description,
            '", "image": "',
            "image",
            '", "attributes": [',
            bobAttributes,
            "]}"
        );
        string memory newExpected =
            string(abi.encodePacked("data:application/json;base64,", Base64.encode(newMetadata)));
        string memory bobExpected =
            string(abi.encodePacked("data:application/json;base64,", Base64.encode(bobMetadata)));
        assertEq(yohaku.tokenURI(0), newExpected);
        assertEq(yohaku.tokenURI(1), bobExpected);
    }

    function testVersion() external view {
        assertEq(yohaku.version(), "1.0.0");
    }

    function testSupportsInterface() external view {
        assertEq(yohaku.supportsInterface(INTERFACE_ID_ERC721), true);
        assertEq(yohaku.supportsInterface(INTERFACE_ID_ACCESS_CONTROL), true);
    }

    function testSetMinter() external {
        vm.startPrank(owner);
        yohaku.setMinter(alice);
        assertEq(yohaku.hasRole(yohaku.MINTER_ROLE(), alice), true);
        vm.stopPrank();
    }

    function testPause() external {
        vm.startPrank(owner);
        yohaku.pause();
        assertEq(yohaku.paused(), true);
        vm.stopPrank();
    }

    function testUnpause() external {
        vm.startPrank(owner);
        yohaku.pause();
        assertEq(yohaku.paused(), true);
        yohaku.unpause();
        assertEq(yohaku.paused(), false);
        vm.stopPrank();
    }

    function testGetOwners() external {
        _mintYohaku(alice, "");
        address[] memory owners = new address[](1);
        owners[0] = alice;
        assertEq(yohaku.getOwners(0), owners);
        vm.prank(alice);
        yohaku.approve(address(this), 0);
        yohaku.safeTransferFrom(alice, bob, 0);

        address[] memory newOwners = new address[](2);
        newOwners[0] = alice;
        newOwners[1] = bob;

        assertEq(yohaku.getOwners(0), newOwners);
        assertEq(yohaku.ownerOf(0), bob);
    }

    function testSetImageURL() external {
        _mintYohaku(alice, "");
        assertEq(yohaku.getTokenData(0).imageUrl, "");
        vm.startPrank(owner);
        yohaku.setImageURL(0, "newImage");
        Yohaku.TokenData memory tokenData = yohaku.getTokenData(0);
        assertEq(tokenData.imageUrl, "newImage");
        vm.stopPrank();
    }

    function testSetDefaultImageUrl() external {
        vm.startPrank(owner);
        Yohaku.TokenData memory aliceToken = yohaku.safeMint(alice, "Image");
        Yohaku.TokenData memory beforeBobToken = yohaku.safeMint(bob, "");

        assertEq(aliceToken.imageUrl, "Image");
        assertEq(beforeBobToken.imageUrl, "");
        assertEq(yohaku.defaultImageUrl(), "defaultImage");

        yohaku.setDefaultImageUrl("newImage");
        Yohaku.TokenData memory afterBobToken = yohaku.getTokenData(1);
        // THIS IS DESIRED BEHAVIOR
        /// If 'imageUrl' is empty, the default image URL will be used when tokenURI() is called, and store empty string
        /// in the tokenData mapping.
        /// We don't store the default image URL in the tokenData mapping to avoid conflicts when owner updated default
        /// image URL.
        /// e.g. If we store the default image URL in the tokenData mapping here and then update the default image URL,
        /// the tokenURI() will return the old default image URL.
        assertEq(aliceToken.imageUrl, "Image");
        assertEq(afterBobToken.imageUrl, "");
        assertEq(yohaku.defaultImageUrl(), "newImage");

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

    function testRevertYohaku_ALREADY_HAVE_TOKEN() external {
        _mintYohaku(alice, "");
        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSelector(Yohaku.ALREADY_HAVE_TOKEN.selector, alice));
        _mintYohaku(alice, "");

        vm.stopPrank();
    }

    function testRevertInvalidMinterRole() external {
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

    function testRevertInvalidPauserRole() external {
        vm.startPrank(alice);
        assertEq(yohaku.hasRole(yohaku.PAUSER_ROLE(), owner), true);
        assertEq(yohaku.hasRole(yohaku.PAUSER_ROLE(), alice), false);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, alice, yohaku.PAUSER_ROLE()
            )
        );
        yohaku.pause();
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
        if (block.chainid == 10 || block.chainid == 11_155_420) {
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
