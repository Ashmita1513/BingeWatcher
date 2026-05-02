// ViewModels/HomeViewModel.swift
// Drives the Home screen. Fetches real data from MangaDex.

import Foundation
import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published State
    @Published var featuredManhwa: Manhwa?
    @Published var recentlyUpdated: [Manhwa] = []
    @Published var trending: [Manhwa] = []
    @Published var continueReading: [Manhwa] = []

    @Published var isLoading  = true
    @Published var errorMsg: String?

    @Published var heroBannerIndex = 0
    @Published var heroCandidates: [Manhwa] = []

    private let store: MyListStore
    private var bannerTimer: AnyCancellable?
    private var storeCancellable: AnyCancellable?

    // MARK: - Init
    init(store: MyListStore = .shared) {
        self.store = store
        storeCancellable = store.$items
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                self?.continueReading = items
            }
    }

    // MARK: - Load real data
    func loadData() async {
        isLoading = true
        errorMsg  = nil
        do {
            async let trendTask  = APIService.shared.fetchTrending(limit: 20)
            async let recentTask = APIService.shared.fetchRecentlyUpdated(limit: 20)
            let (trendResult, recentResult) = try await (trendTask, recentTask)

            trending        = trendResult
            recentlyUpdated = recentResult
            heroCandidates  = Array(trendResult.prefix(5))
            featuredManhwa  = heroCandidates.first

            withAnimation(.easeInOut(duration: 0.4)) { isLoading = false }
            startBannerRotation()
        } catch {
            errorMsg = error.localizedDescription
            isLoading = false
        }
    }

    func refresh() async { await loadData() }

    func toggleList(_ manhwa: Manhwa) { store.toggle(manhwa) }
    func isInList(_ manhwa: Manhwa) -> Bool { store.isInList(manhwa) }

    // MARK: - Hero banner auto-cycle
    private func startBannerRotation() {
        bannerTimer?.cancel()
        guard heroCandidates.count > 1 else { return }
        bannerTimer = Timer.publish(every: 6, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                withAnimation(.easeInOut(duration: 0.6)) {
                    self.heroBannerIndex = (self.heroBannerIndex + 1) % self.heroCandidates.count
                    self.featuredManhwa  = self.heroCandidates[self.heroBannerIndex]
                }
            }
    }
}
