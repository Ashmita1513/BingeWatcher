// ViewModels/MyListViewModel.swift
// Drives MyListView — wraps MyListStore.

import Foundation
import Combine
import SwiftUI

@MainActor
final class MyListViewModel: ObservableObject {

    @Published var filter: MyListFilter = .all
    @Published var items: [Manhwa] = []

    private let store: MyListStore
    private var cancellable: AnyCancellable?

    init(store: MyListStore = .shared) {
        self.store = store
        // Mirror store changes through the filter
        cancellable = store.$items
            .combineLatest($filter)
            .receive(on: RunLoop.main)
            .sink { [weak self] (storeItems, f) in
                guard let self else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.items = store.filtered(by: f)
                }
            }
    }

    func remove(_ manhwa: Manhwa) {
        store.remove(manhwa)
    }

    func isInList(_ manhwa: Manhwa) -> Bool { store.isInList(manhwa) }
}
