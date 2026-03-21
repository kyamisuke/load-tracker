import Foundation
import CoreLocation
import UIKit
import Combine

@MainActor
final class LocationTrackingService: NSObject, ObservableObject, LocationTrackingServiceProtocol {

    @Published private(set) var state: RecordingState = .idle
    @Published private(set) var currentLocation: CLLocation?

    private let locationManager = CLLocationManager()
    private let dataService: RouteDataService
    private var activeRecord: RouteRecord?
    private var pointBuffer: [RoutePoint] = []
    private var flushTimer: Timer?
    private var totalDistance: Double = 0
    private var lastLocation: CLLocation?
    private var speedReadings: [Double] = []
    private var currentSpeedTier: SpeedTier = .stationary
    private var isPowerSaveMode: Bool = false
    private var liveUpdatesTask: Task<Void, Never>?
    private var staySpotDetector = StaySpotDetectionService()

    private let maxBufferSize = 10
    private let flushInterval: TimeInterval = 30

    enum SpeedTier: CaseIterable {
        case stationary   // < 1 km/h
        case walking      // 1-6 km/h
        case running      // 6-30 km/h
        case vehicle      // > 30 km/h

        var desiredAccuracy: CLLocationAccuracy {
            switch self {
            case .stationary: return kCLLocationAccuracyNearestTenMeters
            case .walking: return kCLLocationAccuracyBest
            case .running: return kCLLocationAccuracyBest
            case .vehicle: return kCLLocationAccuracyNearestTenMeters
            }
        }

        var distanceFilter: CLLocationDistance {
            switch self {
            case .stationary: return 50
            case .walking: return 5
            case .running: return 10
            case .vehicle: return 30
            }
        }

        static func from(speedMS: Double) -> SpeedTier {
            let kmh = speedMS * 3.6
            switch kmh {
            case ..<1: return .stationary
            case 1..<6: return .walking
            case 6..<30: return .running
            default: return .vehicle
            }
        }
    }

    init(dataService: RouteDataService) {
        self.dataService = dataService
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = true
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelDidChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        locationManager.startMonitoringSignificantLocationChanges()
        Task { await checkForInterruptedRecord() }
    }

    // MARK: - Public API

    func startRecording() async throws {
        guard state != .recording else { return }
        let authStatus = locationManager.authorizationStatus
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
        }
        guard authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse else {
            return
        }
        activeRecord = await dataService.createRecord()
        totalDistance = 0
        lastLocation = nil
        pointBuffer = []
        staySpotDetector.reset()
        applySpeedTier(.walking)
        locationManager.startUpdatingLocation()
        startFlushTimer()
        startLiveUpdatesMonitoring()
        state = .recording
    }

    func stopRecording() async {
        guard state == .recording, let record = activeRecord else { return }
        locationManager.stopUpdatingLocation()
        stopFlushTimer()
        liveUpdatesTask?.cancel()
        liveUpdatesTask = nil
        await flushBuffer()
        await dataService.stopRecord(record, interrupted: false)
        activeRecord = nil
        state = .idle
    }

    // MARK: - Interrupted Record Recovery (EC-006)

    private func checkForInterruptedRecord() async {
        if let record = await dataService.activeRecord() {
            await dataService.stopRecord(record, interrupted: true)
            state = .interrupted
        }
    }

    func resumeAfterInterruption() async throws {
        state = .idle
        try await startRecording()
    }

    // MARK: - Speed Tier Management (FR-010)

    private func updateSpeedTier(from location: CLLocation) {
        guard location.speed >= 0 else { return }
        speedReadings.append(location.speed)
        if speedReadings.count > 3 { speedReadings.removeFirst() }
        guard speedReadings.count >= 3 else { return }
        let avgSpeed = speedReadings.reduce(0, +) / Double(speedReadings.count)
        let newTier = SpeedTier.from(speedMS: avgSpeed)
        if newTier != currentSpeedTier {
            currentSpeedTier = newTier
            applySpeedTier(newTier)
        }
    }

    private func applySpeedTier(_ tier: SpeedTier) {
        let multiplier: Double = isPowerSaveMode ? 2.0 : 1.0
        locationManager.desiredAccuracy = tier.desiredAccuracy
        locationManager.distanceFilter = tier.distanceFilter * multiplier
    }

    // MARK: - Battery Monitoring (EC-002)

    @objc private func batteryLevelDidChange() {
        let level = UIDevice.current.batteryLevel
        let shouldSave = level >= 0 && level <= 0.2
        if shouldSave != isPowerSaveMode {
            isPowerSaveMode = shouldSave
            applySpeedTier(currentSpeedTier)
        }
    }

    // MARK: - Point Buffer

    private func bufferPoint(_ location: CLLocation) {
        let point = RoutePoint(location: location)
        pointBuffer.append(point)
        if let last = lastLocation {
            totalDistance += location.distance(from: last)
        }
        lastLocation = location
        currentLocation = location
        if let spot = staySpotDetector.updateOpenCluster(with: point) {
            Task {
                guard let record = activeRecord else { return }
                await dataService.addStaySpot(spot, to: record)
            }
        }
        if pointBuffer.count >= maxBufferSize {
            Task { await flushBuffer() }
        }
    }

    private func flushBuffer() async {
        guard !pointBuffer.isEmpty, let record = activeRecord else { return }
        let points = pointBuffer
        pointBuffer = []
        await dataService.addPoints(points, to: record)
        await dataService.updateDistance(totalDistance, for: record)
    }

    private func startFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.flushBuffer()
            }
        }
    }

    private func stopFlushTimer() {
        flushTimer?.invalidate()
        flushTimer = nil
    }

    // MARK: - Live Updates (isStationary detection)

    private func startLiveUpdatesMonitoring() {
        liveUpdatesTask = Task.detached { [weak self] in
            let updates = CLLocationUpdate.liveUpdates(.fitness)
            do {
                for try await update in updates {
                    guard !Task.isCancelled else { break }
                    if update.isStationary {
                        await MainActor.run {
                            self?.speedReadings = [0, 0, 0]
                            let newTier = SpeedTier.stationary
                            if self?.currentSpeedTier != newTier {
                                self?.currentSpeedTier = newTier
                                self?.applySpeedTier(newTier)
                            }
                        }
                    }
                }
            } catch {}
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationTrackingService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            for location in locations {
                guard location.horizontalAccuracy >= 0 else { continue }
                updateSpeedTier(from: location)
                bufferPoint(location)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {}
}
