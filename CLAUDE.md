# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS route tracking app built with Swift 5.9+, SwiftUI, MapKit, CoreLocation, and SwiftData. Records GPS routes with adaptive accuracy based on speed tiers, detects stay spots, and provides route history with map visualization.

## Build & Test Commands

```bash
# Build
xcodebuild -project load-tracker.xcodeproj -scheme load-tracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run all tests
xcodebuild -project load-tracker.xcodeproj -scheme load-tracker -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test class
xcodebuild -project load-tracker.xcodeproj -scheme load-tracker -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:load-trackerTests/DouglasPeuckerTests

# Run a single test method
xcodebuild -project load-tracker.xcodeproj -scheme load-tracker -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:load-trackerTests/DouglasPeuckerTests/simplifyStraightLine
```

Tests use Swift Testing framework (`import Testing`, `@Test`, `#expect`) — not XCTest.

## Architecture

**App entry**: `load_trackerApp` creates the SwiftData `ModelContainer` (RouteRecord, RoutePoint, StaySpot schemas) and injects `LocationTrackingService` into `MapScreen`.

**Services layer** (protocol-backed):
- `LocationTrackingService` — `@MainActor ObservableObject` wrapping `CLLocationManager`. Manages recording state, adaptive speed tiers (stationary/walking/running/vehicle), battery-aware power saving, and buffered point writes (flush every 30s or 10 points).
- `RouteDataService` — `@ModelActor` actor for all SwiftData CRUD. Handles storage cleanup (30-day TTL) on launch.
- `StaySpotDetectionService` — value type (struct). Detects stay spots using spatial clustering (50m radius, 5min threshold). Supports both batch (`detectSpots`) and incremental (`updateOpenCluster`) detection.

**Data flow**: `LocationTrackingService` buffers `RoutePoint`s and flushes to `RouteDataService`. Views use `@Query` for SwiftData reads and `@ObservedObject` for tracking state.

**Key behaviors**:
- Interrupted recording recovery: on launch, checks for records with `stoppedAt == nil` and marks them interrupted.
- Background location via `UIBackgroundModes: location` and `allowsBackgroundLocationUpdates`.
- Data protection: `NSFileProtectionComplete` entitlement.

## Specs

Feature specs live in `specs/001-route-tracker/`. The spec IDs (FR-010, EC-002, etc.) referenced in code comments trace back to these documents.
