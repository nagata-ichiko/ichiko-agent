# ハーネス構成カタログ（現状棚卸し）

> 目的: ichiko-agent ハーネスの再設計に向けた客観的な現状カタログ。**良し悪しの判断・取捨選択は一切しない。事実のみ。**
> 作成日: 2026-07-01 / 対象: `/Users/kinoshita/Dev/ichiko-agent`

## サマリ（定量）

| 指標 | 値 |
|------|----|
| スキル総数（`_shared` 除く） | 27 |
| ルール総数 | 25 |
| `_shared` モジュール総数 | 28（※タスク記載の「30」に対し実測 28） |
| 設計書テンプレート総数（phase1〜4） | 29（※タスク記載「約30」に対し実測 29） |
| スキル機能重複グループ数 | 5 |
| 常時ロード相当のルール数 | 9（下記 B 節参照） |
| 孤立 `_shared` モジュール数 | 3 |
| 1機能あたり最大ドキュメント生成本数 | 約 20 本（下記 D 節参照） |

---

## A. スキル棚卸し

### A-1. 全スキル一覧（27）

生成物凡例: **Doc**=ドキュメント / **Code**=コード / **Both**=両方 / **Op**=操作・運用系（生成物なし）

| スキル | 一言用途 | 行数 | トリガー要約 | 依存（_shared / 他スキル / Agent） | 生成物 |
|--------|---------|-----:|------------|----------------------------------|:------:|
| add-repo | 既存WSへリポ追加しCLAUDE.md/設計書を差分更新 | 81 | 「リポを追加した」 | tech-stack-guide, project-scale-thresholds, screen-transition-diagram | Doc |
| analyze-codebase | 既存コードを並列分析し overview.md 生成（init-spec前処理） | 68 | 「コードベース分析」「overview作って」 | project-scale-thresholds, subagent-task-format / Agent 並列 | Doc |
| apply-design | ロジック不変で見た目だけ差し替え | 31 | 「デザイン差し替え」「CSSだけ」 | finish-impl | Code |
| browse | agent-browser で画面確認（AIの目） | 167 | 「画面見て」「スクショ」 | (なし) | Op |
| detail-design | 詳細設計書の一括生成（コード分析/設計ファースト2モード） | 206 | 「詳細設計を作って」 | subagent-task-format, tech-stack-guide, spec-coverage-review, screen-transition-diagram, detail-design/formats / Agent | Doc |
| docs-serve | MkDocsプレビュー+承認APIを起動 | 68 | 「docs起動」「承認ボタン」 | (なし, allowed-tools: Bash) | Op |
| domain-pm | ドメインPMとしてタスク分解・実装指揮（orchestrate専用） | 51 | orchestrate から自動起動 | task-decomposition-pattern, completion-checklist, error-recovery / Agent(PG) | Both |
| draft-spec | 新機能の要件定義（自然言語→質問→要件定義書） | 178 | 「○○機能を作りたい」 | spec-writing-standard, spec-unified-base, screen-transition-diagram, doc-integrity-check / spec-writer | Doc |
| drawio | 複雑な図（drawio）を生成 | 122 | 「drawio作って」 | (なし) | Doc |
| feedback-template | 改善をテンプレートリポにPRで反映（push） | 124 | 「テンプレに反映」 | (なし) | Op |
| gen-test-report | テスト実行結果を集計し報告書生成 | 54 | 「テスト報告書」 | (なし) | Doc |
| gen-test-specs | システム/受入テスト仕様書を生成 | 51 | 「UAT準備」「システムテスト仕様」 | (なし) | Doc |
| gen-tests | テスト追加・補強・TDD（実装前テスト先行） | 153 | 「テスト書いて」「E2E」 | spec-map-operations, code-search-2stage, finish-impl, tech-stack-guide | Code |
| handle | 全リクエストの受け皿・振り分け | 70 | 「対応して」「やって」「相談」 | (なし, 他スキルへルーティング) | — |
| hotfix | 緊急修正（コード先行→Spec後追い） | 94 | 「本番が落ちた」「至急修正」 | spec-map-operations, code-search-2stage, finish-impl, error-recovery | Both |
| implement-spec | Spec基準の新規実装（プラン→実装→テスト→レビュー） | 133 | 「REQ-XXX実装」「○○作って」 | spec-map-operations, design-priority, error-recovery, +多数（下記） / coder, spec-writer | Both |
| init-spec | 既存プロジェクト初回セットアップ（CLAUDE.md/設計書一式生成） | 195 | 「セットアップして」「初期化」 | project-scale-thresholds, code-search-2stage, screen-transition-diagram, tech-stack-guide / Agent | Doc |
| notebook-query | NotebookLM から議事録・決定事項を検索 | 75 | 「議事録参照」「MTG背景」 | (なし, user-invocable) | Op |
| orchestrate | SuperPMとしてドメインPM経由でPGに配布 | 97 | 実装リクエストで自動選択 | task-decomposition-pattern, completion-checklist, error-recovery / domain-pm, Agent | Both |
| review-mark | レビューマーカーの一覧・承認・除去 | 131 | 「未承認一覧」「承認して」 | (なし) | Op |
| review-pr | PRを複数観点で並列レビュー・統合 | 161 | 「PRレビュー」 | (なし) / Agent 並列 | Op |
| revise-spec | 実装済み機能の仕様変更（設計書先行→コード修正） | 186 | 「○○の仕様変更」「修正して」 | spec-writing-standard, spec-unified-base, spec-map-operations, screen-transition-diagram, design-priority, error-recovery, +多数 / coder, spec-writer | Both |
| skill-auditor | SKILLポートフォリオ健全性監査 | 65 | 「スキル監査」「skill audit」 | subagent-task-format, health-check, skill-auditor/decision-tree / 専用Agent×4 | Doc |
| spec-all | 全機能一括Spec化・一括更新（PM×並列） | 129 | 「Spec全部作って」 | spec-writing-standard, spec-unified-base, spec-map-operations, subagent-task-format, spec-consistency-review, screen-transition-diagram, tech-stack-guide, spec-coverage-review, spec-all/execution / Agent 並列 | Doc |
| spec-feature | 既存機能のSpec化（コード→要件定義書 逆生成） | 200 | 「○○機能のSpec作って」 | spec-writing-standard, spec-unified-base, spec-map-operations, code-search-2stage, spec-consistency-review, screen-transition-diagram | Doc |
| sync-template | テンプレートリポの最新を取り込み（pull） | 280 | 「テンプレ同期」 | (なし) | Op |
| update-docs | コード変更→ドキュメント追従更新（例外措置） | 116 | 「設計書を最新化」 | spec-writing-standard, spec-unified-base, spec-map-operations, code-search-2stage | Doc |

