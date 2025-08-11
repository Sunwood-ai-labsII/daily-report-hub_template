#!/bin/bash

# Git活動を分析してMarkdownファイルを生成するスクリプト

set -e

DATE=${DATE:-$(date '+%Y-%m-%d')}

echo "🔍 Fetching all commits for $DATE..."

# その日の全コミット履歴を取得（時刻順）
git log --since="$DATE 00:00:00" --until="$DATE 23:59:59" \
  --pretty=format:"%h|%s|%an|%ad" --date=format:'%H:%M:%S' \
  --reverse > daily_commits_raw.txt

# コミット数をカウント
COMMIT_COUNT=$(wc -l < daily_commits_raw.txt)
echo "📊 Found $COMMIT_COUNT commits for today"

# その日の全ての差分を統合（安全な方法で）
if [ $COMMIT_COUNT -gt 0 ]; then
  FIRST_COMMIT_TODAY=$(git log --since="$DATE 00:00:00" --pretty=format:"%H" --reverse | head -1)
  LAST_COMMIT_TODAY=$(git log --since="$DATE 00:00:00" --pretty=format:"%H" | head -1)
  
  echo "First commit: $FIRST_COMMIT_TODAY"
  echo "Last commit: $LAST_COMMIT_TODAY"
  
  # 親コミットが存在するかチェック
  if git rev-parse --verify "$FIRST_COMMIT_TODAY^" >/dev/null 2>&1; then
    # 親コミットが存在する場合
    PARENT_OF_FIRST=$(git rev-parse $FIRST_COMMIT_TODAY^)
    git diff $PARENT_OF_FIRST..$LAST_COMMIT_TODAY --name-status > daily_cumulative_diff_raw.txt 2>/dev/null || echo "No diff available" > daily_cumulative_diff_raw.txt
    git diff $PARENT_OF_FIRST..$LAST_COMMIT_TODAY --stat > daily_diff_stats_raw.txt 2>/dev/null || echo "No stats available" > daily_diff_stats_raw.txt
    # コードの詳細差分を取得
    git diff $PARENT_OF_FIRST..$LAST_COMMIT_TODAY > daily_code_diff_raw.txt 2>/dev/null || echo "No code diff available" > daily_code_diff_raw.txt
  else
    # 初回コミットの場合（親が存在しない）
    echo "Initial commit detected - showing all files as new"
    git diff --name-status 4b825dc642cb6eb9a060e54bf8d69288fbee4904..$LAST_COMMIT_TODAY > daily_cumulative_diff_raw.txt 2>/dev/null || \
    git ls-tree --name-status $LAST_COMMIT_TODAY > daily_cumulative_diff_raw.txt 2>/dev/null || \
    echo "A\t(all files added in initial commit)" > daily_cumulative_diff_raw.txt
    
    git diff --stat 4b825dc642cb6eb9a060e54bf8d69288fbee4904..$LAST_COMMIT_TODAY > daily_diff_stats_raw.txt 2>/dev/null || \
    echo "Initial commit - all files added" > daily_diff_stats_raw.txt
    
    # 初回コミットのコード内容
    git show $LAST_COMMIT_TODAY > daily_code_diff_raw.txt 2>/dev/null || echo "No code diff available" > daily_code_diff_raw.txt
  fi
else
  echo "No commits found for today" > daily_cumulative_diff_raw.txt
  echo "No commits found for today" > daily_diff_stats_raw.txt
  echo "No commits found for today" > daily_code_diff_raw.txt
fi

# 最新コミットの個別差分
git diff HEAD~1 --name-status > latest_diff_raw.txt 2>/dev/null || echo "No recent diff available" > latest_diff_raw.txt
git diff HEAD~1 > latest_code_diff_raw.txt 2>/dev/null || echo "No recent code diff available" > latest_code_diff_raw.txt

echo "✅ Git activity analysis complete!"