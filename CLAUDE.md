# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Yohaku is a blockchain-based project for community contribution tracking using NFTs and Token Bound Accounts (TBA). The project uses Ethereum Attestation Service (EAS) for contribution attestations and ERC6551 for token-bound accounts that enable NFT inheritance between users.

## Architecture

### Core Contracts Structure
- **`/contracts`**: Main smart contract implementations
  - `Yohaku.sol`: Upgradeable ERC721 NFT contract for main community tokens (one per user)
  - `YohakuV2.sol`: Updated version of the Yohaku contract
  - `ContributionNFT.sol`: ERC721 tokens representing individual contributions
  - `NFTFactory.sol`: Factory contract for creating new Contribution NFTs
  - `/EAS/AttesterResolver.sol`: Custom resolver for Ethereum Attestation Service
  - `/TBA/`: Token Bound Account implementation (ERC6551)

### Key Dependencies
- **OpenZeppelin Contracts (Upgradeable)**: For secure, upgradeable smart contracts
- **Ethereum Attestation Service (EAS)**: For contribution attestations at `/lib/eas-contracts`
- **ERC6551**: Token bound account implementation at `/lib/erc6551`
- **Foundry**: Primary development framework for Solidity

## Development Commands

### Build & Testing
```bash
# Build contracts
pnpm build               # Formats, cleans, and compiles contracts
forge compile            # Compile only

# Testing  
pnpm test:coverage       # Run coverage analysis
pnpm test:mumbai         # Test on Polygon Mumbai testnet fork
pnpm test:polygon        # Test on Polygon mainnet fork  
pnpm test:op             # Test on Optimism mainnet fork

# Formatting & Cleanup
forge fmt                # Format Solidity code
forge clean              # Clean build artifacts
```

### Deployment Scripts
All deployment scripts are in `/script/` and follow the pattern `pnpm deploy:[contract]-[network]`:

- `pnpm deploy:yohaku-mumbai` / `pnpm deploy:yohaku-polygon` / `pnpm deploy:yohaku-sepolia`
- `pnpm deploy:factory-mumbai` / `pnpm deploy:factory-polygon` / `pnpm deploy:factory-sepolia`

### Configuration Files
- **`foundry.toml`**: Foundry configuration with Solidity 0.8.24, src='contracts', test='test/foundry'
- **`remappings.txt`**: Import path mappings for dependencies
- **`hardhat.config.ts`**: Hardhat configuration for additional tooling
- **`.env`**: Environment variables for RPC URLs and private keys (not committed)

## Key Features

1. **Upgradeable NFTs**: Yohaku contract uses OpenZeppelin's upgradeable pattern
2. **Single Token Constraint**: Each address can hold only one Yohaku NFT
3. **Contribution Tracking**: ContributionNFT represents individual contributions 
4. **Token Inheritance**: TBA enables transferring accumulated contributions between users
5. **Multi-chain Support**: Deployments on Polygon, Optimism, Sepolia testnets

## Testing Strategy

Tests use Foundry and fork testing against live networks. Set up environment variables before running network-specific tests:
```bash
source .env && pnpm test:op
```

## Important Notes

- Always run `forge fmt` before commits
- Environment variables required for deployment and testing
- Uses pnpm for package management
- Multi-network deployment support with verification on Etherscan variants