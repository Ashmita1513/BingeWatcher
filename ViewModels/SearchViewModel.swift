// ViewModels/SearchViewModel.swift
// Drives the Search screen — real API calls with debounce.

import Foundation
import Combine
import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {

    @Published var query: String = ""
    @Published var results: [Manhwa] = []
    @Published var isSearching: Bool = false
    @Published var errorMsg: String?

    // Suggestions shown when query is empty
    let trendingTags = ["Action", "Fantasy", "Romance", "Martial Arts", "Isekai", "Drama", "Thriller", "Comedy"]
    @Published var recentSearches: [String] = {
        (UserDefaults.standard.stringArray(forKey: "binge_recent_searches") ?? [])
    }()

    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Debounce: fire search 400 ms after the user stops typing
        $query
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] q in
                self?.performSearch(query: q)
            }
            .store(in: &cancellables)
    }

    // MARK: - Search
    private func performSearch(query: String) {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else {
            results = []
            isSearching = false
            return
        }

        searchTask?.cancel()
        isSearching = true
        errorMsg = nil

        searchTask = Task {
            do {
                let items = try await APIService.shared.searchManhwa(query: q, limit: 20)
                guard !Task.isCancelled else { return }
                results = items
                saveRecentSearch(q)
            } catch {
                guard !Task.isCancelled else { return }
                errorMsg = error.localizedDescription
            }
            isSearching = false
        }
    }

    // MARK: - Public helpers
    func selectRecentSearch(_ term: String) {
        query = term  // triggers debounce → performSearch
    }

    func clearSearch() {
        searchTask?.cancel()
        query      = ""
        results    = []
        isSearching = false
    }

    func searchByTag(_ tag: String) {
        query = tag
    }

    // MARK: - Recent search persistence
    private func saveRecentSearch(_ q: String) {
        var recent = recentSearches.filter { $0 != q }
        recent.insert(q, at: 0)
        recent = Array(recent.prefix(8))
        recentSearches = recent
        UserDefaults.standard.set(recent, forKey: "binge_recent_searches")
    }

    func removeRecentSearch(_ q: String) {
        recentSearches.removeAll { $0 == q }
        UserDefaults.standard.set(recentSearches, forKey: "binge_recent_searches")
    }
}
