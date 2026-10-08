import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TodoStore
    @State private var newText = ""
    @State private var showSettings = false

    private var sortedItems: [TodoItem] {
        store.items.filter { !$0.checked } + store.items.filter { $0.checked }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if showSettings || !store.isConfigured {
                SettingsView(onDone: { showSettings = false })
            } else {
                todoList
                TextField("Tambah todo…", text: $newText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        let t = newText
                        newText = ""
                        Task { await store.add(t) }
                    }
            }

            if let error = store.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
            HStack {
                Spacer()
                Button("Keluar") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 320)
        .task { await store.refresh() }
    }

    private var header: some View {
        HStack {
            Text("Todo").font(.headline)
            Spacer()
            if store.isLoading { ProgressView().controlSize(.small) }
            Button { Task { await store.refresh() } } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .disabled(!store.isConfigured)
            Button { showSettings.toggle() } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var todoList: some View {
        if store.items.isEmpty && !store.isLoading {
            Text("Belum ada todo di halaman ini.")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(sortedItems) { item in
                        TodoRow(item: item)
                    }
                }
            }
            .frame(maxHeight: 320)
        }
    }
}

struct TodoRow: View {
    let item: TodoItem
    @EnvironmentObject var store: TodoStore
    @State private var hovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button { Task { await store.toggle(item) } } label: {
                Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.checked ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)

            Text(item.text.isEmpty ? "(kosong)" : item.text)
                .strikethrough(item.checked)
                .foregroundStyle(item.checked ? Color.secondary : Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if hovering {
                Button { Task { await store.delete(item) } } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.secondary)
            }
        }
        .onHover { hovering = $0 }
    }
}
