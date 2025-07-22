# Yohaku System Overview

## 概要

Yohaku（余白）は、ブロックチェーン技術を活用したコミュニティ貢献追跡システムです。NFT（Non-Fungible Token）とToken Bound Account（TBA）を組み合わせることで、コミュニティメンバーの貢献を記録・追跡し、NFT間での貢献履歴の継承を可能にします。

**プロジェクトの理念**: "[](yohaku) is a project aimed at improving communities and the connections among the people involved."

## システムアーキテクチャ

### 核となるコンポーネント

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Yohaku NFT    │    │ ContributionNFT │    │   NFTFactory    │
│  (Community)    │    │  (Individual)   │    │   (Creator)     │
└─────┬───────────┘    └─────────────────┘    └─────────────────┘
      │                          │                        │
      │                          │                        │
      v                          v                        v
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Token Bound     │    │  Ethereum       │    │   Attester      │
│   Account       │◄───┤  Attestation    │◄───┤   Resolver      │
│   (TBA)         │    │   Service       │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 1. Yohaku NFT (`contracts/Yohaku.sol`)
- **目的**: コミュニティメンバーシップを表すメインNFT
- **特徴**:
  - アップグレード可能なERC721実装
  - 1アドレスにつき1つのNFTのみ保持可能
  - OpenZeppelinのAccessControlによる権限管理
  - 所有者履歴の追跡機能
  - Base64エンコードされたオンチェーンメタデータ

**主要機能**:
```solidity
function safeMint(address to, string memory imageUrl) external onlyRole(MINTER_ROLE)
function getOwners(uint256 tokenId) public view returns (address[] memory)
function setImageURL(uint256 tokenId, string memory imageUrl) external
```

### 2. ContributionNFT (`contracts/ContributionNFT.sol`)
- **目的**: 個別の貢献活動を表すNFT
- **特徴**:
  - ERC721実装
  - 1アドレスにつき1つのトークンのみ保持可能
  - 貢献スコア（basePoints）の管理
  - EASとの統合による自動証明
  - バッチミント機能

**主要機能**:
```solidity
function safeMint(address to, address account, string memory description) external
function batchMint(address[] memory to, address[] memory account, string memory description) external
function getPoints() public view returns (uint8)
```

### 3. NFTFactory (`contracts/NFTFactory.sol`)
- **目的**: ContributionNFTの動的生成
- **特徴**:
  - ファクトリーパターンによるNFT作成
  - EAS統合の自動設定
  - AttesterResolverの管理
  - スキーマ登録の自動化

### 4. Token Bound Account - TBA (`contracts/TBA/`)
- **目的**: NFTに紐づくスマートコントラクトアカウント
- **実装**: ERC6551標準準拠
- **特徴**:
  - NFT所有者による制御
  - 状態管理機能
  - ERC721/ERC1155受信対応
  - 署名検証機能（ERC1271）

**主要機能**:
```solidity
function execute(address to, uint256 value, bytes calldata data, uint8 operation) external payable
function isValidSigner(address signer, bytes calldata) external view returns (bytes4)
function owner() public view returns (address)
```

### 5. Ethereum Attestation Service統合 (`contracts/EAS/`)
- **目的**: 貢献の証明と検証
- **実装**: AttesterResolverによるカスタム制御
- **スキーマ**: 
  ```
  address TokenBoundAccount,
  address CurrentOwner,
  address TokenAddress,
  uint256 tokenId,
  uint8 Score,
  string Description
  ```

## 技術仕様

### 開発環境
- **Solidity**: 0.8.24
- **フレームワーク**: Foundry (primary) + Hardhat
- **依存関係**:
  - OpenZeppelin Contracts (Upgradeable)
  - ERC6551 Reference Implementation
  - Ethereum Attestation Service

### 対応ネットワーク
- **メインネット**: Polygon, Optimism
- **テストネット**: Polygon Mumbai, Sepolia
- **ローカル**: Hardhat Network

### セキュリティ機能
- **アクセス制御**: OpenZeppelinのAccessControl
- **アップグレード**: OpenZeppelinのTransparent Proxy
- **証明システム**: EASによる改ざん防止
- **署名検証**: ERC1271準拠

## 主要な制約と設計原則

### 制約
1. **単一NFT原則**: 各アドレスは各コントラクトにつき1つのNFTのみ保持可能
2. **アクセス制御**: MINTER_ROLEによる厳格な発行権限管理
3. **チェーン固有**: TBAはチェーンIDを検証
4. **証明必須**: ContributionNFTの発行時にEAS証明が必須

