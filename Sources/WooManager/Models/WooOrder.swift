import Foundation

struct WooOrder: Codable, Identifiable, Hashable {
    let id: Int
    var status: String
    let dateCreated: String
    let total: String
    let currency: String?
    let billing: WooBilling?
    let shipping: WooShipping?
    let lineItems: [WooLineItem]?
    let customerNote: String?

    enum CodingKeys: String, CodingKey {
        case id, status, total, currency, billing, shipping
        case dateCreated = "date_created"
        case lineItems = "line_items"
        case customerNote = "customer_note"
    }

    var statusLabel: String {
        switch status {
        case "pending": return "En attente"
        case "processing": return "En cours"
        case "on-hold": return "En suspens"
        case "completed": return "Terminée"
        case "cancelled": return "Annulée"
        case "refunded": return "Remboursée"
        case "failed": return "Échouée"
        default: return status.capitalized
        }
    }

    var formattedDate: String {
        String(dateCreated.prefix(10))
    }

    var customerName: String {
        let first = billing?.firstName ?? ""
        let last = billing?.lastName ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Client" : name
    }

    var itemsSummary: String {
        (lineItems ?? []).map { "\($0.quantity)x \($0.name)" }.joined(separator: ", ")
    }
}

struct WooBilling: Codable, Hashable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?
    let address1: String?
    let city: String?
    let postcode: String?
    let country: String?

    enum CodingKeys: String, CodingKey {
        case email, phone, city, country
        case firstName = "first_name"
        case lastName = "last_name"
        case address1 = "address_1"
        case postcode = "postcode"
    }
}

struct WooShipping: Codable, Hashable {
    let firstName: String?
    let lastName: String?
    let address1: String?
    let city: String?
    let postcode: String?
    let country: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case address1 = "address_1"
        case city, postcode, country
    }
}

struct WooLineItem: Codable, Hashable {
    let name: String
    let quantity: Int
    let price: Double?
}
