import SwiftUI

struct ContentView_ContentTab: View {
    @EnvironmentObject private var state: AppState
    @State private var tab: String = "posts"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Type", selection: $tab) {
                    Text("Articles").tag("posts")
                    Text("Pages").tag("pages")
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
                Spacer()
                Button {
                    Task { await state.loadContent() }
                } label: {
                    Label("Actualiser", systemImage: "arrow.clockwise")
                }
            }
            .padding(10)
            Divider()
            if state.loadingContent {
                Spacer()
                ProgressView("Chargement du contenu…")
                Spacer()
            } else {
                List(current) { post in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.plainTitle.isEmpty ? "(sans titre)" : post.plainTitle).bold()
                            Text(post.plainExcerpt).lineLimit(2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(post.statusLabel)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background((post.status == "publish" ? Color.green : Color.orange).opacity(0.2))
                            .clipShape(Capsule())
                        if let link = post.link, let url = URL(string: link) {
                            Link(destination: url) {
                                Image(systemName: "safari")
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .task { if state.posts.isEmpty && state.pages.isEmpty { await state.loadContent() } }
    }

    private var current: [WPPost] {
        tab == "posts" ? state.posts : state.pages
    }
}
