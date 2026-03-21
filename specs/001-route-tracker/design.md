# Design Document: 経路トラッカー (Route Tracker)

**Branch**: `001-route-tracker`
**Date**: 2026-03-20
**Source**: `specs/001-route-tracker/spec.md`
**Status**: Draft

## Architecture Overview

本アプリは iOS 17+ の SwiftUI ベースモバイルアプリケーションで、飲酒中の移動経路をバックグラウンドで自動記録し、地図上で確認できるようにする。アーキテクチャは3層構成を採用する:

```
┌─────────────────────────────────────────────┐
│  Views Layer (SwiftUI)                      │
│  MapScreen / RecordingControls / HistoryList│
│  MapViewRepresentable (UIViewRepresentable) │
├─────────────────────────────────────────────┤
│  Services Layer (Protocol-based)            │
│  LocationTrackingService                    │
│  RouteDataService (ModelActor)              │
│  StaySpotDetectionService                   │
├─────────────────────────────────────────────┤
│  Models Layer (SwiftData @Model)            │
│  RouteRecord / RoutePoint / StaySpot        │
└─────────────────────────────────────────────┘
         ↓                    ↓
   CoreLocation          SwiftData (SQLite)
   (CLLocationManager)   NSFileProtection
```

**主要な設計方針**:
- Services 層は Protocol で抽象化し、テスト時にモック差し替え可能（Constitution IV: Testable Architecture）
- すべてのデータはローカル SQLite に保存し、ネットワーク通信は一切行わない（Constitution I: Privacy-First）
- CLLocationManager が位置情報取得のメインループを担当し、速度帯に応じて精度を動的調整（Constitution II: Battery-Conscious）
- Apple 標準フレームワークのみ使用（Constitution III: Platform-Native）

## Data Model

data-model.md で定義された3エンティティを SwiftData `@Model` として実装する。

### RouteRecord (経路記録)

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | UUID | 一意識別子 | PK, auto-generated |
| startedAt | Date | 記録開始時刻 | NOT NULL |
| stoppedAt | Date? | 記録停止時刻 | NULL = 記録中 |
| totalDistance | Double | 総移動距離（メートル） | >= 0 |
| isInterrupted | Bool | 強制終了等で中断されたか | default: false |

**Relationships**: points: [RoutePoint] (1:N, cascade delete), staySpots: [StaySpot] (1:N, cascade delete)

**State transitions**: Created → recording (stoppedAt == nil) → stopped / interrupted

### RoutePoint (経路ポイント)

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | UUID | 一意識別子 | PK, auto-generated |
| latitude | Double | 緯度 | -90 ~ 90 |
| longitude | Double | 経度 | -180 ~ 180 |
| altitude | Double | 高度（メートル） | — |
| timestamp | Date | 記録時刻 | NOT NULL |
| horizontalAccuracy | Double | GPS水平精度（メートル） | >= 0 |
| speed | Double | 移動速度（m/s） | >= 0, -1 = 不明 |
| course | Double | 進行方向（度） | 0-360, -1 = 不明 |

**Relationship**: record: RouteRecord (N:1, required)
**Index**: (record.id, timestamp) — 時間範囲クエリ用

### StaySpot (滞在スポット)

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | UUID | 一意識別子 | PK, auto-generated |
| centerLatitude | Double | 中心緯度 | クラスタ重心 |
| centerLongitude | Double | 中心経度 | クラスタ重心 |
| arrivedAt | Date | 到着時刻 | NOT NULL |
| departedAt | Date? | 出発時刻 | NULL = 滞在中 |
| duration | TimeInterval | 滞在時間（秒） | >= 300 |

**Relationship**: record: RouteRecord (N:1, required)

### ER Diagram

```
RouteRecord (1) ──── (*) RoutePoint
     │
     └──── (*) StaySpot
```

## Component Breakdown

### Component: LocationTrackingService

**責務**: CoreLocation を使用したバックグラウンド位置情報の取得・管理。速度帯に応じた精度の動的調整。強制終了後の再起動検知。
**担当要件**: FR-001, FR-008, FR-010
**入力**: ユーザーからの記録開始/停止指示、CLLocation イベント
**出力**: RoutePoint データ（RouteDataService 経由で永続化）、RecordingState の変更通知

