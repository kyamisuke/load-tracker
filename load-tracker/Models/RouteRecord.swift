import Foundation
import SwiftData

@Model
final class RouteRecord {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var stoppedAt: Date?
    var totalDistance: Double
    var isInterrupted: Bool

    @Relationship(deleteRule: .cascade, inverse: \RoutePoint.record)
    var points: [RoutePoint]

    @Relationship(deleteRule: .cascade, inverse: \StaySpot.record)
    var staySpots: [StaySpot]

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        stoppedAt: Date? = nil,
        totalDistance: Double = 0,
        isInterrupted: Bool = false
    ) {
        self.id = id
        self.startedAt = startedAt
        self.stoppedAt = stoppedAt
        self.totalDistance = totalDistance
        self.isInterrupted = isInterrupted
        self.points = []
        self.staySpots = []
    }

    var isRecording: Bool {
        stoppedAt == nil
    }

    var duration: TimeInterval {
        let end = stoppedAt ?? Date()
        return end.timeIntervalSince(startedAt)
    }
}
