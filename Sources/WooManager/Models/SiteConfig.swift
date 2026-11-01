import Foundation

struct SiteConfig: Codable {
    var siteURL: String
    var consumerKey: String
    var consumerSecret: String

    static let defaults = SiteConfig(siteURL: "", consumerKey: "", consumerSecret: "")

    var isValid: Bool {
        !siteURL.isEmpty && !consumerKey.isEmpty && !consumerSecret.isEmpty
    }
}

enum ConfigStore {
    private static let key = "woo.manager.site.config"

    static func load() -> SiteConfig {
        guard let data = UserDefaults.standard.data(forKey: key) else { return .defaults }
        return (try? JSONDecoder().decode(SiteConfig.self, from: data)) ?? .defaults
    }

    static func save(_ config: SiteConfig) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
