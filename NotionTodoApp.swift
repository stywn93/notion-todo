import SwiftUI

@main
struct NotionTodoApp: App {
    @StateObject private var store = TodoStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(store)
        } label: {
            Image(systemName: "checklist")
            if store.openCount > 0 {
                Text("\(store.openCount)")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
