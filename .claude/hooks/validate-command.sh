#!/usr/bin/env bash
# PreToolUse hook: Bash コマンドの危険パターンを検出してブロックする
# exit 0 = 許可, exit 2 = ブロック
#
# Claude Code は stdin に JSON を渡す:
# { "tool_name": "Bash", "tool_input": { "command": "..." } }

set -u

# stdin から実行予定のコマンドを取得
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

if [ -z "$COMMAND" ]; then
  exit 0
fi

# --- 危険パターン定義 ---

# 1. 本番環境への直接接続を示唆するパターン
if echo "$COMMAND" | grep -qiE '(production|prod)\s*(db|database|server|host|env)'; then
  echo "BLOCKED: 本番環境への直接接続が検出されました" >&2
  exit 2
fi

# 2. 環境変数経由での機密情報漏洩
if echo "$COMMAND" | grep -qiE '(echo|printf|cat).*\$[{(]?[A-Za-z_]*(_KEY|_SECRET|_TOKEN|_PASSWORD|_CREDENTIAL)[A-Za-z_]*[})]?'; then
  echo "BLOCKED: 機密環境変数の出力が検出されました" >&2
  exit 2
fi

# 3. SSH/SCP による外部サーバー操作
if echo "$COMMAND" | grep -qE '^(ssh|scp)\s'; then
  echo "BLOCKED: SSH/SCP コマンドは手動で実行してください" >&2
  exit 2
fi

# 4. Docker の特権モード
if echo "$COMMAND" | grep -qE 'docker\s+run.*--privileged'; then
  echo "BLOCKED: Docker の特権モードは禁止されています" >&2
  exit 2
fi

# 5. ディスク全体への再帰的な権限変更
if echo "$COMMAND" | grep -qE 'chmod\s+-R\s+.*\s+/[^.]'; then
  echo "BLOCKED: ルートディレクトリ配下への再帰的 chmod は禁止されています" >&2
  exit 2
fi

# 6. git の危険な履歴改変（deny ルールの補完）
#    通常の git rebase main は許可。--onto, filter-branch, push --force をブロック
if echo "$COMMAND" | grep -qE 'git\s+(filter-branch|rebase\s+--onto|push.*--force)'; then
  echo "BLOCKED: git の履歴改変コマンドは手動で実行してください" >&2
  exit 2
fi

# 7. base64 エンコードによるデータ持ち出しの疑い
if echo "$COMMAND" | grep -qE 'base64.*\|.*(curl|wget|nc|ncat)'; then
  echo "BLOCKED: エンコードデータの外部送信パターンが検出されました" >&2
  exit 2
fi

# =============================================================================
# 自己防衛（絶対禁止 / principles §11・security.md）: ガードレールの無効化を
# Bash 経由で行う手口を hard-block する。テンプレの正規編集（Edit/Write ツール）は
# 妨げない — ここで止めるのは自律エージェントによるバイパス実行のみ。
# =============================================================================

# SD1. コミット/プッシュ時のフック無効化（--no-verify / 短縮形 -n）
#      短縮形 -n は commit のみ対象（git push -n は dry-run、git merge -n は --no-stat で別義）
if echo "$COMMAND" | grep -qE 'git\s+(commit|push|merge)\b[^|;&]*--no-verify|git\s+commit\b[^|;&]*\s-[a-z]*n\b'; then
  echo "BLOCKED: --no-verify（短縮形 -n 含む）によるフック無効化は禁止です（ガードレールは人間が手動で扱う / principles §11）" >&2
  exit 2
fi

# SD2. git フックパスの差し替え（フック迂回）
if echo "$COMMAND" | grep -qE 'git\s+config\b[^|;&]*core\.hooksPath'; then
  echo "BLOCKED: core.hooksPath の変更（フック迂回）は禁止です" >&2
  exit 2
fi

# SD3. hooks / settings の破壊的改変（deny削除・フック削除/空化）
if echo "$COMMAND" | grep -qE '(\brm\b|\bsed\b[^|;&]*-i|\btruncate\b|\bmv\b|\btee\b|>>?)[^|;&]*\.claude/(hooks|settings)'; then
  echo "BLOCKED: .claude/hooks・settings の Bash 経由改変は禁止です（編集は Edit/Write でレビュー可能な形で行う）" >&2
  exit 2
fi

# SD4. フックスクリプトの実行権限剥奪（無効化）
if echo "$COMMAND" | grep -qE 'chmod\b[^|;&]*\.claude/hooks'; then
  echo "BLOCKED: .claude/hooks への chmod（フック無効化）は禁止です" >&2
  exit 2
fi

# =============================================================================
# 一線（確認必須 / principles §11）: 外部アクセス・データ外部送出・不可逆破壊は
# 非ブロックで警告する。実行は止めないが、Claude は §11 に従い実行前に確認すること。
# =============================================================================

WARN=""
add_warn() { WARN="${WARN}  - $1\n"; }

# 一線①: 外部ホストへの能動アクセス（ポートスキャン・外部DB接続）
echo "$COMMAND" | grep -qE '\b(nmap|masscan|telnet|nc|ncat|netcat)\b' && \
  add_warn "外部アクセス/ポートスキャンの疑い（nmap/nc/telnet 等）"
echo "$COMMAND" | grep -qE '\b(psql|mysql|mongo|mongosh|redis-cli)\b[^|;]*(-h|--host)\s+' && \
  add_warn "外部DBへの接続の疑い（host 指定あり）"

# 一線②: データの外部送出
echo "$COMMAND" | grep -qE '\brsync\b[^|;]*[A-Za-z0-9._-]+@|\bnpm\s+publish\b|\baws\s+s3\s+(cp|sync|mv)\b|\bgh\s+release\s+(create|upload)\b|\bgcloud\b[^|;]*\bcp\b' && \
  add_warn "データの外部送出の疑い（rsync remote / npm publish / aws s3 / gh release 等）"

# 一線③: バックアップ無き不可逆破壊
echo "$COMMAND" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f|\bdd\b[^|;]*\bof=|\bshred\b|\bmkfs|\btruncate\b\s+-s' && \
  add_warn "不可逆破壊の疑い（git clean -f / dd / shred / mkfs / truncate 等）"

if [ -n "$WARN" ]; then
  # exit 0（非ブロック）。警告のみ提示し、Claude/ユーザーの判断に委ねる。
  printf 'WARN(自律の封筒・一線): 以下は確認必須の操作です。実行前に §11 に従い確認してください:\n%b' "$WARN" >&2
fi

# すべてのチェックを通過
exit 0
