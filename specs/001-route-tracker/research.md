# Research: 経路トラッカー (Route Tracker)

**Feature Branch**: `001-route-tracker`
**Date**: 2026-03-20

## 1. iOS バックグラウンド位置情報トラッキング

### Decision
`CLLocationUpdate.liveUpdates(.fitness)` (iOS 17+ async stream API) を主要トラッキング手段とし、`startMonitoringSignificantLocationChanges()` を強制終了後の再起動フォールバックとして併用する。

### Rationale
- `liveUpdates()` は Swift concurrency と自然に統合され、delegate パターンより簡潔
- `.fitness` プリセットが歩行経路記録に最適化されている
- `CLLocationUpdate.isStationary` プロパティで静止検出が簡易化
- 動的な精度調整（FR-010 の速度帯別ルール）には `CLLocationManager` の `desiredAccuracy`/`distanceFilter` の直接制御が必要なため、ハイブリッドアプローチを採用
- `startMonitoringSignificantLocationChanges()` は強制終了後にアプリを再起動できる唯一の手段（セルタワー変更ベース、~500m精度）

### Alternatives Considered
| Alternative | Why Rejected |
|---|---|
| `startMonitoringSignificantLocationChanges()` のみ | ~500m精度では歩行経路の描画に不十分 |
| CLLocationManager delegate パターンのみ | 動作するが async stream の方がコードが簡潔。ただし精度制御のフォールバックとして保持 |
| CLMonitor (iOS 17+ ジオフェンス) | イベントベース（enter/exit）で連続記録に不適 |

## 2. バックグラウンド実行設定

### Decision
Background Modes: Location updates を有効化し、"Always" 位置情報権限を要求する。

### Rationale
- Xcode Signing & Capabilities で "Background Modes" → "Location updates" を有効化（`UIBackgroundModes` に `location` を追加）
- Info.plist に以下の3キーが必要:
  - `NSLocationWhenInUseUsageDescription`
  - `NSLocationAlwaysAndWhenInUseUsageDescription`
- `allowsBackgroundLocationUpdates = true` + `showsBackgroundLocationIndicator = true` を設定
- 権限フロー: `requestWhenInUseAuthorization()` → `requestAlwaysAuthorization()`（iOS 13+ は provisional Always を付与し、後日確認プロンプトを表示）

### Alternatives Considered
| Alternative | Why Rejected |
|---|---|
| When In Use のみ | 長時間セッションで更新が停止される可能性がある |
| BGTaskScheduler | 連続位置記録ではなく定期的短時間タスク向け |

## 3. バッテリー最適化戦略

### Decision
`desiredAccuracy`、`distanceFilter`、`activityType` を移動速度に応じて動的に切り替える。`pausesLocationUpdatesAutomatically = true` で静止時の自動一時停止を有効化。

### Rationale
速度帯ごとの設定（FR-010 対応）:

| 速度帯 | desiredAccuracy | distanceFilter | 実効間隔 |
|--------|----------------|----------------|----------|
| 静止時 (< 1 km/h) | NearestTenMeters | 50m | ~60秒 |
| 歩行 (1-6 km/h) | Best (~5m) | 5m | ~10秒 |
| 走行/自転車 (6-30 km/h) | Best | 10m | ~5秒 |
| 車両/電車 (> 30 km/h) | NearestTenMeters | 30m | ~30秒 |
| バッテリー ≤ 20% | 上記各値を2倍 | 上記各値を2倍 | 上記各値を2倍 |

- `activityType = .fitness` で歩行パターンに最適化
- `CLLocation.speed` を監視し、3回連続で閾値を超えたら設定変更（デバウンス）
- `CMMotionActivityManager` を補助信号として活用可能（歩行/運転/静止の分類）

### Alternatives Considered
| Alternative | Why Rejected |
|---|---|
| `allowDeferredLocationUpdates` | iOS 13 で非推奨 |
| 静止時に Significant Location Changes に切り替え | GPS 再取得にレイテンシがあり移動開始を見逃す可能性 |

## 4. 強制終了時の挙動

### Decision
強制終了を受け入れ、`startMonitoringSignificantLocationChanges()` を再起動ヒントとして使用。ただし自動再開はせず、次回起動時にユーザーに通知する。

### Rationale
- スワイプキルで `startUpdatingLocation()` セッションは即座に終了。回避不可
- `startMonitoringSignificantLocationChanges()` は終了後もセルタワー変更でアプリを再起動可能
- ただし: 再起動まで数分〜の遅延、~500m移動が必要、データギャップは回復不可
- EC-006 の方針に従い: 記録停止 → データ保持 → 次回起動時に中断通知 → 再開促進
- `applicationWillTerminate` でバッファデータを即座にフラッシュ

