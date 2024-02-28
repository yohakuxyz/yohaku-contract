// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "erc6551/interfaces/IERC6551Executable.sol";

import "./NFTFactory.sol";

error InvalidChainId();

contract TokenBoundAccount is
    Ownable,
    IERC6551Account,
    IERC6551Executable,
    IERC721Receiver,
    IERC1155Receiver
{
    constructor(NFTFactory _factory) Ownable(msg.sender) {
        owners.push(msg.sender);
        nftFactory = _factory;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    address[] public owners;
    NFTFactory public nftFactory;

    // get the total points of all the NFTs owned by the account including the previous owners
    function getTotalPoint() public view returns (uint256) {
        uint256 totalPoints = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            totalPoints += nftFactory.getTotalPoints(owners[i]);
        }
        return totalPoints;
    }

    /// inherit IERC6551Account
    uint256 public state;

    enum TokenType {
        ERC721,
        ERC1155
    }
    struct Token {
        address tokenContract;
        uint256 tokenId; // only used for ERC1155
        TokenType tokenType;
    }

    receive() external payable {}

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable virtual returns (bytes memory result) {
        require(_isValidSigner(msg.sender), "Invalid signer");
        require(operation == 0, "Only call operations are supported");

        ++state;

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function isValidSigner(
        address signer,
        bytes calldata
    ) external view virtual returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view virtual returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(
            owner(),
            hash,
            signature
        );

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return bytes4(0);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure virtual returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC6551Executable).interfaceId;
    }

    function token()
        public
        view
        virtual
        returns (uint256 chainId, address tokenContract, uint256 tokenId)
    {
        bytes memory footer = new bytes(0x60);

        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    // returns owner of the NFT
    function owner() public view override returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();
        if (chainId != block.chainid) revert InvalidChainId();

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    // get the balance of specific Token(ERC721 or ERC1155)
    function getTokenBalance(
        Token calldata _token
    ) public view returns (uint256 count) {
        if (_token.tokenType == TokenType.ERC721) {
            return IERC721(_token.tokenContract).balanceOf(address(this));
        } else if (_token.tokenType == TokenType.ERC1155) {
            return
                IERC1155(_token.tokenContract).balanceOf(
                    address(this),
                    _token.tokenId
                );
        }
    }

    // get the total balance of tokens(ERC721 or ERC1155)
    function getTokenCounts(
        Token[] calldata _tokens
    ) public view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i].tokenType == TokenType.ERC721) {
                count += IERC721(_tokens[i].tokenContract).balanceOf(
                    address(this)
                );
            } else if (_tokens[i].tokenType == TokenType.ERC1155) {
                count += IERC1155(_tokens[i].tokenContract).balanceOf(
                    address(this),
                    _tokens[i].tokenId
                );
            }
        }
        return count;
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @inheritdoc IERC1155Receiver
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @inheritdoc IERC1155Receiver
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function _isValidSigner(
        address signer
    ) internal view virtual returns (bool) {
        return signer == owner();
    }
}
