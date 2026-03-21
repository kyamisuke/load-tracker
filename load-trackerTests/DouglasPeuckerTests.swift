import Testing
import CoreLocation
@testable import load_tracker

struct DouglasPeuckerTests {

    @Test func simplifyEmptyArray() async throws {
        let result = DouglasPeucker.simplify([], epsilon: 0.001)
        #expect(result.isEmpty)
    }

    @Test func simplifySinglePoint() async throws {
        let points = [CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0)]
        let result = DouglasPeucker.simplify(points, epsilon: 0.001)
        #expect(result.count == 1)
    }

    @Test func simplifyTwoPoints() async throws {
        let points = [
            CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0),
            CLLocationCoordinate2D(latitude: 35.1, longitude: 139.1),
        ]
        let result = DouglasPeucker.simplify(points, epsilon: 0.001)
        #expect(result.count == 2)
    }

    @Test func simplifyStraightLine() async throws {
        // Points on a straight line should reduce to 2
        var points: [CLLocationCoordinate2D] = []
        for i in 0..<10 {
            points.append(CLLocationCoordinate2D(
                latitude: 35.0 + Double(i) * 0.001,
                longitude: 139.0 + Double(i) * 0.001
            ))
        }
        let result = DouglasPeucker.simplify(points, epsilon: 0.0001)
        #expect(result.count == 2)
    }

    @Test func simplifyPreservesSharpTurn() async throws {
        // L-shaped path: should preserve the corner
        let points = [
            CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0),
            CLLocationCoordinate2D(latitude: 35.0, longitude: 139.01),
            CLLocationCoordinate2D(latitude: 35.0, longitude: 139.02),
            CLLocationCoordinate2D(latitude: 35.01, longitude: 139.02),  // corner
            CLLocationCoordinate2D(latitude: 35.02, longitude: 139.02),
        ]
        let result = DouglasPeucker.simplify(points, epsilon: 0.001)
        #expect(result.count >= 3) // Must preserve corner
    }

    @Test func higherEpsilonReducesMorePoints() async throws {
        var points: [CLLocationCoordinate2D] = []
        for i in 0..<100 {
            let angle = Double(i) * 0.1
            points.append(CLLocationCoordinate2D(
                latitude: 35.0 + sin(angle) * 0.001,
                longitude: 139.0 + Double(i) * 0.0001
            ))
        }
        let fine = DouglasPeucker.simplify(points, epsilon: 0.000045)
        let coarse = DouglasPeucker.simplify(points, epsilon: 0.00027)
        #expect(coarse.count <= fine.count)
    }

    @Test func precomputeLODProducesThreeLevels() async throws {
        var points: [RoutePoint] = []
        for i in 0..<50 {
            let angle = Double(i) * 0.1
            points.append(RoutePoint(
                latitude: 35.0 + sin(angle) * 0.001,
                longitude: 139.0 + Double(i) * 0.0001,
                timestamp: Date().addingTimeInterval(TimeInterval(i * 10))
            ))
        }
        let lod = DouglasPeucker.precomputeLOD(from: points)
        #expect(lod.full.count == 50)
        #expect(lod.medium.count <= lod.full.count)
        #expect(lod.coarse.count <= lod.medium.count)
    }
}
