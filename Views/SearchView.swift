// Views/SearchView.swift
// Real-time search using MangaDex API with debounce, recent searches, and tag chips.

import SwiftUI

struct SearchView: View {

    @StateObject private var vm = SearchViewModel()
    @State private var selectedManhwa: Manhwa?
    @FocusState private var searchFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0B0B0B").ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    Divider().background(Color.white.opacity(0.08))

                    // Content area
                    if vm.isSearching {
                        searchingIndicator
                    } else if !vm.query.isEmpty && vm.results.isEmpty {
                        noResults
                    } else if !vm.query.isEmpty {
                        resultsList
                    } else {
                        suggestionsContent
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedManhwa) { m in
                ManhwaDetailView(manhwa: m)
            }
        }
        .onAppear { searchFocused = true }
    }

    // MARK: - Search bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            // Back button (when pushed into a NavigationStack)
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.4))

                TextField("Search manhwa, author, genre…", text: $vm.query)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .tint(Color(hex: "#E50914"))
                    .autocorrectionDisabled()
                    .focused($searchFocused)

                if !vm.query.isEmpty {
                    Button { vm.clearSearch() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Loading indicator
    private var searchingIndicator: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .tint(Color(hex: "#E50914"))
                .scaleEffect(1.3)
            Text("Searching…")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        }
    }

    // MARK: - No results
    private var noResults: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.15))
            Text("No results for "\(vm.query)"")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
            Text("Try a different title or author")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.3))
            Spacer()
        }
    }

    // MARK: - Results list
    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vm.results.count) result\(vm.results.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                ForEach(vm.results) { manhwa in
                    Button {
                        selectedManhwa = manhwa
                    } label: {
                        SearchResultRow(manhwa: manhwa)
                    }
                    .buttonStyle(CardPressStyle())
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Suggestions (shown when query is empty)
    private var suggestionsContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {

                // Trending tags
                VStack(alignment: .leading, spacing: 14) {
                    sectionLabel("Trending Tags")
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 100), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(vm.trendingTags, id: \.self) { tag in
                            Button { vm.searchByTag(tag) } label: {
                                Text(tag)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .frame(maxWidth: .infinity)
                                    .background(tagBackground(for: tag))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Recent searches
                if !vm.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            sectionLabel("Recent Searches")
                            Spacer()
                            Button("Clear All") {
                                vm.recentSearches.forEach { vm.removeRecentSearch($0) }
                            }
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#E50914"))
                        }
                        .padding(.horizontal, 16)

                        ForEach(vm.recentSearches, id: \.self) { term in
                            Button {
                                vm.selectRecentSearch(term)
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white.opacity(0.35))
                                    Text(term)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.75))
                                    Spacer()
                                    Button {
                                        vm.removeRecentSearch(term)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.3))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)
                            }
                            Divider()
                                .background(Color.white.opacity(0.06))
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white)
    }

    // Deterministic tag background colour
    private func tagBackground(for tag: String) -> some ShapeStyle {
        let palettes: [Color] = [
            Color(hex: "#E50914"), Color(hex: "#1B4B8A"),
            Color(hex: "#2D6A4F"), Color(hex: "#5C2A00"),
            Color(hex: "#4A0080"), Color(hex: "#1A3A6A"),
            Color(hex: "#3D1A00"), Color(hex: "#001A3D")
        ]
        let idx = abs(tag.hashValue) % palettes.count
        return palettes[idx].opacity(0.5)
    }
}

// MARK: - Search result row
struct SearchResultRow: View {
    let manhwa: Manhwa

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            RemoteCoverView(manhwa: manhwa, cornerRadius: 8)
                .frame(width: 56, height: 78)

            VStack(alignment: .leading, spacing: 5) {
                Text(manhwa.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(manhwa.author)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))

                HStack(spacing: 8) {
                    StatusBadgeView(status: manhwa.status)
                    if !manhwa.genres.isEmpty {
                        Text(manhwa.genres.prefix(2).joined(separator: " · "))
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.03))
    }
}

#Preview {
    SearchView()
}
