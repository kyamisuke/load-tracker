import Foundation
import SwiftData
import CoreLocation

@Model
final class RoutePoint {
    @Attribute(.unique) var id: UUID
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var timestamp: Date
    var horizontalAccuracy: Double
    var speed: Double
    var course: Double

    var record: RouteRecord?

    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        timestamp: Date = Date(),
        horizontalAccuracy: Double = 0,
        speed: Double = -1,
        course: Double = -1
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
        self.horizontalAccuracy = horizontalAccuracy
        self.speed = speed
        self.course = course
    }

    convenience init(location: CLLocation) {
        self.init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            timestamp: location.timestamp,
            horizontalAccuracy: location.horizontalAccuracy,
            speed: location.speed,
            course: location.course
        )
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: -1,
            course: course,
            speed: speed,
            timestamp: timestamp
        )
    }

    var isLowAccuracy: Bool {
        horizontalAccuracy > 65
    }
}