**内部構成**:
- CLLocationManager (delegate): メインの位置取得ループ、desiredAccuracy/distanceFilter の動的切り替え、significant changes 監視
- CLLocationUpdate.liveUpdates(.fitness): isStationary による静止検出の補助
- 速度帯デバウンス: CLLocation.speed を3回連続で監視し、閾値超過で設定変更
- メモリバッファ: 最大10ポイントをバッファリングし、RouteDataService にバッチ送信。30秒タイマーで安全フラッシュ

### Component: RouteDataService

**責務**: SwiftData を使用した経路データの CRUD 操作。ModelActor によるバックグラウンドスレッドセーフ書き込み。ストレージ管理（自動削除）。
**担当要件**: FR-005, FR-006, FR-006a, FR-007, FR-011
**入力**: RoutePoint バッチ、削除リクエスト、ストレージクリーンアップトリガー
**出力**: RouteRecord / RoutePoint / StaySpot のクエリ結果

**内部構成**:
- ModelActor: バックグラウンドスレッドで SwiftData 書き込みを担当
- @MainActor ModelContext: UI 側の @Query 読み取りを担当
- ストレージクリーンアップ: アプリ起動時に30日超過データ削除、100MB超過時に古い順から削除

### Component: StaySpotDetectionService

**責務**: 経路ポイントから滞在スポットを自動検出する。スライディングアンカーポイントアルゴリズムにより O(n) で処理。
**担当要件**: FR-003
**入力**: [RoutePoint]（時系列順）
**出力**: [StaySpot]

**内部構成**:
- アンカーポイント: 最初の未処理ポイントを起点とし、50m以内のポイントをクラスタリング
- 検出条件: クラスタ経過時間 >= 5分で StaySpot を生成
- 処理モード: インクリメンタル後処理（~60秒ごと）+ リアルタイム仮検出（オープンクラスタ維持）

### Component: MapViewRepresentable + RouteOverlayRenderer

**責務**: MKMapView を SwiftUI にブリッジし、経路ポリラインと滞在スポットアノテーションを描画。Douglas-Peucker 簡略化による LOD レンダリング。
**担当要件**: FR-002, FR-004, FR-009
**入力**: [RoutePoint]、[StaySpot]、ズームレベル
**出力**: 地図上の視覚的描画

**内部構成**:
- DouglasPeucker: 3段階の LOD（全詳細 / ε~5m / ε~30m）をプリコンピュート
- RouteOverlayRenderer: horizontalAccuracy に基づく実線/点線切り替え（FR-009）
- StaySpotAnnotation: タップ時にコールアウト表示（滞在時間・到着/出発時刻）
- regionDidChangeAnimated でズームレベルに応じた LOD 切り替え

### Component: RecordingControls

**責務**: 記録の開始/停止 UI と記録状態のステータス表示。初回起動時のオンボーディング。
**担当要件**: FR-001a, FR-001b
**入力**: ユーザータップ、RecordingState
**出力**: LocationTrackingService への開始/停止指示

**画面状態**: Empty（CTA + オンボーディング）、Idle（開始ボタン）、Recording（停止ボタン + インジケータ）、Interrupted（中断通知 + 再開ボタン）

### Component: HistoryList + RouteDetailMap

**責務**: 経路履歴の一覧表示、個別/全削除、日付・時間帯フィルタによる経路詳細表示。
**担当要件**: FR-002a, FR-007
**入力**: RouteDataService からの [RouteRecord]、ユーザーのフィルタ/削除操作
**出力**: 選択された RouteRecord の詳細表示、削除リクエスト

## Design Decisions

### DD-001: CLLocationManager ハイブリッドアプローチによるバックグラウンド位置記録

