// Components/ManhwaCoverView.swift
// Thin wrapper — real cover loading is in RemoteCoverView.
// Kept for #Preview compatibility only.

import SwiftUI

// ManhwaCoverView is now a typealias to RemoteCoverView (defined in RemoteCoverView.swift)
// This file intentionally left minimal to avoid duplicate symbol errors.

#Preview {
    RemoteCoverView(manhwa: Manhwa(
        id: UUID(), mangaDexID: "preview",
        title: "Preview Manhwa",
        coverImageURL: "",
        heroGradientColors: ["#1A0533","#4A0080","#0B0B0B"],
        status: .ongoing, lastUpdated: Date(),
        genres: ["Action","Fantasy"], chapters: [], synopsis: "Synopsis.",
        rating: 4.7, isFollowed: false, author: "Author"
    ))
    .frame(width: 130, height: 190)
    .padding()
    .background(Color(hex: "#0B0B0B"))
}
