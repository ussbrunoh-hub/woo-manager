import SwiftUI

struct ProductEditor: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    let product: WooProduct

    @State private var name: String
    @State private var price: String
    @State private var salePrice: String
    @State private var stock: Int
    @State private var manageStock: Bool
    @State private var published: Bool
    @State private var description: String
    @State private var shortDescription: String
    @State private var saving = false

    init(product: WooProduct) {
        self.product = product
        _name = State(initialValue: product.displayName)
        _price = State(initialValue: product.regularPrice ?? product.price ?? "")
        _salePrice = State(initialValue: product.salePrice ?? "")
        _stock = State(initialValue: product.stockQuantity ?? 0)
        _manageStock = State(initialValue: product.manageStock ?? false)
        _published = State(initialValue: product.status == "publish")
        _description = State(initialValue: product.cleanDescription)
        _shortDescription = State(initialValue: (product.shortDescription ?? "").strippingHTML)
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("ID \(product.id)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                let region = regionPreview
                Text(region)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
            }
            Form {
                Section("Informations") {
                    LabeledContent("Nom") {
                        TextField("Nom du produit", text: $name)
                    }
                    LabeledContent("Prix") {
                        TextField("0.00", text: $price)
                    }
                    LabeledContent("Prix promo") {
                        TextField("0.00 (vide = aucun)", text: $salePrice)
                    }
                }
                Section("Stock et publication") {
                    Toggle("Gérer le stock", isOn: $manageStock)
                    if manageStock {
                        Stepper("Quantité : \(stock)", value: $stock)
                    }
                    Toggle("Publié sur le site", isOn: $published)
                }
                Section("Description courte") {
                    TextEditor(text: $shortDescription)
                        .frame(minHeight: 50)
                }
                Section("Description complète") {
                    TextEditor(text: $description)
                        .frame(minHeight: 110)
                }
            }
            .formStyle(.grouped)
            HStack {
                Button("Annuler") { dismiss() }
                Spacer()
                if saving {
                    ProgressView().controlSize(.small)
                }
                Button("Enregistrer") {
                    Task {
                        saving = true
                        var updated = product
                        updated.name = name
                        updated.regularPrice = price
                        updated.salePrice = salePrice
                        updated.stockQuantity = stock
                        updated.manageStock = manageStock
                        updated.status = published ? "publish" : "draft"
                        updated.description = description
                        updated.shortDescription = shortDescription
                        await state.saveProduct(updated)
                        saving = false
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(saving)
            }
        }
        .padding(20)
        .frame(width: 560, height: 620)
    }

    private var regionPreview: String {
        let code = product.regionCode ?? "—"
        switch code {
        case "EU": return "🇪🇺 Europe (EUR)"
        case "US": return "🇺🇸 USA (USD)"
        case "CH": return "🇨🇭 Suisse (CHF)"
        default: return "Région inconnue"
        }
    }
}
