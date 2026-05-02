// Components/ManhwaCardView.swift
// Compact card used inside horizontal scroll rows.

import SwiftUI

struct ManhwaCardView: View {
    let manhwa: Manhwa
    var width: CGFloat  = 130
    var height: CGFloat = 190

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                RemoteCoverView(manhwa: manhwa, cornerRadius: 10)
                    .frame(width: width, height: height)

                // Update badge
                if manhwa.updateBadge != .none {
                    Text(manhwa.updateBadge.label)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(manhwa.updateBadge.color)
                        .clipShape(Capsule())
                        .padding(7)
                }

                // Progress arc for followed cards
                if MyListStore.shared.isInList(manhwa) && manhwa.readChaptersCount > 0 && !manhwa.chapters.isEmpty {
                    ProgressArcView(
                        progress: Double(manhwa.readChaptersCount) / Double(manhwa.chapters.count)
                    )
                    .frame(width: 28, height: 28)
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }

            Text(manhwa.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(width: width, alignment: .leading)

            if let ch = manhwa.latestChapter {
                Text("Ch. \(ch.number)")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(width: width)
    }
}

// MARK: - Small progress arc
struct ProgressArcView: View {
    let progress: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.2), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color(hex: "#E50914"),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}
