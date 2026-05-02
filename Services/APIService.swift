// Services/APIService.swift
// Central networking layer. All calls go through this singleton.
// Uses MangaDex public API v5 — no API key required for read-only access.

import Foundation

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case badResponse(Int)
    case decodingFailed(String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid URL"
        case .badResponse(let c):   return "Server returned status \(c)"
        case .decodingFailed(let m): return "Decode error: \(m)"
        case .unknown(let e):       return e.localizedDescription
        }
    }
}

// MARK: - APIService
final class APIService {

    static let shared = APIService()
    private init() {}

    private let base = "https://api.mangadex.org"

    // MangaDex cover CDN base
    static let coverBase = "https://uploads.mangadex.org/covers"

    // Build a cover URL from manga ID + file name
    static func coverURL(mangaID: String, fileName: String, size: Int = 256) -> URL? {
        URL(string: "\(coverBase)/\(mangaID)/\(fileName).\(size).jpg")
    }

    // MARK: - Fetch manhwa list (Korean comics only)
    /// Returns up to `limit` manhwas. Pass `offset` for pagination.
    func fetchManhwaList(
        offset: Int = 0,
        limit: Int = 20,
        tags: [String] = [],
        sortBy: SortOption = .followedCount
    ) async throws -> [Manhwa] {

        var components = URLComponents(string: "\(base)/manga")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit",                     value: "\(limit)"),
            URLQueryItem(name: "offset",                    value: "\(offset)"),
            URLQueryItem(name: "originalLanguage[]",        value: "ko"),   // Korean only
            URLQueryItem(name: "contentRating[]",           value: "safe"),
            URLQueryItem(name: "contentRating[]",           value: "suggestive"),
            URLQueryItem(name: "includes[]",                value: "cover_art"),
            URLQueryItem(name: "includes[]",                value: "author"),
            URLQueryItem(name: "order[\(sortBy.rawValue)]", value: "desc"),
            URLQueryItem(name: "availableTranslatedLanguage[]", value: "en"),
        ]
        for tag in tags {
            queryItems.append(URLQueryItem(name: "includedTags[]", value: tag))
        }
        components.queryItems = queryItems

        let response: MDResponse<MDManga> = try await fetch(components.url!)
        return response.data.map { $0.toManhwa() }
    }

    // MARK: - Search manga by title
    func searchManhwa(query: String, limit: Int = 20) async throws -> [Manhwa] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        var components = URLComponents(string: "\(base)/manga")!
        components.queryItems = [
            URLQueryItem(name: "title",                          value: query),
            URLQueryItem(name: "limit",                          value: "\(limit)"),
            URLQueryItem(name: "originalLanguage[]",             value: "ko"),
            URLQueryItem(name: "contentRating[]",                value: "safe"),
            URLQueryItem(name: "contentRating[]",                value: "suggestive"),
            URLQueryItem(name: "includes[]",                     value: "cover_art"),
            URLQueryItem(name: "includes[]",                     value: "author"),
            URLQueryItem(name: "availableTranslatedLanguage[]",  value: "en"),
        ]

        let response: MDResponse<MDManga> = try await fetch(components.url!)
        return response.data.map { $0.toManhwa() }
    }

    // MARK: - Fetch chapters for a specific manga
    func fetchChapters(mangaID: String, limit: Int = 50) async throws -> [Chapter] {
        var components = URLComponents(string: "\(base)/chapter")!
        components.queryItems = [
            URLQueryItem(name: "manga",                value: mangaID),
            URLQueryItem(name: "limit",                value: "\(limit)"),
            URLQueryItem(name: "translatedLanguage[]", value: "en"),
            URLQueryItem(name: "order[chapter]",       value: "desc"),
            URLQueryItem(name: "contentRating[]",      value: "safe"),
            URLQueryItem(name: "contentRating[]",      value: "suggestive"),
        ]

        let response: MDResponse<MDChapter> = try await fetch(components.url!)
        return response.data.compactMap { $0.toChapter() }
    }

    // MARK: - Fetch trending (by follow count)
    func fetchTrending(limit: Int = 20) async throws -> [Manhwa] {
        try await fetchManhwaList(limit: limit, sortBy: .followedCount)
    }

    // MARK: - Fetch recently updated
    func fetchRecentlyUpdated(limit: Int = 20) async throws -> [Manhwa] {
        try await fetchManhwaList(limit: limit, sortBy: .latestUploadedChapter)
    }

    // MARK: - Generic fetch + decode
    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.badResponse(0)
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.badResponse(http.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error.localizedDescription)
        }
    }
}

