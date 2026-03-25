import SwiftUI
import StoreKit

struct TipJarSheet: View {
    @StateObject private var service = TipJarService()
    @Environment(\.dismiss) private var dismiss
    @State private var purchaseState: PurchaseState = .idle

    var body: some View {
        ZStack {
            Color.App.bgPrimary.ignoresSafeArea()

            switch purchaseState {
            case .success(let product):
                thankYouView(for: product)
            default:
                mainContent
            }
        }
        .task {
            await service.loadProducts()
        }
        .presentationBackground(Color.App.bgPrimary)
        .presentationDragIndicator(.visible)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: AppSpacing.sm) {
                Text("☕")
                    .font(.system(size: 56))
                    .padding(.top, AppSpacing.xxl)

                Text("開発者にごちそうする")
                    .font(AppFont.display(AppFont.Size.titleXL))
                    .foregroundStyle(Color.App.textPrimary)

                Text("あしあとを気に入ってもらえたら、\nコーヒー1杯おごってくれると嬉しいです")
                    .font(AppFont.body(AppFont.Size.body))
                    .foregroundStyle(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            Spacer()

            Group {
                if service.isLoading {
                    loadingView
                } else if service.products.isEmpty {
                    unavailableView
                } else {
                    tipButtonsList
                }
            }

            Spacer()

            if case .failure(let message) = purchaseState {
                Text(message)
                    .font(AppFont.body(AppFont.Size.caption))
                    .foregroundStyle(Color.Primitive.ember)
                    .padding(.bottom, AppSpacing.xs)
            }

            Button("また今度") {
                dismiss()
            }
            .font(AppFont.body(AppFont.Size.labelMD))
            .foregroundStyle(Color.App.textSecondary)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    // MARK: - Tip Buttons

    private var tipButtonsList: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(service.products, id: \.id) { product in
                tipButton(for: product)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func tipButton(for product: Product) -> some View {
        let meta = TipMeta.from(productID: product.id)
        let isPurchasing = purchaseState.isPurchasing

        return Button {
            Task { await executePurchase(product) }
        } label: {
            HStack {
                Text(meta.emoji)
                    .font(.system(size: 22))
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(meta.title)
                        .font(AppFont.heading(AppFont.Size.labelLG))
                        .foregroundStyle(Color.App.textPrimary)
                    Text(meta.subtitle)
                        .font(AppFont.body(AppFont.Size.caption))
                        .foregroundStyle(Color.App.textSecondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(AppFont.heading(AppFont.Size.labelLG))
                    .foregroundStyle(Color.Primitive.amber)
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: Token.Button.height)
            .background(Color.App.bgCard, in: RoundedRectangle(cornerRadius: Token.Button.radius))
            .overlay(
                RoundedRectangle(cornerRadius: Token.Button.radius)
                    .stroke(Color.App.buttonSecondaryBorder, lineWidth: 1)
            )
        }
        .disabled(isPurchasing)
        .opacity(isPurchasing ? 0.6 : 1.0)
        .animation(AppAnimation.tap, value: isPurchasing)
    }

    // MARK: - Loading / Unavailable

    private var loadingView: some View {
        VStack(spacing: AppSpacing.sm) {
            ProgressView()
                .tint(Color.Primitive.amber)
            Text("読み込み中...")
                .font(AppFont.body(AppFont.Size.body))
                .foregroundStyle(Color.App.textSecondary)
        }
    }

    private var unavailableView: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32))
                .foregroundStyle(Color.App.textFaint)
            Text("現在ご利用いただけません")
                .font(AppFont.body(AppFont.Size.body))
                .foregroundStyle(Color.App.textSecondary)
        }
    }

    // MARK: - Thank You

    private func thankYouView(for product: Product) -> some View {
        let meta = TipMeta.from(productID: product.id)

        return VStack(spacing: AppSpacing.lg) {
            Spacer()

            Text(meta.emoji)
                .font(.system(size: 80))

            VStack(spacing: AppSpacing.sm) {
                Text("ありがとう！")
                    .font(AppFont.display(AppFont.Size.titleXL))
                    .foregroundStyle(Color.App.textPrimary)
                Text("\(meta.title)のお礼、ちゃんと受け取りました\nこれからも改善がんばります！")
                    .font(AppFont.body(AppFont.Size.body))
                    .foregroundStyle(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("閉じる")
                    .font(Token.Button.font)
                    .foregroundStyle(Token.Button.primaryFg)
                    .frame(maxWidth: .infinity)
                    .frame(height: Token.Button.height)
                    .background(Token.Button.primaryBg, in: RoundedRectangle(cornerRadius: Token.Button.radius))
                    .appShadow(Token.Button.primaryShadow)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Purchase Flow

    private func executePurchase(_ product: Product) async {
        purchaseState = .purchasing
        do {
            let success = try await service.purchase(product)
            if success {
                withAnimation(AppAnimation.transition) {
                    purchaseState = .success(product)
                }
            } else {
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failure("購入できませんでした")
            try? await Task.sleep(for: .seconds(3))
            purchaseState = .idle
        }
    }
}

// MARK: - Purchase State

private enum PurchaseState {
    case idle
    case purchasing
    case success(Product)
    case failure(String)

    var isPurchasing: Bool {
        if case .purchasing = self { return true }
        return false
    }
}

// MARK: - Tip Metadata

private struct TipMeta {
    let emoji: String
    let title: String
    let subtitle: String

    static func from(productID: String) -> TipMeta {
        switch productID {
        case "tip_coffee":
            TipMeta(emoji: "☕", title: "コーヒー1杯", subtitle: "ちょっと一息")
        case "tip_lunch":
            TipMeta(emoji: "🍱", title: "ランチ1回", subtitle: "お腹いっぱい")
        case "tip_dinner":
            TipMeta(emoji: "🍽️", title: "ディナー1回", subtitle: "豪勢にいきましょ")
        case "tip_feast":
            TipMeta(emoji: "🥩", title: "ごちそう", subtitle: "最高にうれしい")
        default:
            TipMeta(emoji: "🎁", title: "サポート", subtitle: "ありがとう")
        }
    }
}
