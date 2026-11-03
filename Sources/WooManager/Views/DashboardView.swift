import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                productsCard
                ordersCard
                revenueCard
                stockCard
            }
            .padding(20)
        }
        .task {
            if state.products.isEmpty { await state.loadProducts() }
            if state.orders.isEmpty { await state.loadOrders() }
        }
    }

    private var productsCard: some View {
        card("Produits", icon: "shippingbox", color: .blue) {
            statRow("Total chargés", "\(state.products.count)")
            ForEach(regionCounts, id: \.0) { item in
                statRow(regionName(item.0), "\(item.1)")
            }
        }
    }

    private var ordersCard: some View {
        card("Commandes", icon: "cart", color: .purple) {
            statRow("Total chargées", "\(state.orders.count)")
            ForEach(orderStatusCounts, id: \.0) { item in
                statRow(item.0, "\(item.1)")
            }
        }
    }

    private var revenueCard: some View {
        card("Chiffre d'affaires", icon: "banknote", color: .green) {
            if revenueByCurrency.isEmpty {
                Text("Aucune commande chargée.").foregroundStyle(.secondary)
            } else {
                ForEach(revenueByCurrency, id: \.0) { item in
                    statRow(item.0, formattedAmount(item.1))
                }
            }
        }
    }

    private var stockCard: some View {
        card("Ruptures de stock", icon: "exclamationmark.triangle", color: .orange) {
            if outOfStockProducts.isEmpty {
                Text("Aucune rupture 🎉").foregroundStyle(.secondary)
            } else {
                statRow("Produits en rupture", "\(outOfStockProducts.count)")
                ForEach(outOfStockProducts.prefix(5)) { p in
                    HStack {
                        Text("• \(p.displayName)").lineLimit(1)
                        Spacer()
                        Text(regionBadge(state.region(for: p)))
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                }
                if outOfStockProducts.count > 5 {
                    Text("… et \(outOfStockProducts.count - 5) autres")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Stats

    private var regionCounts: [(String, Int)] {
        var counts: [String: Int] = ["EU": 0, "US": 0, "CH": 0, "—": 0]
        for p in state.products {
            counts[state.region(for: p), default: 0] += 1
        }
        return counts.sorted { $0.key < $1.key }
    }

    private var orderStatusCounts: [(String, Int)] {
        var counts: [String: Int] = [:]
        for o in state.orders {
            counts[o.statusLabel, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }

    private var revenueByCurrency: [(String, Double)] {
        var totals: [String: Double] = [:]
        for o in state.orders
        where o.status != "cancelled" && o.status != "refunded" && o.status != "failed" {
            let currency = o.currency ?? "EUR"
            totals[currency, default: 0] += Double(o.total) ?? 0
        }
        return totals.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    private var outOfStockProducts: [WooProduct] {
        state.products.filter {
            $0.stockStatus == "outofstock" || ($0.manageStock == true && ($0.stockQuantity ?? 0) <= 0)
        }
    }

    // MARK: - Helpers

    private func regionName(_ code: String) -> String {
        switch code {
        case "EU": return "🇪🇺 Europe"
        case "US": return "🇺🇸 USA"
        case "CH": return "🇨🇭 Suisse"
        default: return "— Non classés"
        }
    }

    private func regionBadge(_ code: String) -> String {
        switch code {
        case "EU": return "🇪🇺"
        case "US": return "🇺🇸"
        case "CH": return "🇨🇭"
        default: return "—"
        }
    }

    private func formattedAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private func card<Content: View>(_ title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).bold()
        }
        .font(.callout)
    }
}
