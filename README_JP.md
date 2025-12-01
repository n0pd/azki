# Azki - シンプルで素敵な Windows用 SKK+AZIK IME

[![License: MIT/Apache-2.0](https://img.shields.io/badge/License-MIT%2FApache--2.0-blue.svg)](LICENSE.md)

Azki は、**プロセス分離モデル (Process Isolation Model)** を採用した、Windows 用の SKK + AZIK 入力メソッドエディタ (IME) です。\
フロントエンドは Zig で書かれた軽量な TSF ラッパー DLL であり、バックエンドはすべての変換ロジック、辞書検索、候補 UI の描画を処理する Rust 製の実行ファイルで構成されています。

## 特徴 (Features)

  - **AZIK 入力メソッド**: 効率的な日本語入力のための拡張ローマ字レイアウト。
  - **SKK 変換**: SKK 辞書および Mozc 連携を使用した文脈変換。
  - **プロセス分離**: フロントエンド DLL が COM/TSF インターフェースと IPC を処理し、バックエンド EXE がすべてのビジネスロジックを管理します。
  - **名前付きパイプ IPC**: フロントエンドとバックエンド間の効率的な通信。
  - **Mozc 連携**: Google Mozc を活用した高度な変換機能。

## はじめに (Getting Started)

> [!IMPORTANT]
> このプロジェクトは**開発中**であり、まだ実運用には適していません。\
> 詳細なアーキテクチャとコンポーネントの仕様については、[Docs/Spec.md](https://www.google.com/search?q=Docs/Spec.md) を参照してください。

## ディレクトリ構成

```
Azki/
  frontend_dll/     # Zig - TSFラッパー, IPCクライアント
    src/main.zig, tsf.zig, ipc.zig
  backend_core/     # Rust - コアロジック, 辞書, GUI
    src/main.rs, ipc.rs, azik.rs, skk.rs, dict/, gui/
  proto/            # mozc_commands.proto
  assets/           # SKK-JISYO.L 辞書ファイル
```

## ビルドと開発

  - Zig フロントエンド: `frontend_dll/` ディレクトリで `zig build`
  - Rust バックエンド: `backend_core/` ディレクトリで `cargo build`
  - DLL の登録: `regsvr32 Azki.dll` (管理者権限が必要)

## ライセンス (Azki License)

本プロジェクトは、MIT ライセンスおよび Apache-2.0 ライセンスの下で提供されています。

### MIT License

[MIT ライセンスの全文はこちら](https://www.google.com/search?q=./LICENSE-MIT)

### Apache-2.0 License

[Apache-2.0 ライセンスの全文はこちら](https://www.google.com/search?q=./LICENSE-APACHE)

### デュアルライセンスについて

本プロジェクトは、MIT ライセンスと Apache-2.0 ライセンスのデュアルライセンスです。利用者は、どちらかのライセンスを選択して、本プロジェクトを使用、変更、配布することができます。

本プロジェクトを使用または配布する際は、選択したライセンスの条件に従う必要があります。Apache-2.0 ライセンスを選択した場合は、通知や貢献に関する追加要件にも従う必要があります。\
本プロジェクトを使用することで、利用者は自身が選択したライセンス（MIT または Apache-2.0）の規約を受け入れたことになります。\
各ライセンスの条件の詳細については、それぞれのライセンス全文を参照してください。

### ライセンスの概要

  - **MIT License**: 非常に寛容なライセンスです。ライセンス条項と著作権表示を含める限り、プロプライエタリソフトウェア（クローズドソース）内での再利用も許可されます。
  - **Apache-2.0 License**: 寛容なライセンスですが、貢献者からユーザーへの特許権の付与も明示されています。ライセンス条項と通知の保存が必要であり、貢献と商標に関する特定の条件が含まれます。

本プロジェクトを使用または貢献する前に、両方のライセンスを読み、理解していることを確認してください。\
ライセンスに関するご質問は、プロジェクトのメンテナーまでお問い合わせください。

#### なぜデュアルライセンスなのか？

MIT と Apache-2.0 のデュアルライセンスを採用することで、ユーザーと貢献者に柔軟性を提供します。\
MIT ライセンスはシンプルで寛容であるため、開発者が自身のプロジェクト（プロプライエタリなものを含む）にコードを統合しやすくなります。\
一方で、Apache-2.0 ライセンスは、特に特許に関する保護を提供しており、大規模なプロジェクトや商用環境において重要となります。\
両方のライセンスを提供することで、Azki はユーザーがニーズに合ったものを選択できるようにしつつ、プロジェクトのオープン性とアクセシビリティを維持します。

## 貢献について (Contributing)

貢献を歓迎します！バグ修正や機能強化のための Issue や Pull Request をお待ちしています。
ガイドラインについては [CONTRIBUTING.md](./CONTRIBUTING.md) を参照してください。