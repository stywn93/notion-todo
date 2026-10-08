import SwiftUI

@main
struct NotionTodoApp: App {
    @State private var store = TodoStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(store)
        } label: {
            Image(systemName: "checklist")
            if store.openCount > 0 {
                Text("\(store.openCount)")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