### Alternatives Considered
| Alternative | Why Rejected |
|---|---|
| サイレント自動再開 | 侵入的、App Store 審査リスク |
| プッシュ通知での復帰 | サーバー必要（Out of Scope） |

## 5. データ永続化戦略

### Decision
SwiftData (SQLite + WAL) でバッチ書き込み（10ポイントまたは30秒ごと）。`ModelActor` でバックグラウンドスレッドセーフな書き込みを実現。

### Rationale
- SwiftData は SQLite + WAL モードを使用（クラッシュセーフ、読み書き非ブロック）
- `ModelActor`（iOS 17+）で専用バックグラウンドコンテキストを作成し、スレッドセーフを確保
- メイン `@ModelContext`（`@MainActor`）は UI 読み取り用
- バッファ: メモリに最大10ポイント → バッチ書き込み。30秒タイマーで安全フラッシュ
- **データ保護**: `NSFileProtectionCompleteUntilFirstUserAuthentication`（端末ロック中もバックグラウンド書き込み可能）
- 6時間セッションで約3,000〜15,000ポイント（FR-010 の間隔設定による）

### Alternatives Considered
| Alternative | Why Rejected |
|---|---|
| Core Data | SwiftData より冗長。`@Query` による SwiftUI 統合がない |
| SQLite 直接 (GRDB) | サードパーティ依存。SwiftData で十分な規模 |
| ファイルベース (JSON/GPX) | 時間範囲クエリが遅い、インデックスなし、個別削除が困難 |

## 6. MapKit ポリライン描画パフォーマンス

### Decision
`MKMapView`（UIKit）を `UIViewRepresentable` でラップ。Douglas-Peucker 簡略化 + LOD（Level of Detail）レンダリングを採用。

### Rationale
- SwiftUI `Map` ビューはオーバーレイカスタマイズが不十分（FR-009 の点線表示、LOD 切り替え）
- MKPolyline は 10,000+ ポイントで性能低下 → 簡略化が必須（SC-007: 2秒以内）
- LOD 戦略（プリコンピュート）:
  - Level 0（全詳細）: 全ポイント。ズームスパン < ~500m
  - Level 1（中）: ε ~5m。近隣レベル
  - Level 2（粗）: ε ~30m。市街地レベル以上
- 経路をセグメント分割（時間帯/移動状態ごと）し、個別 `MKPolyline` オーバーレイとして追加
- カスタム `MKPolylineRenderer` で GPS 精度に応じたスタイル変更（実線/点線）

### Alternatives Considered
| Alternative | Why Rejected |
|---|---|
| SwiftUI Map のみ | オーバーレイカスタマイズ不足、LOD 制御デリゲートなし |
| Mapbox | サードパーティ依存、コスト、オフライン要件と相性悪い |
| Metal カスタムレンダリング | 工数過大。MKMapView + 簡略化で SC-007 達成可能 |

## 7. 滞在スポット検出アルゴリズム

### Decision
時間窓付きスライディングアンカーポイントアルゴリズム。インクリメンタル後処理 + リアルタイム仮検出のハイブリッド。

### Rationale
- FR-003: 半径50m、滞在5分以上
- アルゴリズム:
  1. 最初の未処理ポイントをアンカーに設定
  2. 後続ポイントとの距離を `CLLocation.distance(from:)` で計算
  3. ≤ 50m → クラスタに追加、続行
  4. > 50m → クラスタの経過時間チェック（≥ 5分なら StaySpot を生成）
  5. 重心計算: `mean(latitudes)`, `mean(longitudes)`（50m規模では球面歪み無視可能）
- O(n) 時間計算量、DBSCAN より単純で時間制約を自然に扱える
- 処理モード:
  - **インクリメンタル後処理**: ~60秒ごとまたはフォアグラウンド復帰時に新規ポイントを処理
  - **リアルタイム仮検出**: メモリ上の「現在のオープンクラスタ」を維持。5分超過で仮 StaySpot を UI に表示
  - **履歴データ**: 過去経路表示時にフル検出 → SwiftData に StaySpot エンティティとしてキャッシュ

### Alternatives Considered
| Alternative | Why Rejected |
|---|---|
| DBSCAN | 時間制約を自然に扱えない、minPts チューニング必要、O(n log n) |
| ジオハッシュグリッド | セル境界での分割問題。50m半径と固定グリッドの相性悪い |
| K-means | k（クラスタ数）が事前に不明 |
