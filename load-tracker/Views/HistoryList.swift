import SwiftUI
import SwiftData

struct HistoryList: View {
    @Query(sort: \RouteRecord.startedAt, order: .reverse)
    private var records: [RouteRecord]

    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAllConfirmation = false


    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(records) { record in
                    NavigationLink(destination: RouteDetailMap(record: record)) {
                        historyCard(record)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("削除", role: .destructive) {
                            deleteRecord(record)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .background(Color.App.bgPrimary)
        .navigationTitle("履歴")
        .toolbar {
            if !records.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("全削除", role: .destructive) {
                        showDeleteAllConfirmation = true
                    }
                    .foregroundStyle(Color.Primitive.ember)
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
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.App.textFaint)
                    Text("履歴がありません")
                        .font(AppFont.heading(AppFont.Size.titleMD))
                        .foregroundStyle(Color.App.textSecondary)
                    Text("経路を記録すると、ここに表示されます")
                        .font(AppFont.body(AppFont.Size.body))
                        .foregroundStyle(Color.App.textFaint)
                }
            }
        }
    }

    // MARK: - History Card

    private func historyCard(_ record: RouteRecord) -> some View {
        HStack(spacing: 0) {
            // Left accent line
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor(for: record))
                .frame(width: Token.HistoryCard.accentWidth)
                .padding(.vertical, AppSpacing.xs)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                // Date
                Text(relativeDateString(record.startedAt))
                    .font(AppFont.body(AppFont.Size.caption))
                    .foregroundStyle(Color.App.textSecondary)

                // Distance
                Text(distanceString(record.totalDistance))
                    .font(Token.HistoryCard.distFont)
                    .foregroundStyle(Color.App.textPrimary)

                // Time range
                HStack(spacing: AppSpacing.xxs) {
                    Text(timeString(record.startedAt))
                    Text("→")
                        .foregroundStyle(Color.App.textFaint)
                    if let stopped = record.stoppedAt {
                        Text(timeString(stopped))
                    } else {
                        statusTag(text: "記録中", style: .stay)
                    }
                }
                .font(AppFont.body(AppFont.Size.caption))
                .foregroundStyle(Color.App.textSecondary)

                // Tags row
                HStack(spacing: AppSpacing.xs) {
                    if !record.staySpots.isEmpty {
                        statusTag(
                            text: "立ち寄り \(record.staySpots.count)件",
                            icon: "mappin.circle.fill",
                            style: .stay
                        )
                    }
                    if record.isInterrupted {
                        statusTag(
                            text: "一部記録あり",
                            icon: "exclamationmark.triangle.fill",
                            style: .warn
                        )
                    }
                }
            }
            .padding(.leading, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm)

            Spacer()
        }
        .background(Token.HistoryCard.bg, in: RoundedRectangle(cornerRadius: Token.HistoryCard.radius))
        .overlay(
            RoundedRectangle(cornerRadius: Token.HistoryCard.radius)
                .stroke(Token.HistoryCard.border, lineWidth: 1)
        )
    }

    // MARK: - Status Tag

    private enum TagStyle { case stay, warn, ok }

    private func statusTag(text: String, icon: String? = nil, style: TagStyle) -> some View {
        let (bg, fg, border): (Color, Color, Color) = {
            switch style {
            case .stay:  return (Token.Tag.Stay.bg, Token.Tag.Stay.fg, Token.Tag.Stay.border)
            case .warn:  return (Token.Tag.Warn.bg, Token.Tag.Warn.fg, Token.Tag.Warn.border)
            case .ok:    return (Token.Tag.Ok.bg, Token.Tag.Ok.fg, Token.Tag.Ok.border)
            }
        }()

        return HStack(spacing: AppSpacing.xxs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: AppFont.Size.micro))
            }
            Text(text)
                .font(AppFont.heading(AppFont.Size.micro))
        }
        .foregroundStyle(fg)
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, 3)
        .background(bg, in: Capsule())
        .overlay(Capsule().stroke(border, lineWidth: 0.5))
    }

    // MARK: - Helpers

    private func accentColor(for record: RouteRecord) -> Color {
        if record.isRecording {
            return Token.HistoryCard.accentActive
        } else if record.isInterrupted {
            return Token.HistoryCard.accentInterrupted
        } else {
            return Token.HistoryCard.accentNormal
        }
    }

    private func relativeDateString(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "今日"
        } else if Calendar.current.isDateInYesterday(date) {
            return "昨日"
        } else {
            return date.formatted(.dateTime.month().day().weekday())
        }
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

    private func deleteRecord(_ record: RouteRecord) {
        modelContext.delete(record)
        try? modelContext.save()
    }

    private func deleteAllRecords() {
        for record in records {
            modelContext.delete(record)
        }
        try? modelContext.save()
    }
}
