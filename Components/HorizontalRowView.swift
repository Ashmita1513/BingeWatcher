// Components/HorizontalRowView.swift

import SwiftUI

struct HorizontalRowView: View {
    let title: String
    let emoji: String
    let manhwas: [Manhwa]
    let onTap: (Manhwa) -> Void

    @State private var showSeeAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(emoji).font(.system(size: 18))
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    showSeeAll = true
                } label: {
                    HStack(spacing: 3) {
                        Text("See All")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "#E50914"))
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(manhwas) { m in
                        Button { onTap(m) } label: {
                            ManhwaCardView(manhwa: m)
                        }
                        .buttonStyle(CardPressStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
        .navigationDestination(isPresented: $showSeeAll) {
            SectionListView(title: title, emoji: emoji, manhwas: manhwas)
        }
    }
}

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
