// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "erc6551/interfaces/IERC6551Executable.sol";

import {IEAS, Attestation, AttestationRequest, AttestationRequestData} from "eas-contracts/IEAS.sol";
import {ISchemaRegistry} from "eas-contracts/ISchemaRegistry.sol";

import "../../contracts/MockNFT.sol";
import "../../contracts/Registry.sol";
import "../../contracts/TokenBoundAccount.sol";
import "../../contracts/SkyBlue.sol";
import "../../contracts/NFTFactory.sol";
import {AttesterResolver} from "../../contracts/AttesterResolver.sol";

contract TokenBoundAccountTest is Test {
    MockERC721 public mockERC721;
    TokenBoundAccount public implementation;
    Registry public registry;
    NFTFactory public factory;
    AttesterResolver public attesterResolver;
    IEAS public eas;
    ISchemaRegistry public schemaRegistry;
    SkyBlue public skyblue;
    bytes32 public schemaUID;

    address public currentPrankee;
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    string schema =
        "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string Description";

    event Minted(address indexed to, address indexed account, bytes32 indexed attestationUID);
    event AttesterAdded(address indexed NewAttester);
    event Attested(address indexed recipient, address indexed attester, bytes32 uid, bytes32 indexed schemaUID);

    function setUp() public {
        configureChain();
        vm.startPrank(owner);
        registry = new Registry();
        factory = factory = new NFTFactory(owner, eas, schemaRegistry);
        schemaUID = factory.schemaUID();
        attesterResolver = factory.resolver();
        mockERC721 = factory.createERC721("Mock721", "MOCK", 5);
        skyblue = new SkyBlue(owner, "");
        implementation = new TokenBoundAccount();
        vm.stopPrank();
    }

    function testAttestManual() external {
        address account = _createTBA();
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

    // EAS test
    function testMintERC721() external {
        address account = _createTBA();

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
        address account = _createTBA();

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

    // TBA test
    function testCreateAccount() external {
        address account = _createTBA();

        assertEq(
            account,
            registry.account(
                address(implementation), //implementation
                0, //salt,
                block.chainid, //chainId,
                address(skyblue), //tokenContract
                0 //tokenId
            )
        );
    }

    function testSendTransaction() external {
        address recipient = makeAddr("recipient");
        address account = _createTBA();

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

    // revert test

    function testRevertInvalidAttester() external {
        address account = _createTBA();
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
        address account = _createTBA();
        address recipient = makeAddr("recipient");
        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        assertEq(tba.owner(), alice);
        _transferSkyBlue(alice, recipient, 0);
        assertEq(tba.owner(), recipient);

        vm.deal(address(tba), 1 ether);
        vm.expectRevert("Invalid signer");
        tba.execute(payable(address(0)), 0.5 ether, "", 0);
    }

    function _createTBA() internal returns (address) {
        _mintSkyBlue(alice, "test", "");
        vm.startPrank(alice);
        address account = registry.createAccount(
            address(implementation), //implementation
            0, //salt,
            block.chainid, //chainId,
            address(skyblue), //tokenContract
            0 //tokenId
        );
        assertTrue(account != address(0));
        return account;
    }

    function _mintSkyBlue(address to, string memory description, string memory imageUrl) internal prankception(owner) {
        skyblue.mintWithMetaData(to, description, imageUrl);
    }

    function _transferSkyBlue(address from, address to, uint256 tokenId) internal prankception(from) {
        skyblue.safeTransferFrom(from, to, tokenId);
    }

    function configureChain() public {
        if (block.chainid == 80001) {
            eas = IEAS(0xaEF4103A04090071165F78D45D83A0C0782c2B2a);
            schemaRegistry = ISchemaRegistry(0x55D26f9ae0203EF95494AE4C170eD35f4Cf77797);
        } else if (block.chainid == 137) {
            eas = IEAS(0x5E634ef5355f45A855d02D66eCD687b1502AF790);
            schemaRegistry = ISchemaRegistry(0x7876EEF51A891E737AF8ba5A5E0f0Fd29073D5a7);
        } else if (block.chainid == 10) {
            eas = IEAS(0x4E0275Ea5a89e7a3c1B58411379D1a0eDdc5b088);
            schemaRegistry = ISchemaRegistry(0x6232208d66bAc2305b46b4Cb6BCB3857B298DF13);
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
