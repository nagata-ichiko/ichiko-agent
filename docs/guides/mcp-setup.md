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

> **導入判断（重要）:** 単発・たまの GitHub 操作（push、PR を1本作る等）は `gh` CLI で足りる。
> MCP が元を取るのは、**会話の流れの中で PR / Issue / DB を繰り返し構造化アクセスする運用**に
> なってから。`gh` CLI と GitHub MCP を漫然と両方持つのは、同じ仕事の経路が重複し
> 「ツールが多すぎる」状態を招く。必要になってから入れ、不要なら入れない。

> **注意:** MCP エコシステムは変化が速い。本ガイドの設定値は導入時点で各サーバーの公式 README を
> 必ず確認すること。かつて広く使われた `@modelcontextprotocol/server-github` /
> `@modelcontextprotocol/server-postgres`（npm）は**廃止済み**で、以下が現行の推奨構成。

## 前提条件

- GitHub MCP（リモート型）: GitHub アカウント（OAuth）または Personal Access Token（PAT）
- GitHub MCP（ローカル型）/ DB MCP: Docker
- DB の接続情報は **ローカル・開発環境のみ**（本番接続は禁止）

## GitHub MCP（推奨: リモートホスト型）

GitHub 公式が提供するリモート MCP サーバーを使う。ローカルに Docker やバイナリを置く必要がなく、
URL を指すだけで使える。プロジェクトルートの `.mcp.json` に追記する:

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_PAT}"
      }
    }
  }
}
```

- `GITHUB_PAT` はシェルの環境変数から渡す。`.mcp.json` にトークンを直書きしないこと（git 管理対象になりうる）
- PAT には必要最小のスコープ（`repo`, `read:org` 等）のみ付与する
- 読み取り専用に限定したい場合は URL を `https://api.githubcopilot.com/mcp/readonly` にする
- クライアントが OAuth に対応していれば PAT なしのワンクリック認証も可能（対応状況はクライアント側に依存）

### ローカル Docker 型（代替）

オフラインや自前管理が必要な場合は、公式 Docker イメージ `ghcr.io/github/github-mcp-server` を
stdio で起動する構成も使える。詳細は [github/github-mcp-server](https://github.com/github/github-mcp-server) の README を参照。

### 使い方の例

```
このリポジトリのオープン PR を一覧して、レビュー観点ごとにコメントをまとめて
```

```
Issue #123 の内容を読んで、関連するコードを調べて
```

## データベース MCP（PostgreSQL）

検証クエリ（EXPLAIN ANALYZE・件数突合・FK 整合性チェック等）を構造化実行するための設定。
ここでは保守が継続している `crystaldba/postgres-mcp`（Postgres MCP Pro）を例にする。

### Docker（推奨）

```json
{
  "mcpServers": {
    "postgres": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "DATABASE_URI",
        "crystaldba/postgres-mcp",
        "--access-mode=restricted"
      ],
      "env": {
        "DATABASE_URI": "postgresql://user:password@localhost:5432/dbname"
      }
    }
  }
}
```

- `--access-mode=restricted` で**読み取り専用トランザクション**に制限される。検証用途では必ずこれを指定する
- Docker は macOS/Windows で `localhost` を自動的に `host.docker.internal` に解決する
- 接続情報は `DATABASE_URI` 環境変数経由で渡し、直書きしない

### pipx / uv 版（Docker を使わない場合）

```json
{
  "mcpServers": {
    "postgres": {
      "command": "postgres-mcp",
      "args": ["--access-mode=restricted"],
      "env": {
        "DATABASE_URI": "postgresql://user:password@localhost:5432/dbname"
      }
    }
  }
}
```

### MySQL を使う場合

MySQL は公式の単一実装がないため、利用するサーバーパッケージの README に従って設定する。
接続情報は環境変数経由で渡し、読み取り専用モードがあれば必ず有効にする。

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

`GITHUB_PAT` がシェルにエクスポートされているか、PAT が失効していないか、必要なスコープが付いているかを確認する。

### 接続エラー（DB）

`DATABASE_URI` のホスト名を確認する。Docker 版では `localhost` ではなく `host.docker.internal` が必要なケースがある。

## 注意事項

- **DB MCP は本番データベースに接続しないこと** — ローカル・開発環境の接続情報のみを使う。本番接続は `validate-command.sh` フックでもブロック対象
- 接続情報・トークンは `.mcp.json` に直書きせず、環境変数経由で渡す
- ツールの使用許可（コマンド承認）は各利用者の Claude Code 設定で管理する。プロジェクト共有設定やこのテンプレートには含めない
- MCP サーバーはサブエージェントに自動継承されない。サブエージェントで使う場合は明示的に設定が必要（`.claude/skills/_shared/config-reference.md` 参照）
