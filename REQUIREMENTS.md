# Yohaku プロジェクト要件定義書

## 1. プロジェクト概要

### 1.1 プロジェクト名
Yohaku - ブロックチェーンベースコミュニティ貢献追跡システム

### 1.2 プロジェクトの目的
コミュニティメンバーの貢献を NFT とToken Bound Account（TBA）を活用して記録・追跡し、NFT間での貢献履歴の継承を可能にするシステムの構築

### 1.3 プロジェクトの理念
"[](yohaku) is a project aimed at improving communities and the connections among the people involved."

### 1.4 プロジェクトスコープ
- ブロックチェーン上でのコミュニティメンバーシップ管理
- 個別貢献活動のNFT化と証明システム
- Token Bound Accountによる貢献履歴継承メカニズム
- マルチチェーン対応デプロイメント

## 2. ステークホルダー

### 2.1 プライマリステークホルダー
- **コミュニティ管理者**: システムの管理・運営
- **コミュニティメンバー**: Yohaku NFT保有者
- **貢献者**: ContributionNFT受領者
- **開発者**: システムの構築・保守

### 2.2 セカンダリステークホルダー
- **ネットワーク運営者**: ブロックチェーンインフラ提供
- **監査者**: セキュリティ検証
- **将来のコントリビューター**: オープンソース貢献者

## 3. 機能要件

### 3.1 Yohaku NFT機能（メインNFT）

#### 3.1.1 NFT発行機能
**要件ID**: YHK-001  
**機能名**: Yohaku NFT ミント機能  
**説明**: 承認されたミンターがコミュニティメンバーにYohaku NFTを発行する

**詳細要件**:
- 関数: `safeMint(address to, string memory imageUrl)`
- アクセス制御: MINTER_ROLE必須
- 制約: 1アドレスにつき1つのNFTのみ発行可能
- エラーハンドリング: `CannnotHoldMoreThanOneYohakuNFT`エラー
- 戻り値: TokenData構造体

#### 3.1.2 メタデータ管理機能
**要件ID**: YHK-002  
**機能名**: NFTメタデータ管理  
**説明**: NFTの画像URL、説明文の設定・更新

**詳細要件**:
- デフォルト画像URL設定: `setDefaultImageUrl(string memory defaultImageUrl)`
- 個別画像URL設定: `setImageURL(uint256 tokenId, string memory imageUrl)`
- Base64エンコードされたオンチェーンメタデータ生成
- OpenSea対応のattributes形式

#### 3.1.3 所有者履歴追跡機能
**要件ID**: YHK-003  
**機能名**: 所有者履歴管理  
**説明**: NFTの過去・現在の所有者を記録・参照

**詳細要件**:
- 所有者履歴取得: `getOwners(uint256 tokenId)`
- 転送時の自動履歴更新: `_update`フック
- トークンデータ取得: `getTokenData(uint256 tokenId)`

#### 3.1.4 アップグレード機能
**要件ID**: YHK-004  
**機能名**: コントラクトアップグレード  
**説明**: OpenZeppelinのTransparent Proxyによるアップグレード

**詳細要件**:
- 初期化機能: `initialize(address initialOwner, string memory _description, string memory defaultImageUrl)`
- アップグレード安全性: `@custom:oz-upgrades-unsafe-allow constructor`
- V2機能: `revokeMinter(address minter)` (YohakuV2)

#### 3.1.5 アクセス制御機能
**要件ID**: YHK-005  
**機能名**: 権限管理システム  
**説明**: OpenZeppelinのAccessControlによる権限管理

**詳細要件**:
- DEFAULT_ADMIN_ROLE: 管理者権限
- MINTER_ROLE: NFT発行権限
- ロール付与・剥奪機能
- ロールベースアクセス制御

### 3.2 ContributionNFT機能（貢献NFT）

#### 3.2.1 貢献NFT発行機能
**要件ID**: CNT-001  
**機能名**: 貢献NFT単体ミント  
**説明**: 個別の貢献に対してNFTを発行し、EAS証明を自動作成

**詳細要件**:
- 関数: `safeMint(address to, address account, string memory description)`
- EAS証明自動作成: `_attest`内部関数
- Token Bound Accountへの証明送付
- 戻り値: 証明UID（bytes32）

#### 3.2.2 バッチミント機能
**要件ID**: CNT-002  
**機能名**: 貢献NFTバッチミント  
**説明**: 複数の貢献者に対して一括でNFTを発行

