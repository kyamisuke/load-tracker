# Data Model: 経路トラッカー (Route Tracker)

**Feature Branch**: `001-route-tracker`
**Date**: 2026-03-20
**Storage**: SwiftData (SQLite + WAL)
**Protection**: NSFileProtectionCompleteUntilFirstUserAuthentication

## Entities

### RouteRecord

経路記録。1回の記録セッション（開始〜停止）に対応する。

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | UUID | 一意識別子 | PK, auto-generated |
| startedAt | Date | 記録開始時刻 | NOT NULL |
| stoppedAt | Date? | 記録停止時刻 | NULL = 記録中 |
| totalDistance | Double | 総移動距離（メートル） | >= 0, 記録中は随時更新 |
| isInterrupted | Bool | 強制終了等で中断されたか | default: false |

**Relationships**:
- `points`: [RoutePoint] — 1:N, cascade delete
- `staySpots`: [StaySpot] — 1:N, cascade delete

**State transitions**:
```
[Created] → recording (stoppedAt == nil)
         → stopped (stoppedAt != nil, isInterrupted == false)
         → interrupted (stoppedAt != nil, isInterrupted == true)
```

**Indexes**:
- `startedAt` DESC — 履歴一覧の日付順ソート
- `stoppedAt` — 記録中セッションの検索 (WHERE stoppedAt IS NULL)

---

### RoutePoint

個々の位置情報ポイント。

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | UUID | 一意識別子 | PK, auto-generated |
| latitude | Double | 緯度 | -90 ~ 90 |
| longitude | Double | 経度 | -180 ~ 180 |
| altitude | Double | 高度（メートル） | optional context |
| timestamp | Date | 記録時刻 | NOT NULL |
| horizontalAccuracy | Double | GPS水平精度（メートル） | >= 0 |
| speed | Double | 移動速度（m/s） | >= 0, -1 = 不明 |
| course | Double | 進行方向（度） | 0-360, -1 = 不明 |

**Relationships**:
- `record`: RouteRecord — N:1 (required)

**Indexes**:
- (`record.id`, `timestamp`) — 時間範囲クエリ用複合インデックス

**Notes**:
- バッチ書き込み: メモリに最大10ポイントバッファ → `ModelActor` 経由で一括保存
- 30秒タイマーによる安全フラッシュ

---

### StaySpot

滞在スポット。半径50m以内に5分以上滞在した場所。

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | UUID | 一意識別子 | PK, auto-generated |
| centerLatitude | Double | 中心緯度 | クラスタ重心 |
| centerLongitude | Double | 中心経度 | クラスタ重心 |
| arrivedAt | Date | 到着時刻 | NOT NULL |
| departedAt | Date? | 出発時刻 | NULL = 滞在中 |
| duration | TimeInterval | 滞在時間（秒） | >= 300 (5分) |

**Relationships**:
- `record`: RouteRecord — N:1 (required)

**Indexes**:
- (`record.id`, `arrivedAt`) — 経路表示時の滞在スポット取得用

**Detection rules** (from FR-003):
- 半径: 50m (`CLLocation.distance(from:)` による測定)
- 最小滞在時間: 300秒（5分）
- 重心計算: `mean(latitudes)`, `mean(longitudes)`

---

## Entity Relationship Diagram

```
RouteRecord (1) ──── (*) RoutePoint
     │
     └──── (*) StaySpot
```

## Storage Budget

- 1 RoutePoint ≈ 80 bytes (8 Double fields × 8 bytes + UUID + overhead)
- 6時間セッション（10秒間隔）≈ 2,160 points ≈ 170 KB
- 30日分 ≈ 5 MB（1日1セッション想定）
- StaySpot は少量（1セッションあたり数個〜十数個）
- **100MB 上限に対して十分な余裕あり**

## Data Lifecycle

1. **作成**: 記録開始時に RouteRecord 生成 → ポイント随時追加
2. **更新**: 記録中に totalDistance を随時更新、StaySpot を検出次第追加
3. **完了**: 記録停止時に stoppedAt を設定
4. **自動削除**: 30日以上経過した RouteRecord を cascade delete（FR-011）
5. **ストレージ管理**: 100MB 超過時、最古の RouteRecord から cascade delete（FR-011）
6. **手動削除**: ユーザーによる個別/全データ削除（FR-007）、即座に完全削除（ソフトデリートなし）
