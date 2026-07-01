---
description: セキュリティ関連の操作時（機密ファイル、認証情報、設定、デプロイ）
paths:
  - ".env*"
  - "**/*.pem"
  - "**/*.key"
  - "**/*credentials*"
  - "**/*secret*"
  - "**/deploy*"
  - "**/Dockerfile*"
  - "**/.ssh/**"
  - ".claude/settings*.json"
  - ".claude/hooks/**"
---

# セキュリティルール

## 絶対禁止事項
- `git push --force` / `git push -f` / `git push --force-with-lease` の実行（deny ルールでブロック済み）
- `git reset --hard` の実行（deny ルールでブロック済み）
- `rm -rf` の実行（deny ルールでブロック済み）
- `sudo` の実行（deny ルールでブロック済み）
- `chmod 777` / `chmod -R 777` の実行（deny ルールでブロック済み）
- `.env`、秘密鍵（`.pem`/`.key`）、クレデンシャルファイルの読み取り（deny ルールでブロック済み）
- `curl`/`wget` による外部通信（deny ルールでブロック済み）
- 本番環境への直接接続（hooks でブロック済み）
- **ガードレール自体の無効化（自己防衛・hooks でブロック済み）**: `--no-verify` によるフック迂回 / `git config core.hooksPath` の変更 / `.claude/hooks`・`.claude/settings*.json` の Bash 経由改変（`rm`/`sed -i`/`truncate`/`mv`/`tee`/リダイレクト）/ `.claude/hooks` への `chmod`。ガードレールの変更は**人間が Edit/Write でレビュー可能な形で**行う（`principles.md` §11「絶対禁止」）

## セキュリティ設定の構成（settings.json）

### deny と hook の役割分担

| 層 | 役割 | 特徴 | 対象コマンド |
|---|---|---|---|
| **deny ルール** | 汎用的な破壊的コマンドのブロック | allow で上書き不可。パターンマッチでブロック | `rm -rf`, `sudo`, `git push --force`, `git reset --hard`, `curl`, `wget`, `chmod 777` |
| **PreToolUse hook** | コンテキスト依存の検出 | コマンド全体を解析し、意図を判定 | 本番接続パターン, 機密変数出力, SSH/SCP, Docker特権, 危険なgit履歴改変, base64データ持ち出し |
**設計原則:** deny は「このコマンド自体を許可しない」、hook は「このコマンドの使い方が危険」を検出する。deny で防げない文脈依存の危険パターン（例: 正当な `ssh` の使い方 vs 本番への直接接続）を hook が補完する。

### deny ルール（最優先・allow で上書き不可）
deny → ask → allow の順で評価される。deny に入れたコマンドは「Always allow」を連打しても実行されない。

### サンドボックス
- `sandbox.enabled: true` — Bash コマンドを OS レベルで隔離
- `sandbox.enableWeakerNetworkIsolation: true` — macOS の TLS 証明書検証サービスへのアクセスを許可（`gh` 等のキーチェーン認証に必要）
- サンドボックスでブロックされた場合、Claude Code がユーザーに `dangerouslyDisableSandbox` の許可を求める（コマンド単位で判断可能）
- セキュリティを厳格にしたいユーザーは `settings.local.json` で個別に `permissions.allow` を追加して対応する

### PreToolUse フック
`.claude/hooks/validate-command.sh` が Bash コマンド実行前に以下を検出・**hard-block（exit 2）**：
- 本番環境接続パターン
- 機密環境変数の出力
- SSH/SCP コマンド
- Docker 特権モード
- ルートディレクトリ配下への再帰的 chmod
- 危険な git 履歴改変（filter-branch、rebase --onto 等）
- base64 エンコードによるデータ持ち出し
- **自己防衛（絶対禁止）**: `--no-verify` / `core.hooksPath` 変更 / `.claude/hooks`・`settings` の Bash 改変 / hooks への `chmod`

さらに**自律の封筒の「一線」を非ブロック警告（exit 0 + stderr）**で提示する（実行は止めず、Claude は principles §11 に従い実行前に確認する）：
- 一線①外部アクセス: ポートスキャン（nmap/nc/telnet）・外部DB接続（host 指定の psql/mysql/mongo/redis-cli）
- 一線②データ外部送出: rsync remote / `npm publish` / `aws s3 cp|sync` / `gh release` 等
- 一線③不可逆破壊: `git clean -f` / `dd of=` / `shred` / `mkfs` / `truncate -s`

> 設計判断: 「一線」は §11 で「確認必須」であり禁止ではないため、hard-block せず警告に留める（誤ブロックで正当な開発を妨げない）。「絶対禁止」（ガードレール無効化）のみ hard-block する。

加えて `.claude/hooks/show-git-context.sh` が git の状態変更操作（commit/push/branch切替/merge/PR作成）の直前に作業ディレクトリ・ブランチ・リポジトリ名を非ブロッキングで表示し、リポジトリ取り違え・ベースブランチ誤りを防ぐ（ブロックはしない。情報提示のみ）。

## 運用ルール
- `/permissions` で月1回、権限設定を棚卸しする
- 不要な allow ルールが蓄積していないか確認する
- hooks スクリプトの変更時はチームレビュー必須

## チーム開発時の追加設定
組織ポリシーを強制する場合は Managed Settings を使用：
- `allowManagedPermissionRulesOnly: true` — ユーザー独自の allow/deny を無効化
- `allowManagedHooksOnly: true` — 管理者許可の hooks のみ有効
- `allowManagedMcpServersOnly: true` — 管理者許可の MCP サーバーのみ有効
