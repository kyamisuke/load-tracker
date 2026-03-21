import SwiftUI
import SwiftData

@main
struct load_trackerApp: App {
    let modelContainer: ModelContainer
    @StateObject private var trackingService: LocationTrackingService

    init() {
        let schema = Schema([
            RouteRecord.self,
            RoutePoint.self,
            StaySpot.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        self.modelContainer = container

        let dataService = RouteDataService(modelContainer: container)
        _trackingService = StateObject(wrappedValue: LocationTrackingService(dataService: dataService))

        // Storage cleanup on launch (FR-011)
        Task {
            await dataService.performStorageCleanup()
        }
    }

    var body: some Scene {
        WindowGroup {
            MapScreen(trackingService: trackingService)
        }
        .modelContainer(modelContainer)
    }
}
