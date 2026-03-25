import SwiftUI

struct RecordingControls: View {
    @ObservedObject var trackingService: LocationTrackingService
    var onResume: () async throws -> Void

    @State private var isPressing = false
    @State private var pulseActive = false

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

    // MARK: - Start Button (idle)

    private var startButton: some View {
        Button {
            Task { try? await trackingService.startRecording() }
        } label: {
            Label("記録を始める", systemImage: "location.fill")
                .font(Token.Button.font)
                .foregroundStyle(Token.Button.primaryFg)
                .frame(maxWidth: .infinity)
                .frame(height: Token.Button.height)
                .background(Token.Button.primaryBg, in: RoundedRectangle(cornerRadius: Token.Button.radius))
                .appShadow(Token.Button.primaryShadow)
        }
        .scaleEffect(isPressing ? 0.97 : 1.0)
        .opacity(isPressing ? 0.9 : 1.0)
        .animation(AppAnimation.tap, value: isPressing)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressing = true }
                .onEnded { _ in isPressing = false }
        )
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Recording Indicator

    private var recordingIndicator: some View {
        VStack(spacing: AppSpacing.sm) {
            // Recording Badge (pill)
            HStack(spacing: AppSpacing.xs) {
                Circle()
                    .fill(Token.RecordingBadge.dot)
                    .frame(width: 10, height: 10)
                    .opacity(pulseActive ? 0.3 : 1.0)
                    .animation(Token.RecordingBadge.animation, value: pulseActive)
                Text("記録中")
                    .font(AppFont.heading(AppFont.Size.caption))
                    .foregroundStyle(Token.RecordingBadge.label)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(Token.RecordingBadge.bg, in: Capsule())
            .overlay(Capsule().stroke(Token.RecordingBadge.border, lineWidth: 1))
            .onAppear { pulseActive = true }
            .onDisappear { pulseActive = false }

            // Stop Button (secondary)
            Button {
                Task { await trackingService.stopRecording() }
            } label: {
                Label("記録を止める", systemImage: "stop.fill")
                    .font(Token.Button.font)
                    .foregroundStyle(Token.Button.secondaryFg)
                    .frame(maxWidth: .infinity)
                    .frame(height: Token.Button.height)
                    .background(
                        RoundedRectangle(cornerRadius: Token.Button.radius)
                            .stroke(Token.Button.secondaryBorder, lineWidth: 1.5)
                    )
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    // MARK: - Interrupted Banner

    private var interruptedBanner: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.Primitive.ember)
                Text("一部記録あり")
                    .font(AppFont.heading(AppFont.Size.labelMD))
                    .foregroundStyle(Color.App.textPrimary)
            }
            Button {
                Task { try? await onResume() }
            } label: {
                Label("記録を再開", systemImage: "arrow.clockwise")
                    .font(Token.Button.font)
                    .foregroundStyle(Token.Button.primaryFg)
                    .frame(maxWidth: .infinity)
                    .frame(height: Token.Button.height)
                    .background(Token.Button.primaryBg, in: RoundedRectangle(cornerRadius: Token.Button.radius))
                    .appShadow(Token.Button.primaryShadow)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .padding(AppSpacing.md)
        .background(Color.App.bgCard, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .padding(.horizontal, AppSpacing.md)
    }
}
