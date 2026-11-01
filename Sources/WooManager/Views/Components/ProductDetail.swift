import SwiftUI

struct ProductDetail: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    let product: WooProduct

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    if let url = product.imageURL {
                        AsyncImage(url: url) { image in image.resizable().scaledToFit() } placeholder: { Color.gray.opacity(0.15) }
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(product.displayName).font(.title2).bold()
                        if let sku = product.sku, !sku.isEmpty {
                            Text("SKU : \(sku)").foregroundStyle(.secondary)
                        }
                        Text("ID produit : \(product.id)").foregroundStyle(.secondary).font(.callout)
                        HStack {
                            let region = state.region(for: product)
                            labelPill(region.isEmpty || region == "—" ? "Région inconnue" : regionLabel(region),
                                      color: regionColor(region))
                            labelPill("Prix : \(product.displayPrice) \(state.currency(for: region))", color: .blue)
                            if product.onSale == true {
                                labelPill("En promo", color: .red)
                            }
                        }
                    }
                    Spacer()
                }

                if let attrs = product.attributes, !attrs.isEmpty {
                    section("Attributs (tailles, designer…)") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(attrs, id: \.name) { attr in
                                HStack(alignment: .top) {
                                    Text(attr.name).bold().frame(width: 160, alignment: .leading)
                                    Text(attr.optionsText)
                                }
                            }
                        }
                    }
                }

                if let meta = product.metaData, !meta.isEmpty {
                    let interesting = meta.filter { !$0.key.hasPrefix("_") && $0.value?.display.isEmpty == false && $0.key != "canonical_demo" }
                    if !interesting.isEmpty {
                        section("Données supplémentaires") {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(interesting, id: \.key) { m in
                                    HStack(alignment: .top) {
                                        Text(m.key).bold().frame(width: 160, alignment: .leading)
                                        Text(m.value?.display ?? "").foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                if !product.cleanDescription.isEmpty {
                    section("Description") {
                        Text(product.cleanDescription)
                            .foregroundStyle(.secondary)
                    }
                }

                if let permalink = product.permalink, let url = URL(string: permalink) {
                    Link("Voir sur le site →", destination: url)
                        .font(.callout)
                }
            }
            .padding(24)
        }
        .frame(width: 640, height: 560)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
        }
    }

    private func regionLabel(_ region: String) -> String {
        switch region {
        case "EU": return "🇪🇺 Europe (EUR)"
        case "US": return "🇺🇸 USA (USD)"
        case "CH": return "🇨🇭 Suisse (CHF)"
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

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func labelPill(_ text: String, color: Color) -> some View {
        Text(text)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .foregroundStyle(color)
    }
}
