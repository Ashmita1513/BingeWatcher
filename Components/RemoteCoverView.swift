// Components/RemoteCoverView.swift
// Loads a remote cover image with gradient fallback.
// Replaces the static ManhwaCoverView for real API data.

import SwiftUI

struct RemoteCoverView: View {
    let manhwa: Manhwa
    var cornerRadius: CGFloat = 10

    // Deterministic gradient from the model
    private var gradient: LinearGradient { manhwa.heroGradient }

    private var genreIcon: String {
        let g = manhwa.genres.map { $0.lowercased() }
        if g.contains(where: { $0.contains("romance") })      { return "heart.fill" }
        if g.contains(where: { $0.contains("martial") })      { return "figure.martial.arts" }
        if g.contains(where: { $0.contains("action") })       { return "bolt.fill" }
        if g.contains(where: { $0.contains("fantasy") })      { return "sparkles" }
        if g.contains(where: { $0.contains("mystery") })      { return "eye.fill" }
        if g.contains(where: { $0.contains("sci") })          { return "atom" }
        return "book.fill"
    }

    var body: some View {
        Group {
            if let url = URL(string: manhwa.coverImageURL), !manhwa.coverImageURL.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure:
                        gradientFallback
                    case .empty:
                        gradientFallback.shimmer()
                    @unknown default:
                        gradientFallback
                    }
                }
            } else {
                gradientFallback
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var gradientFallback: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: cornerRadius).fill(gradient)

            // Decorative circles
            Circle().fill(.white.opacity(0.05)).frame(width: 80).offset(x: -15, y: -10)
            Circle().fill(.white.opacity(0.03)).frame(width: 120).offset(x: 30, y: 20)

            // Icon centred
            VStack {
                Image(systemName: genreIcon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom scrim
            LinearGradient(colors: [.clear, .black.opacity(0.8)],
                           startPoint: .center, endPoint: .bottom)
        }
    }
}

// Keep old name as typealias so existing callers don't break
typealias ManhwaCoverView = RemoteCoverView

#Preview {
    RemoteCoverView(manhwa: {
        Manhwa(id: UUID(), mangaDexID: "", title: "Test",
               coverImageURL: "",
               heroGradientColors: ["#1A0533","#4A0080","#0B0B0B"],
               status: .ongoing, lastUpdated: Date(),
               genres: ["Action"], chapters: [], synopsis: "",
               rating: 4.5, isFollowed: false, author: "Author")
    }())
    .frame(width: 130, height: 190)
    .padding()
    .background(Color(hex: "#0B0B0B"))
}
