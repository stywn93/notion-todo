import SwiftUI
import AppKit

@main
struct NotionTodoApp: App {
    @State private var store = TodoStore()

    /// Ikon kustom untuk menu bar: glyph kubus Notion (monokrom, transparan),
    /// dibuat dari artwork icns asli dengan melepas latar halaman putihnya.
    /// Template=True agar otomatis menyesuaikan warna menu bar.
    /// Ukuran point di-set langsung di NSImage karena MenuBarExtra mengabaikan
    /// .frame() pada label saat layout — NSImage.size-lah yang menentukan.
    /// Margin 4pt di sisi kanan glyph di-bake ke dalam PNG (bukan padding SwiftUI,
    /// karena padding di label justru melebar ke luar item).
    private static let menuBarIcon: NSImage? = {
        guard let img = NSImage(named: "MenuBarIconTemplate") else { return nil }
        img.isTemplate = true
        let aspect = img.size.width / img.size.height
        img.size = NSSize(width: 18 * aspect, height: 18)
        return img
    }()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(store)
        } label: {
            if let icon = Self.menuBarIcon {
                Image(nsImage: icon)
            } else {
                Image(systemName: "checklist")
            }
            if store.openCount > 0 {
                Text("\(store.openCount)")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