**詳細要件**:
- 関数: `batchMint(address[] memory to, address[] memory account, string memory description)`
- 配列長チェック機能
- 各NFTに対する個別EAS証明作成
- ガス効率化

#### 3.2.3 貢献スコア管理機能
**要件ID**: CNT-003  
**機能名**: 貢献スコアシステム  
**説明**: 各ContributionNFTコントラクトごとの基本ポイント管理

**詳細要件**:
- ベースポイント設定: コンストラクタパラメータ
- ポイント更新: `updatePoints(uint8 newPoints)`
- ポイント取得: `getPoints()`
- EAS証明へのスコア埋め込み

#### 3.2.4 制約機能
**要件ID**: CNT-004  
**機能名**: NFT保有制限  
**説明**: 1アドレスにつき1つのContributionNFTのみ保持可能

**詳細要件**:
- 発行前残高チェック
- エラーハンドリング: `CannotHoldMoreThanOneToken`
- バッチミント時の重複チェック

### 3.3 NFTFactory機能（ファクトリー）

#### 3.3.1 ContributionNFT動的作成機能
**要件ID**: FCT-001  
**機能名**: ERC721コントラクト作成  
**説明**: 新しいContributionNFTコントラクトを動的に生成

**詳細要件**:
- 関数: `createERC721(string calldata name, string calldata symbol, uint8 _basePoints, string memory _defaultImageUrl, address initialMinter)`
- EAS統合の自動設定
- AttesterResolverへの自動登録
- 作成履歴の管理

#### 3.3.2 EAS統合自動化機能
**要件ID**: FCT-002  
**機能名**: EAS統合設定  
**説明**: EASスキーマ登録とAttesterResolverの自動設定

**詳細要件**:
- スキーマ自動登録
- AttesterResolver自動デプロイ
- 初期Attester設定
- スキーマUID管理

#### 3.3.3 作成履歴管理機能
**要件ID**: FCT-003  
**機能名**: 作成済みコントラクト管理  
**説明**: 作成されたContributionNFTコントラクトの追跡

**詳細要件**:
- 作成履歴配列: `erc721s`
- 履歴取得: `getCreatedERC721s()`
- イベント発行: `NFTCreated`

### 3.4 Token Bound Account（TBA）機能

#### 3.4.1 アカウント作成機能
**要件ID**: TBA-001  
**機能名**: TBAアカウント作成  
**説明**: NFTに紐づくスマートコントラクトアカウントの作成

**詳細要件**:
- Registry: `createAccount(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId)`
- ERC6551標準準拠
- チェーンID検証
- 決定論的アドレス生成

#### 3.4.2 トランザクション実行機能
**要件ID**: TBA-002  
**機能名**: 代理実行機能  
**説明**: NFT所有者によるトランザクション実行

**詳細要件**:
- 関数: `execute(address to, uint256 value, bytes calldata data, uint8 operation)`
- 所有者検証: `_isValidSigner`
- 状態管理: `state`カウンター
- CALLオペレーションのみサポート

#### 3.4.3 署名検証機能
**要件ID**: TBA-003  
**機能名**: ERC1271署名検証  
**説明**: オフチェーン署名の検証機能

**詳細要件**:
- 関数: `isValidSignature(bytes32 hash, bytes memory signature)`
- ERC1271標準準拠
- NFT所有者による署名のみ有効
- SignatureCheckerライブラリ使用

#### 3.4.4 トークン受信機能
**要件ID**: TBA-004  
**機能名**: マルチトークン対応  
**説明**: ERC721・ERC1155トークンの受信機能

**詳細要件**:
- ERC721Receiver実装
- ERC1155Receiver実装
- 適切なセレクター返却
- バッチ受信対応

### 3.5 Ethereum Attestation Service（EAS）統合機能

#### 3.5.1 証明作成機能
**要件ID**: EAS-001  
**機能名**: 貢献証明作成  
**説明**: ContributionNFT発行時の自動証明作成

**詳細要件**:
- スキーマ: "address TokenBoundAccount,address CurrentOwner,address TokenAddress,uint256 tokenId,uint8 Score,string Description"
- Token Bound Accountへの証明送付
- 改ざん防止機能
- 証明UID返却

#### 3.5.2 AttesterResolver機能
**要件ID**: EAS-002  
**機能名**: アテスター権限管理  
**説明**: 証明作成権限の管理と検証