補足:
- `implement-spec` / `revise-spec` は上記 frontmatter 依存に加え、本文で coding-quality / review-checklist / review-standards / loop-protocol / review-report / impact-report / finish-impl を参照する（`_shared` 参照 grep で確認）。
- スキルは 27 本だが、`.claude/agents/` の専用エージェント（coder, spec-writer, domain-pm 相当, integrity-checker, routing-analyst, portfolio-analyst, improvement-planner 等）を各スキルが呼び出す。

### A-2. 機能重複グループ（5グループ）

**重複グループ①: Spec/要件定義の生成（最重要・最大の重複領域）** — 9スキル
| スキル | 起点 | コード状態 | 粒度 | 主な差分 |
|--------|------|----------|------|---------|
| draft-spec | 自然言語 | コード**なし**（新規） | 1機能 | 新機能をゼロから要件化 |
| spec-feature | 既存コード | コード**あり** | 1機能 | コードから要件を逆生成 |
| spec-all | 既存コード | コード**あり** | **全機能** | 並列で全機能を一括逆生成 |
| init-spec | 既存コード | コード**あり** | プロジェクト全体（初回） | CLAUDE.md含む初期一式生成 |
| analyze-codebase | 既存コード | コード**あり** | overview のみ | init-spec の前処理（200ファイル超向け） |
| detail-design | 要件 or コード | 両対応 | 詳細設計層 | phase3詳細設計書を一括生成 |
| update-docs | コード変更後 | コード**あり** | 差分 | 変更をドキュメントに追従 |
| revise-spec | 変更依頼 | コード**あり** | 差分＋コード | 設計書先行更新＋コード修正 |
| add-repo | リポ追加後 | コード**あり** | 差分 | 追加リポ分の設計書拡張 |

