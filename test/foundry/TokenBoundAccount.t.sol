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
    bytes32 public schemaUID;

    address public owner = makeAddr("owner");
    address public minter = makeAddr("minter");
    string schema =
        "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string Description";

    function setUp() public {
        configureChain();
        vm.startPrank(owner);
        registry = deployRegistry();
        factory = deployFactory();
        mockERC721 = deployMockERC721();
        schemaUID = registerSchema();
        attesterResolver = deploySchemaResolver();
        implementation = new TokenBoundAccount();
        vm.stopPrank();
    }

    function testCreateAccount() public {
        setUp();
        vm.startPrank(owner);
        address account = createTBA();

        assertEq(
            account,
            registry.account(
                address(implementation), //implementation
                0, //salt,
                block.chainid, //chainId,
                address(mockERC721), //tokenContract
                0 //tokenId
            )
        );
    }

    function testRegisterSchema() public {
        setUp();
        vm.startPrank(owner);
        bytes32 uid = registerSchema();
        assertEq(schema, schemaRegistry.getSchema(uid).schema);
    }

    function testAttest() public {
        address account = createTBA();
        vm.startPrank(minter);
        // "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string Description";
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
        bytes32 attestationUID = eas.attest(request);
        emit log_bytes32(attestationUID);

        bytes memory attestationData = eas.getAttestation(attestationUID).data;
        (
            address _tokenBoundAccount,
            address _currentOwner,
            address _tokenAddress,
            uint256 tokenId,
            uint8 _score,
            string memory _description
        ) = abi.decode(attestationData, (address, address, address, uint256, uint8, string));
        assertEq(attestationData, _data);
        assertEq(_tokenBoundAccount, account);
        assertEq(_currentOwner, owner);
        assertEq(_tokenAddress, address(mockERC721));
        assertEq(tokenId, 0);
        assertEq(_score, 5);
        assertEq(_description, "test");
    }

    function testRevertResolver() public {
        bytes32 uid = registerSchema();
        address account = createTBA();

        vm.startPrank(owner);

        bytes memory _data = abi.encode(account, owner, mockERC721, 0, 5, "test");

        AttestationRequestData memory attestationRequestData = AttestationRequestData({
            recipient: owner,
            expirationTime: uint64(block.timestamp + 100),
            revocable: true,
            refUID: 0x0,
            data: _data,
            value: 0
        });

        AttestationRequest memory request = AttestationRequest({schema: uid, data: attestationRequestData});
        eas.attest(request);

        vm.expectRevert();
    }

    function testSendTransaction() external {
        vm.startPrank(owner);
        address recipient = makeAddr("recipient");
        address account = createTBA();

        IERC6551Account accountInstance = IERC6551Account(payable(account));
        IERC6551Executable executableAccountInstance = IERC6551Executable(account);
        assertEq(TokenBoundAccount(payable(account)).owner(), owner);

        assertEq(accountInstance.isValidSigner(owner, ""), IERC6551Account.isValidSigner.selector);
        vm.deal(account, 1 ether);
        executableAccountInstance.execute(payable(recipient), 0.5 ether, "", 0);
        assertEq(account.balance, 0.5 ether);
        assertEq(recipient.balance, 0.5 ether);
        assertEq(accountInstance.state(), 1);
    }

    function testTransferOwnership() public {
        vm.startPrank(owner);
        address account = createTBA();
        address recipient = makeAddr("recipient");
        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        assertEq(tba.owner(), owner);
        mockERC721.safeTransferFrom(owner, recipient, 0);
        assertEq(recipient, tba.owner());

        vm.deal(address(tba), 1 ether);
        vm.expectRevert("Invalid signer");
        tba.execute(payable(address(0)), 0.5 ether, "", 0);
    }

    function createTBA() public returns (address) {
        mockERC721.safeMint(owner, "");

        address account = registry.createAccount(
            address(implementation), //implementation
            0, //salt,
            block.chainid, //chainId,
            address(mockERC721), //tokenContract
            0 //tokenId
        );
        assertTrue(account != address(0));
        return account;
    }

    function createNewAttestation(address _account, address _recipient, address _owner) public returns (bytes32) {
        // "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string Description";
        bytes memory _data = abi.encode(_account, _owner, mockERC721, 0, 5, "test");

        AttestationRequestData memory attestationRequestData = AttestationRequestData({
            recipient: _recipient,
            expirationTime: uint64(block.timestamp + 100),
            revocable: true,
            refUID: 0x0,
            data: _data,
            value: 0
        });

        AttestationRequest memory request = AttestationRequest({schema: schemaUID, data: attestationRequestData});
        vm.startPrank(owner);
        bytes32 attestationUID = eas.attest(request);

        vm.stopPrank();
        return attestationUID;
    }

    function deployFactory() public returns (NFTFactory) {
        factory = new NFTFactory();
        return factory;
    }

    function deployMockERC721() public returns (MockERC721) {
        MockERC721 nft = factory.createERC721("", "", 5);
        return nft;
    }

    function deployRegistry() public returns (Registry) {
        return new Registry();
    }

    function deploySchemaResolver() public returns (AttesterResolver) {
        return new AttesterResolver(eas, minter);
    }

    function registerSchema() public returns (bytes32) {
        bytes32 uid = schemaRegistry.register(schema, attesterResolver, true);
        return uid;
    }

    function configureChain() public {
        if (block.chainid == 80001) {
            eas = IEAS(0xaEF4103A04090071165F78D45D83A0C0782c2B2a);
            schemaRegistry = ISchemaRegistry(0x55D26f9ae0203EF95494AE4C170eD35f4Cf77797);
        }
    }
}
