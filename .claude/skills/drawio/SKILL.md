---
name: drawio
description: Always use when user asks to create, generate, draw, or design a diagram, flowchart, architecture diagram, ER diagram, sequence diagram, class diagram, network diagram, or mentions draw.io, drawio, .drawio files. Use for complex diagrams where Mermaid is insufficient.
---

# Draw.io Diagram Skill

draw.io の `.drawio` ファイルを生成する。生成したファイルは draw.io アプリ／VSCode の Draw.io Integration 拡張で開いて閲覧・編集し、PNG/SVG にエクスポートして参照する。
Mermaid では表現しにくい複雑なアーキテクチャ図・詳細ダイアグラムに使用する。

## Mermaid vs draw.io 使い分け基準

| 用途 | ツール | 理由 |
|------|--------|------|
| シンプルなフロー・シーケンス図 | Mermaid | テキストベースで差分追跡しやすい |
| 複雑なアーキテクチャ図 | draw.io | レイアウト自由度・アイコン豊富 |
| ER図（テーブル少数） | Mermaid | 簡潔に書ける |
| ER図（テーブル多数・リレーション複雑） | draw.io | 配置の自由度が必要 |
| ネットワーク構成図・インフラ図 | draw.io | AWS/GCP等のアイコンが使える |
| 画面遷移図（多数ページ） | draw.io | 配置の自由度が必要 |

## 図の作成手順

1. **draw.io XML を生成** -- mxGraphModel 形式
2. **Write ツールで `.drawio` ファイルを書き出す**
3. **draw.io アプリ／VSCode の Draw.io Integration 拡張で開く** -- 閲覧・編集する
4. **PNG/SVG にエクスポート** -- ドキュメントや資料に貼り込む場合は draw.io からエクスポートした画像を参照する

## ファイル配置・命名規則

- **配置先**: 関連する成果物と同じディレクトリ、または `docs/images/` 配下
- **命名**: `[内容]-[種別].drawio`（例: `aws-architecture.drawio`, `order-flow-detail.drawio`）
- **小文字ハイフン区切り**

## XML 基本構造

```xml
<mxGraphModel adaptiveColors="auto">
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <!-- ここに図の要素を配置。parent="1" -->
  </root>
</mxGraphModel>
```

## CRITICAL: XML ルール

- XML コメント (`<!-- -->`) は**絶対に含めない**
- 特殊文字はエスケープ: `&amp;`, `&lt;`, `&gt;`, `&quot;`
- 全ての `mxCell` に一意の `id` を付与
- `id="0"`（ルート）と `id="1"`（デフォルトレイヤー、parent="0"）は必須
- **Edge には必ず子要素として `<mxGeometry relative="1" as="geometry" />` を含める**（自己閉じタグの edge は描画されない）
- **エッジラベルに HTML を使う場合は `html=1;` をスタイルに必ず含める**（ないと `<font>` タグが生テキストで表示される）

## CRITICAL: z-order（描画順）ルール

XML の記述順で前面/背面が決まる（後に書いたものが前面）。以下の順序を厳守:

1. **グループ/コンテナ**（背面 — 枠線・背景のみ）
2. **エッジ（矢印・接続線）**（中間）
3. **アイコン・テキストラベル**（前面 — 最も手前）

アイコンが矢印の裏に隠れると接続関係が見えなくなるため、**アイコンは必ずエッジの後に定義する**。

### アイコンは parent="1" で絶対座標にする

グループの子にするとグループと同じ z-order 層になり、エッジより背面に描画される。
アイコンをエッジより前面に出すには、**parent="1"（ルート直下）に配置し絶対座標を使う**:

```xml
<!-- 1. グループ（背面） -->
<mxCell id="vpc" value="VPC" style="swimlane;..." vertex="1" parent="1">
  <mxGeometry x="50" y="100" width="600" height="400" as="geometry"/>
</mxCell>

<!-- 2. エッジ（中間） -->
<mxCell id="e1" edge="1" parent="1" source="ec2" target="rds" style="...">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>

<!-- 3. アイコン（前面、絶対座標で配置） -->
<mxCell id="ec2" value="EC2" style="shape=mxgraph.aws4.fargate;..." vertex="1" parent="1">
  <mxGeometry x="70" y="160" width="40" height="40" as="geometry"/>
</mxCell>
```

## レイアウト・重なり禁止ルール

詳細なレイアウト設計原則・グリッドベース配置・重なり禁止ルールは [references/layout-rules.md](references/layout-rules.md) を参照。

## AWS アイコン・スタイル

詳細なAWSアイコン・カラー定義は [references/aws-icons.md](references/aws-icons.md) を参照。

## コンテナ・エッジ・スタイルプロパティ

詳細なコンテナ・エッジ・ダークモード・エクスポートは [references/style-reference.md](references/style-reference.md) を参照。

## XML リファレンス

詳細なスタイル・レイアウトリファレンス: https://github.com/jgraph/drawio-mcp/blob/main/shared/xml-reference.md
