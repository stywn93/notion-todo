import SwiftUI

struct SettingsView: View {
    @Environment(TodoStore.self) private var store
    var onDone: () -> Void

    @State private var token = ""
    @State private var page = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notion Connection").font(.subheadline.bold())

            SecureField("Integration token", text: $token)
            TextField("Notion page URL or ID", text: $page)

            Text("The page must be connected to the integration (… → Connections).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Save") {
                    Task {
                        await store.saveSettings(token: token, page: page)
                        if store.isConfigured { onDone() }
                    }
                }
                .disabled(token.isEmpty || page.isEmpty)

                if store.isConfigured {
                    Button("Cancel", action: onDone)
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
