# GitHub Actions Scripts

このディレクトリには、Daily Report Hub同期ワークフローで使用されるスクリプトが含まれています。

## スクリプト一覧

### 1. `calculate-week-info.sh`
週情報を計算し、環境変数を設定します。

**使用方法:**
```bash
./calculate-week-info.sh [WEEK_START_DAY]
```

**パラメータ:**
- `WEEK_START_DAY`: 週の開始日 (0=日曜日, 1=月曜日, ..., 6=土曜日)

**出力環境変数:**
- `REPO_NAME`: リポジトリ名
- `DATE`: 現在の日付 (YYYY-MM-DD)
- `YEAR`: 現在の年
- `WEEK_FOLDER`: 週フォルダ名
- `WEEK_START_DATE`: 週の開始日
- `WEEK_END_DATE`: 週の終了日
- `WEEK_NUMBER`: 週番号

### 2. `analyze-git-activity.sh`
Gitの活動を分析し、生データファイルを生成します。

**生成ファイル:**
- `daily_commits_raw.txt`: その日のコミット一覧
- `daily_cumulative_diff_raw.txt`: その日の累積差分
- `daily_diff_stats_raw.txt`: その日の統計情報
- `daily_code_diff_raw.txt`: その日のコード差分
- `latest_diff_raw.txt`: 最新の差分
- `latest_code_diff_raw.txt`: 最新のコード差分

### 3. `generate-markdown-reports.sh`
生データからMarkdownレポートを生成します。

**生成ファイル:**
- `daily_commits.md`: コミット詳細レポート
- `daily_cumulative_diff.md`: ファイル変更レポート
- `daily_diff_stats.md`: 統計レポート
- `daily_code_diff.md`: コード差分レポート
- `latest_diff.md`: 最新変更レポート
- `latest_code_diff.md`: 最新コード差分レポート
- `daily_summary.md`: 日次サマリーレポート

### 4. `create-docusaurus-structure.sh`
Docusaurusの構造と`_category_.json`ファイルを作成します。

**必要な環境変数:**
- `REPO_NAME`, `DATE`, `YEAR`, `WEEK_FOLDER`, `WEEK_NUMBER`, `WEEK_START_DATE`, `WEEK_END_DATE`

**出力環境変数:**
- `TARGET_DIR`: ターゲットディレクトリのパス

### 5. `sync-to-hub.sh`
レポートハブにファイルを同期します。

**必要な環境変数:**
- `GITHUB_TOKEN`: GitHubアクセストークン
- `REPORT_HUB_REPO`: レポートハブのリポジトリ
- `TARGET_DIR`: ターゲットディレクトリ
- その他の週情報変数

## 週の開始日設定

ワークフローファイルの`env.WEEK_START_DAY`を変更することで、週の開始日を制御できます：

```yaml
env:
  WEEK_START_DAY: 1  # 0=日曜日, 1=月曜日, 2=火曜日, etc.
```

## プルリクエストフロー設定

v2.0では、プルリクエストベースのフローと自動承認機能が追加されました：

```yaml
env:
  WEEK_START_DAY: 1     # 週の開始日
  AUTO_APPROVE: true    # プルリクエストの自動承認
  AUTO_MERGE: true      # プルリクエストの自動マージ
  CREATE_PR: true       # プルリクエストを作成するか直接プッシュするか
```

### 設定オプション

| 設定 | 説明 | デフォルト |
|------|------|------------|
| `CREATE_PR` | `true`: プルリクエストを作成<br>`false`: 直接プッシュ | `true` |
| `AUTO_APPROVE` | `true`: プルリクエストを自動承認<br>`false`: 手動承認が必要 | `false` |
| `AUTO_MERGE` | `true`: 承認後に自動マージ<br>`false`: 手動マージが必要 | `false` |

### フロー例

1. **完全自動化**: `CREATE_PR=true`, `AUTO_APPROVE=true`, `AUTO_MERGE=true`
   - プルリクエスト作成 → 自動承認 → 自動マージ

2. **承認のみ手動**: `CREATE_PR=true`, `AUTO_APPROVE=false`, `AUTO_MERGE=true`
   - プルリクエスト作成 → 手動承認 → 自動マージ

3. **完全手動**: `CREATE_PR=true`, `AUTO_APPROVE=false`, `AUTO_MERGE=false`
   - プルリクエスト作成 → 手動承認 → 手動マージ

4. **直接プッシュ**: `CREATE_PR=false`
   - 従来通りの直接プッシュ（v1.4と同じ動作）

## ワークフローファイル

2つのバージョンが利用可能です：

- `sync-to-report.yml`: cURLベースの実装
- `sync-to-report-gh.yml`: GitHub CLI使用版（推奨）

## フォルダ構造

生成されるフォルダ構造：
```
docs/docs/activities/
├── _category_.json
└── 2025/
    ├── _category_.json
    └── week-06_2025-08-04_to_2025-08-10/
        ├── _category_.json
        └── 2025-08-05/
            ├── _category_.json
            └── your-repo/
                ├── _category_.json
                ├── daily_summary.md
                ├── daily_commits.md
                ├── daily_cumulative_diff.md
                ├── daily_diff_stats.md
                ├── daily_code_diff.md
                ├── latest_diff.md
                ├── latest_code_diff.md
                ├── README.md
                └── metadata.json
```