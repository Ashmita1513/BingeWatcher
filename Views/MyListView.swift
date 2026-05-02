// Views/MyListView.swift
// Shows the user's saved manhwa list with filter chips and swipe-to-delete.

import SwiftUI

struct MyListView: View {

    @StateObject private var vm = MyListViewModel()
    @State private var selectedManhwa: Manhwa?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0B0B0B").ignoresSafeArea()

                VStack(spacing: 0) {
                    filterChips
                    Divider().background(Color.white.opacity(0.08))

                    if vm.items.isEmpty {
                        emptyState
                    } else {
                        gridContent
                    }
                }
            }
            .navigationTitle("My List")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(vm.items.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            .navigationDestination(item: $selectedManhwa) { m in
                ManhwaDetailView(manhwa: m)
            }
        }
    }

    // MARK: - Filter chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MyListFilter.allCases) { f in
                    Button {
                        withAnimation(.spring(response: 0.3)) { vm.filter = f }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: f.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(f.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(vm.filter == f ? .black : .white.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            vm.filter == f
                            ? Color.white
                            : Color.white.opacity(0.08)
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Grid
    private var gridContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(vm.items) { manhwa in
                    gridCell(manhwa)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 100)
            .animation(.easeInOut(duration: 0.25), value: vm.items.map(\.id))
        }
        .refreshable {
            // no-op: list is local
        }
    }

    private func gridCell(_ manhwa: Manhwa) -> some View {
        Button {
            selectedManhwa = manhwa
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                // Cover
                ZStack(alignment: .topTrailing) {
                    RemoteCoverView(manhwa: manhwa, cornerRadius: 10)
                        .aspectRatio(2/3, contentMode: .fit)

                    if manhwa.updateBadge != .none {
                        Text(manhwa.updateBadge.label)
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(manhwa.updateBadge.color)
                            .clipShape(Capsule())
                            .padding(6)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    // Remove button (appears in the cell itself)
                    Button {
                        withAnimation { vm.remove(manhwa) }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .padding(6)
                }

                Text(manhwa.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Circle()
                        .fill(manhwa.status.badgeColor)
                        .frame(width: 5, height: 5)
                    Text(manhwa.status.rawValue)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .buttonStyle(CardPressStyle())
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "#E50914").opacity(0.7))
            }

            Text("Your list is empty")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Text("Add manhwas by tapping\n\"+ My List\" on any title")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)

            // Filter hint if non-default filter
            if vm.filter != .all {
                Button {
                    vm.filter = .all
                } label: {
                    Text("Show All")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#E50914"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#E50914").opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }
}

#Preview {
    MyListView()
}