重複軸: 「要件定義書/設計書を書く」機能が、**コード有無 × 粒度（1機能/全機能/差分）× 初回か否か** の組合せで 9 スキルに分岐。共通の `_shared`（spec-writing-standard, spec-unified-base, spec-map-operations, spec-writer Agent）を大半が共有。

**重複グループ②: 実装（コードを書く）** — 5スキル
| スキル | 用途 | 設計書先行の扱い |
|--------|------|----------------|
| implement-spec | Spec基準の新規実装 | 設計書ファースト（既存要件を読む） |
| revise-spec | 実装済み機能の変更 | 設計書先行更新→コード |
| hotfix | 緊急修正 | コード先行→Spec後追い（例外） |
| apply-design | 見た目だけ差し替え | 設計変更なし |
| orchestrate/domain-pm | PM層経由の実装配布 | 上記を配下で実行 |

重複軸: いずれも「コードを変更する」。差分は **設計書との順序（先行/後追い/なし）** と **緊急度** と **PM層の有無**。coder Agent・finish-impl・error-recovery を共有。

**重複グループ③: テスト関連** — 4スキル
| スキル | 生成物 |
|--------|--------|
| gen-tests | テストコード（実装） |
| gen-test-specs | テスト仕様書（ドキュメント） |
| gen-test-report | テスト結果報告書（ドキュメント） |
| review-pr | 品質レビュー（テスト観点含む） |

重複軸: 「テスト」という語を共有するが、コード生成/仕様書生成/報告書生成/レビューで役割は分離。用途の近接による誤ルーティング候補。

**重複グループ④: レビュー** — 3スキル + rule
| スキル | 用途 |
|--------|------|
| review-pr | PR単位の並列コードレビュー |
| review-mark | 設計書のレビューマーカー承認・除去 |
| skill-auditor | スキルポートフォリオのメタレビュー |

重複軸: 「レビュー」語の共有。対象（PR / 設計書マーカー / スキル自体）が異なる。加えて post-impl-review ルール・spec-consistency-review 等の `_shared` レビューモジュールが並存。

**重複グループ⑤: テンプレート同期** — 2スキル
| スキル | 方向 |
|--------|------|
| sync-template | pull（テンプレ→プロジェクト） |
| feedback-template | push（プロジェクト→テンプレPR） |

重複軸: テンプレートリポとの双方向同期。方向のみが差分。

---

## B. ルール棚卸し（25）

### B-1. 発火分類

| 分類 | 定義 | 件数 |
|------|------|-----:|
| 常時ロード相当 | `alwaysApply: true` または frontmatter なし（プロジェクト命令として無条件ロード）。system-reminder の CLAUDE.md 文脈にも実際に本文が展開されている | 9 |
| paths 条件付き | 特定パス操作時のみロード | 14 |
| トリガー参照型 | 別ルール/スキルから明示 Read される | 2 |

