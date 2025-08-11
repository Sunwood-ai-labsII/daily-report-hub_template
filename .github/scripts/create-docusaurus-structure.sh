#!/bin/bash

# Docusaurusの構造と_category_.jsonファイルを作成するスクリプト

set -e

# 必要な環境変数をチェック
: ${REPO_NAME:?}
: ${DATE:?}
: ${YEAR:?}
: ${WEEK_FOLDER:?}
: ${WEEK_NUMBER:?}
: ${WEEK_START_DATE:?}
: ${WEEK_END_DATE:?}

REPORT_HUB_DIR="daily-report-hub"
ACTIVITIES_DIR="$REPORT_HUB_DIR/docs/docs/activities"
YEAR_DIR="$ACTIVITIES_DIR/$YEAR"
WEEK_DIR="$YEAR_DIR/$WEEK_FOLDER"
DATE_DIR="$WEEK_DIR/$DATE"
TARGET_DIR="$DATE_DIR/$REPO_NAME"

# ディレクトリを作成
mkdir -p "$TARGET_DIR"

# Docusaurus _category_.json ファイルを作成

# 1. activities ディレクトリの _category_.json
if [ ! -f "$ACTIVITIES_DIR/_category_.json" ]; then
  cat > "$ACTIVITIES_DIR/_category_.json" << 'EOF'
{
  "label": "📊 Activities",
  "position": 1,
  "link": {
    "type": "generated-index",
    "description": "Daily development activities and reports"
  }
}
EOF
fi

# 2. 年ディレクトリの _category_.json
if [ ! -f "$YEAR_DIR/_category_.json" ]; then
  cat > "$YEAR_DIR/_category_.json" << EOF
{
  "label": "$YEAR",
  "position": 1,
  "link": {
    "type": "generated-index",
    "description": "Activities for year $YEAR"
  }
}
EOF
fi

# 3. 週ディレクトリの _category_.json
if [ ! -f "$WEEK_DIR/_category_.json" ]; then
  WEEK_LABEL="Week $WEEK_NUMBER ($WEEK_START_DATE to $WEEK_END_DATE)"
  cat > "$WEEK_DIR/_category_.json" << EOF
{
  "label": "$WEEK_LABEL",
  "position": $WEEK_NUMBER,
  "link": {
    "type": "generated-index",
    "description": "Activities for $WEEK_LABEL"
  }
}
EOF
fi

# 4. 日付ディレクトリの _category_.json
if [ ! -f "$DATE_DIR/_category_.json" ]; then
  DATE_LABEL="📅 $DATE"
  # 日付から位置を計算（月の日にち）
  DATE_POSITION=$(date -d "$DATE" '+%d' | sed 's/^0*//')
  cat > "$DATE_DIR/_category_.json" << EOF
{
  "label": "$DATE_LABEL",
  "position": $DATE_POSITION,
  "link": {
    "type": "generated-index",
    "description": "Activities for $DATE"
  }
}
EOF
fi

# 5. リポジトリディレクトリの _category_.json
if [ ! -f "$TARGET_DIR/_category_.json" ]; then
  cat > "$TARGET_DIR/_category_.json" << EOF
{
  "label": "🔧 $REPO_NAME",
  "position": 1,
  "link": {
    "type": "generated-index",
    "description": "Repository: $GITHUB_REPOSITORY"
  }
}
EOF
fi

echo "📁 Created directory structure:"
echo "  📂 $YEAR_DIR"
echo "    📂 $WEEK_FOLDER"
echo "      📂 $DATE"
echo "        📂 $REPO_NAME"
echo ""
echo "📄 Created _category_.json files for Docusaurus navigation"

# TARGET_DIRを環境変数として出力
echo "TARGET_DIR=$TARGET_DIR" >> $GITHUB_ENV