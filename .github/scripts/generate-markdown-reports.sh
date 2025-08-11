#!/bin/bash

# Markdownレポートを生成するスクリプト（修正版）

set -e

# 各行に4スペースのインデントを追加する関数
add_indent() {
  sed 's/^/    /' "$1"
}

# ファイル変更のステータスアイコンを取得する関数
get_status_icon() {
  case $1 in
    A) echo "- 🆕 **Added:** \`$2\`" ;;
    M) echo "- ✏️ **Modified:** \`$2\`" ;;
    D) echo "- 🗑️ **Deleted:** \`$2\`" ;;
    R*) echo "- 🔄 **Renamed:** \`$2\`" ;;
    *) echo "- 📝 **$1:** \`$2\`" ;;
  esac
}

# コードブロック内容をサニタイズする関数
sanitize_code_block() {
  # バッククォート3つをエスケープ
  sed 's/```/`\`\`/g' "$1"
}

# コミット詳細をMarkdown形式で作成（差分付き）
{
  echo "# 📝 Daily Commits"
  echo ""
  if [ -s daily_commits_raw.txt ]; then
    while IFS='|' read -r hash subject author time; do
      echo "## ⏰ $time - \`$hash\`"
      echo "**$subject**"
      echo "*by $author*"
      echo ""
      
      # 各コミットの変更ファイル一覧を表示
      echo "### 📋 Changed Files"
      echo "\`\`\`bash"
      git show --name-status $hash 2>/dev/null | grep -E '^[AMDRC]' || echo "No file changes"
      echo "\`\`\`"
      echo ""
      
      # 各コミットの統計情報を表示
      echo "### 📊 Statistics"
      echo "\`\`\`bash"
      git show --stat $hash 2>/dev/null | tail -n +2 || echo "No statistics available"
      echo "\`\`\`"
      echo ""
      
      # 各コミットのコード差分を表示（最初の100行まで、サニタイズ済み）
      echo "### 💻 Code Changes"
      echo "\`\`\`diff"
      git show $hash --pretty=format:"" 2>/dev/null | head -100 | sed 's/```/`\`\`/g' || echo "No code changes available"
      echo "\`\`\`"
      echo ""
      echo "---"
      echo ""
    done < daily_commits_raw.txt
  else
    echo "*No commits found for today.*"
  fi
} > daily_commits.md

# 累積差分をMarkdown形式で作成
{
  echo "# 📋 Daily File Changes"
  echo ""
  if [ -s daily_cumulative_diff_raw.txt ]; then
    while read -r line; do
      if [ ! -z "$line" ]; then
        status=$(echo "$line" | cut -f1)
        file=$(echo "$line" | cut -f2)
        get_status_icon "$status" "$file"
      fi
    done < daily_cumulative_diff_raw.txt
  else
    echo "*No file changes today.*"
  fi
} > daily_cumulative_diff.md

# 統計をMarkdown形式で作成
{
  echo "# 📈 Daily Statistics"
  echo ""
  echo "\`\`\`diff"
  # バッククォートをエスケープして出力
  cat daily_diff_stats_raw.txt | sed 's/```/`\`\`/g'
  echo "\`\`\`"
} > daily_diff_stats.md

# コード差分をMarkdown形式で作成（サニタイズ済み）
{
  echo "# 💻 Daily Code Changes"
  echo ""
  echo "## Full Diff"
  echo ""
  echo "\`\`\`diff"
  # バッククォートをエスケープして出力
  cat daily_code_diff_raw.txt | sed 's/```/`\`\`/g'
  echo "\`\`\`"
} > daily_code_diff.md

# 最新差分をMarkdown形式で作成
{
  echo "# 🔄 Latest Changes (File List)"
  echo ""
  if [ -s latest_diff_raw.txt ]; then
    while read -r line; do
      if [ ! -z "$line" ]; then
        status=$(echo "$line" | cut -f1)
        file=$(echo "$line" | cut -f2)
        get_status_icon "$status" "$file"
      fi
    done < latest_diff_raw.txt
  else
    echo "*No recent changes.*"
  fi
} > latest_diff.md

# 最新コード差分をMarkdown形式で作成（修正版）
{
  echo "# 🔄 Latest Code Changes"
  echo ""
  echo "\`\`\`diff"
  # バッククォートをエスケープして出力
  cat latest_code_diff_raw.txt | sed 's/```/`\`\`/g'
  echo "\`\`\`"
} > latest_code_diff.md

# 詳細なアクティビティサマリーをMarkdown形式で作成
if [ -s daily_commits_raw.txt ]; then
  FIRST_COMMIT_TIME=$(head -1 daily_commits_raw.txt | cut -d'|' -f4)
  LAST_COMMIT_TIME=$(tail -1 daily_commits_raw.txt | cut -d'|' -f4)
  FILES_CHANGED=$(grep -c '^' daily_cumulative_diff_raw.txt 2>/dev/null || echo "0")
else
  FIRST_COMMIT_TIME="N/A"
  LAST_COMMIT_TIME="N/A" 
  FILES_CHANGED=0
fi

# メインサマリーファイルを作成
{
  echo "# 📅 Daily Activity Report"
  echo ""
  echo "## 📊 Summary"
  echo "| Item | Value |"
  echo "|------|-------|"
  echo "| Repository | \`$GITHUB_REPOSITORY\` |"
  echo "| Date | $DATE |"
  echo "| Total Commits | **$(wc -l < daily_commits_raw.txt)** |"
  echo "| Files Changed | **$FILES_CHANGED** |"
  echo "| First Activity | $FIRST_COMMIT_TIME |"
  echo "| Last Activity | $LAST_COMMIT_TIME |"
  echo "| Sync Time | $(date '+%H:%M:%S') |"
  echo ""
  
  if [ -s daily_commits_raw.txt ]; then
    echo "## 📝 Commit Details"
    echo ""
    while IFS='|' read -r hash subject author time; do
      echo "### ⏰ $time - \`$hash\`"
      echo "**$subject**"
      echo "*by $author*"
      echo ""
    done < daily_commits_raw.txt
    
    echo "## 📈 File Changes Statistics"
    echo ""
    echo "\`\`\`diff"
    # バッククォートをエスケープして出力
    cat daily_diff_stats_raw.txt | sed 's/```/`\`\`/g'
    echo "\`\`\`"
    echo ""
    
    echo "## 📋 Changed Files List"
    echo ""
    while read -r line; do
      if [ ! -z "$line" ]; then
        status=$(echo "$line" | cut -f1)
        file=$(echo "$line" | cut -f2)
        get_status_icon "$status" "$file"
      fi
    done < daily_cumulative_diff_raw.txt
    echo ""
    
  else
    echo "## 📝 Commit Details"
    echo ""
    echo "*No commits found for today.*"
    echo ""
  fi
  
  echo "---"
  echo "*Generated by GitHub Actions at $(date '+%Y-%m-%d %H:%M:%S')*"
} > daily_summary.md

echo "✅ Markdown reports generated successfully!"
