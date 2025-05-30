# Kabukura アーキテクチャ設計書

## 1. システム概要

Kabukuraは、J-Quants APIを利用して株式市場データを取得・分析するためのElixir/Phoenixベースのアプリケーションです。

## 2. システムアーキテクチャ

### 2.1 全体構成

```
lib/
├── kabukura/                 # コアロジック
│   ├── data_sources/        # データソース管理
│   │   └── jquants/        # J-Quants API実装
│   │       ├── auth.ex     # 認証処理
│   │       ├── client.ex   # APIクライアント
│   │       ├── http.ex     # HTTPリクエスト処理
│   │       ├── pagination.ex # ページネーション処理
│   │       └── models/     # データモデル
│   └── encryption.ex       # 認証情報の暗号化
└── kabukura_web/           # Webインターフェース
    ├── controllers/        # APIエンドポイント
    └── views/             # レスポンス形式
```

### 2.2 主要コンポーネント

#### 2.2.1 データソース管理 (`lib/kabukura/data_sources/`)
- J-Quants APIとの通信を担当
- 認証情報の管理
- データの取得とキャッシュ

##### 2.2.1.1 J-Quants認証 (`jquants/auth.ex`)
- トークンの取得、更新、管理
- 認証情報の暗号化/復号化との連携
- トークンの有効期限管理

##### 2.2.1.2 J-Quants HTTP処理 (`jquants/http.ex`)
- HTTPリクエストの処理
- エラーハンドリングとリトライ
- レート制限の考慮
- タイムアウト設定

##### 2.2.1.3 J-Quantsページネーション (`jquants/pagination.ex`)
- ページネーションパラメータの管理
- 全ページの取得を簡略化するヘルパー関数
- ストリーミング対応

##### 2.2.1.4 J-Quants APIクライアント (`jquants/client.ex`)
- エンドポイントごとのリクエスト処理
- レスポンスの変換
- エラーハンドリング

#### 2.2.2 Webインターフェース (`lib/kabukura_web/`)
- RESTful APIエンドポイント
- データの可視化
- ユーザー認証・認可

## 3. データフロー

1. J-Quants APIからデータを取得
2. データを変換・正規化
3. Web APIを通じて結果を提供

## 4. セキュリティ設計

- 認証情報の暗号化（`lib/kabukura/encryption.ex`）
- 環境変数による設定管理
- APIキーの安全な管理
- レート制限の実装

## 5. スケーラビリティ

- モジュール化された設計による機能の追加のしやすさ
- 新しいデータソースの追加が容易

## 6. 監視とロギング

- データ取得の成功/失敗のログ
- システムの健全性モニタリング
- エラー通知の実装

## 7. J-Quants API実装方針

### 7.1 認証フロー

1. **初期認証**
   - ユーザー名/パスワードでリフレッシュトークンを取得
   - リフレッシュトークンは暗号化して保存

2. **トークン更新**
   - リフレッシュトークンでアクセストークン（IDトークン）を取得
   - アクセストークンは有効期限を考慮して管理

3. **トークン管理**
   - トークンの有効期限をチェック
   - 必要に応じて自動更新
   - トークンのキャッシュ

### 7.2 HTTP処理設計

1. **リクエスト/レスポンス処理**
   - 標準化されたリクエスト/レスポンス処理
   - エラーハンドリングの統一
   - リトライロジックの実装

2. **レート制限対応**
   - リクエスト間隔の制御
   - バックオフ戦略の実装
   - レート制限超過時の処理

3. **エラーハンドリング**
   - 標準化されたエラー型
   - エラーメッセージの統一
   - エラーログの記録

### 7.3 ページネーション対応

1. **ページネーションラッパー**
   - ページネーションパラメータの管理
   - 全ページの取得を簡略化するヘルパー関数

2. **ストリーミング対応**
   - 大量データの効率的な取得
   - メモリ使用量の最適化

3. **ページネーション情報の保持**
   - 次ページのURLやトークンの管理
   - ページネーション状態の追跡 