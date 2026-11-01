import SwiftUI

struct ProductEditor: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    let product: WooProduct

    @State private var price: String
    @State private var stock: Int
    @State private var manageStock: Bool
    @State private var published: Bool
    @State private var saving = false

    init(product: WooProduct) {
        self.product = product
        _price = State(initialValue: product.regularPrice ?? product.price ?? "")
        _stock = State(initialValue: product.stockQuantity ?? 0)
        _manageStock = State(initialValue: product.manageStock ?? false)
        _published = State(initialValue: product.status == "publish")
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(product.displayName).font(.title2).bold().lineLimit(2)
            Form {
                LabeledContent("Prix (€)") {
                    TextField("0.00", text: $price).textFieldStyle(.roundedBorder)
                }
                Toggle("Gérer le stock", isOn: $manageStock)
                if manageStock {
                    Stepper("Quantité : \(stock)", value: $stock)
                }
                Toggle("Publié sur le site", isOn: $published)
            }
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
                        updated.regularPrice = price
                        updated.stockQuantity = stock
                        updated.manageStock = manageStock
                        updated.status = published ? "publish" : "draft"
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
        .frame(width: 460, height: 360)
    }
}
