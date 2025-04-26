# ジョブキューシステム設計書

## 1. 概要

Kabukuraのジョブキューシステムは、J-Quants APIを利用した定期的な株価データの取得を管理するためのシステムです。
Obanを基盤として、信頼性が高く、スケーラブルなデータ取得システムを実現します。

## 2. システムアーキテクチャ

### 2.1 全体構成

```
lib/
├── kabukura/
│   ├── jobs/                # ジョブ管理
│   │   ├── daily_quotes_job.ex    # 日次株価取得ジョブ
│   │   ├── company_info_job.ex    # 企業情報更新ジョブ
│   │   └── market_info_job.ex     # 市場情報更新ジョブ
│   ├── data_sources/       # データソース管理
│   │   └── jquants/       # J-Quants API実装
│   │       ├── auth.ex     # 認証処理
│   │       ├── http.ex     # HTTPリクエスト処理
│   │       ├── token_store.ex # トークン管理
│   │       └── fetcher.ex  # データ取得処理
│   ├── models/            # データモデル
│   │   ├── company.ex     # 企業情報モデル
│   │   ├── stock_price.ex # 株価データモデル
│   │   └── financial_info.ex # 財務情報モデル
│   └── monitoring/         # モニタリング
│       ├── metrics.ex      # メトリクス収集
│       └── alerts.ex       # アラート管理
```

### 2.2 主要コンポーネント

#### 2.2.1 ジョブ管理
- Obanを利用したジョブ管理
- 定期的なジョブのスケジューリング
- ジョブの状態管理とリトライ処理

##### 2.2.1.1 日次株価取得ジョブ
- 毎日15:30に実行
- 全銘柄の株価データを取得
- データベースへの保存と更新

##### 2.2.1.2 企業情報更新ジョブ
- 毎日9:00に実行
- 上場企業情報の更新
- 企業情報の新規登録

##### 2.2.1.3 市場情報更新ジョブ
- 毎日9:00に実行
- 市場区分情報の更新
- 業種情報の更新

#### 2.2.2 データモデル

##### 2.2.2.1 企業情報モデル
```elixir
schema "companies" do
  field :code, :string                    # 証券コード
  field :name, :string                    # 企業名
  field :sector33_code, :string          # 33業種コード
  field :sector17_code, :string          # 17業種コード
  field :market_code, :string            # 市場区分コード
  field :is_listed, :boolean             # 上場状態
  field :last_updated_at, :utc_datetime  # 最終更新日時

  timestamps()
end
```

##### 2.2.2.2 株価データモデル
```elixir
schema "stock_prices" do
  field :code, :string                    # 証券コード
  field :date, :date                      # 日付
  field :open, :decimal                   # 始値
  field :high, :decimal                   # 高値
  field :low, :decimal                    # 安値
  field :close, :decimal                  # 終値
  field :volume, :integer                 # 出来高
  field :adjustment_factor, :decimal      # 調整係数
  field :is_adjusted, :boolean            # 調整済みフラグ

  timestamps()
end
```

##### 2.2.2.3 財務情報モデル
```elixir
schema "financial_infos" do
  field :code, :string                    # 証券コード
  field :date, :date                      # 決算日
  field :fiscal_year, :string             # 決算期
  field :quarter, :integer                # 四半期
  field :revenue, :decimal                # 売上高
  field :operating_profit, :decimal       # 営業利益
  field :ordinary_profit, :decimal        # 経常利益
  field :profit, :decimal                 # 純利益
  field :eps, :decimal                    # 1株当たり利益
  field :diluted_eps, :decimal            # 希薄化後1株当たり利益
  field :bps, :decimal                    # 1株当たり純資産
  field :roe, :decimal                    # 自己資本利益率
  field :roa, :decimal                    # 総資産利益率

  timestamps()
end
```

## 3. ジョブの実行フロー

### 3.1 定期的なジョブ
```
1. スケジューラーによるジョブ登録
   └── Obanジョブ
       ├── ジョブパラメータ設定
       ├── 実行スケジュール設定
       └── 優先順位設定

2. ジョブ実行
   └── ワーカープロセス
       ├── トークン管理
       ├── APIリクエスト
       └── レート制限管理

3. データ保存
   └── データベース処理
       ├── バリデーション
       ├── データ変換
       └── データ保存
```

### 3.2 オンデマンドジョブ
```
1. APIリクエスト受付
   └── ジョブ登録
       ├── パラメータ検証
       ├── ジョブ優先順位設定
       └── ジョブ登録

2. ジョブ実行
   └── データ取得処理
       ├── APIリクエスト
       ├── データ変換
       └── データ保存

3. レスポンス返却
   └── 結果通知
       ├── 成功/失敗通知
       ├── エラー情報
       └── 取得データ
```

## 4. エラーハンドリング

### 4.1 リトライポリシー
- 最大リトライ回数: 3回
- バックオフ戦略: 指数バックオフ
- リトライ間隔: 1分、5分、15分

### 4.2 エラー通知
- エラーログの記録
- Slack/メール通知
- エラー統計の収集

## 5. モニタリング

### 5.1 メトリクス
- ジョブ実行時間
- 成功/失敗率
- データ取得件数
- リソース使用率

### 5.2 アラート
- エラー率閾値超過
- ジョブ遅延
- リソース使用率閾値超過
- データ品質異常

## 6. 運用管理

### 6.1 定期メンテナンス
- 古いデータのアーカイブ
- インデックスの最適化
- 統計情報の更新

### 6.2 バックアップ/リストア
- データベースのバックアップ
- ジョブ履歴のバックアップ
- リストア手順

### 6.3 トラブルシューティング
- エラーコード一覧
- 一般的な問題と解決策
- サポート連絡先 