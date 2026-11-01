import SwiftUI

struct OrdersView: View {
    @EnvironmentObject private var state: AppState
    @State private var filter: String?

    private let filters: [(String?, String)] = [
        (nil, "Toutes"),
        ("processing", "En cours"),
        ("completed", "Terminées"),
        ("on-hold", "En suspens"),
        ("cancelled", "Annulées"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if state.loadingOrders {
                Spacer()
                ProgressView("Chargement des commandes…")
                Spacer()
            } else if filtered.isEmpty {
                Spacer()
                ContentUnavailableView("Aucune commande", systemImage: "cart", description: Text("Cliquez sur « Actualiser » pour charger les commandes."))
                Spacer()
            } else {
                orderList
            }
        }
        .task { if state.orders.isEmpty { await state.loadOrders() } }
    }

    private var filtered: [WooOrder] {
        guard let filter else { return state.orders }
        return state.orders.filter { $0.status == filter }
    }

    private var toolbar: some View {
        HStack {
            Picker("Filtre", selection: $filter) {
                ForEach(filters, id: \.0) { item in
                    Text(item.1).tag(item.0)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 420)
            Spacer()
            Button {
                Task { await state.loadOrders() }
            } label: {
                Label("Actualiser", systemImage: "arrow.clockwise")
            }
        }
        .padding(10)
    }

    private var orderList: some View {
        List(filtered) { order in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Commande #\(order.id)").bold()
                        Text(order.formattedDate).foregroundStyle(.secondary)
                        Text(order.statusLabel)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(color(for: order.status).opacity(0.2))
                            .clipShape(Capsule())
                            .foregroundStyle(color(for: order.status))
                    }
                    Text("\(order.customerName) — \(order.itemsSummary)")
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(order.total) \(order.currency ?? "€")")
                    .bold()
                Menu("Statut") {
                    ForEach(["pending", "processing", "on-hold", "completed", "cancelled", "refunded"], id: \.self) { status in
                        Button(WooOrder(id: 0, status: status, dateCreated: "", total: "", currency: nil, billing: nil, shipping: nil, lineItems: nil, customerNote: nil).statusLabel) {
                            Task { await state.setOrderStatus(order, status: status) }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func color(for status: String) -> Color {
        switch status {
        case "processing": return .blue
        case "completed": return .green
        case "on-hold": return .orange
        case "cancelled", "failed", "refunded": return .red
        default: return .gray
        }
    }
}
