# Quickstart: 経路トラッカー (Route Tracker)

**Feature Branch**: `001-route-tracker`
**Date**: 2026-03-20

## Prerequisites

- macOS with Xcode 15+
- iOS 17.0+ device (シミュレータではバックグラウンド位置情報テストに制限あり)
- Apple Developer account (実機テスト用)

## Project Setup

```bash
# リポジトリのクローン
git clone <repo-url>
cd load-tracker
git checkout 001-route-tracker

# Xcode でプロジェクトを開く
open LoadTracker.xcodeproj  # or .xcworkspace
```

## Xcode Configuration

### 1. Signing & Capabilities

- **Background Modes** を追加し、"Location updates" にチェック
- **Data Protection** を追加 (CompleteUntilFirstUserAuthentication)

### 2. Info.plist

以下のキーを追加:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>移動経路を記録するために位置情報を使用します</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>バックグラウンドで経路を継続記録するために位置情報の常時使用を許可してください</string>
```

### 3. Target Settings

- Deployment Target: iOS 17.0
- Swift Language Version: 5.9

## Architecture Overview

```
LoadTracker/
├── App/
│   └── LoadTrackerApp.swift        # @main, ModelContainer setup
├── Models/
│   ├── RouteRecord.swift           # @Model
│   ├── RoutePoint.swift            # @Model
│   └── StaySpot.swift              # @Model
├── Services/
│   ├── LocationTrackingService.swift  # CLLocationManager + async stream
│   ├── RouteDataService.swift         # SwiftData CRUD via ModelActor
│   └── StaySpotDetectionService.swift # Sliding anchor algorithm
├── Views/
│   ├── MapScreen.swift             # メイン画面 (SwiftUI)
│   ├── MapViewRepresentable.swift  # MKMapView wrapper
│   ├── RecordingControls.swift     # 開始/停止 UI
│   ├── HistoryList.swift           # 履歴一覧
│   └── RouteDetailMap.swift        # 経路詳細
├── Utilities/
│   └── DouglasPeucker.swift        # ポリライン簡略化
└── Tests/
    ├── StaySpotDetectionTests.swift
    ├── RouteDataServiceTests.swift
    └── DouglasPeuckerTests.swift
```

## Build & Run

```bash
# コマンドラインビルド (optional)
xcodebuild -scheme LoadTracker -destination 'platform=iOS,name=<device-name>' build

# テスト実行
xcodebuild -scheme LoadTracker -destination 'platform=iOS Simulator,name=iPhone 16' test
```

実機テストを推奨: バックグラウンド位置情報、バッテリー消費、GPS精度はシミュレータでは正確に検証できない。

## Verification Checklist

- [ ] アプリ起動後、位置情報権限を求められる
- [ ] 「記録を開始」で記録開始 → ステータスインジケータ表示
- [ ] アプリをバックグラウンドにしても青い位置情報バーが表示される
- [ ] 数分歩いた後、アプリに戻ると経路が地図上に描画されている
- [ ] 履歴画面で過去の経路を確認・削除できる
- [ ] ネットワーク通信が一切発生しない（機内モードで全機能動作）