### 設計原則
1. **アップグレード可能性**: 将来の機能拡張に対応
2. **マルチチェーン対応**: 異なるネットワークでのデプロイメント
3. **標準準拠**: ERC721, ERC6551, EAS標準の遵守
4. **ガス効率**: バッチ処理とオプティマイザーの活用

## 開発とデプロイメント

### セットアップ
```bash
# 依存関係のインストール
pnpm install

# 環境変数の設定
cp .env.example .env
# RPC URLs, API Keys, Private Keysを設定
```

### ビルドとテスト
```bash
# ビルド（フォーマット + クリーン + コンパイル）
pnpm build

# テスト実行
pnpm test:coverage          # カバレッジ分析
pnpm test:mumbai           # Mumbai testnet fork
pnpm test:polygon          # Polygon mainnet fork
pnpm test:op               # Optimism mainnet fork
```

### デプロイメント
```bash
# Polygon Mumbai
pnpm deploy:yohaku-mumbai
pnpm deploy:factory-mumbai

# Polygon Mainnet
pnpm deploy:yohaku-polygon
pnpm deploy:factory-polygon

# Ethereum Sepolia
pnpm deploy:yohaku-sepolia
pnpm deploy:factory-sepolia
```

### プロジェクト構造
```
yohaku-contract/
├── contracts/              # スマートコントラクト
│   ├── Yohaku.sol          # メインNFTコントラクト
│   ├── YohakuV2.sol        # アップグレード版
│   ├── ContributionNFT.sol # 貢献NFT
│   ├── NFTFactory.sol      # ファクトリー
│   ├── EAS/               # EAS統合
│   └── TBA/               # Token Bound Account
├── script/                # デプロイメントスクリプト
├── test/foundry/          # Foundryテスト
├── lib/                   # 外部ライブラリ
├── foundry.toml           # Foundry設定
└── package.json           # パッケージ設定
```

## 使用フロー

### 1. 初期セットアップ
1. YohakuコントラクトとNFTFactoryをデプロイ
2. EASスキーマを登録
3. 必要な権限を設定

### 2. コミュニティメンバーの参加
1. 管理者がYohaku NFTをユーザーにミント
2. ユーザーがToken Bound Accountを作成
3. アカウントが有効化される

### 3. 貢献の記録
1. 管理者がContributionNFTコントラクトを作成（NFTFactory経由）
2. 貢献者に対してContribution NFTをミント
3. 自動的にEAS証明が作成される
4. Token Bound Accountに証明が記録される

### 4. NFT継承
1. Yohaku NFTの譲渡により、Token Bound Accountの制御権が移る
2. 新しい所有者が累積された貢献履歴にアクセス可能
3. 貢献スコアと証明が継承される

## APIリファレンス

### Yohaku Contract
```solidity
// NFTのミント
function safeMint(address to, string memory imageUrl) external returns (TokenData memory)

// トークンデータの取得
function getTokenData(uint256 tokenId) public view returns (TokenData memory)

// 所有者履歴の取得
function getOwners(uint256 tokenId) public view returns (address[] memory)
```

### ContributionNFT Contract
```solidity
// 単体ミント（証明付き）
function safeMint(address to, address account, string memory description) external returns (bytes32)

// バッチミント
function batchMint(address[] memory to, address[] memory account, string memory description) external

// 貢献スコアの取得
function getPoints() public view returns (uint8)
```

### NFTFactory Contract
```solidity
// 新しいContributionNFTの作成
function createERC721(
    string calldata name,
    string calldata symbol,
    uint8 _basePoints,
    string memory _defaultImageUrl,
    address initialMinter
) public returns (ContributionNFT)
```

## 今後の展開

### アップグレード計画
- YohakuV2では`revokeMinter`機能を追加
- 将来的な機能拡張に対応する設計

### 拡張可能性
- 新しい貢献タイプの追加
- より複雑なスコアリングシステム
- クロスチェーン対応の強化
- ガバナンス機能の統合

## セキュリティ考慮事項

### 監査項目
- アクセス制御の適切性
- アップグレードプロセスの安全性
- EAS統合の検証
- TBA実装の標準準拠

### リスク管理
- 管理者権限の集中化リスク
- アップグレード時の互換性
- 外部依存関係の脆弱性
- チェーン固有の問題

---

このドキュメントはYohakuプロジェクトの包括的な概要を提供しています。詳細な実装については、各コントラクトのソースコードとテストファイルを参照してください。 