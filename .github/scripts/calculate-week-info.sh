#!/bin/bash

# 週情報を計算するスクリプト
# 使用方法: ./calculate-week-info.sh [WEEK_START_DAY]

set -e

WEEK_START_DAY=${1:-1}  # デフォルトは月曜日

# リポジトリ名と日付を取得
REPO_NAME=$(basename $GITHUB_REPOSITORY)
DATE=$(date '+%Y-%m-%d')
YEAR=$(date '+%Y')

# 週の計算（週の開始日を考慮）
CURRENT_DAY_OF_WEEK=$(date '+%w')  # 0=日曜日
DAYS_SINCE_WEEK_START=$(( (CURRENT_DAY_OF_WEEK - WEEK_START_DAY + 7) % 7 ))
WEEK_START_DATE=$(date -d "$DATE -$DAYS_SINCE_WEEK_START days" '+%Y-%m-%d')
WEEK_END_DATE=$(date -d "$WEEK_START_DATE +6 days" '+%Y-%m-%d')

# 週番号を計算（年の最初の週の開始日から数える）
YEAR_START=$(date -d "$YEAR-01-01" '+%Y-%m-%d')
YEAR_START_DAY_OF_WEEK=$(date -d "$YEAR_START" '+%w')
FIRST_WEEK_START_OFFSET=$(( (WEEK_START_DAY - YEAR_START_DAY_OF_WEEK + 7) % 7 ))
FIRST_WEEK_START=$(date -d "$YEAR_START +$FIRST_WEEK_START_OFFSET days" '+%Y-%m-%d')

# 週番号を計算
DAYS_DIFF=$(( ($(date -d "$WEEK_START_DATE" '+%s') - $(date -d "$FIRST_WEEK_START" '+%s')) / 86400 ))
WEEK_NUMBER=$(( DAYS_DIFF / 7 + 1 ))

# 週フォルダ名を作成
WEEK_FOLDER=$(printf "week-%02d_%s_to_%s" $WEEK_NUMBER $WEEK_START_DATE $WEEK_END_DATE)

# 環境変数に出力
echo "REPO_NAME=$REPO_NAME" >> $GITHUB_ENV
echo "DATE=$DATE" >> $GITHUB_ENV
echo "YEAR=$YEAR" >> $GITHUB_ENV
echo "WEEK_FOLDER=$WEEK_FOLDER" >> $GITHUB_ENV
echo "WEEK_START_DATE=$WEEK_START_DATE" >> $GITHUB_ENV
echo "WEEK_END_DATE=$WEEK_END_DATE" >> $GITHUB_ENV
echo "WEEK_NUMBER=$WEEK_NUMBER" >> $GITHUB_ENV

echo "📅 Date: $DATE"
echo "📅 Week: $WEEK_FOLDER"