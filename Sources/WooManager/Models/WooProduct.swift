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
    var attributes: [WooAttribute]?
    var metaData: [WooMeta]?

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
        case weight, type, categories, images, attributes
        case metaData = "meta_data"
    }

    var displayName: String { name.strippingHTML }

    var displayPrice: String {
        guard let price, !price.isEmpty else { return "—" }
        return price
    }

    var categoryNames: String {
        (categories ?? []).map(\.name).joined(separator: ", ")
    }

    var imageURL: URL? {
        guard let src = images?.first?.src else { return nil }
        return URL(string: src)
    }

    var cleanDescription: String {
        (description ?? "").strippingHTML
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

struct WooAttribute: Codable, Hashable {
    let id: Int?
    let name: String
    let options: [String]?
    let variation: Bool?

    var optionsText: String {
        (options ?? []).joined(separator: " · ")
    }
}

struct WooMeta: Codable, Hashable {
    let key: String
    let value: WooMetaValue?
}

enum WooMetaValue: Codable, Hashable {
    case string(String)
    case int(Int)
    case other

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else {
            self = .other
        }
    }

    func encode(to encoder: Encoder) throws {}

    var display: String {
        switch self {
        case .string(let s): return s
        case .int(let i): return "\(i)"
        case .other: return "—"
        }
    }
}
