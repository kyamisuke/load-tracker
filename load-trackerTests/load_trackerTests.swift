import Foundation
import Testing
@testable import load_tracker

struct load_trackerTests {

    @Test func routeRecordInitialization() async throws {
        let record = RouteRecord()
        #expect(record.isRecording == true)
        #expect(record.stoppedAt == nil)
        #expect(record.totalDistance == 0)
        #expect(record.isInterrupted == false)
    }

    @Test func routePointFromCLLocation() async throws {
        let point = RoutePoint(
            latitude: 35.6762,
            longitude: 139.6503,
            altitude: 40,
            horizontalAccuracy: 5,
            speed: 1.5,
            course: 90
        )
        #expect(point.latitude == 35.6762)
        #expect(point.longitude == 139.6503)
        #expect(point.isLowAccuracy == false)
    }

    @Test func routePointLowAccuracy() async throws {
        let point = RoutePoint(
            latitude: 35.6762,
            longitude: 139.6503,
            horizontalAccuracy: 100
        )
        #expect(point.isLowAccuracy == true)
    }

    @Test func staySpotFormattedDuration() async throws {
        let spot = StaySpot(
            centerLatitude: 35.6762,
            centerLongitude: 139.6503,
            arrivedAt: Date(),
            duration: 600
        )
        #expect(spot.formattedDuration == "10分")
    }

    @Test func staySpotFormattedDurationHours() async throws {
        let spot = StaySpot(
            centerLatitude: 35.6762,
            centerLongitude: 139.6503,
            arrivedAt: Date(),
            duration: 7200
        )
        #expect(spot.formattedDuration == "2時間0分")
    }
}
