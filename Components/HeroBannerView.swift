// Components/HeroBannerView.swift
// Used only if you need the standalone component; HomeView uses inline banner logic.

import SwiftUI

struct HeroBannerView: View {
    let manhwa: Manhwa
    let onContinue: () -> Void
    let onAddToList: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteCoverView(manhwa: manhwa, cornerRadius: 0)
                .frame(height: 480)
                .allowsHitTesting(false)

            LinearGradient(
                colors: [.clear, Color(hex: "#0B0B0B").opacity(0.5), Color(hex: "#0B0B0B")],
                startPoint: .center, endPoint: .bottom
            )
            .frame(height: 480)
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) { ForEach(manhwa.genres, id: \.self) { GenreTagView(genre: $0) } }
                }
                .allowsHitTesting(false)

                Text(manhwa.title)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    StatusBadgeView(status: manhwa.status)
                    StarRatingView(rating: manhwa.rating)
                }

                HStack(spacing: 12) {
                    Button(action: onContinue) {
                        Label("Read Now", systemImage: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20).padding(.vertical, 12)
                            .background(.white).clipShape(Capsule())
                    }
                    Button(action: onAddToList) {
                        Label("My List", systemImage: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20).padding(.vertical, 12)
                            .background(Color.white.opacity(0.18)).clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .frame(height: 480)
        .clipped()
    }
}
