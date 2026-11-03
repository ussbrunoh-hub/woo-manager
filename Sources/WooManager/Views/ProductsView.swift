import SwiftUI

struct ProductsView: View {
    @EnvironmentObject private var state: AppState
    @State private var search = ""
    @State private var editing: WooProduct?
    @State private var detail: WooProduct?
    @State private var regionFilter: String?
    @State private var groupedMode = false

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
            } else if filteredProducts.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "shippingbox")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(state.products.isEmpty ? (state.errorMessage ?? "Aucun produit") : "Aucun produit pour cette zone")
                        .bold()
                    Text(state.products.isEmpty ? "Vérifiez Réglages puis cliquez sur « Actualiser »." : "Changez de filtre de région.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else if groupedMode {
                groupedList
            } else {
                productTable
            }
        }
        .task {
            if state.products.isEmpty && state.config.isValid {
                await state.loadProducts()
            }
        }
        .onChange(of: state.config.isValid) { _, valid in
            if valid && state.products.isEmpty {
                Task { await state.loadProducts() }
            }
        }
        .sheet(item: $editing) { product in
            ProductEditor(product: product)
        }
        .sheet(item: $detail) { product in
            ProductDetail(product: product)
        }
    }

    private var filteredProducts: [WooProduct] {
        guard let regionFilter else { return state.products }
        return state.products.filter { state.region(for: $0) == regionFilter }
    }

    private var toolbar: some View {
        HStack {
            TextField("Rechercher…", text: $search)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
                .onSubmit { Task { await state.loadProducts(search: search) } }
            Picker("Région", selection: $regionFilter) {
                ForEach(regionFilters, id: \.0) { item in
                    Text(item.1).tag(item.0)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
            Picker("Vue", selection: $groupedMode) {
                Text("Par zone").tag(false)
                Text("Groupée").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 170)
            Button {
                Task { await state.loadProducts(search: search) }
            } label: {
                Label("Actualiser", systemImage: "arrow.clockwise")
            }
            Spacer()
            Text("\(filteredProducts.count) produits")
                .foregroundStyle(.secondary)
        }
        .padding(10)
    }

    // MARK: - Vue groupée

    private var productGroups: [(key: String, items: [WooProduct])] {
        let dict = Dictionary(grouping: filteredProducts) { $0.groupKey }
        return dict
            .map { (key: $0.key, items: $0.value.sorted { regionOrder($0) < regionOrder($1) }) }
            .sorted { ($0.items.first?.displayName ?? "") < ($1.items.first?.displayName ?? "") }
    }

    private func regionOrder(_ product: WooProduct) -> Int {
        switch state.region(for: product) {
        case "EU": return 0
        case "CH": return 1
        case "US": return 2
        default: return 3
        }
    }

    private var groupedList: some View {
        List {
            ForEach(productGroups, id: \.key) { group in
                DisclosureGroup {
                    ForEach(group.items) { product in
                        groupRow(product)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if let url = group.items.first?.imageURL {
                            AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.15) }
                                .frame(width: 26, height: 26)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Text(group.items.first?.displayName ?? "—")
                            .bold()
                        Spacer()
                        Text("\(group.items.count) version\(group.items.count > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func groupRow(_ product: WooProduct) -> some View {
        let region = state.region(for: product)
        return HStack {
            regionPill(region)
            Text(product.displayName)
                .lineLimit(1)
            Spacer()
            Text("\(product.displayPrice) \(state.currency(for: region))")
                .bold()
            Text(product.manageStock == true ? "Stock : \(product.stockQuantity ?? 0)" : (product.stockStatus == "instock" ? "En stock" : "Rupture"))
                .foregroundStyle(.secondary)
                .font(.callout)
            Button("Détails") { detail = product }
                .buttonStyle(.link)
            Button("Modifier") { editing = product }
                .buttonStyle(.link)
        }
        .padding(.vertical, 2)
    }

    private func regionPill(_ region: String) -> some View {
        Text(regionLabel(region))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(regionColor(region).opacity(0.15))
            .clipShape(Capsule())
            .font(.caption)
            .foregroundStyle(regionColor(region))
    }

    // MARK: - Table par zone

    private var productTable: some View {
        Table(filteredProducts) {
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
