import SwiftUI

struct ProductsView: View {
    @EnvironmentObject private var state: AppState
    @State private var search = ""
    @State private var editing: WooProduct?
    @State private var detail: WooProduct?
    @State private var regionFilter: String?

    private let regionFilters: [(String?, String)] = [
        (nil, "Toutes"),
        ("EU", "🇪🇺 Europe"),
        ("US", "🇺🇸 USA"),
        ("CH", "🇨🇭 Suisse"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if state.loadingProducts {
                Spacer()
                ProgressView("Chargement des produits…")
                Spacer()
            } else if filtered.isEmpty {
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

    private var filtered: [WooProduct] {
        guard let regionFilter else { return state.products }
        return state.products.filter { state.region(for: $0) == regionFilter }
    }

    private var toolbar: some View {
        HStack {
            TextField("Rechercher…", text: $search)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .onSubmit { Task { await state.loadProducts(search: search) } }
            Picker("Région", selection: $regionFilter) {
                ForEach(regionFilters, id: \.0) { item in
                    Text(item.1).tag(item.0)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 320)
            Button {
                Task { await state.loadProducts(search: search) }
            } label: {
                Label("Actualiser", systemImage: "arrow.clockwise")
            }
            Spacer()
            Text("\(filtered.count) produits")
                .foregroundStyle(.secondary)
        }
        .padding(10)
    }

    private var productTable: some View {
        Table(filtered) {
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
            TableColumn("Région") { product in
                let region = state.region(for: product)
                Text(regionLabel(region))
                    .foregroundStyle(regionColor(region))
            }
            TableColumn("Devise") { product in
                Text(state.currency(for: state.region(for: product)))
                    .foregroundStyle(.secondary)
            }
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

    private func regionLabel(_ region: String) -> String {
        switch region {
        case "EU": return "🇪🇺 Europe"
        case "US": return "🇺🇸 USA"
        case "CH": return "🇨🇭 Suisse"
        default: return "—"
        }
    }

    private func regionColor(_ region: String) -> Color {
        switch region {
        case "EU": return .blue
        case "US": return .purple
        case "CH": return .red
        default: return .secondary
        }
    }
}
