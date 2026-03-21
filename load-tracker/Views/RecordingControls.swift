import SwiftUI

struct RecordingControls: View {
    @ObservedObject var trackingService: LocationTrackingService
    var onResume: () async throws -> Void

    var body: some View {
        VStack {
            Spacer()
            switch trackingService.state {
            case .idle:
                startButton
            case .recording:
                recordingIndicator
            case .interrupted:
                interruptedBanner
            }
        }
        .padding(.bottom, 40)
    }

    private var startButton: some View {
        Button {
            Task { try? await trackingService.startRecording() }
        } label: {
            Label("記録を開始", systemImage: "location.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 24)
    }

    private var recordingIndicator: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                Text("記録中")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
            }
            Button {
                Task { await trackingService.stopRecording() }
            } label: {
                Label("停止", systemImage: "stop.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
        }
    }

    private var interruptedBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("記録が中断されました")
                    .font(.subheadline.bold())
            }
            Button {
                Task { try? await onResume() }
            } label: {
                Label("記録を再開", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
    }
}
