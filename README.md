# あしあと

「昨日どこいったっけ？」

バックグラウンドで経路を自動記録し、翌朝地図で振り返ることができるiOSアプリ。

## Features

- **バックグラウンド自動記録** — 記録を始めたらスマホをしまうだけ。GPSで経路を自動追跡
- **立ち寄りスポット検出** — 一定時間滞在した場所を自動で検出・表示
- **履歴の振り返り** — 記録した経路を地図上で確認。時間帯フィルタで絞り込み可能
- **速度適応型精度** — 歩行・走行・車両などの速度帯に応じてGPS精度を自動調整し、バッテリー消費を最適化
- **オフライン・プライベート** — データは端末内のみに保存。外部送信なし

## Tech Stack

- Swift 5.9+
- SwiftUI / MapKit / CoreLocation
- SwiftData (永続化)
- Swift Testing (テスト)

## Requirements

- iOS 17.0+
- Xcode 16.0+

## Build

```bash
xcodebuild -project load-tracker.xcodeproj -scheme load-tracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Test

```bash
xcodebuild -project load-tracker.xcodeproj -scheme load-tracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Project Structure

```
load-tracker/
  Design/          # デザイントークン (色・フォント・スペーシング・アニメーション)
  Models/          # SwiftData モデル (RouteRecord, RoutePoint, StaySpot)
  Services/        # ロケーション追跡・データ永続化・立ち寄り検出
  Views/           # SwiftUI 画面 (マップ・履歴・オンボーディング・記録コントロール)
  Utilities/       # ユーティリティ (Douglas-Peucker 間引きアルゴリズム等)
  Resources/       # フォント (Nunito, Noto Sans JP)
```

## Design

ダークテーマ + アンバーアクセント。「深夜の街灯」をイメージしたウォームなダークパレット。

デザイン定義書: `docs/re-design/ashiato-design-spec.docx`

## License

Private
