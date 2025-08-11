#!/bin/bash

# YUKIHIKOアカウントでPR作成＆自動承認するスクリプト

set -e

# 必要な環境変数をチェック
: ${GITHUB_TOKEN:?}
: ${YUKIHIKO_TOKEN:?}  # YUKIHIKOのトークン
: ${REPORT_HUB_REPO:?}
: ${TARGET_DIR:?}
: ${REPO_NAME:?}
: ${DATE:?}
: ${WEEK_NUMBER:?}

echo "🔥 YUKIHIKOアカウントでPR作成モード開始！"

# ファイルコピー処理
cp README.md "$TARGET_DIR/" 2>/dev/null || echo "# $REPO_NAME" > "$TARGET_DIR/README.md"
cp daily_commits.md "$TARGET_DIR/"
cp daily_cumulative_diff.md "$TARGET_DIR/"
cp daily_diff_stats.md "$TARGET_DIR/"
cp daily_code_diff.md "$TARGET_DIR/"
cp latest_diff.md "$TARGET_DIR/"
cp latest_code_diff.md "$TARGET_DIR/"
cp daily_summary.md "$TARGET_DIR/"

# メタデータ作成
COMMIT_COUNT=$(wc -l < daily_commits_raw.txt)
FILES_CHANGED=$(grep -c '^' daily_cumulative_diff_raw.txt 2>/dev/null || echo "0")

cat > "$TARGET_DIR/metadata.json" << EOF
{
  "repository": "$GITHUB_REPOSITORY",
  "date": "$DATE",
  "week_folder": "$WEEK_FOLDER",
  "week_number": $WEEK_NUMBER,
  "week_start_date": "$WEEK_START_DATE",
  "week_end_date": "$WEEK_END_DATE",
  "branch": "$GITHUB_REF_NAME",
  "latest_commit_sha": "$GITHUB_SHA",
  "sync_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "workflow_run": "$GITHUB_RUN_ID",
  "daily_commit_count": $COMMIT_COUNT,
  "daily_files_changed": $FILES_CHANGED,
  "has_activity": $([ $COMMIT_COUNT -gt 0 ] && echo "true" || echo "false"),
  "pr_creator": "yukihiko",
  "auto_approved": true,
  "files": {
    "readme": "README.md",
    "summary": "daily_summary.md",
    "commits": "daily_commits.md",
    "file_changes": "daily_cumulative_diff.md",
    "stats": "daily_diff_stats.md",
    "code_diff": "daily_code_diff.md",
    "latest_diff": "latest_diff.md",
    "latest_code_diff": "latest_code_diff.md"
  }
}
EOF

cd daily-report-hub

# 最新のmainブランチを取得
git fetch origin main
git checkout main
git pull origin main

# 変更をステージング
git add .

if git diff --staged --quiet; then
  echo "📝 変更がありません"
  exit 0
fi

COMMIT_MESSAGE="📊 週次同期: $REPO_NAME ($DATE) - 第${WEEK_NUMBER}週 - ${COMMIT_COUNT}件のコミット"
BRANCH_NAME="sync/$REPO_NAME-$DATE"

# 既存ブランチとPRをクリーンアップ
git branch -D "$BRANCH_NAME" 2>/dev/null || true
git push origin --delete "$BRANCH_NAME" 2>/dev/null || true

# 🔥 重要：YUKIHIKOアカウントでコミット作成
echo "👤 YUKIHIKOアカウントでコミット作成中..."
git config user.name "Yukihiko Kondo"
git config user.email "yukihiko.fuyuki@example.com"

# ブランチ作成・コミット・プッシュ（YUKIHIKOトークンで）
git checkout -b "$BRANCH_NAME"
git commit -m "$COMMIT_MESSAGE"

# YUKIHIKOのトークンでプッシュ
git remote set-url origin https://x-access-token:${YUKIHIKO_TOKEN}@github.com/${REPORT_HUB_REPO}.git
git push origin "$BRANCH_NAME"

# 日本語PR作成（YUKIHIKOトークンで）
PR_BODY="## 📊 デイリーレポート同期

**リポジトリ:** \`$GITHUB_REPOSITORY\`  
**日付:** $DATE  
**週:** 第${WEEK_NUMBER}週 ($WEEK_START_DATE ～ $WEEK_END_DATE)

### 📈 アクティビティサマリー
- **コミット数:** ${COMMIT_COUNT}件
- **変更ファイル数:** ${FILES_CHANGED}件  
- **同期時刻:** $(date '+%Y年%m月%d日 %H:%M:%S')

### 📋 生成されたファイル
- 📄 日次サマリーレポート
- 📝 コミット詳細  
- 📁 ファイル変更一覧
- 💻 コード差分
- 📊 統計情報

### 🤖 自動化情報
- **PR作成者:** YUKIHIKO (自動承認可能)
- **データ作成者:** GitHub Actions
- **承認者:** 手動 or 自動

---
*GitHub Actions により自動生成（YUKIHIKO権限）*"

echo "📝 YUKIHIKOアカウントでPR作成中..."

# YUKIHIKOトークンでPR作成
export GITHUB_TOKEN="$YUKIHIKO_TOKEN"
PR_URL=$(gh pr create \
  --title "$COMMIT_MESSAGE" \
  --body "$PR_BODY" \
  --base main \
  --head "$BRANCH_NAME" \
  --repo "$REPORT_HUB_REPO" 2>/dev/null || echo "")

if [ -n "$PR_URL" ]; then
  echo "✅ YUKIHIKOアカウントでPR作成完了: $PR_URL"
  
  PR_NUMBER=$(gh pr view "$PR_URL" --repo "$REPORT_HUB_REPO" --json number --jq '.number')
  
  # # CI完了待機
  # echo "⏳ CI完了を待機中..."
  # max_wait=300
  # wait_time=0
  # while [ $wait_time -lt $max_wait ]; do
  #   CHECK_STATUS=$(gh pr view "$PR_NUMBER" --repo "$REPORT_HUB_REPO" --json statusCheckRollup --jq '.statusCheckRollup[-1].state' 2>/dev/null || echo "PENDING")
    
  #   if [ "$CHECK_STATUS" = "SUCCESS" ]; then
  #     echo "✅ CI完了！"
  #     break
  #   elif [ "$CHECK_STATUS" = "FAILURE" ]; then
  #     echo "❌ CI失敗"
  #     exit 1
  #   else
  #     echo "⏳ CI実行中... (${wait_time}秒)"
  #     sleep 10
  #     wait_time=$((wait_time + 10))
  #   fi
  # done
  
  # 🔥 ここがポイント：元のトークンで承認
  echo "👍 元のアカウントで承認実行中..."
  export GITHUB_TOKEN="$GITHUB_TOKEN_ORIGINAL"  # 元のトークンに戻す
  
  if gh pr review "$PR_NUMBER" --approve --body "✅ 自動承認：データ同期完了" --repo "$REPORT_HUB_REPO" 2>/dev/null; then
    echo "✅ 承認完了！"
    
    # 自動マージ実行
    echo "🔀 自動マージ実行中..."
    sleep 3
    
    if gh pr merge "$PR_NUMBER" --squash --delete-branch --repo "$REPORT_HUB_REPO" 2>/dev/null; then
      echo "🎉 完全自動化成功！PRがマージされました！"
    else
      echo "⚠️ マージ失敗。手動マージが必要: $PR_URL"
    fi
  else
    echo "⚠️ 承認失敗。手動承認が必要: $PR_URL"
  fi
else
  echo "❌ PR作成失敗"
  exit 1
fi
