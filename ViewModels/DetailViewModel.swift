// ViewModels/DetailViewModel.swift

import Foundation
import SwiftUI

@MainActor
final class DetailViewModel: ObservableObject {

    @Published var manhwa: Manhwa
    @Published var chapters: [Chapter] = []
    @Published var recommendations: [Manhwa] = []
    @Published var isLoadingChapters = false
    @Published var notificationsEnabled = false
    @Published var showFollowAnimation = false
    @Published var chapterError: String?

    private let store: MyListStore
    var isFollowed: Bool { store.isInList(manhwa) }

    init(manhwa: Manhwa, store: MyListStore = .shared) {
        self.manhwa = manhwa
        self.store  = store
    }

    func loadChapters() async {
        isLoadingChapters = true
        chapterError = nil
        do {
            async let chaptersTask  = APIService.shared.fetchChapters(mangaID: manhwa.mangaDexID, limit: 50)
            async let recommendTask = APIService.shared.fetchTrending(limit: 10)
            let (fetched, trending) = try await (chaptersTask, recommendTask)
            chapters        = fetched
            recommendations = trending.filter { $0.mangaDexID != manhwa.mangaDexID }
        } catch {
            chapterError = error.localizedDescription
        }
        isLoadingChapters = false
    }

    func toggleFollow() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            store.toggle(manhwa)
            showFollowAnimation = store.isInList(manhwa)
        }
        if store.isInList(manhwa) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.showFollowAnimation = false
            }
        }
    }

    func toggleNotifications() { withAnimation { notificationsEnabled.toggle() } }

    func markChapterRead(_ chapter: Chapter) {
        guard let idx = chapters.firstIndex(where: { $0.id == chapter.id }) else { return }
        chapters[idx].isRead.toggle()
    }

    var progressFraction: Double {
        guard !chapters.isEmpty else { return 0 }
        return Double(chapters.filter(\.isRead).count) / Double(chapters.count)
    }

    var nextUnreadChapter: Chapter? {
        chapters.sorted { $0.number < $1.number }.first(where: { !$0.isRead })
    }
}
