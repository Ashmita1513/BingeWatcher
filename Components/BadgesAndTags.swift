// Components/BadgesAndTags.swift
// Reusable small UI pieces

import SwiftUI

// MARK: - Status Badge
struct StatusBadgeView: View {
    let status: ManhwaStatus

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.icon)
                .font(.system(size: 10, weight: .bold))
            Text(status.rawValue)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(status.badgeColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.badgeColor.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(status.badgeColor.opacity(0.4), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Genre Tag
struct GenreTagView: View {
    let genre: String

    var body: some View {
        Text(genre)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.75))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
    }
}

// MARK: - Star Rating
struct StarRatingView: View {
    let rating: Double  // 0–5

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starIcon(for: star))
                    .font(.system(size: 11))
                    .foregroundStyle(star <= Int(rating.rounded()) ? Color(hex: "#EAB308") : .white.opacity(0.25))
            }
            Text(String(format: "%.1f", rating))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func starIcon(for star: Int) -> String {
        let full = Int(rating)
        let hasHalf = rating - Double(full) >= 0.5
        if star <= full { return "star.fill" }
        if star == full + 1 && hasHalf { return "star.leadinghalf.filled" }
        return "star"
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        HStack {
            StatusBadgeView(status: .ongoing)
            StatusBadgeView(status: .completed)
            StatusBadgeView(status: .hiatus)
        }
        HStack {
            GenreTagView(genre: "Action")
            GenreTagView(genre: "Fantasy")
            GenreTagView(genre: "Romance")
        }
        StarRatingView(rating: 4.5)
    }
    .padding()
    .background(Color(hex: "#0B0B0B"))
}