**対応要件**: FR-001, FR-008, FR-010
**決定**: CLLocationManager (delegate) をメインの位置取得ループとし、CLLocationUpdate.liveUpdates(.fitness) を静止検出の補助として併用する。significant changes 監視は強制終了後の再起動検知に常時使用する。省電力モードは UIDevice.current.batteryLevel を監視し、20% 以下で全速度帯の distanceFilter を 2 倍に延長する。UIDevice.batteryLevelDidChangeNotification で閾値の上下を検知し、動的に切り替える。
**根拠**: FR-010 の速度帯別ルール（4段階の desiredAccuracy/distanceFilter）は CLLocationManager の直接制御でのみ実現可能。liveUpdates() のプリセットでは粒度が不足する。一方、liveUpdates() の isStationary プロパティは静止検出に有用であり、delegate パターンの補助として併用する。バッテリー監視は UIDevice の標準 API で実現でき、追加の依存なく省電力モードを実装可能。
**代替案**: liveUpdates() 単独（精度制御の粒度不足で却下）、CLLocationManager delegate 単独（動作するが isStationary の利便性を失う）

### DD-002: SwiftData + ModelActor によるローカルデータ永続化

**対応要件**: FR-005, FR-006, FR-006a
**決定**: SwiftData (SQLite + WAL) を使用し、ModelActor でバックグラウンドスレッドセーフな書き込みを実現する。NSFileProtectionCompleteUntilFirstUserAuthentication でデータを暗号化保護する。ネットワーク通信コードは一切含まない。
**根拠**: SwiftData は iOS 17+ の標準 ORM で @Query による SwiftUI 統合が優れている。ModelActor により CLLocationManager のバックグラウンドスレッドからのスレッドセーフ書き込みが可能。CompleteUntilFirstUserAuthentication は端末ロック中もバックグラウンド書き込みを許容しつつ、再起動時の暗号化保護を提供する。
**代替案**: Core Data（冗長、@Query 統合なし）、GRDB（サードパーティ依存）、ファイルベース（クエリ性能不足）

### DD-003: MKMapView (UIViewRepresentable) + Douglas-Peucker LOD による経路描画

**対応要件**: FR-002, FR-004, FR-009
**決定**: MKMapView を UIViewRepresentable でラップし、カスタム MKPolylineRenderer で GPS 精度に応じた実線/点線の描き分けを行う。Douglas-Peucker アルゴリズムで3段階の LOD をプリコンピュートし、ズームレベルに応じて切り替える。滞在スポットは MKAnnotation として円形マーカーで強調表示し、経路線とは視覚的に区別する（FR-004）。
**根拠**: SwiftUI Map ビューはオーバーレイのカスタマイズ（点線スタイル、LOD 切り替えデリゲート、カスタムアノテーション）が不十分。MKMapView は regionDidChangeAnimated で LOD 切り替えトリガーを取得可能。Douglas-Peucker は SC-007（2秒以内の描画）を達成するために必要。
**代替案**: SwiftUI Map 単独（カスタマイズ不足）、Mapbox（サードパーティ依存・コスト）、Metal レンダリング（工数過大）

### DD-004: スライディングアンカーポイントアルゴリズムによる滞在検出

**対応要件**: FR-003
**決定**: 時間窓付きスライディングアンカーポイントアルゴリズムで滞在スポットを検出する。アンカーから50m以内のポイントをクラスタリングし、経過時間 >= 5分で StaySpot を生成。重心を mean(lat), mean(lon) で算出。
**根拠**: O(n) の時間計算量で時系列データの時間制約を自然に扱える。DBSCAN は時間制約の組み込みが困難で O(n log n)。50m 規模では球面歪みが無視可能なため、算術平均で十分な精度の重心が得られる。
**代替案**: DBSCAN（時間制約不自然、チューニング必要）、ジオハッシュ（境界分割問題）、K-means（k 未知）

### DD-005: SwiftUI ベースの記録制御 UI と状態管理

**対応要件**: FR-001a, FR-001b
**決定**: RecordingControls を SwiftUI View として実装し、RecordingState enum（idle / recording / interrupted）で状態を管理する。初回起動時は OnboardingSheet を表示し、CTA「記録を開始」で即座に記録開始可能にする（SC-006: 30秒以内）。
**根拠**: 状態バリアント（Empty / Idle / Recording / Interrupted）を enum で明示的に管理することで、UI の網羅性を保証する。EC-006（強制終了後の中断通知）と EC-007（初回起動オンボーディング）をこの状態管理に統合する。
**代替案**: なし（SwiftUI View は Constitution III の要件）

