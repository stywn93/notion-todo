# NotionTodo (menu bar)

A small macOS menu bar app that keeps your todo list in sync with one Notion page.
It reads and writes `to-do` checkboxes on that page.

- Requires **macOS 14.6+**.
- No Dock icon — the app lives in the menu bar (top-right of the screen).
- Interface language: **English and Indonesian** (follows your macOS language).

---

## 1. Install

1. Open **Notion Todo-1.0.dmg**.
2. Drag **Notion todo.app** into the **Applications** folder.
3. Eject the DMG, then open the app from Applications.

### First launch: "App is from an unidentified developer"

This is normal. The app is signed only for your own Mac, so macOS does not know it.
Allow it once:

1. Try to open the app. macOS shows a warning and **does not open it**. Close the warning.
2. Go to **System Settings → Privacy & Security**.
3. Scroll down to the **Security** section.
4. Click **Open Anyway**.
5. Confirm with your password or Touch ID, then open the app again.

You only do this once. After that, the app opens normally.

If a new version shows the same warning, repeat these steps.

---

## 2. Connect to Notion (one-time setup)

You need two things: an **integration token** and your **page URL**.

### Step 1 — Create the integration

1. Open https://www.notion.so/my-integrations in your browser (log in first).
2. Click **New integration**.
3. Name it (for example: `NotionTodo`), pick your workspace, and click **Save**.
4. On the **Configuration** tab, copy the **Internal Integration Secret** (starts with `ntn_` or `secret_`).
   This is your token. Keep it private.

### Step 2 — Connect your page

1. Open the Notion page where you keep your todos.
2. Click the **⋯** (three dots) menu at the top-right of the page.
3. Click **Connections → +**.
4. Search for the integration you just created and select it.

Without this step the app cannot read the page (you will get a "Page not found" error).

### Step 3 — Paste both into the app

1. Click the Notion icon in the menu bar (top-right of the screen).
2. The settings screen opens automatically the first time.
3. Paste the **token** into the first field.
4. Paste the **page URL** (or the 32-character page ID) into the second field.
5. Click **Save**.

Your todos appear. Done!

> The token is stored in the macOS **Keychain**, the page ID in UserDefaults.

---

## 3. How sync works

- The app checks Notion every **30 seconds** and when you open the popup. It is not real-time.
- Checking, renaming, and deleting are **optimistic** (the UI updates instantly) and roll back if the request fails.
- Only **top-level to-do blocks** on the page are used. Text, headings, and other blocks are ignored.
- **Sub-todos** (indented to-dos) are not supported yet.
- New todos are added at the **end** of the page.
- "Clear Completed" deletes all checked todos on the page.

---

## 4. Build from source (for developers)

Requirements: **Xcode 16+** (project was made with Xcode 26), **macOS 14.6+**.

1. Open **`Notion todo.xcodeproj`** in Xcode.
2. Check two settings on the target:
   - **Info** tab: `Application is agent (UIElement)` = `YES`
     (this hides the app from the Dock).
   - **Signing & Capabilities**: if **App Sandbox** is on, enable
     **Outgoing Connections (Client)** — without it every Notion request fails.
     "Sign to Run Locally" is enough for personal use.
3. Run (⌘R). The Notion icon appears in the menu bar.

> Creating a new project from scratch instead? Make a **macOS → App** project
> (SwiftUI, Swift), replace the generated views with the `.swift` files from this
> folder, then apply the two settings above.

### Make a DMG

```
xcodebuild -project "Notion todo.xcodeproj" -scheme "Notion todo" -configuration Release build
# then copy the .app from DerivedData into a folder with an Applications symlink and run:
hdiutil create -volname "Notion Todo" -srcfolder <folder> -ov -format UDZO "Notion Todo-1.0.dmg"
```

### Localization

All UI strings live in `Localizable.xcstrings` (English = source, Indonesian = `id`).
To add a string, use a literal in `Text`/`Button` or `String(localized: "...")` —
Xcode adds the key to the catalog automatically.

---

## 5. Privacy

- The token never leaves your Mac except to call the Notion API.
- There is no analytics, no server, no account.
