# Implementation Plan: 経路トラッカー (Route Tracker)

**Branch**: `001-route-tracker` | **Date**: 2026-03-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-route-tracker/spec.md`

## Summary

飲酒中の移動経路を自動的にバックグラウンドで記録し、地図上で確認できる iOS アプリ。CoreLocation の `CLLocationUpdate.liveUpdates()` (iOS 17+) でバッテリー効率の良い連続記録を実現し、SwiftData でローカルに永続化。MapKit (MKMapView) で Douglas-Peucker 簡略化による高速経路描画、スライディングアンカーアルゴリズムで滞在スポットを自動検出する。すべてのデータはローカルのみ、ネットワーク通信なし。

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, MapKit, CoreLocation, SwiftData
**Storage**: SwiftData (SQLite + WAL), NSFileProtectionCompleteUntilFirstUserAuthentication
**Testing**: XCTest
**Target Platform**: iOS 17.0+
**Project Type**: mobile-app
**Performance Goals**: 6h経路データの地図描画 ≤ 2秒 (SC-007), バッテリー6h ≤ 15% (SC-004)
**Constraints**: オフライン専用, ストレージ ≤ 100MB, サードパーティ依存なし
**Scale/Scope**: 単一ユーザー, 30日分データ保持, 5画面

### CoreLocation API 責任分界

本アプリは2つの CoreLocation API をハイブリッドで使用する。責任を以下のように分離する:

| API | 責任 | ライフサイクル |
|-----|------|--------------|
| **CLLocationManager** (delegate) | FR-010 の速度帯別 `desiredAccuracy`/`distanceFilter` 動的切り替え、`startMonitoringSignificantLocationChanges()` による強制終了後の再起動検知 | アプリ起動時に初期化、アプリ終了まで保持 |
| **CLLocationUpdate.liveUpdates(.fitness)** | `isStationary` による静止検出、ライフサイクル管理（async stream の開始/終了で記録セッションを制御） | 記録開始〜停止の間のみアクティブ |

**連携パターン**: CLLocationManager が位置情報取得のメインループを担当し、速度帯変更時に `desiredAccuracy`/`distanceFilter` を動的に再設定する。`liveUpdates()` は補助的に使用し、`isStationary` プロパティで静止検出を簡易化する。significant changes 監視は CLLocationManager が常時担当し、強制終了後の `application(_:didFinishLaunchingWithOptions:)` で `.location` キーを検出して中断通知を表示する。

### SwiftData フォールバック戦略

SwiftData (iOS 17+) は比較的新しいフレームワークのため、以下のリスク軽減策を設ける:

- **ストレステスト**: 実装フェーズで6時間相当のデータ連続挿入テスト（~2,160回の save()）を実施し、メモリリーク・コンテキスト同期遅延・WAL ファイル肥大化を検証する
- **フォールバック判断基準**: 以下のいずれかに該当する場合、Core Data への切り替えを検討する
  - ModelActor 経由のバッチ書き込みで1時間あたり10回以上のクラッシュまたはエラーが発生
  - メモリ使用量が100MBを超えて増加し続ける（リーク）
  - `@Query` の UI 更新レイテンシが500msを超える
- **切り替えコスト最小化**: Service Protocol 層（RouteDataServiceProtocol）により、SwiftData 実装と Core Data 実装を差し替え可能。Models/ 層の `@Model` を `NSManagedObject` サブクラスに書き換えるのみ

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy-First | ✅ PASS | ローカルのみ (FR-005/006), 暗号化 (FR-006a), 完全削除 (FR-007) |
| II. Battery-Conscious | ✅ PASS | 動的頻度調整 (FR-010), 15%/6h 目標 (SC-004) |
| III. Platform-Native | ✅ PASS | SwiftUI + MapKit + CoreLocation + SwiftData, サードパーティなし |
| IV. Testable Architecture | ✅ PASS | Protocol ベースサービス層, ModelActor による分離 |
| V. Simplicity | ✅ PASS | 5画面, 単一ユーザー, Out of Scope 明確 |

**Post-Phase 1 Re-check**:

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy-First | ✅ PASS | データモデルにソフトデリートなし、外部通信なし |
| II. Battery-Conscious | ✅ PASS | 速度帯別 desiredAccuracy/distanceFilter テーブル定義済み |
| III. Platform-Native | ✅ PASS | MKMapView (UIViewRepresentable) は SwiftUI Map の機能不足を補うために必要 |
| IV. Testable Architecture | ✅ PASS | 3つの Protocol 定義済み (contracts/ui-contracts.md) |
| V. Simplicity | ✅ PASS | Douglas-Peucker は SC-007 達成に必要な最小限の複雑さ |

## Project Structure

### Documentation (this feature)

```text
specs/001-route-tracker/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── ui-contracts.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
LoadTracker/
├── App/
│   └── LoadTrackerApp.swift           # @main, ModelContainer setup
├── Models/
│   ├── RouteRecord.swift              # @Model entity
│   ├── RoutePoint.swift               # @Model entity
│   └── StaySpot.swift                 # @Model entity
├── Services/
│   ├── Protocols/
│   │   ├── LocationTrackingServiceProtocol.swift
│   │   ├── RouteDataServiceProtocol.swift
│   │   └── StaySpotDetectionServiceProtocol.swift
│   ├── LocationTrackingService.swift  # CLLocationManager (メイン精度制御) + liveUpdates (静止検出)
│   ├── RouteDataService.swift         # SwiftData CRUD via ModelActor
│   └── StaySpotDetectionService.swift # Sliding anchor algorithm
├── Views/
│   ├── MapScreen.swift                # メイン画面
│   ├── MapViewRepresentable.swift     # MKMapView wrapper (UIViewRepresentable)
│   ├── RouteOverlayRenderer.swift     # カスタム MKPolylineRenderer
│   ├── RecordingControls.swift        # 開始/停止 overlay
│   ├── OnboardingSheet.swift          # 初回起動オンボーディング
│   ├── HistoryList.swift              # 履歴一覧
│   └── RouteDetailMap.swift           # 経路詳細
└── Utilities/
    └── DouglasPeucker.swift           # ポリライン簡略化アルゴリズム