**常時ロード相当（注意力予算を恒常的に消費）9件:**
| ルール | 行数 | 根拠 |
|--------|-----:|------|
| agent-delegation.md | 27 | alwaysApply: true |
| claude-code-qa.md | 11 | alwaysApply: true |
| github-issues.md | 43 | alwaysApply: true（paths も併記） |
| parallel-work-trigger.md | 11 | alwaysApply: true（参照トリガー） |
| skill-routing.md | 23 | alwaysApply: true |
| environment-preflight.md | 19 | frontmatter なし＝無条件 |
| long-output.md | 16 | frontmatter なし＝無条件 |
| post-impl-review.md | 30 | frontmatter なし＝無条件 |
| scope-confirm.md | 19 | frontmatter なし＝無条件 |

> 注: 上記9件はいずれも本セッションの system-reminder（project instructions）に実本文が展開されており、常時コンテキストに載っていることを実測確認した。合計約 199 行。

### B-2. paths 条件付きロード（14件）

| ルール | 行数 | ロード条件（paths 要約） |
|--------|-----:|------------------------|
| async-teams.md | 54 | domains/, logs/context/, tasks/ |
| claude-code-config.md | 19 | .claude/skills, rules, settings, agents |
| design-handoff.md | 41 | docs/designs/, docs/design/features/ |
| doc-accuracy.md | 27 | docs/requirements/, docs/design/ |
| git-workflow.md | 43 | .git/, .github/ |
| i18n.md | 16 | **/i18n/, locales/, messages/ 等 |
| implementation.md | 92 | src/, app/, lib/, api/, spec-map.yml 等 |
| parallel-work.md | 173 | alwaysApply: false（trigger 経由でロード） |
| pm-orchestration.md | 32 | docs/requirements/, design/, api/, mkdocs.yml |
| release-and-branching.md | 50 | .github/, ci-templates/ |
| review-mark.md | 127 | docs/requirements/, design/, design-detail/ |
| security.md | 68 | .env*, *.pem, *.key, credentials, deploy, Dockerfile 等 |
| session-ops.md | 112 | tasks/, logs/ |
| spec-management.md | 156 | docs/requirements/, design/, spec-map.yml, templates/, api/, pre-specs/ |
| supabase.md | 70 | supabase/ |
| testing.md | 114 | tests/, *.test.*, *.spec.*, e2e/, *.config.* |

（parallel-work.md は alwaysApply:false だが parallel-work-trigger 経由でロードされるため実質トリガー参照型。上表に併記。）

### B-3. ルール間の内容重複・相互参照（事実列挙、判断なし）

- **並列作業が2ファイルに分割**: parallel-work-trigger.md（常時ロード・11行）が parallel-work.md（173行）を Read させる二段構成。トリガーと本体が別ファイル。
- **スキルルーティングの多重化**: skill-routing.md（rule, 常時）＋ handle スキル＋ `_shared/skill-decision-tree.md`（孤立）が同じ「どのスキルを使うか」を扱う。
- **レビュー系の分散**: post-impl-review.md（rule）が `_shared` の doc-integrity-check / spec-consistency-review / review-checklist / review-standards を参照。レビュー基準が rule と _shared に跨る。
- **Spec管理の重複記述**: spec-management.md（rule, 156行）と `_shared/spec-writing-standard.md`（120行）・spec-unified-base.md が Spec 執筆規約を分担。rule が _shared を参照。
- **Claude Code 設定QAの二重化**: claude-code-qa.md（常時）と claude-code-config.md（paths）が両方 `_shared/config-reference.md` を参照。
- **doc-accuracy.md / spec-management.md / review-mark.md** が同じ `docs/requirements/**` `docs/design/**` を paths に持ち、同一ファイル編集時に複数同時発火しうる。
- **implementation.md / testing.md / security.md** はコード・テスト・機密の各領域で独立。相互参照は少ない。
- 優先順位は `.claude/CLAUDE.md` に明文化（security > spec-management > implementation/testing > その他）。

---

## C. `_shared` 棚卸し（28モジュール）

参照数は `.claude/skills` + `.claude/rules` 内の grep 実測（自ファイル定義を除外）。

