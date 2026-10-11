import Foundation

struct Hack: Identifiable, Hashable {
    enum Access: String, CaseIterable, Identifiable {
        case publicAPI = "Public"
        case undocumented = "Undocumented"
        case mixed = "Mixed"

        var id: Self { self }
    }

    let category: String
    let name: String
    let summary: String
    let accessNotes: String
    let access: Access

    var id: String {
        "\(category)/\(name)"
    }
}

enum Catalog {
    static func load() -> Result<[Hack], CatalogError> {
        guard let url = catalogURL() else {
            return .failure(.fileNotFound)
        }

        do {
            let markdown = try String(contentsOf: url, encoding: .utf8)
            let hacks = parse(markdown)
            guard !hacks.isEmpty else {
                return .failure(.emptyCatalog)
            }
            return .success(hacks)
        } catch {
            return .failure(.unreadable(error.localizedDescription))
        }
    }

    private static func catalogURL() -> URL? {
        if let bundled = Bundle.main.url(forResource: "catalog", withExtension: "md") {
            return bundled
        }

        let workingCopy = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("README.md")
        return FileManager.default.fileExists(atPath: workingCopy.path) ? workingCopy : nil
    }

    private static func parse(_ markdown: String) -> [Hack] {
        var category: String?
        var hacks: [Hack] = []

        for line in markdown.components(separatedBy: .newlines) {
            if line.hasPrefix("## ") {
                category = String(line.dropFirst(3))
                continue
            }

            guard let category, line.hasPrefix("|"), line.hasSuffix("|") else {
                continue
            }

            let columns = line
                .dropFirst()
                .dropLast()
                .split(separator: "|", omittingEmptySubsequences: false)
                .map { cleanMarkdown(String($0).trimmingCharacters(in: .whitespaces)) }

            guard columns.count == 3,
                  columns[0] != "Idea",
                  !columns[0].allSatisfy({ $0 == "-" || $0 == " " }) else {
                continue
            }

            let accessNotes = columns[2]
            hacks.append(
                Hack(
                    category: category,
                    name: columns[0],
                    summary: columns[1],
                    accessNotes: accessNotes,
                    access: accessLevel(for: accessNotes)
                )
            )
        }

        return hacks
    }

    private static func cleanMarkdown(_ value: String) -> String {
        value
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "`", with: "")
    }

    private static func accessLevel(for notes: String) -> Hack.Access {
        let normalized = notes.lowercased()
        let mentionsPublic = normalized.contains("public")
        let mentionsUndocumented = normalized.contains("undocumented")

        if mentionsPublic && !mentionsUndocumented {
            return .publicAPI
        }
        if mentionsUndocumented && !mentionsPublic {
            return .undocumented
        }
        return .mixed
    }
}

enum CatalogError: LocalizedError {
    case fileNotFound
    case emptyCatalog
    case unreadable(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            "The bundled hack catalog could not be found."
        case .emptyCatalog:
            "The hack catalog does not contain any readable ideas."
        case .unreadable(let reason):
            "The hack catalog could not be read: \(reason)"
        }
    }
}
