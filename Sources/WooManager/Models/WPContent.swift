import Foundation

struct WPPost: Codable, Identifiable, Hashable {
    let id: Int
    var title: WPRendered
    var excerpt: WPRendered?
    let status: String
    let date: String
    let link: String?
    let type: String

    var statusLabel: String {
        switch status {
        case "publish": return "Publié"
        case "draft": return "Brouillon"
        case "pending": return "En relecture"
        case "private": return "Privé"
        case "future": return "Programmé"
        case "trash": return "Corbeille"
        default: return status.capitalized
        }
    }

    var plainTitle: String {
        title.rendered.strippingHTML
    }

    var plainExcerpt: String {
        (excerpt?.rendered ?? "").strippingHTML
    }
}

struct WPRendered: Codable, Hashable {
    let rendered: String
}

extension String {
    var strippingHTML: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&#8211;", with: "–")
            .replacingOccurrences(of: "&#8217;", with: "'")
            .replacingOccurrences(of: "&#8230;", with: "…")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
