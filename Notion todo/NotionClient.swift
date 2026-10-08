import Foundation

struct TodoItem: Identifiable, Equatable {
    let id: String      // Notion block id
    var text: String
    var checked: Bool
}

// MARK: - Decoding (hanya field yang dibutuhkan; block tipe lain diabaikan)

private struct BlockList: Decodable {
    let results: [Block]
    let hasMore: Bool
    let nextCursor: String?
}

private struct Block: Decodable {
    let id: String
    let type: String
    let toDo: ToDo?

    struct ToDo: Decodable {
        let richText: [RichText]
        let checked: Bool
    }
    struct RichText: Decodable {
        let plainText: String
    }

    var asTodo: TodoItem? {
        guard type == "to_do", let t = toDo else { return nil }
        return TodoItem(id: id,
                        text: t.richText.map(\.plainText).joined(),
                        checked: t.checked)
    }
}

// MARK: - Client

struct NotionClient {
    let token: String
    private let base = URL(string: "https://api.notion.com/v1")!

    enum NotionError: LocalizedError {
        case http(Int, String)

        var errorDescription: String? {
            switch self {
            case .http(let code, let msg):
                switch code {
                case 401: return "Token tidak valid."
                case 404: return "Halaman tidak ditemukan. Pastikan integration sudah di-connect ke halaman ini (… → Connections)."
                case 429: return "Kena rate limit Notion, coba lagi sebentar."
                default:  return "Notion error \(code): \(msg)"
                }
            }
        }
    }

    /// Ambil 32 karakter hex terakhir dari URL / ID yang ditempel user.
    static func parsePageID(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = trimmed.split(whereSeparator: { $0 == "?" || $0 == "#" }).first.map(String.init) ?? trimmed
        let last = path.split(separator: "/").last.map(String.init) ?? path
        let compact = last.replacingOccurrences(of: "-", with: "")
        guard compact.count >= 32 else { return nil }
        let id = String(compact.suffix(32))
        return id.allSatisfy({ $0.isHexDigit }) ? id.lowercased() : nil
    }

    private func request(_ path: String,
                         method: String = "GET",
                         query: [URLQueryItem] = [],
                         body: Any? = nil) async throws -> Data {
        var comps = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { comps.queryItems = query }

        var req = URLRequest(url: comps.url!)
        req.httpMethod = method
        req.timeoutInterval = 15
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let msg = (obj?["message"] as? String) ?? ""
            throw NotionError.http(http.statusCode, msg)
        }
        return data
    }

    func fetchTodos(pageID: String) async throws -> [TodoItem] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        var items: [TodoItem] = []
        var cursor: String?
        repeat {
            var q = [URLQueryItem(name: "page_size", value: "100")]
            if let cursor { q.append(URLQueryItem(name: "start_cursor", value: cursor)) }
            let data = try await request("blocks/\(pageID)/children", query: q)
            let list = try decoder.decode(BlockList.self, from: data)
            items += list.results.compactMap(\.asTodo)
            cursor = list.hasMore ? list.nextCursor : nil
        } while cursor != nil
        return items
    }

    /// Menambah todo di akhir halaman. Mengembalikan block id baru.
    func addTodo(pageID: String, text: String) async throws -> String {
        let body: [String: Any] = [
            "children": [[
                "object": "block",
                "type": "to_do",
                "to_do": [
                    "rich_text": [["type": "text", "text": ["content": text]]],
                    "checked": false
                ]
            ]]
        ]
        let data = try await request("blocks/\(pageID)/children", method: "PATCH", body: body)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let results = obj?["results"] as? [[String: Any]]
        guard let id = results?.last?["id"] as? String else {
            throw NotionError.http(0, "Respons tidak berisi block id")
        }
        return id
    }

    func setChecked(blockID: String, checked: Bool) async throws {
        _ = try await request("blocks/\(blockID)", method: "PATCH",
                              body: ["to_do": ["checked": checked]])
    }

    func delete(blockID: String) async throws {
        _ = try await request("blocks/\(blockID)", method: "DELETE")
    }
}
