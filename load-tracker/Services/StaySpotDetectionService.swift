import Foundation
import CoreLocation

struct StaySpotDetectionService: StaySpotDetectionServiceProtocol {

    private static let radiusThreshold: CLLocationDistance = 50
    private static let durationThreshold: TimeInterval = 300 // 5 minutes

    private var anchorPoint: RoutePoint?
    private var clusterPoints: [RoutePoint] = []

    // MARK: - Full Detection (for historical data)

    func detectSpots(in points: [RoutePoint]) -> [StaySpot] {
        guard !points.isEmpty else { return [] }
        var spots: [StaySpot] = []
        var anchor = points[0]
        var cluster: [RoutePoint] = [anchor]

        for i in 1..<points.count {
            let point = points[i]
            let distance = anchor.clLocation.distance(from: point.clLocation)

            if distance <= Self.radiusThreshold {
                cluster.append(point)
            } else {
                if let spot = createSpotIfQualified(cluster) {
                    spots.append(spot)
                }
                anchor = point
                cluster = [anchor]
            }
        }
        if let spot = createSpotIfQualified(cluster) {
            spots.append(spot)
        }
        return spots
    }

    // MARK: - Incremental Detection (real-time)

    mutating func updateOpenCluster(with point: RoutePoint) -> StaySpot? {
        guard let anchor = anchorPoint else {
            anchorPoint = point
            clusterPoints = [point]
            return nil
        }

        let distance = anchor.clLocation.distance(from: point.clLocation)

        if distance <= Self.radiusThreshold {
            clusterPoints.append(point)
            let duration = point.timestamp.timeIntervalSince(anchor.timestamp)
            if duration >= Self.durationThreshold {
                let spot = createSpotFromCluster(clusterPoints)
                // Keep cluster open for continued stay
                return spot
            }
            return nil
        } else {
            let result: StaySpot?
            if let spot = createSpotIfQualified(clusterPoints) {
                result = spot
            } else {
                result = nil
            }
            anchorPoint = point
            clusterPoints = [point]
            return result
        }
    }

    mutating func reset() {
        anchorPoint = nil
        clusterPoints = []
    }

    // MARK: - Private

    private func createSpotIfQualified(_ cluster: [RoutePoint]) -> StaySpot? {
        guard cluster.count >= 2 else { return nil }
        let duration = cluster.last!.timestamp.timeIntervalSince(cluster.first!.timestamp)
        guard duration >= Self.durationThreshold else { return nil }
        return createSpotFromCluster(cluster)
    }

    private func createSpotFromCluster(_ cluster: [RoutePoint]) -> StaySpot {
        let centerLat = cluster.map(\.latitude).reduce(0, +) / Double(cluster.count)
        let centerLon = cluster.map(\.longitude).reduce(0, +) / Double(cluster.count)
        let arrivedAt = cluster.first!.timestamp
        let departedAt = cluster.last!.timestamp
        let duration = departedAt.timeIntervalSince(arrivedAt)

        return StaySpot(
            centerLatitude: centerLat,
            centerLongitude: centerLon,
            arrivedAt: arrivedAt,
            departedAt: departedAt,
            duration: duration
        )
    }
}
