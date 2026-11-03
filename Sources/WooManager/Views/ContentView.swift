import SwiftUI
import AppKit

enum WooSection: String, CaseIterable, Identifiable {
    case dashboard = "Tableau de bord"
    case products = "Produits"
    case orders = "Commandes"
    case content = "Contenu"
    case settings = "Réglages"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar"
        case .products: return "shippingbox"
        case .orders: return "cart"
        case .content: return "doc.text"
        case .settings: return "gearshape"
        }
    }
}

@main
struct WooManagerApp: App {
    @StateObject private var state = AppState()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .frame(minWidth: 980, minHeight: 640)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
        }
        .windowStyle(.automatic)
    }
}

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    @State private var section: WooSection = .dashboard

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(WooSection.allCases) { item in
                    Button {
                        section = item
                    } label: {
                        Label(item.rawValue, systemImage: item.icon)
                            .foregroundStyle(section == item ? Color.accentColor : .primary)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Group {
                switch section {
                case .dashboard: DashboardView()
                case .products: ProductsView()
                case .orders: OrdersView()
                case .content: ContentView_ContentTab()
                case .settings: SettingsView()
                }
            }
            .navigationTitle(section.rawValue)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .bottom) {
            if let message = state.errorMessage {
                banner(message, color: .red) { state.errorMessage = nil }
            } else if let message = state.infoMessage {
                banner(message, color: .green) { state.infoMessage = nil }
            }
        }
    }

    private func banner(_ text: String, color: Color, dismiss: @escaping () -> Void) -> some View {
        HStack {
            Text(text)
                .lineLimit(4)
            Spacer()
            Button("OK") { dismiss() }
        }
        .padding(10)
        .background(color.opacity(0.15))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.5)))
        .padding()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
