// Views/HomeView.swift
// Netflix-style home screen — real API data, fixed scrolling, working My List.

import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var selectedManhwa: Manhwa?
    @State private var showProfile = false
    @State private var headerOpacity: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(hex: "#0B0B0B").ignoresSafeArea()

                mainScroll

                // Floating nav bar (drawn on top, NOT intercepting scroll)
                navBar
                    .allowsHitTesting(true)   // only nav bar buttons are tappable
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedManhwa) { m in
                ManhwaDetailView(manhwa: m)
            }
            .task { await vm.loadData() }
        }
    }

    // MARK: - Main scrollable content
    // Uses a single ScrollView — no nested gesture conflicts.
    private var mainScroll: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: []) {

                // Spacer beneath transparent nav bar
                Color.clear.frame(height: 56)

                // Hero banner or skeleton
                if vm.isLoading {
                    heroSkeleton
                } else if let featured = vm.featuredManhwa {
                    heroBanner(featured)
                        .transition(.opacity)
                }

                // Error state
                if let err = vm.errorMsg {
                    errorBanner(err)
                }

                // Content rows
                if vm.isLoading {
                    VStack(spacing: 28) {
                        RowSkeleton()
                        RowSkeleton()
                        RowSkeleton()
                    }
                    .padding(.top, 24)
                } else {
                    rowsContent
                }

                Color.clear.frame(height: 100) // tab bar clearance
            }
            // Track scroll for nav bar opacity
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: -geo.frame(in: .named("homeScroll")).minY
                    )
                }
            )
        }
        .coordinateSpace(name: "homeScroll")
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            headerOpacity = min(offset / 80, 1)
        }
        .refreshable {
            await vm.refresh()
        }
    }

    // MARK: - Nav bar
    private var navBar: some View {
        HStack {
            Text("BingeWatcher")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#E50914"), Color(hex: "#FF6B6B")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )

            Spacer()

            HStack(spacing: 18) {
                NavigationLink(destination: SearchView()) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Button { showProfile = true } label: {
                    ZStack {
                        Circle().fill(Color(hex: "#E50914")).frame(width: 32, height: 32)
                        Text("B")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Color(hex: "#0B0B0B")
                .opacity(headerOpacity)
                .ignoresSafeArea(edges: .top)
        )
        .sheet(isPresented: $showProfile) {
            ProfileSheetView()
        }
    }

    // MARK: - Hero banner
    private func heroBanner(_ manhwa: Manhwa) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            RemoteCoverView(manhwa: manhwa, cornerRadius: 0)
                .frame(height: 490)
                .clipped()
                // Allow gestures to pass through to the ScrollView
                .allowsHitTesting(false)

            // Gradient overlay — also non-interactive
            LinearGradient(
                colors: [.clear, Color(hex: "#0B0B0B").opacity(0.4), Color(hex: "#0B0B0B")],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 490)
            .allowsHitTesting(false)

            // Content: only the buttons need hit-testing
            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(manhwa.genres.prefix(4), id: \.self) { GenreTagView(genre: $0) }
                    }
                }
                .allowsHitTesting(false)

                Text(manhwa.title)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 8)
                    .allowsHitTesting(false)

                HStack(spacing: 12) {
                    StatusBadgeView(status: manhwa.status)
                    StarRatingView(rating: manhwa.rating)
                }
                .allowsHitTesting(false)

                HStack(spacing: 12) {
                    // Continue / Read Now
                    Button {
                        selectedManhwa = manhwa
                    } label: {
                        Label("Read Now", systemImage: "book.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.white)
                            .clipShape(Capsule())
                    }

                    // My List toggle
                    let isIn = vm.isInList(manhwa)
                    Button {
                        vm.toggleList(manhwa)
                    } label: {
                        Label(isIn ? "In My List" : "+ My List",
                              systemImage: isIn ? "checkmark" : "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isIn ? Color(hex: "#22C55E") : .white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }
                    .animation(.spring(response: 0.3), value: isIn)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .frame(height: 490)
        .id(manhwa.id)
        .animation(.easeInOut(duration: 0.5), value: manhwa.id)
    }

    // MARK: - Hero skeleton
    private var heroSkeleton: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 490)
            .shimmer()
    }

    // MARK: - Banner page indicators
    private var bannerIndicators: some View {
        HStack(spacing: 6) {
            ForEach(vm.heroCandidates.indices, id: \.self) { i in
                Capsule()
                    .fill(i == vm.heroBannerIndex
                          ? Color(hex: "#E50914")
                          : Color.white.opacity(0.3))
                    .frame(width: i == vm.heroBannerIndex ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.3), value: vm.heroBannerIndex)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Rows
    private var rowsContent: some View {
        VStack(spacing: 0) {
            // Page indicators
            bannerIndicators
                .padding(.bottom, 8)

            VStack(spacing: 28) {
                // Continue Reading (from My List)
                if !vm.continueReading.isEmpty {
                    HorizontalRowView(
                        title: "My List",
                        emoji: "📖",
                        manhwas: vm.continueReading,
                        onTap: { selectedManhwa = $0 }
                    )
                }

                // Recently Updated
                if !vm.recentlyUpdated.isEmpty {
                    HorizontalRowView(
                        title: "New Updates",
                        emoji: "🔥",
                        manhwas: vm.recentlyUpdated,
                        onTap: { selectedManhwa = $0 }
                    )
                }

                // Trending
                if !vm.trending.isEmpty {
                    HorizontalRowView(
                        title: "Trending",
                        emoji: "📈",
                        manhwas: vm.trending,
                        onTap: { selectedManhwa = $0 }
                    )
                }
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Error banner
    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(Color(hex: "#E50914"))
            Text(msg)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(2)
            Spacer()
            Button("Retry") { Task { await vm.refresh() } }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#E50914"))
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - Scroll offset preference key
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Profile sheet
struct ProfileSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = MyListStore.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0B0B0B").ignoresSafeArea()
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(hex: "#E50914"), Color(hex: "#FF6B6B")],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 90, height: 90)
                        Text("B")
                            .font(.system(size: 40, weight: .black))
                            .foregroundStyle(.white)
                    }
                    Text("BingeReader")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Tracking \(store.items.count) series")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))

                    statsGrid
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#E50914"))
                }
            }
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 0) {
            statCell(value: "\(store.items.count)", label: "Following")
            Divider().frame(height: 40)
            statCell(value: "\(store.items.filter { $0.status == .ongoing }.count)", label: "Ongoing")
            Divider().frame(height: 40)
            statCell(value: "\(store.items.filter { $0.status == .completed }.count)", label: "Completed")
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview { HomeView() }