| モジュール | 一言用途 | 行数 | 参照数 | 主な参照元 |
|-----------|---------|-----:|------:|-----------|
| tech-stack-guide.md | 技術スタック対応ガイド | 191 | 11 | detail-design, init-spec, gen-tests, spec-all, add-repo, finish-impl 他 |
| screen-transition-diagram.md | 画面遷移図ルール | 99 | 13 | detail-design, spec-feature, init-spec, spec-all, draft-spec, revise-spec 他 |
| code-search-2stage.md | 2段階コード探索 | 50 | 9 | spec-feature, hotfix, update-docs, init-spec, gen-tests, implement-spec, revise-spec, rule:implementation |
| doc-integrity-check.md | ドキュメント機械的整合性チェック | 223 | 9 | detail-design, spec-feature, update-docs, init-spec, spec-all, revise-spec, draft-spec, rule:post-impl-review |
| error-recovery.md | エラーリカバリーパターン集 | 124 | 9 | hotfix, domain-pm, finish-impl, implement-spec, orchestrate, revise-spec, rule:session-ops, rule:async-teams |
| spec-writing-standard.md | Spec執筆標準 | 120 | 9 | spec-feature, update-docs, spec-all, draft-spec, revise-spec, spec-unified-base, rule:spec-management |
| spec-map-operations.md | spec-map.yml 操作ガイド | 78 | 8 | spec-feature, hotfix, update-docs, gen-tests, spec-all, implement-spec, revise-spec |
| spec-unified-base.md | Spec統一基盤確認 | 14 | 7 | spec-feature, update-docs, spec-all, revise-spec, draft-spec, spec-writing-standard, rule:pm-orchestration |
| subagent-task-format.md | サブエージェント指示フォーマット | 40 | 6 | detail-design, analyze-codebase, skill-auditor, spec-all, rule:pm-orchestration |
| finish-impl.md | 共通仕上げ手順 | 110 | 5 | hotfix, gen-tests, apply-design, implement-spec, revise-spec |
| review-standards.md | レビュー基準 | 61 | 5 | review-checklist, loop-protocol, implement-spec, revise-spec, rule:post-impl-review |
| spec-consistency-review.md | Spec統一性レビュー | 99 | 5 | spec-feature, spec-all, rule:post-impl-review |
| project-scale-thresholds.md | プロジェクト規模の閾値定義 | 27 | 4 | analyze-codebase, init-spec, add-repo |
| spec-coverage-review.md | 仕様カバレッジレビュー | 80 | 4 | detail-design, spec-all |
| coding-quality.md | コーディング品質ルール | 53 | 3 | review-standards, implement-spec, revise-spec |
| completion-checklist.md | 完了確認チェックリスト | 15 | 3 | domain-pm, task-decomposition-pattern, orchestrate |
| health-check.md | プロジェクトヘルスチェック | 58 | 3 | skill-auditor, finish-impl, rule:session-ops |
| loop-protocol.md | レビュー→修正ループ監視 | 86 | 3 | review-checklist, implement-spec, revise-spec |
| review-checklist.md | レビューチェックリスト | 43 | 3 | implement-spec, revise-spec, rule:post-impl-review |
| review-report.md | レビュー指摘レポート出力契約 | 33 | 3 | review-checklist, implement-spec, revise-spec |
| config-reference.md | Claude Code設定リファレンス | 210 | 2 | rule:claude-code-qa, rule:claude-code-config |
| design-priority.md | 設計書間の優先順位 | 22 | 2 | implement-spec, revise-spec |
| impact-report.md | 影響範囲レポート出力契約 | 55 | 2 | implement-spec, revise-spec |
| task-decomposition-pattern.md | タスク分解パターン | 83 | 2 | domain-pm, orchestrate |
| **session-recovery.md** | セッション復帰プロトコル | 74 | **0** | （孤立。tasks/session-state.md からのみ言及） |
| **skill-decision-tree.md** | スキル選択フローチャート | 103 | **0** | （孤立） |
| **skill-dependency-map.md** | スキル間の前提・成果物マップ | 91 | **0** | （孤立） |

