import Foundation

struct WooProduct: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let slug: String?
    let permalink: String?
    var status: String
    var catalogVisibility: String?
    var description: String?
    var shortDescription: String?
    var sku: String?
    var price: String?
    var regularPrice: String?
    var salePrice: String?
    var onSale: Bool?
    var stockStatus: String?
    var stockQuantity: Int?
    var manageStock: Bool?
    var weight: String?
    var type: String?
    var categories: [WooCategory]?
    var images: [WooImage]?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, permalink, status
        case catalogVisibility = "catalog_visibility"
        case description
        case shortDescription = "short_description"
        case sku, price
        case regularPrice = "regular_price"
        case salePrice = "sale_price"
        case onSale = "on_sale"
        case stockStatus = "stock_status"
        case stockQuantity = "stock_quantity"
        case manageStock = "manage_stock"
        case weight, type, categories, images
    }

    var displayName: String { name.replacingOccurrences(of: "&#8211;", with: "–").replacingOccurrences(of: "&#8217;", with: "'").replacingOccurrences(of: "&amp;", with: "&") }

    var displayPrice: String {
        guard let price, !price.isEmpty else { return "—" }
        return "\(price) €"
    }

    var categoryNames: String {
        (categories ?? []).map(\.name).joined(separator: ", ")
    }

    var imageURL: URL? {
        images?.first?.src
    }
}

struct WooCategory: Codable, Hashable {
    let id: Int
    let name: String
}

struct WooImage: Codable, Hashable {
    let id: Int?
    let src: String
}
