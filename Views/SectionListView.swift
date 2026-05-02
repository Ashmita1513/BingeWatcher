// Views/SectionListView.swift
// Full-screen grid shown when user taps "See All" in a row.

import SwiftUI

struct SectionListView: View {
    let title: String
    let emoji: String
    let manhwas: [Manhwa]

    @State private var selectedManhwa: Manhwa?
    @Environment(\.dismiss) private var dismiss

    // 2-column adaptive grid
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            Color(hex: "#0B0B0B").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(manhwas) { manhwa in
                        Button {
                            selectedManhwa = manhwa
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                // Cover card
                                ZStack(alignment: .topTrailing) {
                                    RemoteCoverView(manhwa: manhwa, cornerRadius: 12)
                                        .aspectRatio(2/3, contentMode: .fit)

                                    // Update badge
                                    if manhwa.updateBadge != .none {
                                        Text(manhwa.updateBadge.label)
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(manhwa.updateBadge.color)
                                            .clipShape(Capsule())
                                            .padding(8)
                                    }
                                }

                                // Title
                                Text(manhwa.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)

                                // Status + chapter
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(manhwa.status.badgeColor)
                                        .frame(width: 6, height: 6)
                                    Text(manhwa.status.rawValue)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white.opacity(0.55))
                                    if let ch = manhwa.latestChapter {
                                        Text("· Ch.\(ch.number)")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                }
                            }
                        }
                        .buttonStyle(CardPressStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("\(emoji) \(title)")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $selectedManhwa) { m in
            ManhwaDetailView(manhwa: m)
        }
    }
}

#Preview {
    NavigationStack {
        SectionListView(
            title: "Trending",
            emoji: "📈",
            manhwas: (0..<8).map { i in
                Manhwa(id: UUID(), mangaDexID: "id\(i)", title: "Manhwa \(i)",
                       coverImageURL: "", heroGradientColors: ["#1A0533","#4A0080","#0B0B0B"],
                       status: .ongoing, lastUpdated: Date(), genres: ["Action"],
                       chapters: [], synopsis: "", rating: 4.5, isFollowed: false, author: "Auth")
            }
        )
    }
}
