# Architecture Review Report

**対象**: `specs/001-route-tracker/plan.md`
**日時**: 2026-03-20
**ステータス**: Approved

## スコアサマリー

| 評価次元 | スコア (1-5) | 指摘数 |
|----------|:-----------:|:------:|
| 技術選定の合理性 (TR) | 5 | 1 |
| 内部整合性 (IC) | 5 | 0 |
| スケール適合性 (SF) | 5 | 0 |
| リスク評価 (RA) | 4 | 3 |
| **総合** | **4.75** | **4** |

## 関連アーティファクト

| ファイル | 状態 |
|---------|------|
| spec.md | ✓ 検出 |
| research.md | ✓ 検出 |
| data-model.md | ✓ 検出 |

## 指摘一覧

### CRITICAL

なし

### HIGH

なし

### MEDIUM

- **[TR-1]** liveUpdates() と CLLocationManager のハイブリッド連携パターンが未詳細化 (Confidence: Medium)
  - research.md では `CLLocationUpdate.liveUpdates(.fitness)` をメイントラッキング、`CLLocationManager` を精度制御と significant changes 監視に使用する方針が記載されている。しかし plan.md の Technical Context と Project Structure では `LocationTrackingService.swift` に「CLLocationManager + liveUpdates」とあるのみで、2つの API の責任分界点（どちらが精度制御を担うか、切り替えトリガーは何か）が不明確
  - **改善提案**: plan.md に API 連携パターンを追記する。例: 「liveUpdates() がメインの位置取得ループ、CLLocationManager は (1) significant changes の監視（強制終了後の再起動用）と (2) 速度帯変更時の desiredAccuracy/distanceFilter 動的切り替えに使用」

- **[RA-1]** SwiftData の大量バッチ挿入における成熟度リスク (Confidence: Medium)
  - SwiftData は iOS 17 (2023) で登場した比較的新しいフレームワーク。ModelActor を使ったバックグラウンドバッチ書き込み（10ポイント/30秒ごと）は、6時間連続セッションで数千回の save() 呼び出しを伴う。SwiftData のバックグラウンドコンテキスト操作にはエッジケース（メモリリーク、コンテキスト同期の遅延）が報告されている
  - **改善提案**: (1) 6時間相当のデータ連続挿入ストレステストを実装フェーズに含める。(2) research.md に記載の Core Data フォールバック戦略を plan.md に明示化し、SwiftData で問題が発生した場合の切り替え判断基準を定義する

- **[RA-2]** liveUpdates() の制御粒度と FR-010 速度帯ルールの適合性 (Confidence: Medium)
  - `CLLocationUpdate.liveUpdates(.fitness)` はプリセットベースで、`desiredAccuracy` や `distanceFilter` の個別設定ができない。FR-010 は4つの速度帯ごとに異なる精度/間隔を要求しており、プリセットでは表現しきれない可能性がある。research.md では「CLLocationManager の直接制御が必要」と言及しているが、plan.md には反映されていない
  - **改善提案**: FR-010 の速度帯ルール実装は liveUpdates() ではなく CLLocationManager の delegate パターンで行い、liveUpdates() は isStationary 検出と全体的なライフサイクル管理に限定使用する方針を plan.md に明記する

### LOW

- **[RA-3]** LocationTrackingService のテストファイルが Project Structure に未記載 (Confidence: High)
  - LoadTrackerTests/ に StaySpotDetectionTests, RouteDataServiceTests, DouglasPeuckerTests, StorageCleanupTests は含まれているが、LocationTrackingService（アプリのコア機能）のテストが含まれていない。Constitution IV (Testable Architecture) では「各 user story に最低1つの integration-level test」を要求している
  - **改善提案**: `LocationTrackingServiceTests.swift` を追加する。Protocol ベースの LocationTrackingServiceProtocol をモックし、速度帯切り替えロジック・バッファフラッシュタイミング・省電力モード切り替えをユニットテストでカバーする

## メトリクス

- Technical Context フィールド充足率: 9/9 (100%)
- 総指摘数: 4 (CRITICAL: 0, HIGH: 0, MEDIUM: 3, LOW: 1)
- アクション付き指摘率: 100%

## 推奨アクション

1. plan.md の Technical Context または Summary に liveUpdates() / CLLocationManager の責任分界を追記する（TR-1, RA-2 の同時解消）
2. SwiftData のストレステスト計画と Core Data フォールバック基準を plan.md に追記する（RA-1）
3. LoadTrackerTests/ に LocationTrackingServiceTests.swift を追加する（RA-3）
