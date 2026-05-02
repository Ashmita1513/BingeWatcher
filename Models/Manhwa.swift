// Models/Manhwa.swift
// Core data model for BingeWatcher — updated to support real API data

import Foundation
import SwiftUI

// MARK: - Status Enum
enum ManhwaStatus: String, CaseIterable, Codable {
    case ongoing   = "Ongoing"
    case completed = "Completed"
    case hiatus    = "Hiatus"

    var badgeColor: Color {
        switch self {
        case .ongoing:   return Color(hex: "#22C55E")
        case .completed: return Color(hex: "#3B82F6")
        case .hiatus:    return Color(hex: "#EF4444")
        }
    }

    var icon: String {
        switch self {
        case .ongoing:   return "bolt.fill"
        case .completed: return "checkmark.seal.fill"
        case .hiatus:    return "pause.circle.fill"
        }
    }
}

// MARK: - Update Badge
enum UpdateBadge: Equatable {
    case newChapter
    case upcoming
    case hiatus
    case none

    var color: Color {
        switch self {
        case .newChapter: return Color(hex: "#22C55E")
        case .upcoming:   return Color(hex: "#EAB308")
        case .hiatus:     return Color(hex: "#EF4444")
        case .none:       return .clear
        }
    }

    var label: String {
        switch self {
        case .newChapter: return "NEW"
        case .upcoming:   return "SOON"
        case .hiatus:     return "HIATUS"
        case .none:       return ""
        }
    }
}

// MARK: - Chapter
struct Chapter: Identifiable, Codable, Equatable {
    let id: UUID
    let number: Int
    let title: String
    let releaseDate: Date
    var isRead: Bool

    init(id: UUID = UUID(), number: Int, title: String, releaseDate: Date, isRead: Bool = false) {
        self.id = id; self.number = number; self.title = title
        self.releaseDate = releaseDate; self.isRead = isRead
    }

    var formattedDate: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: releaseDate, relativeTo: Date())
    }
}

// MARK: - Manhwa
struct Manhwa: Identifiable, Codable, Equatable {
    let id: UUID
    var mangaDexID: String
    var title: String
    var coverImageURL: String
    var heroGradientColors: [String]
    var status: ManhwaStatus
    var lastUpdated: Date
    var nextReleaseEstimate: Date?
    var genres: [String]
    var chapters: [Chapter]
    var synopsis: String
    var rating: Double
    var isFollowed: Bool
    var author: String

    var latestChapter: Chapter? { chapters.max(by: { $0.number < $1.number }) }
    var readChaptersCount: Int  { chapters.filter(\.isRead).count }

    var updateBadge: UpdateBadge {
        let days = Calendar.current.dateComponents([.day], from: lastUpdated, to: Date()).day ?? 0
        switch status {
        case .hiatus:    return .hiatus
        case .completed: return .none
        case .ongoing:
            if days <= 3 { return .newChapter }
            if let next = nextReleaseEstimate, next > Date() { return .upcoming }
            return .none
        }
    }

    var nextReleaseText: String {
        guard let next = nextReleaseEstimate else { return "Unknown" }
        if next < Date() { return "Overdue" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
        return days == 0 ? "Today!" : "In \(days) day\(days == 1 ? "" : "s")"
    }

    var heroGradient: LinearGradient {
        LinearGradient(
            colors: heroGradientColors.map { Color(hex: $0) },
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    static func == (lhs: Manhwa, rhs: Manhwa) -> Bool { lhs.id == rhs.id }
}

// MARK: - Color hex init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default: r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
