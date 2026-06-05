#!/usr/bin/env bash
# PreToolUse hook: git 操作の直前に作業ディレクトリとブランチを表示する
# リポジトリ取り違え・ベースブランチ誤り・worktree 事故を防ぐための非ブロッキング通知。
#
# exit 0 = 許可（このフックはブロックしない。情報提示のみ）
#
# Claude Code は stdin に JSON を渡す:
# { "tool_name": "Bash", "tool_input": { "command": "..." } }

set -u

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

if [ -z "$COMMAND" ]; then
  exit 0
fi

# git の状態を変える操作のみ対象（commit / push / branch 切替 / merge / PR 作成）
if ! echo "$COMMAND" | grep -qE '\b(git\s+(commit|push|switch|checkout|merge|rebase|branch)|gh\s+pr\s+create)\b'; then
  exit 0
fi

CWD=$(pwd)
BRANCH=$(git branch --show-current 2>/dev/null || echo "(git管理外)")
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "?")
REPO=$(basename "$ROOT" 2>/dev/null || echo "?")

# worktree かどうかを判定（.git がファイルなら worktree）
WORKTREE_NOTE=""
if [ -f "$ROOT/.git" ]; then
  WORKTREE_NOTE=" / worktree"
fi

MSG="📍 git操作の実行先 → repo: ${REPO}${WORKTREE_NOTE} | branch: ${BRANCH} | cwd: ${CWD}"

# main/master への直接 commit/push は追加警告
if echo "$BRANCH" | grep -qE '^(main|master)$' && echo "$COMMAND" | grep -qE '\bgit\s+(commit|push)\b'; then
  MSG="${MSG}\n⚠️ ベースブランチ（${BRANCH}）への直接操作です。意図したものか確認してください。"
fi

# systemMessage で非ブロッキング通知（exit 0）
python3 -c "import json,sys; print(json.dumps({'systemMessage': sys.argv[1].replace('\\\\n', chr(10))}))" "$MSG"
exit 0
