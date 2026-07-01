# M2: 新ハーネス設計（Loop Engineering + Grill Me）

**作成日**: 2026-07-01 / **対象**: ichiko-agent 再設計 / **前提**: [Issue #1](https://github.com/nagata-ichiko/ichiko-agent/issues/1)
**確定方針**: 設計書は軽量1枚に統合 / 既存互換に縛られずクリーン作り直し / 今回は設計確定まで
**根拠**: `harness-inventory.md`（現状: スキル27・ルール25・_shared 28・テンプレ29）/ `yamasaki-issues-summary.md`（実ログ課題）

---

## 1. 開発ライフサイクル（5フェーズ）

```
1. Grill  … AIがユーザーを問い詰め、要件・制約・ゴールを引き出す
              └ 曖昧語・対義語ペア（受入/差入等）・スコープを潰す。出力=要件カード草案
2. Sketch … 画面/モックを実際に作って見せ、イメージを合わせる（ループの核）
              └ Artifact でUIモック生成→ユーザー反応→修正。認識一致まで反復
3. Fix    … 要件カード（1枚）に受入基準・ゴール・スコープ外・未決を確定
              └ ここが唯一の「確定ゲート」。以降はゴールが動かない
4. Plan   … ゴールをタスク分解しマイルストーン化（goal-board.md）
              └ 依存順・完了判定・各マイルストーンの受入基準を明示
5. Loop   … 封筒の中で自律実装。マイルストーンごとに build→test→self-review→commit
              └ 境界越え時のみ確認。M完了ごとに進捗報告、必要なら Grill/Sketch へ戻る
```

**旧との違い**: 旧は phase1→4 で最大20本の設計書を前段生成してから実装（BDUF）。新は「確定は要件カード1枚だけ」、詳細設計はコードとテストが真実、モックで認識合わせ、実装は自律ループ。

---

## 2. 新ドキュメントフォーマット（29本 → 3種）

### 2-1. 要件カード `spec-card.md`（1機能=1枚、旧 requirements-spec + feature-design + feature-logic を代替）
```markdown
# [SPEC-xxx] 機能名
## 目的        … なぜ作るか（1-2行）
## ユーザーストーリー … 誰が / 何を / なぜ（箇条書き）
## 受入基準    … Given-When-Then 形式。これがテストの元ネタになる
## スコープ外  … やらないこと（明示）
## 未決        … Grillで潰しきれなかった論点（あれば）
## モック      … Sketchで作ったArtifactへのリンク
## メモ        … 対義語ペア・実装状態など、取り違え防止の1行注記
```

### 2-2. ゴールボード `goal-board.md`（生きたドキュメント、旧 impl-plan + orchestrate分解を代替）
```markdown
# ゴール: <一文で>
## 受入基準（ゴール到達の判定）
## マイルストーン
- [ ] M1: <名前> — 完了判定: <条件> — 状態: 未着手/進行/完了
  - [ ] タスク1.1
  - [ ] タスク1.2
## 現在地 / ブロッカー / 次アクション
```

### 2-3. モック（Artifact）
Sketch フェーズで HTML/画面モックを Artifact 生成。認識すり合わせの主役。ファイルではなくArtifactとして保持。

### 補助（最小限だけ残す）
- `docs/domain-knowledge/`（軽量）— 用語・対義語・実装状態マトリクス。tides の文脈取り違え対策。**2回調べた知識はここへ**。
- OpenAPI（任意）— API契約が重要なプロジェクトのみ、生きた契約として。フェーズには含めない。

**廃止**: phase2-4 テンプレート約24本（system-architecture / db-design / feature-design / module-design / db-schema / error-codes / batch-design / security-design / 各種test-spec 等）。詳細はコード＋テスト＋（必要なら）ADR的な短いメモで代替。

---

## 3. ターゲット・スキル構成（27 → 10コア + 数ユーティリティ）

| 新スキル | 役割 | 統合元（旧スキル） |
|---|---|---|
| **grill** | 要件ヒアリング（AI主導の問い詰め）→ 要件カード | draft-spec + spec-feature の要件抽出部 |
| **mock** | UIモック生成（Sketch、イメージ合わせ） | 新規（Artifact活用）+ apply-design の見た目部 |
| **plan** | ゴール+マイルストーン+タスク分解 | impl-plan運用 + orchestrate/domain-pm 分解部 |
| **build** | 自律実装ループ（実装+テスト+自己レビュー、封筒内） | implement-spec + revise-spec + hotfix + apply-design + gen-tests + orchestrate 実行部 |
| **map** | 既存コード理解（軽量overview、オンデマンド） | init-spec + analyze-codebase + spec-feature/spec-all の分析部 |
| **browse** | 画面確認（AIの目） | browse（維持） |
| **review-pr** | PRレビュー | review-pr（維持・簡素化） |
| **skill-auditor** | メタ監査 | skill-auditor（維持） |
| **sync-template / feedback-template** | テンプレ同期（pull/push） | 維持（ichiko-agent宛に既変更済み） |
| **handle** | 受け皿ルーター | handle（維持・簡素化） |
| ユーティリティ | drawio / notebook-query | オンデマンド維持 |

**廃止（役割がコードとテストに移る/重複解消）**: detail-design, update-docs, spec-all, add-repo, gen-test-specs, gen-test-report, review-mark, docs-serve, orchestrate/domain-pm の3層PM儀式。

> **確定（2026-07-01）**: orchestrate（SuperPM→ドメインPM→PG の3層PM）を**廃止**。build が必要時に parallel-work に従って自らエージェントを fan-out する方式に一本化する。domain-pm / pm-orchestration / async-teams も廃止。

---

## 4. ターゲット・ルール構成（25 / 常時9本≈199行 → 約7 / 常時2-3本）

| 新ルール | ロード | 役割 | 統合元 |
|---|---|---|---|
| **principles.md** | 常時（短く） | 行動原則・スキルルーティング・委任・スコープ確認・出力方針・**自律の封筒の既定** | agent-delegation + skill-routing + scope-confirm + long-output + environment-preflight + post-impl-review の要点 |
| **security.md** | 常時+paths（厚い） | **自律の封筒の一線**（外部ネット/データ送出/不可逆破壊）+ 機密保護 + フック/settings改変禁止 | security（拡張） |
| **autonomous-mode.md** | build/loop時 | 自律実行規律（スコープ分割・逐次commit・ポーリング禁止・チェックポイント・境界越え確認） | 新規（実ログ課題ISSUE-01〜07の対策） |
| **git-workflow.md** | .git/.github時 | 履歴改変は**自動バックアップ→実行**（force-push摩擦を消す） | git-workflow + release-and-branching（拡張） |
| **testing.md** | tests時 | テスト＝仕様（受入基準→テスト）。件数は機械取得 | testing（スリム化） |
| **implementation.md** | src時 | コーディング規約（スリム化） | implementation + coding-quality |
| **parallel-work.md** | 並列時 | worktree分離・fan-out・取りまとめ（自己検証必須） | parallel-work + agent-delegation の委任規約 |
| （任意paths） | 各領域 | supabase.md / i18n.md | 維持（プロジェクト依存） |

**廃止/吸収**: claude-code-qa, parallel-work-trigger, github-issues, spec-management, review-mark, design-handoff, doc-accuracy, pm-orchestration, async-teams, session-ops の重い部分 → principles / autonomous-mode / security へ要点だけ吸収。

---

## 5. _shared クリーンアップ（28 → 約10）

- **削除（孤立3）**: session-recovery, skill-decision-tree, skill-dependency-map（参照0）
- **削除（重いSpec体系依存）**: spec-writing-standard, spec-unified-base, spec-map-operations, spec-consistency-review, spec-coverage-review, doc-integrity-check の重い部分, screen-transition-diagram（重い設計書用）
- **維持**: code-search-2stage, error-recovery, tech-stack-guide, finish-impl, review-standards, review-checklist, health-check, subagent-task-format, task-decomposition-pattern, project-scale-thresholds

---

## 6. 自律の封筒（M4実装の予告・設計確定分）

- **封筒の中（聞かない）**: 自リポ・自マシンに閉じ可逆な操作。force-push は自動バックアップ後に実行。
- **一線（確認必須）**: ①外部ホストへの能動アクセス（顧客/社内ネット・本番・ポートスキャン・外部DB）②データ外部送出 ③バックアップ無き不可逆破壊。
- **実装（M4）**: security.md 書き換え / settings.json deny（hooks・settings改変、プライベートIP通信）/ validate-command.sh（force-push→自動backup、外部ネット検出）。

---

## 7. 変更規模まとめ

| | 現状 | 目標 | 削減 |
|---|---:|---:|---:|
| スキル | 27 | 〜10 + 数ユーティリティ | 約6割減 |
| ルール | 25（常時9・199行） | 〜7（常時2-3） | 常時ロード7割減 |
| _shared | 28 | 〜10 | 約6割減 |
| 設計書テンプレ | 29 | 3種 + 任意 | 約9割減 |
| 1機能あたり生成文書 | 最大約20本 | 要件カード1 + ゴールボード1 + モック | 約9割減 |

---

## 8. 確定した判断（2026-07-01）

1. **orchestrate 3層PM を廃止** → build に一本化（build が parallel-work に従い自らfan-out）。domain-pm / pm-orchestration / async-teams も廃止。
2. **mkdocs / docs-serve を手放す** → 要件カード・ゴールボードは Markdown 直読み、モックは Artifact で閲覧。docs-serve スキル・mkdocs関連（mkdocs.yml / overrides / stylesheets / javascripts）を廃止対象に。
3. **map（既存コード理解）は overview 1枚に留める**（逆生成の大量Spec化はしない）。
4. **handle は新5フェーズへのルーターとして再定義**（Grill/Sketch/Plan/Build へ振り分け）。

## 9. M3以降の残タスク（実装）

- M3: スキル/ルール/_shared/テンプレートの統合・削除・新規作成（本設計に沿って）
- M4: 自律の封筒の実装（security.md / settings.json deny / validate-command.sh）
- M5: ドッグフーディング（新ハーネスで小機能を1本通す）