### 孤立モジュール（どのスキル/ルールからも参照されない）: 3件
1. **session-recovery.md**（74行） — `tasks/session-state.md`（生成データ側）でのみ言及。スキル/ルール本文からの参照なし。
2. **skill-decision-tree.md**（103行） — 参照ゼロ。スキルルーティングは rule:skill-routing + handle が担当。
3. **skill-dependency-map.md**（91行） — 参照ゼロ。

---

## D. 設計書テンプレート棚卸し（phase1〜4：29本）

### D-1. 4フェーズ構成 全体図（テキスト）

```
┌─ phase1 : WHAT（要件・業務） 5本 ────────────────────────┐
│  requirements-spec.md  要件定義書   [REQ-ID] ← 機能ごと      │
│  usecase.md            ユースケース一覧                      │
│  screen-flow.md        画面一覧・遷移図                      │
│  business-flow.md      業務フロー図                          │
│  glossary.md           用語定義書                            │
└──────────────────────────┬───────────────────────────────┘
                           ▼
┌─ phase2 : HOW / 基本設計  12本 ─────────────────────────┐
│  system-architecture.md   システム構成図                    │
│  db-design.md             DB論理設計書                       │
│  api-spec.md              外部連携仕様書                     │
│  feature-design.md        画面・UI設計書   [REQ-ID] ← 機能ごと│
│  feature-logic.md         ロジック設計書   [REQ-ID] ← 機能ごと│
│  shared-components.md      共通コンポーネント一覧            │
│  non-functional.md        非機能要件定義書                   │
│  availability-design.md    可用性・スケーラビリティ設計書    │
│  performance-design.md     性能設計書                        │
│  operations-design.md      運用・保守設計書                  │
│  platform-integration.md   プラットフォーム間連携設計        │
│  report-design.md          帳票設計書                        │
└──────────────────────────┬───────────────────────────────┘
                           ▼
┌─ phase3 : 詳細設計  7本 ─────────────────────────────────┐
│  module-design.md      クラス/モジュール設計書 [REQ-ID]←機能ごと│
│  db-schema.md          テーブル定義書（物理設計）            │
│  error-codes.md        エラーコード定義書                    │
│  batch-design.md       バッチ設計書                          │
│  data-migration.md     データマイグレーション設計書          │
│  security-design.md    セキュリティ設計書                    │
│  security-ops.md       セキュリティ運用設計書                │
└──────────────────────────┬───────────────────────────────┘
                           ▼
┌─ phase4 : テスト  5本 ───────────────────────────────────┐
│  unit-test-spec.md         単体テスト仕様書 [REQ-ID]←機能ごと │
│  integration-test-spec.md  結合テスト仕様書                  │
│  system-test-spec.md       システムテスト仕様書              │
│  uat-spec.md               受入テスト仕様書（UAT）           │
│  test-report.md            テスト結果報告書                  │
└──────────────────────────────────────────────────────────┘
```

### D-2. テンプレート一覧・行数

