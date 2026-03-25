import SwiftUI

struct OnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onStart: () async throws -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "figure.walk.motion")
                .font(.system(size: 80))
                .foregroundStyle(Color.Primitive.amber)

            VStack(spacing: AppSpacing.sm) {
                Text("あしあと")
                    .font(AppFont.display(AppFont.Size.display))
                    .foregroundStyle(Color.App.textPrimary)
                Text("昨日どこいったっけ？\n歩いた道をこっそり自動記録します")
                    .font(AppFont.body(AppFont.Size.body))
                    .foregroundStyle(Color.App.textSecondary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                featureRow(icon: "location.fill", text: "バックグラウンドで自動記録")
                featureRow(icon: "map.fill", text: "地図上で経路を確認")
                featureRow(icon: "mappin.circle.fill", text: "立ち寄りスポットを自動検出")
                featureRow(icon: "lock.shield.fill", text: "データは端末内のみに保存")
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()

            Button {
                Task {
                    try? await onStart()
                    dismiss()
                }
            } label: {
                Text("記録を始める")
                    .font(Token.Button.font)
                    .foregroundStyle(Token.Button.primaryFg)
                    .frame(maxWidth: .infinity)
                    .frame(height: Token.Button.height)
                    .background(Token.Button.primaryBg, in: RoundedRectangle(cornerRadius: Token.Button.radius))
                    .appShadow(Token.Button.primaryShadow)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.md)
        }
        .background(Color.App.bgPrimary)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Color.Primitive.amber)
                .frame(width: 28, height: 28)
                .background(Color.Primitive.amberGlow, in: RoundedRectangle(cornerRadius: AppRadius.icon))
            Text(text)
                .font(AppFont.body(AppFont.Size.body))
                .foregroundStyle(Color.App.textPrimary)
        }
    }
}
