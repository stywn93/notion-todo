import SwiftUI

struct SettingsView: View {
    @Environment(TodoStore.self) private var store
    var onDone: () -> Void

    @State private var token = ""
    @State private var page = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Koneksi Notion").font(.subheadline.bold())

            SecureField("Integration token", text: $token)
            TextField("URL atau ID halaman Notion", text: $page)

            Text("Halaman harus sudah di-connect ke integration (… → Connections).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Simpan") {
                    Task {
                        await store.saveSettings(token: token, page: page)
                        if store.isConfigured { onDone() }
                    }
                }
                .disabled(token.isEmpty || page.isEmpty)

                if store.isConfigured {
                    Button("Batal", action: onDone)
                }
            }
        }
        .textFieldStyle(.roundedBorder)
        .onAppear {
            token = store.token
            page = store.pageInput
        }
    }
}
