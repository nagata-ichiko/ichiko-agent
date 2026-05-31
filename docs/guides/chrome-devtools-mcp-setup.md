# Chrome DevTools MCP セットアップガイド

Claude Code から Chrome を直接操作し、画面の実機確認・UI 検証を自動化するための設定手順。

## 概要

Chrome DevTools MCP を設定すると、Claude Code がブラウザを起動して画面を操作・観察できるようになります。スクリーンショット撮影、DOM スナップショット取得、フォーム入力・クリック、ネットワークリクエストやコンソールログの確認などを通じて、実装した画面が意図通り動くかを AI 自身が確認できます。

`browse` スキル（agent-browser CLI）が「AI の目」としての軽量なブラウザ確認を担うのに対し、Chrome DevTools MCP は DevTools プロトコル経由でネットワーク・コンソール・パフォーマンスまで踏み込んだ検証に向きます。

## 前提条件

- Node.js 20 以上（`npx` を使用）
- Google Chrome がインストール済み

認証やビルドは不要です。`npx` が初回起動時に `chrome-devtools-mcp` を自動取得します。

## .mcp.json の設定

プロジェクトルートの `.mcp.json` に `chrome-devtools` サーバーを追記します（既存サーバーがある場合は `mcpServers` に追加）:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest"]
    }
  }
}
```

設定後、Claude Code を再起動すると `.mcp.json` が再読み込みされ、`mcp__chrome-devtools__*` ツールが利用可能になります。

## Claude Code での使い方

設定が完了すれば、セッション内で以下のように使えます:

```
ログイン画面を開いて、フォーム送信が成功するか確認して
```

```
予約一覧画面のネットワークリクエストとコンソールエラーを確認して
```

Claude が自動的に Chrome を起動し、画面操作・観察を行って結果を報告します。

## トラブルシューティング

### MCP サーバーが起動しない / ツールが出てこない

Claude Code を再起動すると `.mcp.json` が再読み込みされます。プロジェクトの MCP サーバーが有効化されているかも確認してください。

### Chrome が見つからない

Google Chrome がインストールされ、起動可能な状態か確認してください。

## 注意事項

- ブラウザ操作は実際の画面に対して行われるため、本番環境には接続しないこと
- ツールの使用許可（コマンド承認）は各利用者の Claude Code 設定で管理する。プロジェクト共有設定やこのテンプレートには含めない
