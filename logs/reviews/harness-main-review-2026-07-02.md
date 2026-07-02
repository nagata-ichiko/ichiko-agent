# main 全体再レビュー（2026-07-02）

**対象**: main（`8bf0738`、M3.5+M4+M3.6+M5+摩擦3対応 反映後）
**方法**: スキル7本（grill/mock/design/plan/build/map/handle）・ルール（principles/autonomous-mode/implementation/testing/security/parallel-work）・テンプレ3枚・hooks 3本・settings.json・agents を通読し、相互整合を機械チェック（grep）で裏取り。過去レビュー（m3.5-review / m5-dogfood）で解消済みの項目は再指摘しない。

---

## 結論（3行）

- 骨格は健全。5フェーズの責務分離・Fixゲート・許可リスト方式・M4強制は一貫しており、過去レビューの上位指摘は解消が確認できた。
- **修正推奨 3件**: フック誤検知（本レビュー中に実発生）、grill/plan への「未決2分類」反映漏れ 2件。いずれも局所修正。
- 低優先 3件（`git commit -n` 抜け・「デザイン方針」参照先不在・E2E タイミング文言）。

---

## 指摘（優先度順）

### F1【Medium・実発生】validate-command.sh SD3 が read-only コマンドを誤ブロック

`.claude/hooks/validate-command.sh:82` の正規表現:

```
(\brm\b|\bsed\b[^|;]*-i|\btruncate\b|\bmv\b|\btee\b|>>?)[^|;]*\.claude/(hooks|settings)
```

`[^|;]*` が `&&` を除外していないため、コマンド連結をまたいでマッチする。本レビュー中に実発生:

```
ls ... 2>/dev/null && ... && ls .claude/hooks/   ← BLOCKED
```

`2>/dev/null` の `>` が起点になり、後方の `.claude/hooks`（読み取り専用の `ls`）まで到達してブロック。リダイレクトを含む複合コマンドの後方でパスに言及するだけで発火するため誤検知率が高い。

**修正案**: SD1〜SD4 の `[^|;]*` を `[^|;&]*` に変更（`&&` 越えを禁止）。攻撃面は変わらない（`rm .claude/hooks/x` / `echo x > .claude/settings.json` は同一コマンド内なので引き続きブロック）。

### F2【Medium】grill SKILL.md の「未決2分類」反映漏れ（同一ファイル内で矛盾）

摩擦3対応（`14862ff`）で Step 4/5 は2分類化されたが、冒頭と末尾が旧文言のまま:

- `grill/SKILL.md:14` — 「かつ**「未決 = なし」**。これを満たすまで grill を終えない」
  → (b)外部確認待ちは残ってよい設計なのに、到達基準が「未決=なし」を要求。Step 5（:71-73）と矛盾。
- `grill/SKILL.md:85` — 「**未決を残したままフェーズを終えない**」
  → 同上。(b) は明記のうえ残してフェーズを終えるのが正。

**修正案**: :14 を「(a)解消必須の未決=なし」に、:85 を「(a)を残したまま終えない。(b)は誰の確認待ちかを明記して残してよい」に揃える。

### F3【Medium】plan SKILL.md が未決2分類未対応（(b)残存で plan まで止まる）

`plan/SKILL.md:16` — 「**Fix ゲート未達（未決あり・完成チェックリスト未達）なら分解に入らず grill に差し戻す**」

(b)外部確認待ちが残っている場合、build は「該当マイルストーンのみブロック」で進める設計（build:19）なのに、その前段の plan が「未決あり」で一律差し戻すと (b) ケースで plan に入れず矛盾する。どのマイルストーンが (b) に依存するかを判定できるのは分解を行う plan 自身であり、むしろ plan が「(b)依存マイルストーンにブロック印を付ける」役割を担うべき。

**修正案**: :16 を「(a)解消必須の未決あり・チェックリスト未達なら差し戻す。(b)のみなら分解に入り、(b)に依存するマイルストーンへブロック印を付ける」に変更。goal-board テンプレに `[B: 外部確認待ち]` 等の印の記法を1行追加。

### F4【Low】SD1 に `git commit -n` の抜け

`validate-command.sh:70` は `--no-verify` の長形式のみ検出。短縮形 `git commit -n` は同義（フック迂回）だが素通りする。**修正案**: `git\s+(commit|push|merge)\b[^|;&]*(--no-verify|\s-n\b)` 等で短縮形も捕捉（`git push -n` は dry-run なので commit に限定するのがより正確）。

