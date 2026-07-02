#!/usr/bin/env bash
# spec-lint.sh の回帰テスト（SPEC-HARNESS-001 §3 M6-3 の受入基準を機械検証）
# 使い方: bash .claude/scripts/tests/spec-lint.test.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT="$SCRIPT_DIR/../spec-lint.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WORK="${TMPDIR:-/tmp}/spec-lint-test.$$"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0

run_case() {
  local expect="$1" desc="$2"; shift 2
  bash "$LINT" "$@" >"$WORK/out.txt" 2>&1
  local actual=$?
  if [ "$actual" -eq "$expect" ]; then
    echo "PASS (exit $actual) : $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL (expect $expect, got $actual) : $desc"
    sed 's/^/       /' "$WORK/out.txt"
    FAIL=$((FAIL+1))
  fi
}

# --- ベース: 完成した最小カード ---
make_base() {
cat > "$1" <<'CARD'
# [SPEC-TEST-001] テスト機能

## 0. 完成チェックリスト（Fix ゲート）
- [x] 目的が1-2行で書かれている
- [x] 受入基準が全て Given-When-Then で書かれている

## 1. 目的
テスト用。

## 2. ユーザーストーリー
- テスターとして、lint を検証したい。

## 3. 受入基準（Given-When-Then）
- [ ] Given 入力X When 実行 Then 結果Yが返る

## 4. 画面遷移表
- なし（UIなし機能）

## 5. 状態遷移表
- なし（状態なし）

## 6. 入力・バリデーション
| 項目 | 型/形式 | 必須 | 制約 | 違反時の挙動 |
|------|--------|------|------|-------------|
| 名前 | text | 必須 | 1〜50字 | エラー表示 |

## 7. スコープ外
- 対象外の機能A

## 8. 未決
- なし

## 9. モック
- なし

## 10. メモ
-
CARD
}

echo "--- 正常系（expect 0） ---"
make_base "$WORK/valid.md"
run_case 0 "完成した最小カード" "$WORK/valid.md"
run_case 0 "実カード: SPEC-HARNESS-001 自身（ドッグフーディング）" "$REPO_ROOT/docs/specs/SPEC-HARNESS-001.md"

echo "--- カード内容の不備（expect 1） ---"
make_base "$WORK/c1.md"
python3 - "$WORK/c1.md" <<'PY'
import sys
p = sys.argv[1]; t = open(p).read()
t = t.replace("- [x] 目的が1-2行で書かれている", "- [ ] 目的が1-2行で書かれている")
open(p, "w").write(t)
PY
run_case 1 "§0 に未チェック項目が残る" "$WORK/c1.md"

make_base "$WORK/c2.md"
python3 - "$WORK/c2.md" <<'PY'
import sys, re
p = sys.argv[1]; t = open(p).read()
t = t.replace("""## 4. 画面遷移表
- なし（UIなし機能）""", """## 4. 画面遷移表
| 遷移元画面 | トリガー | 遷移先画面 | 条件・ガード |
|-----------|---------|-----------|-------------|
|  |  |  |  |""")
open(p, "w").write(t)
PY
run_case 1 "§4 の表が空で「なし（理由）」の明記もない" "$WORK/c2.md"

make_base "$WORK/c3.md"
python3 - "$WORK/c3.md" <<'PY'
import sys
p = sys.argv[1]; t = open(p).read()
t = t.replace("## 8. 未決\n- なし", "## 8. 未決\n- (a) 解消必須: 承認者のロールが未確定")
open(p, "w").write(t)
PY
run_case 1 "§8 に (a)解消必須の未決が残る" "$WORK/c3.md"

make_base "$WORK/c4.md"
python3 - "$WORK/c4.md" <<'PY'
import sys
p = sys.argv[1]; t = open(p).read()
t = t.replace("Then 結果Yが返る", "Then 適切にエラー処理される")
open(p, "w").write(t)
PY
run_case 1 "§3 受入基準に曖昧語（適切に）を含む" "$WORK/c4.md"

echo "--- 付随ケース: (b)外部確認待ちのみは合格（expect 0） ---"
make_base "$WORK/c5.md"
python3 - "$WORK/c5.md" <<'PY'
import sys
p = sys.argv[1]; t = open(p).read()
t = t.replace("## 8. 未決\n- なし", "## 8. 未決\n- (b) 外部確認待ち: 承認者ロールは運用チームの確認待ち（依存: M2のみ）")
open(p, "w").write(t)
PY
run_case 0 "§8 が (b)外部確認待ちのみ" "$WORK/c5.md"

echo "--- 入力エラー（expect 2） ---"
run_case 2 "引数なし（usage）"
run_case 2 "存在しないパス" "$WORK/not-exist.md"

echo ""
echo "RESULT: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
