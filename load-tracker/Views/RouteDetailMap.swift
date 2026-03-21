import SwiftUI
import SwiftData

struct RouteDetailMap: View {
    let record: RouteRecord
    @State private var filterStart: Date
    @State private var filterEnd: Date
    @State private var centerOnUser = false

    init(record: RouteRecord) {
        self.record = record
        _filterStart = State(initialValue: record.startedAt)
        _filterEnd = State(initialValue: record.stoppedAt ?? Date())
    }

    private var filteredPoints: [RoutePoint] {
        record.points
            .filter { $0.timestamp >= filterStart && $0.timestamp <= filterEnd }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private var filteredStaySpots: [StaySpot] {
        record.staySpots
            .filter { $0.arrivedAt >= filterStart && $0.arrivedAt <= filterEnd }
    }

    var body: some View {
        VStack(spacing: 0) {
            MapViewRepresentable(
                routePoints: filteredPoints,
                staySpots: filteredStaySpots,
                centerOnUser: $centerOnUser
            )
            .ignoresSafeArea(edges: .top)

            timeFilter
        }
        .navigationTitle(record.startedAt.formatted(.dateTime.month().day()))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var timeFilter: some View {
        VStack(spacing: 8) {
            Text("時間帯フィルタ")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                DatePicker("開始", selection: $filterStart, in: record.startedAt...(record.stoppedAt ?? Date()), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Text("→")
                DatePicker("終了", selection: $filterEnd, in: record.startedAt...(record.stoppedAt ?? Date()), displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