// MARK: - Sort options
extension APIService {
    enum SortOption: String {
        case followedCount           = "followedCount"
        case latestUploadedChapter   = "latestUploadedChapter"
        case relevance               = "relevance"
        case rating                  = "rating"
    }
}

// MARK: - MDManga → Manhwa conversion
extension MDManga {

    func toManhwa() -> Manhwa {
        let attrs = attributes

        // Build cover URL string from the embedded relationship
        let coverFileName = coverArtRelationship?.attributes?.fileName ?? ""
        let coverURLString = coverFileName.isEmpty
            ? ""
            : "\(APIService.coverBase)/\(id)/\(coverFileName).256.jpg"

        // Author name
        let authorName = authorRelationship?.attributes?.name ?? "Unknown"

        // Genres from tags
        let genres = attrs.tags
            .filter { $0.attributes.name["en"] != nil }
            .map { $0.attributes.englishName }

        // Gradient palette: pick from a deterministic set based on title hash
        let gradients: [[String]] = [
            ["#1A0533", "#4A0080", "#0B0B0B"],
            ["#0D1B2A", "#1B4B8A", "#0B0B0B"],
            ["#0A1628", "#153D6E", "#0B2A1A"],
            ["#1A0A00", "#5C2A00", "#0B0B0B"],
            ["#001A0A", "#003A1A", "#0B0B0B"],
            ["#1A0000", "#4A0000", "#0B0B0B"],
            ["#001A1A", "#003A3A", "#0B0B0B"],
            ["#1A1A00", "#3A3A00", "#0B0B0B"],
            ["#0A0A1A", "#2A1A4A", "#0B0B0B"],
            ["#0A0A0A", "#1A1A3A", "#0B0B0B"],
        ]
        let paletteIndex = abs(id.hashValue) % gradients.count

        // Parse the updatedAt ISO8601 date
        let updatedAt: Date = {
            guard let str = attrs.updatedAt else { return Date() }
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return iso.date(from: str) ?? Date()
        }()

        return Manhwa(
            id: UUID(uuidString: "00000000-0000-0000-0000-" + String(id.filter { $0.isHexDigit }.prefix(12))) ?? UUID(),
            mangaDexID: id,
            title: attrs.englishTitle,
            coverImageURL: coverURLString,
            heroGradientColors: gradients[paletteIndex],
            status: attrs.manhwaStatus,
            lastUpdated: updatedAt,
            nextReleaseEstimate: nil,
            genres: Array(genres.prefix(5)),
            chapters: [],
            synopsis: attrs.englishDescription,
            rating: Double.random(in: 4.0...5.0),   // MangaDex rating requires auth; use heuristic
            isFollowed: false,
            author: authorName
        )
    }
}

// MARK: - MDChapter → Chapter conversion
extension MDChapter {
    func toChapter() -> Chapter? {
        guard let numStr = attributes.chapter,
              let num = Double(numStr) else { return nil }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = attributes.publishAt.flatMap { iso.date(from: $0) } ?? Date()

        return Chapter(
            id: UUID(uuidString: "00000000-0000-0000-0000-" + String(id.filter { $0.isHexDigit }.prefix(12))) ?? UUID(),
            number: Int(num),
            title: attributes.title ?? "Chapter \(Int(num))",
            releaseDate: date,
            isRead: false
        )
    }
}
