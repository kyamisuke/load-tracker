import SwiftUI
import SwiftData

struct HistoryList: View {
    @Query(sort: \RouteRecord.startedAt, order: .reverse)
    private var records: [RouteRecord]

    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAllConfirmation = false

    var body: some View {
        List {
            ForEach(records) { record in
                NavigationLink(destination: RouteDetailMap(record: record)) {
                    recordRow(record)
                }
            }
            .onDelete(perform: deleteRecords)
        }
        .navigationTitle("履歴")
        .toolbar {
            if !records.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("全削除", role: .destructive) {
                        showDeleteAllConfirmation = true
                    }
                }
            }
        }
        .confirmationDialog("すべての経路データを削除しますか？", isPresented: $showDeleteAllConfirmation, titleVisibility: .visible) {
            Button("全データを削除", role: .destructive) {
                deleteAllRecords()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。すべての経路データが完全に削除されます。")
        }
        .overlay {
            if records.isEmpty {
                ContentUnavailableView(
                    "履歴がありません",
                    systemImage: "clock",
                    description: Text("経路を記録すると、ここに表示されます")
                )
            }
        }
    }

    private func recordRow(_ record: RouteRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.startedAt, style: .date)
                .font(.headline)
            HStack {
                let formatter = DateFormatter()
                Text(timeString(record.startedAt))
                Text("→")
                if let stopped = record.stoppedAt {
                    Text(timeString(stopped))
                } else {
                    Text("記録中")
                        .foregroundStyle(.red)
                }
                Spacer()
                Text(distanceString(record.totalDistance))
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            if !record.staySpots.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.orange)
                    Text("滞在スポット \(record.staySpots.count)件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if record.isInterrupted {
                Label("中断", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private func distanceString(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }

    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
        try? modelContext.save()
    }

    private func deleteAllRecords() {
        for record in records {
            modelContext.delete(record)
        }
        try? modelContext.save()
    }
}
