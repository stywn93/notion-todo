import SwiftUI

// MARK: - Liquid Glass (macOS 26+; fallback polos di sistem lebih lama)
extension View {
    @ViewBuilder
    func liquidGlass(_ enabled: Bool = true) -> some View {
        if #available(macOS 26.0, *), enabled {
            self.glassEffect()
        } else {
            self
        }
    }
}

struct ContentView: View {
    @Environment(TodoStore.self) private var store
    @State private var newText = ""
    @State private var showSettings = false

    private var openItems: [TodoItem] { store.items.filter { !$0.checked } }
    private var doneItems: [TodoItem] { store.items.filter { $0.checked } }
    private var hasCompleted: Bool { !doneItems.isEmpty }

    /// Tinggi daftar dihitung dari isi, karena ScrollView di MenuBarExtra (.window)
    /// tidak punya ideal height sehingga window runtuh kalau hanya pakai maxHeight.
    private var listHeight: CGFloat {
        let row: CGFloat = 30
        let header: CGFloat = 28
        var h: CGFloat = 12                       // padding vertikal VStack
        if !openItems.isEmpty { h += header + row * CGFloat(openItems.count) }
        if !doneItems.isEmpty { h += header + row * CGFloat(doneItems.count) }
        return min(max(h, 60), 320)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showSettings || !store.isConfigured {
                SettingsView(onDone: { showSettings = false })
                    .padding(12)
            } else {
                todoList

                Divider()
                addRow
                Divider()
                MenuRow(title: "Clear Completed",
                        enabled: hasCompleted) { Task { await store.clearCompleted() } }
                Divider()
                MenuRow(title: "Settings…") { showSettings = true }
                Divider()
                MenuRow(title: "Quit") { NSApplication.shared.terminate(nil) }
            }

            if let error = store.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
        .frame(width: 340)
        .task { await store.refresh() }
    }

    // MARK: - Daftar

    @ViewBuilder
    private var todoList: some View {
        if openItems.isEmpty && doneItems.isEmpty {
            HStack(spacing: 8) {
                if store.isLoading { ProgressView().controlSize(.small) }
                // String(localized:) eksplisit: ternary membuat Swift memilih overload
                // Text(String) sehingga lookup lokalizasi bisa terlewat.
                Text(store.isLoading ? String(localized: "Loading…") : String(localized: "No todos on this page yet."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !openItems.isEmpty {
                        SectionHeader(title: "Open") {
                            if store.isLoading { ProgressView().controlSize(.small) }
                        }
                        ForEach(openItems) { item in
                            TodoRow(item: item)
                        }
                    }
                    if !doneItems.isEmpty {
                        SectionHeader(title: "Done")
                        ForEach(doneItems) { item in
                            TodoRow(item: item)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(height: listHeight)
        }
    }

    // MARK: - Baris tambah

    private var addRow: some View {
        HStack(spacing: 8) {
            TextField("Add new item…", text: $newText)
                .textFieldStyle(.plain)
                .onSubmit(addCurrentText)
            Button("Add", action: addCurrentText)
                .buttonStyle(.plain)
                .font(.callout.weight(.medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .liquidGlass(true)
                .disabled(newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func addCurrentText() {
        let t = newText
        newText = ""
        Task { await store.add(t) }
    }
}

/// Judul section kecil abu-abu, gaya Memo.
struct SectionHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var trailing: Trailing

    init(title: LocalizedStringKey, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            trailing
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

/// Baris menu full-width (Clear Completed / Settings / Quit), gaya Memo.
struct MenuRow: View {
    let title: LocalizedStringKey
    var enabled = true
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundStyle(enabled ? Color.primary : Color.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .background(
            Rectangle()
                .fill(hovering && enabled ? Color.primary.opacity(0.06) : Color.clear)
        )
        .onHover { hovering = $0 }
    }
}

/// Kotak centang gaya Memo: 16×16, sudut membulat 4pt.
/// Belum tercentang = garis tegas secondary; tercentang = isi accentColor + centang putih.
struct MemoCheckbox: View {
    let checked: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(checked ? Color.clear : Color.secondary,
                              lineWidth: 1.5)
            RoundedRectangle(cornerRadius: 4)
                .fill(checked ? Color.accentColor : Color.clear)
            if checked {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 16, height: 16)
        .contentShape(Rectangle())
    }
}

struct TodoRow: View {
    let item: TodoItem
    @Environment(TodoStore.self) private var store
    @State private var hovering = false
    @State private var isEditing = false
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button { Task { await store.toggle(item) } } label: {
                MemoCheckbox(checked: item.checked)
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .focused($focused)
                    .onSubmit { commitEdit() }
                    .onExitCommand { cancelEdit() }
                    .onChange(of: focused) { _, isFocused in
                        // Kehilangan fokus (klik di luar / popup ditutup) = simpan.
                        if !isFocused && isEditing { commitEdit() }
                    }
            } else {
                Text(item.text.isEmpty ? String(localized: "(empty)") : item.text)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .strikethrough(item.checked)
                    .foregroundStyle(item.checked ? Color.secondary : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { startEditing() }
            }

            Button { Task { await store.delete(item) } } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(hovering || isEditing ? 1 : 0.45)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(hovering ? Color.primary.opacity(0.06) : Color.clear)
                .liquidGlass(hovering)
        )
        .onHover { hovering = $0 }
    }

    private func startEditing() {
        draft = item.text
        isEditing = true
        DispatchQueue.main.async { focused = true }
    }

    private func commitEdit() {
        let text = draft
        isEditing = false
        Task { await store.rename(item, to: text) }
    }

    private func cancelEdit() {
        isEditing = false
    }
}