**詳細要件**:
- アテスター追加: `addAttester(address newAttester)`
- 証明時権限検証: `onAttest`
- 取り消し許可: `onRevoke`
- MINTER_ROLEベース制御

### 3.6 デプロイメント・設定機能

#### 3.6.1 マルチチェーンデプロイ機能
**要件ID**: DPL-001  
**機能名**: 複数ネットワーク対応  
**説明**: 異なるブロックチェーンネットワークへのデプロイ

**詳細要件**:
- 対応ネットワーク: Polygon, Optimism, Sepolia, Mumbai
- チェーン固有EAS設定
- 自動設定スクリプト
- Etherscan検証

#### 3.6.2 環境設定機能
**要件ID**: DPL-002  
**機能名**: 設定管理システム  
**説明**: デプロイメント環境の設定管理

**詳細要件**:
- 環境変数管理
- RPC URL設定
- プライベートキー管理
- API キー設定

## 4. 非機能要件

### 4.1 性能要件

#### 4.1.1 ガス効率性
- オプティマイザー有効化（runs: 1）
- バッチ処理によるガス節約
- 効率的なストレージレイアウト

#### 4.1.2 スケーラビリティ
- マルチチェーン対応
- レイヤー2ソリューション対応
- ファクトリーパターンによる動的拡張

### 4.2 セキュリティ要件

#### 4.2.1 アクセス制御
- OpenZeppelinのAccessControl使用
- ロールベースアクセス制御（RBAC）
- 最小権限の原則

#### 4.2.2 アップグレード安全性
- OpenZeppelinのTransparent Proxy
- 初期化機能の保護
- ストレージレイアウト互換性

#### 4.2.3 外部依存関係
- 監査済みライブラリの使用
- EAS統合によるデータ整合性
- チェーンID検証

### 4.3 可用性要件

#### 4.3.1 コントラクト可用性
- アップグレード可能設計
- 継続的なサービス提供
- 障害時の復旧機能

#### 4.3.2 データ可用性
- オンチェーンメタデータ
- 分散型ストレージ（IPFS）
- 履歴データの永続化

### 4.4 互換性要件

#### 4.4.1 標準準拠
- ERC721標準準拠
- ERC6551標準準拠（TBA）
- ERC1271標準準拠（署名検証）
- EAS標準準拠

#### 4.4.2 インターフェース互換性
- OpenSea互換メタデータ
- ウォレット互換性
- DApps統合対応

## 5. 制約条件

### 5.1 技術制約

#### 5.1.1 ブロックチェーン制約
- ガス制限による実行制約
- ブロック時間による遅延
- チェーン固有の制限

#### 5.1.2 スマートコントラクト制約
- コード不変性（アップグレードを除く）
- ストレージ制限
- 計算資源制限

### 5.2 ビジネス制約

#### 5.2.1 NFT発行制約
- 1アドレス1NFT制限（Yohaku・ContributionNFT）
- 権限者のみ発行可能
- 取り消し不可性

#### 5.2.2 運用制約
- 管理者権限の集中化
- ガスコストの負担
- ネットワーク依存性

### 5.3 コンプライアンス制約

#### 5.3.1 法的制約
- 各国の暗号資産規制遵守
- データ保護規制対応
- 知的財産権保護

## 6. ユースケース

### 6.1 主要ユースケース

#### 6.1.1 コミュニティ参加
**アクター**: 新規メンバー、管理者  
**フロー**:
1. 管理者がYohaku NFTを新規メンバーにミント
2. 新規メンバーがToken Bound Accountを作成
3. アカウントアクティベーション完了

#### 6.1.2 貢献記録
**アクター**: 貢献者、管理者  
**フロー**:
1. 管理者がContributionNFTコントラクトを作成
2. 貢献者の活動を評価
3. ContributionNFTをミント
4. EAS証明を自動作成
5. Token Bound Accountに証明記録

#### 6.1.3 NFT継承
**アクター**: 現在の所有者、新しい所有者  
**フロー**:
1. Yohaku NFTの転送実行
2. Token Bound Accountの制御権移行
3. 累積貢献履歴の継承
4. 新しい所有者による履歴確認

### 6.2 管理ユースケース

#### 6.2.1 システム管理
**アクター**: システム管理者  
**フロー**:
1. 新しいContributionNFTタイプの追加
2. 権限管理とロール設定
3. 設定値の更新とメンテナンス

