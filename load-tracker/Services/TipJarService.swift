import Combine
import StoreKit

@MainActor
final class TipJarService: ObservableObject, @preconcurrency TipJarServiceProtocol {

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false

    private let productIDs = [
        "tip_coffee",
        "tip_lunch",
        "tip_dinner",
        "tip_feast"
    ]

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: productIDs)
            products = productIDs.compactMap { id in
                fetched.first { $0.id == id }
            }
        } catch {
            products = []
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
