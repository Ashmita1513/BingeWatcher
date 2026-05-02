// Services/MyListStore.swift
// Single source of truth for the user's saved manhwa list.
// Persists to UserDefaults so it survives app restarts.

import Foundation
import Combine

final class MyListStore: ObservableObject {

    static let shared = MyListStore()

    // Published list — all views that inject this will auto-update
    @Published private(set) var items: [Manhwa] = []

    private let key = "binge_my_list_v2"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        load()
    }

    // MARK: - Public API

    func isInList(_ manhwa: Manhwa) -> Bool {
        items.contains { $0.mangaDexID == manhwa.mangaDexID }
    }

    /// Adds if absent, removes if present. Returns new state.
    @discardableResult
    func toggle(_ manhwa: Manhwa) -> Bool {
        if isInList(manhwa) {
            remove(manhwa)
            return false
        } else {
            add(manhwa)
            return true
        }
    }

    func add(_ manhwa: Manhwa) {
        guard !isInList(manhwa) else { return }
        var copy = manhwa
        copy.isFollowed = true
        items.append(copy)
        save()
    }

    func remove(_ manhwa: Manhwa) {
        items.removeAll { $0.mangaDexID == manhwa.mangaDexID }
        save()
    }

    // MARK: - Filter helpers
    func filtered(by filter: MyListFilter) -> [Manhwa] {
        switch filter {
        case .all:       return items
        case .ongoing:   return items.filter { $0.status == .ongoing }
        case .completed: return items.filter { $0.status == .completed }
        case .hiatus:    return items.filter { $0.status == .hiatus }
        case .recent:    return items.sorted { $0.lastUpdated > $1.lastUpdated }
        }
    }

    // MARK: - Persistence
    private func save() {
        guard let data = try? encoder.encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data  = UserDefaults.standard.data(forKey: key),
            let saved = try? decoder.decode([Manhwa].self, from: data)
        else { return }
        items = saved
    }
}

// MARK: - Filter enum (shared between MyListView and ViewModel)
enum MyListFilter: String, CaseIterable, Identifiable {
    case all       = "All"
    case ongoing   = "Ongoing"
    case completed = "Completed"
    case hiatus    = "Hiatus"
    case recent    = "Recent"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all:       return "square.grid.2x2"
        case .ongoing:   return "bolt.fill"
        case .completed: return "checkmark.seal.fill"
        case .hiatus:    return "pause.circle.fill"
        case .recent:    return "clock.fill"
        }
    }
}
