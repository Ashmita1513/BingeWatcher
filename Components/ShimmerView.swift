// Components/ShimmerView.swift
// Animated shimmer placeholder for loading states

import SwiftUI

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear,                    location: 0),
                            .init(color: .white.opacity(0.15),      location: 0.3),
                            .init(color: .white.opacity(0.35),      location: 0.5),
                            .init(color: .white.opacity(0.15),      location: 0.7),
                            .init(color: .clear,                    location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: geo.size.width * (phase - 1))
                    .animation(
                        .linear(duration: 1.4).repeatForever(autoreverses: false),
                        value: phase
                    )
                    .clipped()
                }
            )
            .onAppear { phase = 1 }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - Card Skeleton
struct CardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
                .frame(width: 130, height: 190)
                .shimmer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.08))
                .frame(width: 100, height: 10)
                .shimmer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.06))
                .frame(width: 60, height: 8)
                .shimmer()
        }
        .frame(width: 130)
    }
}

// MARK: - Row Skeleton (a labeled row of card skeletons)
struct RowSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(width: 140, height: 14)
                .shimmer()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        CardSkeleton()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        RowSkeleton()
        RowSkeleton()
    }
    .padding(.vertical)
    .background(Color(hex: "#0B0B0B"))
}
