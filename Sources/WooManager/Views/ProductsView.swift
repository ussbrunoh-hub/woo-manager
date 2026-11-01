import SwiftUI

struct ProductsView: View {
    @EnvironmentObject private var state: AppState
    @State private var search = ""
    @State private var editing: WooProduct?
    @State private var detail: WooProduct?

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if state.loadingProducts {
                Spacer()
                ProgressView("Chargement des produits…")
                Spacer()
            } else if state.products.isEmpty {
                Spacer()
                ContentUnavailableView("Aucun produit", systemImage: "shippingbox", description: Text("Cliquez sur « Actualiser » ou recherchez."))
                Spacer()
            } else {
                productTable
            }
        }
        .task { if state.products.isEmpty { await state.loadProducts() } }
        .sheet(item: $editing) { product in
            ProductEditor(product: product)
        }
        .sheet(item: $detail) { product in
            ProductDetail(product: product)
        }
    }

    private var toolbar: some View {
        HStack {
            TextField("Rechercher…", text: $search)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
                .onSubmit { Task { await state.loadProducts(search: search) } }
            Button {
                Task { await state.loadProducts(search: search) }
            } label: {
                Label("Actualiser", systemImage: "arrow.clockwise")
            }
            Spacer()
            Text("\(state.products.count) produits")
                .foregroundStyle(.secondary)
        }
        .padding(10)
    }

    private var productTable: some View {
        Table(state.products) {
            TableColumn("Produit") { product in
                HStack(spacing: 8) {
                    if let url = product.imageURL {
                        AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.15) }
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Text(product.displayName)
                }
            }
            TableColumn("SKU") { product in Text(product.sku ?? "—").foregroundStyle(.secondary) }
            TableColumn("Catégories") { product in
                Text(product.categoryNames)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            TableColumn("Prix") { product in
                Text(product.displayPrice)
            }
            TableColumn("Stock") { product in
                Text(product.manageStock == true ? "\(product.stockQuantity ?? 0)" : (product.stockStatus == "instock" ? "En stock" : "Rupture"))
            }
            TableColumn("Statut") { product in
                Text(product.status == "publish" ? "Publié" : "Brouillon")
                    .foregroundStyle(product.status == "publish" ? .green : .orange)
            }
            TableColumn("") { product in
                HStack(spacing: 6) {
                    Button("Détails") { detail = product }
                    Button("Modifier") { editing = product }
                }
            }
        }
    }
}
