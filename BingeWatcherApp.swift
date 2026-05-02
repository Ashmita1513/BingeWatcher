// BingeWatcherApp.swift
// App entry point with tab bar navigation.

import SwiftUI

@main
struct BingeWatcherApp: App {

    // Inject the shared MyListStore at app level so all tabs share it
    @StateObject private var listStore = MyListStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(listStore)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Root tab view
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)

                SearchView()
                    .tag(1)

                MyListView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))  // hide default tab bar
            .ignoresSafeArea()

            // Custom bottom tab bar
            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(index: 0, icon: "house.fill",      label: "Home")
            tabItem(index: 1, icon: "magnifyingglass", label: "Search")
            tabItem(index: 2, icon: "books.vertical.fill", label: "My List")
        }
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                )
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5),
            alignment: .top
        )
    }

    private func tabItem(index: Int, icon: String, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: selectedTab == index ? .bold : .regular))
                    .foregroundStyle(selectedTab == index ? Color(hex: "#E50914") : .white.opacity(0.4))
                    .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)

                Text(label)
                    .font(.system(size: 10, weight: selectedTab == index ? .semibold : .regular))
                    .foregroundStyle(selectedTab == index ? Color(hex: "#E50914") : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ContentView()
}
