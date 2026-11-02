import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var config: SiteConfig {
        didSet { ConfigStore.save(config) }
    }
    @Published var products: [WooProduct] = []
    @Published var orders: [WooOrder] = []
    @Published var posts: [WPPost] = []
    @Published var pages: [WPPost] = []
    @Published var regionByProduct: [Int: String] = [:]
    @Published var loadingProducts = false
    @Published var loadingOrders = false
    @Published var loadingContent = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private var client: WooClient?

    init() {
        self.config = ConfigStore.load()
        self.client = config.isValid ? WooClient(config: config) : nil
    }

    func reconnectIfNeeded() {
        if config.isValid { client = WooClient(config: config) }
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    func region(for product: WooProduct) -> String {
        regionByProduct[product.id] ?? "—"
    }

    func currency(for region: String) -> String {
        switch region {
        case "EU": return "EUR"
        case "CH": return "CHF"
        case "US": return "USD"
        default: return ""
        }
    }

    func loadProducts(search: String = "") async {
        reconnectIfNeeded()
        guard let client else { errorMessage = "Configurez le site dans Réglages d'abord."; return }
        loadingProducts = true
        defer { loadingProducts = false }
        do {
            async let p = client.products(search: search.isEmpty ? nil : search)
            async let r = try? client.regionMap()
            let loaded = try await p
            products = loaded
            if let map = await r {
                regionByProduct = map
            }
            if loaded.isEmpty {
                errorMessage = "Le site n'a renvoyé aucun produit. Vérifiez que la boutique contient des produits publiés."
            }
        } catch {
            handleError(error)
        }
    }

    func saveProduct(_ product: WooProduct) async {
        guard let client else { return }
        do {
            let updated = try await client.updateProduct(product)
            if let index = products.firstIndex(where: { $0.id == updated.id }) {
                products[index] = updated
            }
            infoMessage = "Produit « \(updated.displayName) » mis à jour."
        } catch { handleError(error) }
    }

    func loadOrders(status: String? = nil) async {
        reconnectIfNeeded()
        guard let client else { errorMessage = "Configurez le site dans Réglages d'abord."; return }
        loadingOrders = true
        defer { loadingOrders = false }
        do {
            orders = try await client.orders(status: status)
        } catch { handleError(error) }
    }

    func setOrderStatus(_ order: WooOrder, status: String) async {
        guard let client else { return }
        do {
            let updated = try await client.updateOrderStatus(id: order.id, status: status)
            if let index = orders.firstIndex(where: { $0.id == updated.id }) {
                orders[index] = updated
            }
            infoMessage = "Commande #\(updated.id) → \(updated.statusLabel)."
        } catch { handleError(error) }
    }

    func loadContent() async {
        reconnectIfNeeded()
        guard let client else { errorMessage = "Configurez le site dans Réglages d'abord."; return }
        loadingContent = true
        defer { loadingContent = false }
        do {
            async let p = client.posts(type: "posts", status: "publish,draft,pending,private,future")
            async let g = client.posts(type: "pages", status: "publish,draft,pending,private,future")
            posts = try await p
            pages = try await g
        } catch { handleError(error) }
    }
}