| phase | テンプレート | 見出し | 行数 | 粒度 |
|:-----:|-------------|-------|-----:|------|
| 1 | requirements-spec.md | 要件定義書 | 66 | **機能ごと** |
| 1 | usecase.md | ユースケース一覧 | 163 | プロジェクト共通 |
| 1 | screen-flow.md | 画面一覧・遷移図 | 172 | プロジェクト共通 |
| 1 | business-flow.md | 業務フロー図 | 100 | プロジェクト共通 |
| 1 | glossary.md | 用語定義書 | 62 | プロジェクト共通 |
| 2 | system-architecture.md | システム構成図 | 130 | プロジェクト共通 |
| 2 | db-design.md | DB論理設計書 | 112 | プロジェクト共通 |
| 2 | api-spec.md | 外部連携仕様書 | 65 | プロジェクト共通 |
| 2 | feature-design.md | 画面・UI設計書 | 265 | **機能ごと** |
| 2 | feature-logic.md | ロジック設計書 | 225 | **機能ごと** |
| 2 | shared-components.md | 共通コンポーネント一覧 | 178 | プロジェクト共通 |
| 2 | non-functional.md | 非機能要件定義書 | 28 | プロジェクト共通 |
| 2 | availability-design.md | 可用性・スケーラビリティ | 57 | プロジェクト共通 |
| 2 | performance-design.md | 性能設計書 | 146 | プロジェクト共通 |
| 2 | operations-design.md | 運用・保守設計書 | 127 | プロジェクト共通 |
| 2 | platform-integration.md | プラットフォーム間連携 | 145 | プロジェクト共通 |
| 2 | report-design.md | 帳票設計書 | 105 | プロジェクト共通（帳票ごと） |
| 3 | module-design.md | クラス/モジュール設計書 | 184 | **機能ごと** |
| 3 | db-schema.md | テーブル定義書（物理） | 163 | プロジェクト共通 |
| 3 | error-codes.md | エラーコード定義書 | 202 | プロジェクト共通 |
| 3 | batch-design.md | バッチ設計書 | 149 | プロジェクト共通（バッチごと） |
| 3 | data-migration.md | データマイグレーション | 103 | プロジェクト共通 |
| 3 | security-design.md | セキュリティ設計書 | 160 | プロジェクト共通 |
| 3 | security-ops.md | セキュリティ運用設計書 | 210 | プロジェクト共通 |
| 4 | unit-test-spec.md | 単体テスト仕様書 | 136 | **機能ごと** |
| 4 | integration-test-spec.md | 結合テスト仕様書 | 151 | プロジェクト共通 |
| 4 | system-test-spec.md | システムテスト仕様書 | 174 | プロジェクト共通 |
| 4 | uat-spec.md | 受入テスト仕様書 | 141 | プロジェクト共通 |
| 4 | test-report.md | テスト結果報告書 | 174 | プロジェクト共通 |

phase別本数: **phase1=5 / phase2=12 / phase3=7 / phase4=5 = 計29本**

### D-3. 1機能あたり最大ドキュメント生成本数

「1つの機能（1 REQ-ID）」をフルに phase1→4 まで通した場合に生成されうるドキュメント本数:

- **機能ごとに1本生成される（[REQ-ID]付き）テンプレート: 5種**
  - requirements-spec / feature-design / feature-logic / module-design / unit-test-spec
- **その機能のために新規/追記されうるプロジェクト共通テンプレート: 最大24種**
  - phase1 共通4 + phase2 共通10 + phase3 共通6 + phase4 共通4

したがって単純合計の上限は **29本**（全テンプレートが1機能起因で生成/更新される最悪ケース）。

現実的な「1機能を新規に通すと生成される専用ドキュメント」= **約20本**:
- 機能専用（毎回新規）: 5本（requirements/feature-design/feature-logic/module-design/unit-test-spec）
- その機能で必ず触るプロジェクト共通の代表: usecase, screen-flow, glossary（phase1）＋ db-design, api-spec, shared-components（phase2）＋ db-schema, error-codes（phase3）＋ integration-test, system-test, uat, test-report（phase4）等 ≈ 15本前後
- 合計 **約20本**（機能専用5＋随伴共通約15）。上限は29本。

---

## 付記（実測との差分）

- タスク記載「_shared 30モジュール」→ 実測 **28**（`.claude/skills/_shared/*.md`）。
- タスク記載「テンプレート約30本」→ 実測 **29**。
- タスク記載「ルール25」→ 実測 **25**（一致）。
- タスク記載「スキル27」→ 実測 **27**（一致、`_shared` 除く）。
