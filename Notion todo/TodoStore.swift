import Foundation
import SwiftUI

@MainActor
@Observable
final class TodoStore {
    var items: [TodoItem] = []
    var isLoading = false
    var errorMessage: String?
    var token: String
    var pageInput: String

    private var pending = 0            // jumlah mutasi yang sedang jalan
    private var mutationVersion = 0    // untuk membuang hasil fetch yang sudah basi
    private var pollTask: Task<Void, Never>?

    var pageID: String? { NotionClient.parsePageID(pageInput) }
    var isConfigured: Bool { !token.isEmpty && pageID != nil }
    var openCount: Int { items.filter { !$0.checked }.count }

    init() {
        token = Keychain.load("notion_token") ?? ""
        pageInput = UserDefaults.standard.string(forKey: "pageInput") ?? ""
        startPolling()
    }

    private func startPolling() {
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    // MARK: - Settings

    func saveSettings(token: String, page: String) async {
        let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard NotionClient.parsePageID(page) != nil else {
            errorMessage = "URL / ID halaman tidak valid."
            return
        }
        self.token = t
        self.pageInput = page
        Keychain.save(t, for: "notion_token")
        UserDefaults.standard.set(page, forKey: "pageInput")
        errorMessage = nil
        items = []
        await refresh()
    }

    // MARK: - Sync

    func refresh() async {
        guard isConfigured, let pid = pageID, pending == 0 else { return }
        let versionAtStart = mutationVersion
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await NotionClient(token: token).fetchTodos(pageID: pid)
            // Ada mutasi lokal selama fetch berjalan → hasil ini mungkin basi.
            guard versionAtStart == mutationVersion, pending == 0 else { return }
            items = fetched
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add(_ text: String) async {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, isConfigured, let pid = pageID else { return }
        mutationVersion += 1
        pending += 1
        defer { pending -= 1 }
        do {
            let id = try await NotionClient(token: token).addTodo(pageID: pid, text: t)
            items.append(TodoItem(id: id, text: t, checked: false))
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ item: TodoItem) async {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        let newValue = !items[idx].checked
        items[idx].checked = newValue          // optimistic
        mutationVersion += 1
        pending += 1
        defer { pending -= 1 }
        do {
            try await NotionClient(token: token).setChecked(blockID: item.id, checked: newValue)
            errorMessage = nil
        } catch {
            if let i = items.firstIndex(where: { $0.id == item.id }) {
                items[i].checked = !newValue   // rollback
            }
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ item: TodoItem) async {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        let removed = items.remove(at: idx)    // optimistic
        mutationVersion += 1
        pending += 1
        defer { pending -= 1 }
        do {
            try await NotionClient(token: token).delete(blockID: item.id)
            errorMessage = nil
        } catch {
            items.insert(removed, at: min(idx, items.count))   // rollback
            errorMessage = error.localizedDescription
        }
    }
}
