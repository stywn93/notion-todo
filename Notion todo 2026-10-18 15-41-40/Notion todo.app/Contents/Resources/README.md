# NotionTodo (menu bar)

App menu bar macOS (SwiftUI, `MenuBarExtra`) yang sync dengan satu halaman Notion lewat block `to_do`.
Target: macOS 13+ (Ventura) dan Xcode 15+.

## Setup Xcode

1. Xcode → File → New → Project → **macOS → App**.
   - Product Name: `NotionTodo`, Interface: **SwiftUI**, Language: **Swift**.
2. Hapus `ContentView.swift` dan `NotionTodoApp.swift` bawaan Xcode.
3. Drag semua file `.swift` dari folder `NotionTodo/` ini ke project (centang "Copy items if needed" dan target `NotionTodo`).
4. Target `NotionTodo` → **Info** tab → tambah key
   **Application is agent (UIElement)** = `YES` (ini yang menyembunyikan app dari Dock).
5. Target → **Signing & Capabilities**:
   - Kalau ada **App Sandbox**: centang **Outgoing Connections (Client)**. Tanpa ini semua request ke Notion gagal.
   - Signing: "Sign to Run Locally" cukup untuk pemakaian pribadi.
6. Target → General → **Minimum Deployments** = macOS 13.0.
7. Run (⌘R). Ikon checklist muncul di menu bar.

## Setup Notion

1. https://www.notion.so/my-integrations → New integration (Internal) → copy token.
2. Buka halaman todo di Notion → `…` → **Connections** → tambahkan integration tadi.
3. Di app: klik ikon menu bar → ⚙ → tempel token dan URL halaman → Simpan.

## Perilaku sync

- Polling tiap 30 detik + saat popup dibuka. Tidak real-time.
- Toggle dan hapus bersifat optimistic, di-rollback kalau request gagal.
- Hanya block `to_do` tingkat atas yang dibaca. Teks/heading lain di halaman tidak disentuh.
- Sub-todo (indent) belum didukung.
- Todo baru selalu ditambahkan di akhir halaman.
- Token disimpan di Keychain, ID halaman di UserDefaults.
