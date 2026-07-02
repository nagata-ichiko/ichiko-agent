#!/usr/bin/env bash
# =============================================================================
# spec-lint: 要件カード（spec-card v2）の Fix ゲートを機械検証する
# =============================================================================
#
# 使い方: .claude/scripts/spec-lint.sh docs/specs/SPEC-XXX-NNN.md
#
# 検査項目（SPEC-HARNESS-001 §3 / §6）:
#   1. §0/§3〜§8 のセクション見出しが存在する
#   2. §0 完成チェックリストに未チェック（- [ ]）が残っていない
#   3. §4/§5/§6 の必須表が「データ行あり」または「なし（理由）」明記のいずれかを満たす
#   4. §8 に (a)解消必須の未決が残っていない（「なし」または (b)外部確認待ちのみ許可）
#   5. §3 受入基準に曖昧語（適切に/いい感じ/柔軟に/TBD/未定/後で決める/うまく）が無い
#
# 終了コード: 0=合格 / 1=カード内容の不備 / 2=入力エラー（usage・パス不存在・形式不正）
# 実行タイミング: grill Step 5（完了判定）と build 準備フェーズ（着手前検証）

set -u

if [ $# -lt 1 ]; then
  echo "usage: spec-lint.sh <要件カード.md>" >&2
  exit 2
fi

CARD="$1"

if [ ! -f "$CARD" ]; then
  echo "ERROR: ファイルが存在しません: $CARD" >&2
  exit 2
fi

case "$CARD" in
  *.md) ;;
  *) echo "ERROR: .md ファイルを指定してください: $CARD" >&2; exit 2 ;;
esac

python3 - "$CARD" <<'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    text = f.read()

# テンプレ由来の HTML コメント（記入ルール等）は検査対象から除外する
text = re.sub(r"<!--.*?-->", "", text, flags=re.S)

# --- セクション分割（## N. 見出し） ---
sections = {}
current = None
for line in text.splitlines():
    m = re.match(r"^##\s*(\d+)\.", line)
    if m:
        current = int(m.group(1))
        sections[current] = []
    elif current is not None:
        sections[current].append(line)

issues = []

# 1. 必須セクション見出しの存在（§0 / §3〜§8）
for n in (0, 3, 4, 5, 6, 7, 8):
    if n not in sections:
        issues.append(f"§{n}: セクション見出しが存在しない")

# 2. §0 完成チェックリスト: 未チェックが残っていないか
for ln in sections.get(0, []):
    if re.match(r"^\s*-\s*\[\s\]", ln):
        issues.append(f"§0 未チェック: {ln.strip()}")

# 3. §4/§5/§6 必須表: データ行あり or「なし（理由）」明記
def table_satisfied(lines):
    joined = "\n".join(lines)
    # 「なし（理由）」の明記（全角/半角括弧とも許可、理由が空でないこと）
    if re.search(r"なし（.+）|なし\(.+\)", joined):
        return True
    pipe_rows = [l for l in lines if l.strip().startswith("|")]
    # 先頭2行（ヘッダ・区切り）を除いたデータ行に中身があるか
    for l in pipe_rows[2:]:
        cells = [c.strip() for c in l.strip().strip("|").split("|")]
        if any(cells):
            return True
    return False

for n, name in ((4, "画面遷移表"), (5, "状態遷移表"), (6, "入力・バリデーション表")):
    if n in sections and not table_satisfied(sections[n]):
        issues.append(f"§{n} {name}: 表が空で「なし（理由）」の明記もない")

# 4. §8 未決: (a)解消必須の残存を検出（「なし」と (b)外部確認待ちのみ許可）
for ln in sections.get(8, []):
    s = ln.strip()
    if not s.startswith("-"):
        continue
    body = s.lstrip("-").strip()
    if not body or body.startswith("なし"):
        continue
    if re.search(r"[（(]\s*b\s*[）)]", body):
        continue
    issues.append(f"§8 (a)解消必須の未決が残存（(b)明記のない未決は(a)とみなす）: {s}")

# 5. §3 受入基準: 曖昧語の検出
AMBIGUOUS = ["適切に", "いい感じ", "柔軟に", "TBD", "未定", "後で決める", "うまく"]
for ln in sections.get(3, []):
    for w in AMBIGUOUS:
        if w in ln:
            issues.append(f"§3 曖昧語「{w}」: {ln.strip()}")

if issues:
    print(f"FAIL: {path} — Fix ゲート未達 {len(issues)} 件")
    for i in issues:
        print(f"  - {i}")
    sys.exit(1)

print(f"PASS: {path} — Fix ゲート機械検証 合格")
sys.exit(0)
PYEOF
