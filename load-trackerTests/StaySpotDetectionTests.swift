import Testing
import CoreLocation
@testable import load_tracker

struct StaySpotDetectionTests {

    private func makePoint(lat: Double, lon: Double, timestamp: Date, accuracy: Double = 5) -> RoutePoint {
        RoutePoint(
            latitude: lat,
            longitude: lon,
            timestamp: timestamp,
            horizontalAccuracy: accuracy,
            speed: 0
        )
    }

    @Test func detectStaySpotWith5MinutesAtSameLocation() async throws {
        var detector = StaySpotDetectionService()
        let baseTime = Date()
        let baseLat = 35.6762
        let baseLon = 139.6503

        // 6 minutes of points at same location (every 30s)
        var points: [RoutePoint] = []
        for i in 0..<12 {
            let point = makePoint(
                lat: baseLat + Double.random(in: -0.0001...0.0001),
                lon: baseLon + Double.random(in: -0.0001...0.0001),
                timestamp: baseTime.addingTimeInterval(TimeInterval(i * 30))
            )
            points.append(point)
        }

        let spots = detector.detectSpots(in: points)
        #expect(spots.count == 1)
        #expect(spots.first!.duration >= 300)
    }

    @Test func noStaySpotForShortStay() async throws {
        var detector = StaySpotDetectionService()
        let baseTime = Date()

        // 3 minutes only
        var points: [RoutePoint] = []
        for i in 0..<6 {
            points.append(makePoint(
                lat: 35.6762,
                lon: 139.6503,
                timestamp: baseTime.addingTimeInterval(TimeInterval(i * 30))
            ))
        }

        let spots = detector.detectSpots(in: points)
        #expect(spots.isEmpty)
    }

    @Test func noStaySpotForMovingUser() async throws {
        var detector = StaySpotDetectionService()
        let baseTime = Date()

        // Moving user: 100m apart each point
        var points: [RoutePoint] = []
        for i in 0..<12 {
            points.append(makePoint(
                lat: 35.6762 + Double(i) * 0.001,
                lon: 139.6503,
                timestamp: baseTime.addingTimeInterval(TimeInterval(i * 30))
            ))
        }

        let spots = detector.detectSpots(in: points)
        #expect(spots.isEmpty)
    }

    @Test func incrementalDetection() async throws {
        var detector = StaySpotDetectionService()
        let baseTime = Date()
        let baseLat = 35.6762
        let baseLon = 139.6503

        var detected: StaySpot?

        // Feed points one by one for 6 minutes
        for i in 0..<12 {
            let point = makePoint(
                lat: baseLat,
                lon: baseLon,
                timestamp: baseTime.addingTimeInterval(TimeInterval(i * 30))
            )
            if let spot = detector.updateOpenCluster(with: point) {
                detected = spot
            }
        }

        #expect(detected != nil)
        #expect(detected!.duration >= 300)
    }

    @Test func emptyInput() async throws {
        let detector = StaySpotDetectionService()
        let spots = detector.detectSpots(in: [])
        #expect(spots.isEmpty)
    }
}
