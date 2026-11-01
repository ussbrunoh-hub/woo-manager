import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState
    @State private var testing = false
    @State private var testResult: String?

    var body: some View {
        Form {
            Section("Connexion au site") {
                TextField("URL du site (https://monsite.com)", text: $state.config.siteURL)
                    .textFieldStyle(.roundedBorder)
                SecureField("Clé client (ck_…)", text: $state.config.consumerKey)
                    .textFieldStyle(.roundedBorder)
                SecureField("Secret client (cs_…)", text: $state.config.consumerSecret)
                    .textFieldStyle(.roundedBorder)
            }
            Section {
                HStack {
                    Button {
                        testConnection()
                    } label: {
                        if testing {
                            HStack { ProgressView().controlSize(.small); Text("Test en cours…") }
                        } else {
                            Label("Tester la connexion", systemImage: "plug")
                        }
                    }
                    .disabled(testing || !state.config.isValid)
                    if let testResult {
                        Text(testResult)
                            .foregroundStyle(testResult.hasPrefix("OK") ? .green : .red)
                    }
                }
            }
            Section("Comment obtenir vos clés API") {
                Text("1. Dans l'admin WordPress : WooCommerce → Réglages → Avancé → API REST.\n2. Cliquez sur « Ajouter une clé ».\n3. Description : Vibe Manager. Utilisateur : vous. Permissions : Lecture/Écriture.\n4. Copiez la « Clé client » (ck_…) et le « Secret client » (cs_…).")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func testConnection() {
        testing = true
        testResult = nil
        state.reconnectIfNeeded()
        let client = WooClient(config: state.config)
        Task {
            do {
                let products = try await client.products(page: 1)
                testResult = "OK — \(products.count) produits accessibles."
            } catch {
                testResult = error.localizedDescription
            }
            testing = false
        }
    }
}