#### 6.2.2 アップグレード
**アクター**: システム管理者  
**フロー**:
1. 新機能の実装完了
2. アップグレード実行
3. 既存データの互換性確認
4. 新機能の有効化

## 7. データモデル

### 7.1 Yohaku NFT データ構造

```solidity
struct TokenData {
    address owner;        // 現在の所有者
    string description;   // NFTの説明
    string imageUrl;      // 画像URL
}
```

### 7.2 EAS証明スキーマ

```
address TokenBoundAccount    // 証明の送付先TBA
address CurrentOwner         // 現在のNFT所有者
address TokenAddress         // ContributionNFTアドレス
uint256 tokenId             // トークンID
uint8 Score                 // 貢献スコア
string Description          // 貢献の説明
```

### 7.3 マッピング構造

- `mapping(uint256 => TokenData) _tokenData`: トークンデータ管理
- `mapping(uint256 => address[]) previousOwners`: 所有者履歴
- `mapping(address => uint256) userOwnedToken`: ユーザー所有トークン

## 8. インターフェース要件

### 8.1 外部システム連携

#### 8.1.1 Ethereum Attestation Service
- EAS コントラクトとの統合
- スキーマレジストリとの連携
- カスタムリゾルバーの実装

#### 8.1.2 IPFS統合
- メタデータの分散ストレージ
- 画像ファイルの保存
- コンテンツアドレッシング

### 8.2 ユーザーインターフェース

#### 8.2.1 ウォレット連携
- MetaMask対応
- WalletConnect対応
- ハードウェアウォレット対応

#### 8.2.2 Web3インターフェース
- Webアプリケーション連携
- モバイルアプリ対応
- API提供

## 9. テスト要件

### 9.1 単体テスト要件

#### 9.1.1 コントラクト別テスト
- Yohaku NFT機能テスト
- ContributionNFT機能テスト
- NFTFactory機能テスト
- TBA機能テスト
- EAS統合テスト

#### 9.1.2 エラーケーステスト
- 不正アクセステスト
- 制約違反テスト
- リバート条件テスト

### 9.2 統合テスト要件

#### 9.2.1 フロー別統合テスト
- NFT発行から証明まで
- 継承プロセステスト
- アップグレードテスト

#### 9.2.2 マルチチェーンテスト
- ネットワーク別デプロイテスト
- チェーン固有機能テスト
- 互換性テスト

### 9.3 カバレッジ要件

- **コード行カバレッジ**: 最低90%
- **分岐カバレッジ**: 最低85%
- **関数カバレッジ**: 100%

## 10. 運用要件

### 10.1 デプロイメント要件

#### 10.1.1 デプロイメント自動化
- Foundryスクリプトによる自動デプロイ
- 環境別設定管理
- コントラクト検証自動化

#### 10.1.2 設定管理
- 環境変数による設定外部化
- チェーン別設定ファイル
- デプロイメント履歴管理

### 10.2 監視・ログ要件

#### 10.2.1 イベント監視
- NFTミントイベント
- 証明作成イベント
- エラーイベント

#### 10.2.2 メトリクス収集
- ガス使用量監視
- トランザクション成功率
- システム利用統計

## 11. リスク・課題

### 11.1 技術リスク

#### 11.1.1 スマートコントラクトリスク
- コード脆弱性
- アップグレード失敗
- 外部依存関係の問題

#### 11.1.2 ブロックチェーンリスク
- ネットワーク混雑
- ガス価格変動
- チェーン固有問題

### 11.2 運用リスク

#### 11.2.1 管理権限リスク
- 管理者アカウント侵害
- 権限の不適切な使用
- 単一障害点

#### 11.2.2 互換性リスク
- アップグレード時の互換性
- 外部システム変更
- 標準仕様変更

## 12. 成功基準

### 12.1 機能的成功基準

- 全ての要件機能が正常動作
- テストカバレッジ目標達成
- セキュリティ監査クリア

### 12.2 非機能的成功基準

- ガス効率目標達成
- レスポンス時間要件満足
- 可用性目標達成

### 12.3 ビジネス成功基準

- コミュニティ採用率
- システム利用継続性
- エコシステム拡張性

---

**文書作成日**: 2024年  
**バージョン**: 1.0  
**承認者**: プロジェクトマネージャー  
**次回レビュー予定**: 四半期ごと 