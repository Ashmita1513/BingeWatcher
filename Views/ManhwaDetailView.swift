// Views/ManhwaDetailView.swift
// Full detail view for a selected manhwa.

import SwiftUI

struct ManhwaDetailView: View {

    let manhwa: Manhwa
    @StateObject private var vm: DetailViewModel
    @State private var selectedManhwa: Manhwa?
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = MyListStore.shared

    init(manhwa: Manhwa) {
        self.manhwa = manhwa
        _vm = StateObject(wrappedValue: DetailViewModel(manhwa: manhwa))
    }

    var body: some View {
        ZStack {
            Color(hex: "#0B0B0B").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroHeader
                    contentBody
                }
                .padding(.bottom, 100)
            }

            // Follow animation overlay
            if vm.showFollowAnimation {
                followToast
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedManhwa) { m in
            ManhwaDetailView(manhwa: m)
        }
        .task { await vm.loadChapters() }
        .overlay(alignment: .topLeading) {
            // Custom back button
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 52)
        }
    }

    // MARK: - Hero header
    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Large cover/gradient
            RemoteCoverView(manhwa: manhwa, cornerRadius: 0)
                .frame(height: 380)
                .clipped()

            // Gradient fade to background
            LinearGradient(
                colors: [.clear, Color(hex: "#0B0B0B").opacity(0.6), Color(hex: "#0B0B0B")],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 380)

            VStack(alignment: .leading, spacing: 10) {
                Text(vm.manhwa.title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(vm.manhwa.author)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 10) {
                    StatusBadgeView(status: vm.manhwa.status)
                    StarRatingView(rating: vm.manhwa.rating)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Main body
    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 24) {

            // Action buttons
            actionButtons

            // Genre tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.manhwa.genres, id: \.self) { GenreTagView(genre: $0) }
                }
                .padding(.horizontal, 16)
            }

            // Stats row
            statsRow

            // Synopsis
            synopsisSection

            // Progress bar (if in list)
            if vm.isFollowed && !vm.chapters.isEmpty {
                progressSection
            }

            Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 16)

            // Chapters
            chaptersSection

            // Recommendations
            if !vm.recommendations.isEmpty {
                HorizontalRowView(
                    title: "More Like This",
                    emoji: "✨",
                    manhwas: vm.recommendations
                ) { selectedManhwa = $0 }
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Read Now
            Button {
                // In production: open reader
            } label: {
                Label("Read Now", systemImage: "book.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Follow / Unfollow
            Button { vm.toggleFollow() } label: {
                Label(
                    vm.isFollowed ? "Following" : "+ My List",
                    systemImage: vm.isFollowed ? "checkmark" : "plus"
                )
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(vm.isFollowed ? Color(hex: "#22C55E") : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    vm.isFollowed
                    ? Color(hex: "#22C55E").opacity(0.15)
                    : Color.white.opacity(0.1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            vm.isFollowed ? Color(hex: "#22C55E").opacity(0.5) : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .animation(.spring(response: 0.3), value: vm.isFollowed)

            // Notify
            Button { vm.toggleNotifications() } label: {
                Image(systemName: vm.notificationsEnabled ? "bell.fill" : "bell")
                    .font(.system(size: 16))
                    .foregroundStyle(vm.notificationsEnabled ? Color(hex: "#EAB308") : .white.opacity(0.6))
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(
                icon: "doc.text.fill",
                value: vm.chapters.isEmpty ? "—" : "\(vm.chapters.count)",
                label: "Chapters"
            )
            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
            statCell(
                icon: "clock.fill",
                value: relativeDate(vm.manhwa.lastUpdated),
                label: "Updated"
            )
            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
            statCell(
                icon: "calendar.badge.clock",
                value: vm.manhwa.nextReleaseText,
                label: "Next Est."
            )
        }
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private func statCell(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#E50914"))
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Synopsis
    private var synopsisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text(vm.manhwa.synopsis)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.65))
                .lineSpacing(5)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Progress bar
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Your Progress")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(vm.progressFraction * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "#E50914"))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 6)
                    Capsule()
                        .fill(Color(hex: "#E50914"))
                        .frame(width: geo.size.width * vm.progressFraction, height: 6)
                        .animation(.easeInOut, value: vm.progressFraction)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Chapters
    private var chaptersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Chapters")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                if vm.isLoadingChapters {
                    ProgressView().tint(Color(hex: "#E50914"))
                }
            }
            .padding(.horizontal, 16)

            if let err = vm.chapterError {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(.horizontal, 16)
            } else if vm.chapters.isEmpty && !vm.isLoadingChapters {
                Text("No chapters found in English")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.horizontal, 16)
            } else {
                // Show up to 20 most recent chapters
                VStack(spacing: 0) {
                    ForEach(vm.chapters.prefix(20)) { chapter in
                        ChapterRowView(chapter: chapter) {
                            vm.markChapterRead(chapter)
                        }
                        Divider().background(Color.white.opacity(0.06)).padding(.leading, 56)
                    }
                }
            }
        }
    }

    // MARK: - Follow toast
    private var followToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "#22C55E"))
                Text("Added to My List")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 12)
            .padding(.bottom, 100)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.4), value: vm.showFollowAnimation)
    }

    // MARK: - Helpers
    private func relativeDate(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Chapter Row
struct ChapterRowView: View {
    let chapter: Chapter
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Read indicator
                ZStack {
                    Circle()
                        .fill(chapter.isRead
                              ? Color(hex: "#E50914").opacity(0.2)
                              : Color.white.opacity(0.08))
                        .frame(width: 36, height: 36)
                    Image(systemName: chapter.isRead ? "checkmark" : "book")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(chapter.isRead
                                         ? Color(hex: "#E50914")
                                         : .white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Chapter \(chapter.number)")
                        .font(.system(size: 14, weight: chapter.isRead ? .regular : .semibold))
                        .foregroundStyle(chapter.isRead ? .white.opacity(0.45) : .white)
                    Text(chapter.title)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.35))
                        .lineLimit(1)
                }

                Spacer()

                Text(chapter.formattedDate)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
