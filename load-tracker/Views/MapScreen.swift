import SwiftUI
import SwiftData

struct MapScreen: View {
    @ObservedObject var trackingService: LocationTrackingService
    @Query(sort: \RouteRecord.startedAt, order: .reverse)
    private var records: [RouteRecord]
    @State private var showOnboarding = false
    @State private var centerOnUser = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private var latestRecord: RouteRecord? {
        records.first
    }

    private var latestPoints: [RoutePoint] {
        guard let record = latestRecord else { return [] }
        return record.points.sorted { $0.timestamp < $1.timestamp }
    }

    private var latestStaySpots: [StaySpot] {
        latestRecord?.staySpots ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MapViewRepresentable(
                    routePoints: latestPoints,
                    staySpots: latestStaySpots,
                    centerOnUser: $centerOnUser
                )
                .ignoresSafeArea(edges: .top)

                RecordingControls(trackingService: trackingService) {
                    try await trackingService.resumeAfterInterruption()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: HistoryList()) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .onAppear {
                if !hasSeenOnboarding && records.isEmpty {
                    showOnboarding = true
                }
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingSheet {
                    hasSeenOnboarding = true
                    try await trackingService.startRecording()
                }
                .presentationBackground(Color.App.bgPrimary)
            }
        }
    }
}
