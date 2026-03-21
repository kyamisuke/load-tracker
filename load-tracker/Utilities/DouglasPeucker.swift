import Foundation
import CoreLocation

enum DouglasPeucker {

    struct SimplifiedRoute {
        let full: [CLLocationCoordinate2D]
        let medium: [CLLocationCoordinate2D]   // ε ~5m
        let coarse: [CLLocationCoordinate2D]   // ε ~30m
    }

    static func precomputeLOD(from points: [RoutePoint]) -> SimplifiedRoute {
        let coords = points.map(\.coordinate)
        return SimplifiedRoute(
            full: coords,
            medium: simplify(coords, epsilon: 0.000045),  // ~5m
            coarse: simplify(coords, epsilon: 0.00027)    // ~30m
        )
    }

    static func simplify(_ points: [CLLocationCoordinate2D], epsilon: Double) -> [CLLocationCoordinate2D] {
        guard points.count > 2 else { return points }

        var maxDistance: Double = 0
        var maxIndex = 0

        let start = points.first!
        let end = points.last!

        for i in 1..<(points.count - 1) {
            let d = perpendicularDistance(point: points[i], lineStart: start, lineEnd: end)
            if d > maxDistance {
                maxDistance = d
                maxIndex = i
            }
        }

        if maxDistance > epsilon {
            let left = simplify(Array(points[...maxIndex]), epsilon: epsilon)
            let right = simplify(Array(points[maxIndex...]), epsilon: epsilon)
            return Array(left.dropLast()) + right
        } else {
            return [start, end]
        }
    }

    private static func perpendicularDistance(
        point: CLLocationCoordinate2D,
        lineStart: CLLocationCoordinate2D,
        lineEnd: CLLocationCoordinate2D
    ) -> Double {
        let dx = lineEnd.longitude - lineStart.longitude
        let dy = lineEnd.latitude - lineStart.latitude

        if dx == 0 && dy == 0 {
            let pdx = point.longitude - lineStart.longitude
            let pdy = point.latitude - lineStart.latitude
            return sqrt(pdx * pdx + pdy * pdy)
        }

        let t = max(0, min(1,
            ((point.longitude - lineStart.longitude) * dx + (point.latitude - lineStart.latitude) * dy)
            / (dx * dx + dy * dy)
        ))

        let projX = lineStart.longitude + t * dx
        let projY = lineStart.latitude + t * dy

        let distX = point.longitude - projX
        let distY = point.latitude - projY

        return sqrt(distX * distX + distY * distY)
    }
}
