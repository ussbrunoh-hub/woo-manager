import SwiftUI
import AppKit

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
            .onAppear {
                NSApp.activate(ignoringOtherApps: true)
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
            Section("Contenu (Articles / Pages) — optionnel") {
                Text("Si l'onglet Contenu affiche une erreur 403, votre site bloque l'API REST anonyme. Créez alors un mot de passe d'application et renseignez-le ci-dessous.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                TextField("Identifiant WordPress", text: binding($state.config.wpUser))
                    .textFieldStyle(.roundedBorder)
                SecureField("Mot de passe d'application (xxxx xxxx xxxx xxxx)", text: binding($state.config.wpAppPassword))
                    .textFieldStyle(.roundedBorder)
            }
            Section("Comment obtenir vos clés API") {
                Text("1. Dans l'admin WordPress : WooCommerce → Réglages → Avancé → API REST.\n2. Cliquez sur « Ajouter une clé ».\n3. Description : Vibe Manager. Utilisateur : vous. Permissions : Lecture/Écriture.\n4. Copiez la « Clé client » (ck_…) et le « Secret client » (cs_…).")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section("Comment créer un mot de passe d'application") {
                Text("1. Dans l'admin WordPress : Utilisateurs → Profil.\n2. Tout en bas, section « Mot de passe d'application » : donnez un nom (ex. WooManager) et cliquez sur « Ajouter un nouveau mot de passe d'application ».\n3. Copiez le mot de passe généré (format xxxx xxxx xxxx xxxx) et collez-le ci-dessus avec votre identifiant WordPress.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func binding(_ optional: Binding<String?>) -> Binding<String> {
        Binding<String>(
            get: { optional.wrappedValue ?? "" },
            set: { optional.wrappedValue = $0.isEmpty ? nil : $0 }
        )
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
