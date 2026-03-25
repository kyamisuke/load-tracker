import StoreKit

protocol TipJarServiceProtocol: AnyObject {
    var products: [Product] { get }
    var isLoading: Bool { get }
    func loadProducts() async
    func purchase(_ product: Product) async throws -> Bool
}
