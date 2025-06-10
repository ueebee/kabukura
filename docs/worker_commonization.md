# ワーカーの共通化方針

## 概要

JQuantsデータソースのワーカー（`ListedInfoWorker`、`DailyQuotesWorker`など）には共通する処理が多く存在します。これらの処理を共通化することで、コードの重複を減らし、メンテナンス性を向上させることができます。また、将来的に新しいデータ種別のワーカーを追加する際の実装コストも削減できます。

## 共通化対象の処理

### 1. ジョブのスケジューリングロジック ✅
- `create_cron_job`関数の基本構造
- cron式のパース
- 次の実行時間の計算
- ジョブの登録処理
- メタデータの基本構造の管理
- ログ出力の標準化

### 2. エラーハンドリングとリトライロジック ✅
- `perform`関数内でのエラーハンドリング
- 成功/失敗時のスケジューリング処理
- リトライロジック

### 3. メタデータの管理 ✅
- 共通のメタデータ構造（`is_one_time`、`cron_expression`など）
- メタデータのバリデーション

### 4. ロギング ✅
- ログ出力の標準化
- エラーログの形式統一
- 英語でのログメッセージ
- 構造化されたログデータ

### 5. パラメータのバリデーション ✅
- パラメータの検証ロジック
- 必須パラメータのチェック

### 6. テスト ❌
- ユニットテスト
  - `WorkerBehaviour`のテスト
  - `CronJobBuilder`のテスト
  - `JobLogger`のテスト
  - 各ワーカーのテスト
- 統合テスト
  - エンドツーエンドのテスト
  - エラーケースのテスト
  - スケジューリングのテスト

## 実装方針

### ディレクトリ構造
```
lib/kabukura/data_sources/jquants/workers/
├── common/
│   ├── cron_job_builder.ex
│   ├── worker_behaviour.ex
│   ├── cron_job_builder_behaviour.ex
│   └── job_logger.ex
├── listed_info_worker.ex
└── daily_quotes_worker.ex

test/kabukura/data_sources/jquants/workers/
├── common/
│   ├── cron_job_builder_test.exs
│   ├── worker_behaviour_test.exs
│   └── job_logger_test.exs
├── listed_info_worker_test.exs
└── daily_quotes_worker_test.exs
```

### 各モジュールの役割

#### WorkerBehaviour ✅
- 各ワーカーが実装すべき振る舞いを定義
  - パラメータの検証（`validate_params/1`）
  - データ取得処理（`fetch_data/1`）
  - オプションの変換処理（`normalize_opts/1`）
  - 結果処理（`handle_result/4`）
  - スケジューリング処理（`schedule_next_job/1`）
- コンパイル時の型チェックと実装漏れの検出
- 新しいワーカー追加時の指針提供

#### CronJobBuilder ✅
- cronジョブの作成とスケジューリングを担当
  - cronジョブの作成とスケジューリング
  - cron式のパースと検証
  - 次の実行時間の計算
  - ジョブの登録処理
  - メタデータの基本構造の管理
  - ログ出力の標準化

#### CronJobBuilderBehaviour ✅
- cronジョブの作成とスケジューリングの振る舞いを定義
  - `create_cron_job/4`: cronジョブの作成
  - `schedule_next_job/3`: 次のジョブのスケジューリング

#### JobLogger ✅
- 標準化されたログ出力機能を提供
  - ジョブ実行の開始/完了/エラーのログ
  - スケジューリングのログ
  - デバッグ情報のログ
  - 構造化されたログデータ
  - 英語でのログメッセージ

## 実装の詳細

### WorkerBehaviourの実装例
各ワーカーは`WorkerBehaviour`を実装し、以下のような処理を実装します：

```elixir
defmodule Kabukura.DataSources.JQuants.Workers.ListedInfoWorker do
  @behaviour WorkerBehaviour

  @impl true
  def validate_params(_args) do
    {:ok, %{}}
  end

  @impl true
  def fetch_data(_params) do
    # データ取得処理
  end

  @impl true
  def normalize_opts(opts) do
    # オプションの正規化
  end

  @impl true
  def handle_result(result, meta, attempt, max_attempts) do
    # 結果処理
  end

  @impl true
  def schedule_next_job(meta) do
    # スケジューリング処理
  end
end
```

## メリット

1. **コードの重複削減** ✅
   - 共通処理の集約により、コードの重複を減らすことができます
   - バグ修正や機能追加が一箇所で済むようになります

2. **メンテナンス性の向上** ✅
   - 共通処理の変更が容易になります
   - コードの一貫性が保たれます

3. **新規ワーカー追加の容易化** ✅
   - 共通処理を再利用することで、新規ワーカーの実装が容易になります
   - 実装の標準化が図れます

4. **エラーハンドリングの統一** ✅
   - エラーハンドリングの一貫性が保証されます
   - ログ出力の形式が統一されます

## 注意点

1. **柔軟性の確保** ✅
   - 共通化する際は、各ワーカーの特殊な要件に対応できる柔軟性を確保する必要があります
   - オーバーライド可能なポイントを適切に設けることが重要です

2. **パフォーマンスへの影響** ⚠️
   - 共通化による抽象化レイヤーの追加は、パフォーマンスに影響を与える可能性があります
   - 必要に応じてパフォーマンスの測定と最適化を行う必要があります

3. **テストの充実** ❌
   - 共通化された処理は、より多くの箇所で使用されるため、テストの重要性が増します
   - ユニットテストと統合テストの両方を充実させる必要があります

## 次のステップ

1. **テストの実装**
   - 各モジュールのユニットテストの作成
   - テストカバレッジの確保
   - エッジケースのテスト
   - モックとスタブの適切な使用

2. **パフォーマンスの検証**
   - 共通化による影響の測定
   - 必要に応じた最適化
   - ベンチマークテストの実施 