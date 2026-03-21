import SwiftUI

struct OnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onStart: () async throws -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.walk.motion")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            VStack(spacing: 12) {
                Text("経路トラッカー")
                    .font(.largeTitle.bold())
                Text("歩いた道を自動で記録します")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "location.fill", text: "バックグラウンドで自動記録")
                featureRow(icon: "map.fill", text: "地図上で経路を確認")
                featureRow(icon: "mappin.circle.fill", text: "滞在スポットを自動検出")
                featureRow(icon: "lock.shield.fill", text: "データは端末内のみに保存")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                Task {
                    try? await onStart()
                    dismiss()
                }
            } label: {
                Text("記録を開始")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 28)
            Text(text)
                .font(.body)
        }
    }
}
