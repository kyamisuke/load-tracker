# Tasks: 経路トラッカー (Route Tracker)

**Input**: Design documents from `/specs/001-route-tracker/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Constitution IV (Testable Architecture) requires each user story to have at least one test. Tests are included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **iOS project**: `LoadTracker/` at repository root
- **Tests**: `LoadTrackerTests/` at repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Xcode プロジェクト初期化と iOS バックグラウンド位置情報の基本設定

- [x] T001 Create Xcode project (LoadTracker) with SwiftUI App lifecycle, deployment target iOS 17.0, Swift 5.9+ in LoadTracker/
- [x] T002 Configure Background Modes capability (Location updates) and add Info.plist keys: NSLocationWhenInUseUsageDescription, NSLocationAlwaysAndWhenInUseUsageDescription in LoadTracker/Info.plist
- [x] T003 [P] Configure Data Protection entitlement (NSFileProtectionCompleteUntilFirstUserAuthentication) in LoadTracker/LoadTracker.entitlements

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: SwiftData モデル定義、ModelContainer 設定、Service Protocol 層の構築

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create RouteRecord @Model entity with fields (id, startedAt, stoppedAt, totalDistance, isInterrupted), relationships (points, staySpots), and indexes in LoadTracker/Models/RouteRecord.swift
- [x] T005 [P] Create RoutePoint @Model entity with fields (id, latitude, longitude, altitude, timestamp, horizontalAccuracy, speed, course), relationship (record), and composite index (record.id, timestamp) in LoadTracker/Models/RoutePoint.swift
- [x] T006 [P] Create StaySpot @Model entity with fields (id, centerLatitude, centerLongitude, arrivedAt, departedAt, duration), relationship (record), and index (record.id, arrivedAt) in LoadTracker/Models/StaySpot.swift
- [x] T007 [P] Create LocationTrackingServiceProtocol (state, currentLocation, startRecording, stopRecording) in LoadTracker/Services/Protocols/LocationTrackingServiceProtocol.swift
- [x] T008 [P] Create RouteDataServiceProtocol (activeRecord, allRecords, records by date range, points, staySpots, deleteRecord, deleteAllRecords, performStorageCleanup) in LoadTracker/Services/Protocols/RouteDataServiceProtocol.swift
- [x] T009 [P] Create StaySpotDetectionServiceProtocol (detectSpots, updateOpenCluster) in LoadTracker/Services/Protocols/StaySpotDetectionServiceProtocol.swift
- [x] T010 Implement RouteDataService as ModelActor with background-thread-safe SwiftData CRUD, batch write support (10-point buffer + 30s timer flush) in LoadTracker/Services/RouteDataService.swift
- [x] T011 Configure ModelContainer with NSFileProtectionCompleteUntilFirstUserAuthentication and inject RouteDataService in LoadTracker/App/LoadTrackerApp.swift

**Checkpoint**: Foundation ready — SwiftData models, protocols, and data service operational. User story implementation can now begin.

---

## Phase 3: User Story 1 — バックグラウンドでの自動経路記録 (Priority: P1) 🎯 MVP

**Goal**: アプリをバックグラウンドにしても移動経路が自動記録され続ける。飲酒中にアプリ操作不要。

**Independent Test**: アプリで記録開始後、バックグラウンドにして数分歩き、再度開いて経路が記録されていることを確認。

### Tests for User Story 1

- [x] T012 [P] [US1] Unit test for LocationTrackingService: speed tier switching (4 bands), buffer flush timing (10 points / 30s), battery ≤ 20% power save mode (distanceFilter 2x) in LoadTrackerTests/LocationTrackingServiceTests.swift
- [x] T013 [P] [US1] Unit test for RouteDataService: CRUD operations, batch write, active record detection (stoppedAt == nil) in LoadTrackerTests/RouteDataServiceTests.swift

### Implementation for User Story 1

- [x] T014 [US1] Implement LocationTrackingService: CLLocationManager delegate (main tracking loop, dynamic desiredAccuracy/distanceFilter per speed tier, 3-read debounce), liveUpdates(.fitness) for isStationary detection, significant changes monitoring for force-quit recovery, UIDevice.batteryLevel monitoring for power save mode in LoadTracker/Services/LocationTrackingService.swift
- [x] T015 [US1] Implement RecordingControls: start/stop buttons, RecordingState enum (idle/recording/interrupted), recording status indicator, interrupted state banner with resume prompt in LoadTracker/Views/RecordingControls.swift
- [x] T016 [P] [US1] Implement OnboardingSheet: first-launch single-screen onboarding with CTA「記録を開始」button in LoadTracker/Views/OnboardingSheet.swift
- [x] T017 [US1] Implement MapScreen: main view with state variants (Empty → CTA + onboarding, Idle → start button, Recording → live indicator + stop, Interrupted → resume banner), current location centering in LoadTracker/Views/MapScreen.swift
- [x] T018 [US1] Wire up app entry point: inject LocationTrackingService and RouteDataService into MapScreen, handle force-quit recovery (check launchOptions for .location key, set isInterrupted on active record) in LoadTracker/App/LoadTrackerApp.swift

**Checkpoint**: User Story 1 complete — background recording works. App records location in background, persists to SwiftData, handles force-quit and battery optimization. Independently testable on device.

---

## Phase 4: User Story 2 — 経路の地図表示と確認 (Priority: P1)

**Goal**: 記録された経路を地図上に線として描画。GPS 精度に応じた実線/点線の描き分け。

**Independent Test**: 記録済みデータがある状態で地図画面を開き、経路が正しく描画されていることを確認。

### Tests for User Story 2

- [x] T019 [P] [US2] Unit test for DouglasPeucker: simplification correctness at 3 epsilon levels (full detail / ε~5m / ε~30m), edge cases (empty array, single point, straight line) in LoadTrackerTests/DouglasPeuckerTests.swift

### Implementation for User Story 2

- [x] T020 [P] [US2] Implement DouglasPeucker algorithm: Ramer-Douglas-Peucker with configurable epsilon, pre-compute 3 LOD levels (Level 0: all points, Level 1: ε~5m, Level 2: ε~30m) in LoadTracker/Utilities/DouglasPeucker.swift
- [x] T021 [US2] Implement MapViewRepresentable: UIViewRepresentable wrapping MKMapView, MKMapViewDelegate for regionDidChangeAnimated LOD switching, polyline overlay management in LoadTracker/Views/MapViewRepresentable.swift
- [x] T022 [US2] Implement RouteOverlayRenderer: custom MKPolylineRenderer subclass, solid line (systemBlue, 3pt) for horizontalAccuracy ≤ 65m, dashed line (systemGray, 2pt) for > 65m (FR-009) in LoadTracker/Views/RouteOverlayRenderer.swift
- [x] T023 [US2] Integrate route overlay into MapScreen: load RoutePoint data via RouteDataService, apply DouglasPeucker LOD, display on MapViewRepresentable in LoadTracker/Views/MapScreen.swift

**Checkpoint**: User Story 2 complete — routes display on map with LOD and accuracy-based styling. Independently testable.

---

## Phase 5: User Story 3 — 滞在スポットの可視化 (Priority: P2)

**Goal**: 5 分以上滞在した場所を自動検出し、地図上に強調マーカーで表示。タップで詳細表示。

**Independent Test**: 10 分以上滞在したデータで、地図上に滞在マーカーが表示されタップで詳細が見えることを確認。

### Tests for User Story 3

- [x] T024 [P] [US3] Unit test for StaySpotDetectionService: detection with 50m radius / 5min threshold, GPS jitter tolerance, non-overlapping spots, long stay (hours), edge cases (no points, all stationary) in LoadTrackerTests/StaySpotDetectionTests.swift

### Implementation for User Story 3

- [x] T025 [US3] Implement StaySpotDetectionService: sliding anchor-point algorithm (O(n)), CLLocation.distance(from:) for 50m radius check, mean(lat/lon) centroid, incremental post-processing (~60s interval) + real-time open cluster detection in LoadTracker/Services/StaySpotDetectionService.swift
- [x] T026 [US3] Add StaySpotAnnotation to MapViewRepresentable: MKAnnotation with circle marker, callout displaying stay duration / arrival time / departure time in LoadTracker/Views/MapViewRepresentable.swift
- [x] T027 [US3] Integrate stay spot detection into recording loop: trigger detection on new points in LocationTrackingService, persist StaySpot entities via RouteDataService in LoadTracker/Services/LocationTrackingService.swift

**Checkpoint**: User Story 3 complete — stay spots auto-detected and displayed as markers on map. Independently testable.

---

## Phase 6: User Story 4 — 経路履歴の管理 (Priority: P3)

**Goal**: 過去の経路履歴を一覧で確認、個別/全データの完全削除、時間帯フィルタによる詳細表示。

**Independent Test**: 履歴一覧から過去記録を選択・閲覧・削除できることを確認。

### Tests for User Story 4

- [x] T028 [P] [US4] Unit test for storage cleanup: 30-day expiry deletion, 100MB cap enforcement, cascade delete (RouteRecord → RoutePoint + StaySpot) in LoadTrackerTests/StorageCleanupTests.swift

### Implementation for User Story 4

- [x] T029 [US4] Implement HistoryList: @Query sorted by startedAt DESC, row display (date, start-end time, distance, stay spot count), swipe-to-delete (instant hard delete), full delete button with confirmation dialog in LoadTracker/Views/HistoryList.swift
- [x] T030 [US4] Implement RouteDetailMap: single RouteRecord detail view, time range filter with DatePicker, reuse MapViewRepresentable with filtered RoutePoint data in LoadTracker/Views/RouteDetailMap.swift
- [x] T031 [US4] Implement automatic storage cleanup in RouteDataService: on app launch delete RouteRecords older than 30 days (cascade), if total storage > 100MB delete oldest records first in LoadTracker/Services/RouteDataService.swift
- [x] T032 [US4] Integrate HistoryList navigation: add NavigationLink from MapScreen to HistoryList, wire HistoryList row tap to RouteDetailMap in LoadTracker/Views/MapScreen.swift

**Checkpoint**: User Story 4 complete — history management with delete and auto-cleanup. All user stories independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: ストレステスト、プライバシー検証、最終品質チェック

- [ ] T033 [P] Implement 6-hour continuous insertion stress test (~2,160 save() calls) for SwiftData ModelActor: verify no memory leaks, no context sync delays, WAL file size in LoadTrackerTests/RouteDataServiceStressTests.swift
- [ ] T034 Privacy audit: verify zero outbound network requests during full usage session (FR-005/FR-006), test with airplane mode enabled
- [ ] T035 Run quickstart.md validation checklist on physical device

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 (Phase 3) and US2 (Phase 4) are both P1 but US2 depends on US1 (needs recorded data to display)
  - US3 (Phase 5) depends on US1 (needs location data stream) and US2 (needs map rendering)
  - US4 (Phase 6) can start after US1 (needs RouteRecord data) but benefits from US2 (RouteDetailMap reuses MapViewRepresentable)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational — No dependencies on other stories
- **User Story 2 (P1)**: Depends on US1 (RoutePoint data must exist to display routes)
- **User Story 3 (P2)**: Depends on US1 (location stream) + US2 (MapViewRepresentable for annotation display)
- **User Story 4 (P3)**: Depends on US1 (RouteRecord data) + US2 (RouteDetailMap reuses map components)

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models before services
- Services before views
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- T002 + T003: Setup tasks on different files
- T004 + T005 + T006: Three @Model entities in separate files
- T007 + T008 + T009: Three protocol files
- T012 + T013: US1 test files
- T016: OnboardingSheet independent of other US1 views
- T019 + T020: US2 test and algorithm in separate files

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test background recording on physical device
5. MVP delivered — core value (background tracking) works

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. User Story 1 → Test on device → MVP!
3. User Story 2 → Routes visible on map → Demo
4. User Story 3 → Stay spots detected → Demo
5. User Story 4 → History management → Full v1
6. Polish → Stress test + privacy audit → Release candidate

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Physical device required for background location and battery testing
