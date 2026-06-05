# MCP 標準セットアップガイド（GitHub / データベース）

Claude Code から GitHub と データベースを構造化アクセスするための MCP サーバー設定手順。
`gh` コマンドや DB クライアントを Bash で叩く運用を MCP に置き換えることで、権限プロンプトを減らし、
PR 操作・検証クエリを安全かつ確実に実行できるようにする。

## 概要

Bash 経由の `gh` / `psql` / `mysql` には2つの課題がある:

- **権限プロンプトの多発** — Bash 実行のたびに承認が必要で、調査の流れが途切れる
- **出力の非構造化** — テキストをパースする必要があり、取りこぼし・誤読が起きる

MCP サーバーを使うと、これらが構造化ツール呼び出しに置き換わり、上記が両方解消する。
特に GitHub MCP は PR レビュー・Issue 操作の主力に、DB MCP は「テスト合格 ≠ 検証完了」の
原則（`.claude/CLAUDE.md` のエビデンス検証）を満たす実データ検証に有効。

## 前提条件

- Node.js 20 以上（`npx` を使用）
- GitHub MCP: GitHub の Personal Access Token（PAT）
- DB MCP: 接続先データベースの接続情報（**ローカル・開発環境のみ**。本番接続は禁止）

## GitHub MCP

プロジェクトルートの `.mcp.json` に追記する（既存サーバーがある場合は `mcpServers` に追加）:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
}
```

PAT はシェルの環境変数 `GITHUB_PERSONAL_ACCESS_TOKEN` から渡す。`.mcp.json` にトークンを直書きしないこと
（このファイルは git 管理対象になりうるため）。PAT には必要最小のスコープ（`repo`, `read:org` 等）のみ付与する。

### 使い方の例

```
このリポジトリのオープン PR を一覧して、レビュー観点ごとにコメントをまとめて
```

```
Issue #123 の内容を読んで、関連するコードを調べて
```

## データベース MCP（PostgreSQL / MySQL）

検証クエリ（EXPLAIN ANALYZE・件数突合・FK 整合性チェック等）を構造化実行するための設定。

### PostgreSQL

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "${DATABASE_URL}"]
    }
  }
}
```

### MySQL

MySQL は公式実装が分かれているため、利用するサーバーパッケージの README に従って `.mcp.json` を設定する。
接続情報は環境変数（`DATABASE_URL` 等）経由で渡し、直書きしない。

### 使い方の例

```
このクエリの実行計画を EXPLAIN ANALYZE で確認して、インデックスが効いているか見て
```

```
注文テーブルと請求テーブルの件数が一致しているか SQL で突合して
```

## 設定後の反映

`.mcp.json` を編集したら Claude Code を再起動する。再読み込み後、`mcp__github__*` /
`mcp__postgres__*` 等のツールが利用可能になる。

## トラブルシューティング

### ツールが出てこない

Claude Code を再起動して `.mcp.json` を再読み込みする。プロジェクトの MCP サーバーが有効化されているか確認する。

### 認証エラー（GitHub）

`GITHUB_PERSONAL_ACCESS_TOKEN` がシェルにエクスポートされているか、PAT が失効していないか、必要なスコープが付いているかを確認する。

## 注意事項

- **DB MCP は本番データベースに接続しないこと** — ローカル・開発環境の接続情報のみを使う。本番接続は `validate-command.sh` フックでもブロック対象
- 接続情報・トークンは `.mcp.json` に直書きせず、環境変数経由で渡す
- ツールの使用許可（コマンド承認）は各利用者の Claude Code 設定で管理する。プロジェクト共有設定やこのテンプレートには含めない
- MCP サーバーはサブエージェントに自動継承されない。サブエージェントで使う場合は明示的に設定が必要（`.claude/skills/_shared/config-reference.md` 参照）
