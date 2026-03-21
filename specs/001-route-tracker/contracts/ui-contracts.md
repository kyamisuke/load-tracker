# UI Contracts: 経路トラッカー (Route Tracker)

**Date**: 2026-03-20

本アプリは外部 API を持たない（FR-006: ネットワーク通信禁止）ため、
インターフェース契約は UI 画面間の遷移とコンポーネント間のデータフローを定義する。

## Screen Map

```
App Launch
  ├── [初回] OnboardingSheet → MapScreen
  └── [通常] MapScreen
         ├── RecordingControls (overlay)
         ├── RouteOverlay (map layer)
         ├── StaySpotAnnotations (map layer)
         └── HistoryList (navigation)
              └── RouteDetailMap
```

## Screen Contracts

### 1. MapScreen (メイン画面)

**State variants**:

| State | Condition | Display |
|-------|-----------|---------|
| Empty | RouteRecord count == 0 | 現在地中心の地図 + CTA「記録を開始」+ オンボーディングシート |
| Idle | 記録停止中、過去データあり | 直近の経路表示 + 「記録を開始」ボタン |
| Recording | 記録中 | リアルタイム経路描画 + 記録中インジケータ + 「停止」ボタン |
| Interrupted | 前回中断あり | 中断通知バナー + 「再開」ボタン |

**RecordingControls**:
- Start: `() -> Void` — 記録開始。CLLocationManager 起動
- Stop: `() -> Void` — 記録停止。stoppedAt 設定
- Status: `RecordingState` enum { idle, recording, interrupted }

### 2. RouteOverlay (地図レイヤー)

**Input**: `[RoutePoint]` (時間範囲フィルタ済み)

**Rendering rules**:
- 通常精度 (horizontalAccuracy ≤ 65m): 実線、太さ 3pt、色: systemBlue
- 低精度 (horizontalAccuracy > 65m): 点線、太さ 2pt、色: systemGray (FR-009)
- LOD 切り替え: ズームスパンに応じて Douglas-Peucker 簡略化レベルを選択

### 3. StaySpotAnnotation (地図レイヤー)

**Input**: `[StaySpot]`

**Display**:
- マーカー: 円形アイコン（経路線と視覚的に区別）
- タップ時コールアウト: 滞在時間、到着時刻、出発時刻

### 4. HistoryList (履歴画面)

**Input**: `[RouteRecord]` sorted by startedAt DESC

**Row display**: 日付、開始-終了時刻、総距離、滞在スポット数

**Actions**:
- タップ: RouteDetailMap へ遷移
- スワイプ削除: 個別削除（確認なし、即座完全削除）
- 全削除: 確認ダイアログ → 全データ完全削除

### 5. RouteDetailMap (経路詳細画面)

**Input**: 単一 `RouteRecord` + その `points` + `staySpots`

**Display**: MapScreen と同一の描画ルールで単一経路を表示

**Controls**:
- 時間帯フィルタ: DatePicker で時間範囲を選択 → 該当ポイントのみ描画

## Service Layer Contracts

### LocationTrackingService (Protocol)

```
protocol LocationTrackingServiceProtocol {
    var state: RecordingState { get }
    var currentLocation: CLLocation? { get }
    func startRecording() async throws
    func stopRecording() async
}
```

### RouteDataService (Protocol)

```
protocol RouteDataServiceProtocol {
    func activeRecord() async -> RouteRecord?
    func allRecords() async -> [RouteRecord]
    func records(from: Date, to: Date) async -> [RouteRecord]
    func points(for: RouteRecord, from: Date?, to: Date?) async -> [RoutePoint]
    func staySpots(for: RouteRecord) async -> [StaySpot]
    func deleteRecord(_ record: RouteRecord) async
    func deleteAllRecords() async
    func performStorageCleanup() async
}
```

### StaySpotDetectionService (Protocol)

```
protocol StaySpotDetectionServiceProtocol {
    func detectSpots(in points: [RoutePoint]) -> [StaySpot]
    func updateOpenCluster(with point: RoutePoint) -> StaySpot?
}
```
