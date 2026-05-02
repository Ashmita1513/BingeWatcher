// Models/APIModels.swift
// Codable structs that map 1-to-1 with the MangaDex REST API responses.
// https://api.mangadex.org

import Foundation

// MARK: - Generic paginated response wrapper
struct MDResponse<T: Decodable>: Decodable {
    let result: String       // "ok" | "error"
    let response: String     // "collection" | "entity"
    let data: [T]
    let limit: Int
    let offset: Int
    let total: Int
}

struct MDEntityResponse<T: Decodable>: Decodable {
    let result: String
    let response: String
    let data: T
}

// MARK: - Manga entity
struct MDManga: Decodable, Identifiable {
    let id: String
    let type: String
    let attributes: MDMangaAttributes
    let relationships: [MDRelationship]

    // Convenience: first cover art relationship
    var coverArtRelationship: MDRelationship? {
        relationships.first { $0.type == "cover_art" }
    }

    // Convenience: author relationship
    var authorRelationship: MDRelationship? {
        relationships.first { $0.type == "author" }
    }
}

struct MDMangaAttributes: Decodable {
    let title: MDLocalizedString
    let altTitles: [MDLocalizedString]
    let description: MDLocalizedString?
    let status: String?                // "ongoing" | "completed" | "hiatus" | "cancelled"
    let year: Int?
    let contentRating: String?
    let tags: [MDTag]
    let lastChapter: String?
    let lastVolume: String?
    let updatedAt: String?

    // Safe English title fallback
    var englishTitle: String {
        title["en"] ?? title["ja-ro"] ?? title["ja"] ?? title.first?.value ?? "Unknown"
    }

    // Safe English description
    var englishDescription: String {
        description?["en"] ?? description?.first?.value ?? "No description available."
    }

    var manhwaStatus: ManhwaStatus {
        switch status {
        case "completed":            return .completed
        case "hiatus", "cancelled": return .hiatus
        default:                     return .ongoing
        }
    }
}

// MangaDex localised strings are dicts like {"en": "Title", "ja": "..."}
typealias MDLocalizedString = [String: String]

struct MDTag: Decodable {
    let id: String
    let attributes: MDTagAttributes
}

struct MDTagAttributes: Decodable {
    let name: MDLocalizedString
    var englishName: String { name["en"] ?? name.first?.value ?? "" }
}

// MARK: - Relationship (author / cover art / etc.)
struct MDRelationship: Decodable {
    let id: String
    let type: String
    let attributes: MDRelationshipAttributes?
}

struct MDRelationshipAttributes: Decodable {
    // cover_art
    let fileName: String?
    // author/artist
    let name: String?
}

// MARK: - Chapter entity
struct MDChapter: Decodable, Identifiable {
    let id: String
    let type: String
    let attributes: MDChapterAttributes
}

struct MDChapterAttributes: Decodable {
    let title: String?
    let volume: String?
    let chapter: String?
    let publishAt: String?
    let translatedLanguage: String?
    let pages: Int?

    var chapterNumber: Double? { chapter.flatMap { Double($0) } }
}

// MARK: - Cover Art entity (for fetching cover images)
struct MDCoverArt: Decodable, Identifiable {
    let id: String
    let attributes: MDCoverAttributes
}

struct MDCoverAttributes: Decodable {
    let fileName: String
    let volume: String?
}
