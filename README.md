
![](https://github.com/user-attachments/assets/e8fe7c3c-a8d8-4165-86a1-86b9f433f9b3)

<div align="center">

# daily-report-hub dev

<img src="https://img.shields.io/badge/GitHub%20Actions-CICD-blue?style=for-the-badge&logo=github-actions&logoColor=white" alt="GitHub Actions" />
<img src="https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash" />

</div>

---

## 📖 概要

このリポジトリは、**daily-report-hubの開発リポジトリ**です。ここで開発・保守されたスクリプトは、リモート実行される形でdaily-report-hub本体のワークフローで利用されます。

### 🎯 主な用途
- GitHub Actionsスクリプトの開発・テスト・保守
- 日報自動生成機能の実装と改善
- 集約用リポジトリとの同期機能の提供

### 🔄 運用方式
このリポジトリで開発されたスクリプトは、daily-report-hub本体のワークフローから**リモート実行**されます。以下のようなcurlコマンドでスクリプトを取得・実行します：

```bash
curl -LsSf https://raw.githubusercontent.com/Sunwood-ai-labsII/daily-report-hub_dev/main/.github/scripts/スクリプト名.sh | sh
```

---

## 🚩 このリポジトリの役割

### 🛠️ 開発・保守リポジトリとしての機能
- **スクリプト開発**: GitHub Actions用スクリプトの開発とテスト
- **機能改善**: 日報生成機能の継続的な改善とバグ修正
- **ドキュメント**: スクリプトの使い方と設定方法のドキュメント管理
- **バージョン管理**: スクリプトのバージョン管理と変更履歴の追跡

### 📦 提供されるスクリプト
- Gitのコミット履歴・差分から日報（Markdown形式）を自動生成
- 週単位・日単位でレポートを整理
- 別リポジトリ（daily-report-hub）へPRベースで自動同期
- プルリクエストの自動承認・自動マージ（設定可）
- Docusaurus用のディレクトリ・ナビゲーション構造も自動生成

---

## ⚙️ ワークフロー概要

### 🔄 自動化フロー図

```mermaid
graph TB
    A[開発者のコード<br/>commit/push] --> B[GitHub Actions<br/>ワークフロー]
    B --> C[レポート生成<br/>Markdown]
    C --> D[ファイル同期<br/>クローン]
    D --> E[PR作成・承認<br/>自動化可]
    E --> F[集約リポジトリ<br/>daily-report-hub]
```

### 📋 処理ステップ

1. **トリガー**: **GitHub Actions**がmainブランチへのpushやPRをトリガー
2. **データ収集**: `.github/scripts/`配下のシェルスクリプトで
   - 週情報の計算
   - Git活動の分析
   - Markdownレポートの生成
   - Docusaurus用ディレクトリ構造の作成
3. **同期処理**: 集約用リポジトリ（daily-report-hub）をクローンし、レポートをコピー
4. **PR処理**: PR作成・自動承認・自動マージ（設定に応じて自動化）

### ⚙️ 設定可能なオプション

| 設定 | 説明 | デフォルト値 |
|------|------|-------------|
| `WEEK_START_DAY` | 週の開始曜日（0=日曜日, 1=月曜日, ...） | `1`（月曜日） |
| `AUTO_APPROVE` | PR自動承認 | `true` |
| `AUTO_MERGE` | PR自動マージ | `true` |
| `CREATE_PR` | PR作成/直接プッシュ切り替え | `true` |

---

## 📝 主なスクリプト

- `.github/scripts/calculate-week-info.sh`  
  週情報（週番号・開始日・終了日など）を計算し環境変数に出力

- `.github/scripts/analyze-git-activity.sh`  
  Gitのコミット履歴・差分を分析し、生データファイルを生成

- `.github/scripts/generate-markdown-reports.sh`  
  生データから日報・統計・差分などのMarkdownレポートを自動生成

- `.github/scripts/create-docusaurus-structure.sh`  
  Docusaurus用のディレクトリ・_category_.jsonを自動生成

- `.github/scripts/sync-to-hub-gh.sh`  
  集約リポジトリへPR作成・自動承認・自動マージ（YUKIHIKO権限）

---

## 🚀 使い方（クイックスタート）

### 📝 開発者向けの使い方

1. このリポジトリをforkまたはclone
2. `.github/workflows/sync-to-report-gh.yml`の設定を必要に応じて編集
3. 必要なシークレットを設定（下記参照）
4. mainブランチにpushすると自動で日報生成＆集約リポジトリへ同期

### 🌐 daily-report-hubでの実際の運用例

このリポジトリで開発されたスクリプトは、daily-report-hub本体で以下のようにリモート実行されます：

```yaml
name: 📊 デイリーレポートハブ同期 v2.3 (YUKIHIKO PR版 - 完全リモート実行)
on:
  push:
    branches: [main, master]
  pull_request:
    types: [opened, synchronize, closed]

env:
  WEEK_START_DAY: 1
  AUTO_APPROVE: true
  AUTO_MERGE: true
  CREATE_PR: true
  # リモートスクリプトの設定
  SCRIPTS_BASE_URL: https://raw.githubusercontent.com/Sunwood-ai-labsII/daily-report-hub_dev/main/.github/scripts

jobs:
  sync-data:
    runs-on: ubuntu-latest
    steps:
      - name: 📥 現在のリポジトリをチェックアウト
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: 📅 週情報を計算
        run: curl -LsSf ${SCRIPTS_BASE_URL}/calculate-week-info.sh | sh -s -- ${{ env.WEEK_START_DAY }}

      - name: 🔍 Git活動を分析
        run: curl -LsSf ${SCRIPTS_BASE_URL}/analyze-git-activity.sh | sh

      - name: 📝 Markdownレポートを生成
        run: curl -LsSf ${SCRIPTS_BASE_URL}/generate-markdown-reports.sh | sh

      - name: 📂 レポートハブをクローン
        env:
          GITHUB_TOKEN: ${{ secrets.GH_PAT }}
          REPORT_HUB_REPO: ${{ vars.REPORT_HUB_REPO || 'Sunwood-ai-labsII/daily-report-hub' }}
        run: |
          git config --global user.name "GitHub Actions Bot"
          git config --global user.email "actions@github.com"
          git clone https://x-access-token:${GITHUB_TOKEN}@github.com/${REPORT_HUB_REPO}.git daily-report-hub

      - name: 🏗️ Docusaurus構造を作成
        run: curl -LsSf ${SCRIPTS_BASE_URL}/create-docusaurus-structure.sh | sh

      - name: 🚀 YUKIHIKO権限でPR作成＆自動承認
        env:
          GITHUB_TOKEN_ORIGINAL: ${{ secrets.GH_PAT }}      # 承認用
          YUKIHIKO_TOKEN: ${{ secrets.GH_PAT_YUKIHIKO }}     # PR作成用
          GITHUB_TOKEN: ${{ secrets.GH_PAT }}              # デフォルト
          REPORT_HUB_REPO: ${{ vars.REPORT_HUB_REPO || 'Sunwood-ai-labsII/daily-report-hub' }}
        run: curl -LsSf ${SCRIPTS_BASE_URL}/sync-to-hub-gh.sh | sh
```

### 🔑 環境変数・シークレット設定

以下の環境変数を設定する必要があります：

#### 必須シークレット
- `GH_PAT`: GitHub Personal Access Token（リポジトリアクセス用）
- `GH_PAT_YUKIHIKO`: YUKIHIKO権限用のToken（PR作成・承認用）

#### オプション環境変数（ワークフロー内で設定）
- `REPORT_HUB_REPO`: レポートハブリポジトリ（デフォルト: `Sunwood-ai-labsII/daily-report-hub`）
- `WEEK_START_DAY`: 週の開始曜日（0=日曜日, 1=月曜日, ..., 6=土曜日、デフォルト: 1）
- `AUTO_APPROVE`: PR自動承認（true/false、デフォルト: true）
- `AUTO_MERGE`: PR自動マージ（true/false、デフォルト: true）
- `CREATE_PR`: PR作成フラグ（true=PR作成, false=直接プッシュ、デフォルト: true）

#### 環境変数設定例
各環境変数の詳細な設定は、ワークフローファイル内のコメントを参照してください。

### 📋 シークレット設定手順

1. リポジトリの「Settings」→「Secrets and variables」→「Actions」に移動
2. 「New repository secret」をクリックして各シークレットを追加
3. 以下のシークレットを設定：
   - `GH_PAT`: `repo`スコープを持つPersonal Access Token
   - `GH_PAT_YUKIHIKO`: `repo`スコープを持つPersonal Access Token（YUKIHIKO権限用）

---

## 📁 ディレクトリ構成例

```
.
├── .github/
│   ├── scripts/
│   │   ├── calculate-week-info.sh
│   │   ├── analyze-git-activity.sh
│   │   ├── generate-markdown-reports.sh
│   │   ├── create-docusaurus-structure.sh
│   │   ├── sync-to-hub-gh.sh
│   │   └── sync-to-hub.sh
│   └── workflows/
│       └── sync-to-report-gh.yml
├── .SourceSageignore
├── README.md
```

---

## 🛠️ 設定・カスタマイズ

- `.github/workflows/sync-to-report-gh.yml`  
  - `WEEK_START_DAY`：週の開始曜日（0=日, 1=月, ...）
  - `AUTO_APPROVE`：PR自動承認
  - `AUTO_MERGE`：PR自動マージ
  - `CREATE_PR`：PR作成/直接push切替

- スクリプトの詳細は[.github/scripts/README.md](.github/scripts/README.md)参照

---

## 🔗 参考リンク

- [集約用日報ハブリポジトリ](https://github.com/Sunwood-ai-labs/daily-report-hub)
- [GitHub Actions公式ドキュメント](https://docs.github.com/ja/actions)
- [Docusaurus公式サイト](https://docusaurus.io/ja/)

---

© 2025 Sunwood-ai-labsII
