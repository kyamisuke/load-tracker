import Foundation
import SwiftData

@ModelActor
actor RouteDataService: RouteDataServiceProtocol {

    // MARK: - Query

    func activeRecord() async -> RouteRecord? {
        let descriptor = FetchDescriptor<RouteRecord>(
            predicate: #Predicate { $0.stoppedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    func allRecords() async -> [RouteRecord] {
        let descriptor = FetchDescriptor<RouteRecord>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func records(from startDate: Date, to endDate: Date) async -> [RouteRecord] {
        let descriptor = FetchDescriptor<RouteRecord>(
            predicate: #Predicate { $0.startedAt >= startDate && $0.startedAt <= endDate },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func points(for record: RouteRecord, from startDate: Date?, to endDate: Date?) async -> [RoutePoint] {
        let recordID = record.id
        var descriptor = FetchDescriptor<RoutePoint>(
            predicate: #Predicate { $0.record?.id == recordID },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        if let start = startDate, let end = endDate {
            descriptor.predicate = #Predicate {
                $0.record?.id == recordID && $0.timestamp >= start && $0.timestamp <= end
            }
        }
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func staySpots(for record: RouteRecord) async -> [StaySpot] {
        let recordID = record.id
        let descriptor = FetchDescriptor<StaySpot>(
            predicate: #Predicate { $0.record?.id == recordID },
            sortBy: [SortDescriptor(\.arrivedAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Mutation

    func createRecord() async -> RouteRecord {
        let record = RouteRecord()
        modelContext.insert(record)
        try? modelContext.save()
        return record
    }

    func addPoints(_ points: [RoutePoint], to record: RouteRecord) async {
        for point in points {
            point.record = record
            modelContext.insert(point)
        }
        try? modelContext.save()
    }

    func addStaySpot(_ spot: StaySpot, to record: RouteRecord) async {
        spot.record = record
        modelContext.insert(spot)
        try? modelContext.save()
    }

    func stopRecord(_ record: RouteRecord, interrupted: Bool) async {
        record.stoppedAt = Date()
        record.isInterrupted = interrupted
        try? modelContext.save()
    }

    func updateDistance(_ distance: Double, for record: RouteRecord) async {
        record.totalDistance = distance
        try? modelContext.save()
    }

    func deleteRecord(_ record: RouteRecord) async {
        modelContext.delete(record)
        try? modelContext.save()
    }

    func deleteAllRecords() async {
        let descriptor = FetchDescriptor<RouteRecord>()
        guard let records = try? modelContext.fetch(descriptor) else { return }
        for record in records {
            modelContext.delete(record)
        }
        try? modelContext.save()
    }

    // MARK: - Storage Cleanup (FR-011)

    func performStorageCleanup() async {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let expiredDescriptor = FetchDescriptor<RouteRecord>(
            predicate: #Predicate { $0.startedAt < thirtyDaysAgo }
        )
        if let expiredRecords = try? modelContext.fetch(expiredDescriptor) {
            for record in expiredRecords {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
}