### F5【Low】「CLAUDE.md デザイン方針」の参照先が存在しない

`mock:22,34` / `design:30` / `coder AGENT.md:26` の5箇所が CLAUDE.md「デザイン方針」を参照するが、CLAUDE.md テンプレート（ルート）に該当セクションが無い。design はフォールバック（無ければ1行宣言）があるので実害は小さいが、書く場所が定義されていないと永遠に「無ければ」側に落ちる。**修正案**: CLAUDE.md テンプレに `## デザイン方針` プレースホルダを追加するか、参照先を `docs/design/design-system.md`（design モードB成果物）に一本化。

### F6【Low】E2E全件実行のタイミング文言の緊張

`testing.md:56` 「作業が完了したら、**コミット前に**E2E全件」 vs `build:27` 「マイルストーン完了ごとにコミット」+ `build:48` 「仕上げでE2Eデグレチェック」。build の設計ではマイルストーンコミットは E2E 全件より先に積まれるため、「コミット前に」が最終コミットを指すのか毎コミットなのか曖昧。**修正案**: testing.md を「PR作成（または最終コミット）前にE2E全件」に明確化。

---

## 確認して問題なしだった点

- **未決2分類の反映状況**: spec-card §0/§8・principles §1・build 準備フェーズ・grill Step4/5 は反映済み。漏れは F2/F3 の2箇所のみ。
- **M4 強制の実体**: settings.json のフック配線3本（validate/enforce/show-git-context）は全て実在・整合。security.md の記述とフック実装が一致。
- **許可リスト方式の一貫性**: spec-card 注記 → grill Step3 → build ルール → design トークン → implementation.md 既定表（状態遷移=明記なし禁止）まで一気通貫。
- **implementation.md 仮採用矛盾（M3.5レビュー#7)**: 「原則 grill 差し戻し・例外は modeC のみ＋未決追記義務」に修正済みで解消確認。
- **廃止参照の残存なし**: orchestrate / init-spec / spec-all への言及は「旧方式は使わない」の文脈のみ（意図的）。
- **enforce-execution-rules.sh**: execution-rules.yml 未定義時のテスト系ブロックは意図設計。example ファイル実在確認済み。
- **coder AGENT.md**: 証跡付き報告・コミット禁止（親がレビュー後）・スコープ厳守が parallel-work 委任規約と整合。

## 残タスク（変更なし・既知）

- 提案3（build 委任判断の決定化）— 実プロジェクト適用時に再観測
- デザイン連携の深掘り — 必要時ユーザー確認

---

## 対応記録（2026-07-02 同日・ブランチ `fix/harness-review-20260702`）

- **F1 修正済み**: validate-command.sh SD1〜SD4 の `[^|;]*` → `[^|;&]*`（`&&` 越えマッチを禁止）。回帰テスト16ケース全PASS（誤検知5解消・真検知8維持・正常系3素通り）
- **F2 修正済み**: grill :14 到達基準・:85 ルールを「(a)解消必須のみゼロ必須・(b)は明記して残置可」に統一
- **F3 修正済み**: plan Step1 を「(b)のみなら分解可」に変更、Step2 と goal-board テンプレに `[B: 確認内容]` ブロック印を追加
- **F4〜F6 未対応**（低優先・別途対応推奨のまま）

### 公式ドキュメント照合（claude-code-guide agent, 2026-07-02）

- rules `paths:` 条件ロード / PreToolUse exit 2=ブロック・exit 0+stderr=警告 / SKILL.md・AGENT.md frontmatter / sandbox 設定 — **すべて現行公式仕様と一致、非推奨パターンなし**
- `enableWeakerNetworkIsolation` の「project settings では無効」という初回報告は**エージェントの混同（allowAppleEvents との取り違え）**。再照合で訂正済み — スコープ制限の公式記述なし、settings.json は現状のままでよい
- 再発防止として principles §2 に「ハーネス機構の改修も公式ドキュメント照合」を追記

### 自律運用（M6 検討材料）— 公式機構

GitHub Actions（@claude）/ Routines（cloud 定期実行）/ Background agents（--bg）/ `/loop` / SDK。M6=受動起動の設計はこれらを部品にする。
