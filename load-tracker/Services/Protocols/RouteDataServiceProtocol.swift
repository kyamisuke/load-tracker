import Foundation

protocol RouteDataServiceProtocol: Sendable {
    func activeRecord() async -> RouteRecord?
    func allRecords() async -> [RouteRecord]
    func records(from startDate: Date, to endDate: Date) async -> [RouteRecord]
    func points(for record: RouteRecord, from startDate: Date?, to endDate: Date?) async -> [RoutePoint]
    func staySpots(for record: RouteRecord) async -> [StaySpot]
    func createRecord() async -> RouteRecord
    func addPoints(_ points: [RoutePoint], to record: RouteRecord) async
    func addStaySpot(_ spot: StaySpot, to record: RouteRecord) async
    func stopRecord(_ record: RouteRecord, interrupted: Bool) async
    func updateDistance(_ distance: Double, for record: RouteRecord) async
    func deleteRecord(_ record: RouteRecord) async
    func deleteAllRecords() async
    func performStorageCleanup() async
}
