import Foundation
import SwiftData
import CoreLocation

@Model
final class StaySpot {
    @Attribute(.unique) var id: UUID
    var centerLatitude: Double
    var centerLongitude: Double
    var arrivedAt: Date
    var departedAt: Date?
    var duration: TimeInterval

    var record: RouteRecord?

    init(
        id: UUID = UUID(),
        centerLatitude: Double,
        centerLongitude: Double,
        arrivedAt: Date,
        departedAt: Date? = nil,
        duration: TimeInterval
    ) {
        self.id = id
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.arrivedAt = arrivedAt
        self.departedAt = departedAt
        self.duration = duration
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }

    var isActive: Bool {
        departedAt == nil
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        }
        return "\(minutes)分"
    }
}