### DD-006: 時間範囲クエリによる履歴フィルタリングと完全削除

**対応要件**: FR-002a, FR-007
**決定**: RouteDataService が (record.id, timestamp) 複合インデックスを使用して時間範囲クエリを実行する。削除は cascade delete で RouteRecord → RoutePoint / StaySpot を即座に完全削除（ソフトデリートなし）。全データ削除時は確認ダイアログを表示。
**根拠**: 複合インデックスにより、特定セッション内の時間範囲フィルタリングが効率的に実行可能。ソフトデリートは Constitution I（Privacy-First）に反するため、物理削除のみとする。
**代替案**: なし（インデックス設計とハードデリートは要件から直接導出）

### DD-007: 時間ベース + 容量ベースの自動ストレージ管理

**対応要件**: FR-011
**決定**: アプリ起動時に (1) 30日以上経過した RouteRecord を cascade delete、(2) ストレージ使用量が100MBを超える場合は最古の RouteRecord から順に cascade delete する。
**根拠**: 二重の削除トリガー（時間ベース + 容量ベース）により、通常利用では30日ルールで管理し、異常に大量のデータが生成された場合は容量ルールでセーフティネットを提供する。ストレージ見積り（30日分 ≈ 5MB）から通常利用では容量ルールに到達しない。
**代替案**: 古いデータの解像度低減（実装複雑、削除の方がシンプル）

## Traceability Matrix

| FR | DD | Component |
|----|----|-----------|
| FR-001 | DD-001 | LocationTrackingService |
| FR-001a | DD-005 | RecordingControls |
| FR-001b | DD-005 | RecordingControls |
| FR-002 | DD-003 | MapViewRepresentable + RouteOverlayRenderer |
| FR-002a | DD-006 | HistoryList + RouteDetailMap |
| FR-003 | DD-004 | StaySpotDetectionService |
| FR-004 | DD-003 | MapViewRepresentable (StaySpotAnnotation) |
| FR-005 | DD-002 | RouteDataService |
| FR-006 | DD-002 | RouteDataService |
| FR-006a | DD-002 | RouteDataService |
| FR-007 | DD-006 | HistoryList + RouteDataService |
| FR-008 | DD-001 | LocationTrackingService |
| FR-009 | DD-003 | RouteOverlayRenderer |
| FR-010 | DD-001 | LocationTrackingService |
| FR-011 | DD-007 | RouteDataService |

**カバレッジ**: 15/15 = 100%

## Technical Constraints & Assumptions

### 技術的制約 (plan.md より)
- **プラットフォーム**: iOS 17.0+, Swift 5.9+, Xcode 15+
- **フレームワーク**: SwiftUI, MapKit, CoreLocation, SwiftData のみ（サードパーティ依存なし）
- **ストレージ**: SwiftData (SQLite + WAL), 100MB 上限, NSFileProtectionCompleteUntilFirstUserAuthentication
- **ネットワーク**: 一切なし。機内モードで全機能動作
- **パフォーマンス**: 6h 経路描画 ≤ 2秒, バッテリー 6h ≤ 15%

### 前提条件 (spec.md より)
- ユーザーが位置情報の「常に許可」権限を付与する
- ユーザーは外出時に iPhone を携帯している
- 滞在スポット検出閾値はデフォルト5分（将来的に調整可能の余地あり）
- データ保持期間はデフォルト30日

### v1 スコープ外
- クラウド同期・バックアップ
- データエクスポート（GPX 等）
- 他ユーザーとの共有・ソーシャル機能
- Apple Watch 対応
- マルチデバイス間のデータ同期

### SwiftData フォールバック戦略 (plan.md より)
- ModelActor のバッチ書き込みで1時間あたり10回以上のエラー、またはメモリ使用量が100MBを超えて増加し続ける場合、Core Data への切り替えを検討
- RouteDataServiceProtocol により切り替えコストを最小化
