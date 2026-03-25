<!--
  Sync Impact Report
  Version change: 1.0.0 → 1.0.1
  Modified principles:
    - IV. Testable Architecture: "XCTest MUST be used" → "Swift Testing framework MUST be used for unit tests; XCTest for UI tests"
  Added sections: None
  Removed sections: None
  Templates requiring updates:
    - .specify/templates/plan-template.md: ✅ No changes needed (Constitution Check section is generic)
    - .specify/templates/spec-template.md: ✅ No changes needed (structure compatible)
    - .specify/templates/tasks-template.md: ✅ No changes needed (phase structure compatible)
  Follow-up TODOs: None
-->

# Load Tracker Constitution

## Core Principles

### I. Privacy-First (NON-NEGOTIABLE)

- All location data MUST be stored exclusively on the user's device
- Network communication for location data MUST NOT exist; no analytics, no telemetry, no crash reporting that includes location
- Stored data MUST be protected with iOS Data Protection Complete (NSFileProtectionComplete)
- Data deletion MUST be immediate and irreversible — no soft-delete, no recycle bin
- Rationale: Location history is extremely sensitive personal data. The app's value proposition depends on user trust

### II. Battery-Conscious

- Background location recording MUST NOT exceed 15% battery consumption over 6 hours (SC-004)
- Location acquisition frequency MUST dynamically adjust based on movement speed and battery level
- All background operations MUST use the minimum CoreLocation accuracy level sufficient for the current context
- New features MUST include a battery impact assessment before implementation
- Rationale: The app runs for hours in background during drinking outings; excessive drain renders it unusable

### III. Platform-Native

- UI MUST be built with SwiftUI; UIKit bridging is permitted only when SwiftUI lacks required capability
- Maps MUST use MapKit (no third-party map SDKs)
- Location services MUST use CoreLocation directly (no third-party wrappers)
- Persistence MUST use SwiftData (or Core Data if SwiftData proves insufficient)
- No third-party dependencies unless they solve a problem that Apple frameworks cannot
- Rationale: Minimize dependency risk, maximize OS integration, reduce app size

### IV. Testable Architecture

- Business logic (location processing, stay detection, storage management) MUST be separated from UI and framework code
- Core services MUST depend on protocols, not concrete implementations, to enable unit testing without device sensors
- Swift Testing framework (`import Testing`, `@Test`, `#expect`) MUST be used for unit tests; XCTest is permitted for UI tests only
- Each user story MUST have at least one integration-level test validating its acceptance scenarios
- Rationale: Location-dependent code is hard to test; architecture must make it possible

### V. Simplicity

- YAGNI: Do not build for hypothetical future requirements; the Out of Scope list is a commitment, not a backlog
- Prefer fewer screens with clear purpose over many screens with thin functionality
- Avoid abstraction layers unless they serve a current, concrete need (e.g., testability)
- One user, one device, one app — do not design for multi-user or multi-device scenarios in v1
- Rationale: This is a personal utility app; complexity is the enemy of shipping

## Technical Constraints

- **Target**: iOS 17.0+ (required for SwiftData, modern SwiftUI Map API)
- **Language**: Swift 5.9+
- **Build**: Xcode 15+, Swift Package Manager for any external dependencies
- **Storage**: SwiftData with NSFileProtectionComplete; storage budget ≤ 100MB
- **Networking**: None. App MUST function with airplane mode enabled
- **Minimum test coverage**: Core services (location manager, stay detection, storage cleanup) MUST have unit tests

## Quality Gates

- **Pre-merge gate**: All tests (Swift Testing + XCTest UI tests) pass on simulator
- **Performance gate**: 6-hour background recording battery test ≤ 15% drain (manual, pre-release)
- **Rendering gate**: Map with 6 hours of route data renders in ≤ 2 seconds on oldest supported device
- **Privacy gate**: No outbound network requests detected during full usage session (verified via Network Link Conditioner or proxy)
- **Data protection gate**: Location database inaccessible when device is locked (verified via Xcode debugger)

## Governance

- This constitution supersedes ad-hoc decisions. All implementation choices MUST align with these principles
- Amendments require: (1) documented rationale, (2) impact assessment on existing code, (3) version bump
- Complexity that violates a principle MUST be justified in the plan's Complexity Tracking table
- If a principle blocks progress, escalate and document — do not silently bypass

**Version**: 1.0.1 | **Ratified**: 2026-03-20 | **Last Amended**: 2026-03-25