LoadTrackerTests/
├── LocationTrackingServiceTests.swift  # 速度帯切り替え、バッファフラッシュ、省電力モード
├── StaySpotDetectionTests.swift
├── RouteDataServiceTests.swift
├── RouteDataServiceStressTests.swift   # 6h相当の連続挿入ストレステスト
├── DouglasPeuckerTests.swift
└── StorageCleanupTests.swift
```

**Structure Decision**: iOS 単体アプリ（API サーバーなし）。標準的な iOS プロジェクト構成（Models / Services / Views / Utilities）を採用。Services 層は Protocol で抽象化し、テスト時にモック差し替え可能。

## Complexity Tracking

> No constitution violations detected. Table intentionally left empty.

<!-- sdr:design-decisions-start -->
## Design Decisions Summary (from design.md)

> このセクションは `/sdr:spec-to-design` により自動生成されました。
> 詳細は design.md を参照してください。

| DD | 対応FR | 設計判断 |
|----|--------|---------|
| DD-001 | FR-001, FR-008, FR-010 | CLLocationManager ハイブリッドアプローチによるバックグラウンド位置記録 |
| DD-002 | FR-005, FR-006, FR-006a | SwiftData + ModelActor によるローカルデータ永続化 |
| DD-003 | FR-002, FR-004, FR-009 | MKMapView (UIViewRepresentable) + Douglas-Peucker LOD による経路描画 |
| DD-004 | FR-003 | スライディングアンカーポイントアルゴリズムによる滞在検出 |
| DD-005 | FR-001a, FR-001b | SwiftUI ベースの記録制御 UI と状態管理 |
| DD-006 | FR-002a, FR-007 | 時間範囲クエリによる履歴フィルタリングと完全削除 |
| DD-007 | FR-011 | 時間ベース + 容量ベースの自動ストレージ管理 |
<!-- sdr:design-decisions-end -->
