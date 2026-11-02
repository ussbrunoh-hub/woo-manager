import Foundation

enum WooError: LocalizedError {
    case invalidURL
    case invalidResponse
    case http(Int, String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL du site invalide. Vérifiez le format (https://monsite.com)."
        case .invalidResponse:
            return "Réponse invalide du serveur."
        case .http(let code, let body):
            let hint: String
            switch code {
            case 401, 403: hint = " Clé API refusée : vérifiez la clé/le secret WooCommerce."
            case 404: hint = " API introuvable : l'API REST WooCommerce est peut-être désactivée."
            default: hint = ""
            }
            return "Erreur HTTP \(code).\(hint)\(body.isEmpty ? "" : "\n\(body.prefix(300))")"
        case .decoding(let message):
            return "Données inattendues : \(message)"
        }
    }
}

final class WooClient {
    private let session: URLSession
    private let baseURL: URL
    private let key: String
    private let secret: String

    init(config: SiteConfig) {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 30
        cfg.waitsForConnectivity = true
        self.session = URLSession(configuration: cfg)
        var url = config.siteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !url.hasPrefix("http") { url = "https://" + url }
        url = url
            .replacingOccurrences(of: "wp-json", with: "")
            .replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
        self.baseURL = URL(string: url) ?? URL(string: "https://invalid")!
        self.key = config.consumerKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.secret = config.consumerSecret.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func request(path: String, query: [URLQueryItem] = [], method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("wp-json").appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw WooError.invalidURL
        }
        var items = query
        items.append(URLQueryItem(name: "consumer_key", value: key))
        items.append(URLQueryItem(name: "consumer_secret", value: secret))
        components.queryItems = items.isEmpty ? nil : items
        guard let url = components.url else { throw WooError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 30
        if let body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return req
    }

    private func run<T: Decodable>(_ req: URLRequest, as type: T.Type) async throws -> T {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw WooError.invalidResponse
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw WooError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw WooError.decoding(error.localizedDescription)
        }
    }

    func products(page: Int = 1, search: String? = nil, status: String? = nil) async throws -> [WooProduct] {
        var query = [URLQueryItem(name: "per_page", value: "50"), URLQueryItem(name: "page", value: "\(page)"), URLQueryItem(name: "orderby", value: "title"), URLQueryItem(name: "order", value: "asc")]
        if let search, !search.isEmpty { query.append(URLQueryItem(name: "search", value: search)) }
        if let status { query.append(URLQueryItem(name: "status", value: status)) }
        return try await run(try request(path: "wc/v3/products", query: query), as: [WooProduct].self)
    }

    func updateProduct(_ product: WooProduct) async throws -> WooProduct {
        struct Update: Codable { let regularPrice: String?; let stockQuantity: Int?; let status: String?
            enum CodingKeys: String, CodingKey { case regularPrice = "regular_price"; case stockQuantity = "stock_quantity"; case status }
        }
        let body = try JSONEncoder().encode(Update(regularPrice: product.regularPrice, stockQuantity: product.stockQuantity, status: product.status))
        return try await run(try request(path: "wc/v3/products/\(product.id)", method: "PUT", body: body), as: WooProduct.self)
    }

    func orders(page: Int = 1, status: String? = nil) async throws -> [WooOrder] {
        var query = [URLQueryItem(name: "per_page", value: "50"), URLQueryItem(name: "page", value: "\(page)"), URLQueryItem(name: "orderby", value: "date"), URLQueryItem(name: "order", value: "desc")]
        if let status { query.append(URLQueryItem(name: "status", value: status)) }
        return try await run(try request(path: "wc/v3/orders", query: query), as: [WooOrder].self)
    }

    func updateOrderStatus(id: Int, status: String) async throws -> WooOrder {
        struct Update: Codable { let status: String }
        let body = try JSONEncoder().encode(Update(status: status))
        return try await run(try request(path: "wc/v3/orders/\(id)", method: "PUT", body: body), as: WooOrder.self)
    }

    func posts(type: String = "posts", page: Int = 1, status: String? = nil) async throws -> [WPPost] {
        var query = [URLQueryItem(name: "per_page", value: "50"), URLQueryItem(name: "page", value: "\(page)")]
        if let status { query.append(URLQueryItem(name: "status", value: status)) }
        return try await run(try request(path: "wp/v2/\(type)", query: query), as: [WPPost].self)
    }

    func regionMap() async throws -> [Int: String] {
        struct RegionRow: Decodable {
            let name: String?
            let EU_Product_id: String?
            let Swiss_Product_ID: String?
            let USA_Product_ID: String?
        }
        let rows: [RegionRow] = try await run(try request(path: "wooregion/v1/map"), as: [RegionRow].self)
        var map: [Int: String] = [:]
        for row in rows {
            if let id = Int(row.EU_Product_id ?? "") { map[id] = "EU" }
            if let id = Int(row.Swiss_Product_ID ?? "") { map[id] = "CH" }
            if let id = Int(row.USA_Product_ID ?? "") { map[id] = "US" }
        }
        return map
    }
}
