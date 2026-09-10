//
//  ShowListViewModel.swift
//  TVApp
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import Combine
import Foundation

@MainActor
final class ShowListViewModel: ObservableObject {
    @Published private(set) var state: ViewState<[Show]> = .loading

    /// True while a *next page* fetch is in flight. Separate from `state`
    /// (which stays `.success` with the shows we already have) so the list
    /// keeps rendering while a small footer spinner shows underneath it.
    @Published private(set) var isLoadingNextPage = false

    /// Set when a next-page fetch fails. Kept separate from `state` so a
    /// pagination failure doesn't blow away the shows already on screen —
    /// it just surfaces a small inline retry affordance in the list footer.
    @Published private(set) var nextPageErrorMessage: String?

    /// How many rows from the end of the currently-loaded list we trigger
    /// the next page fetch. Small buffer so scrolling feels seamless.
    private let prefetchThreshold = 10

    private let api: TVMazeAPIServicing
    private var currentPage = 0
    private var canLoadMore = true

    init(api: TVMazeAPIServicing = TVMazeAPIService()) {
        self.api = api
    }

    /// Initial load, and what pull-to-refresh calls. Resets pagination.
    func loadShows() async {
        state = .loading
        currentPage = 0
        canLoadMore = true
        nextPageErrorMessage = nil
        do {
            let shows = try await api.fetchShows(page: currentPage)
            canLoadMore = !shows.isEmpty
            state = .success(shows)
        } catch {
            state = .error(Self.message(for: error))
        }
    }

    /// Call from a row's `.task`/`.onAppear` as the user scrolls. Triggers
    /// the next page once the given show is within `prefetchThreshold` rows
    /// of the end of the currently-loaded list.
    func loadMoreIfNeeded(currentShow: Show) async {
        guard case .success(let shows) = state else { return }
        guard let index = shows.firstIndex(where: { $0.id == currentShow.id })
        else { return }
        guard index >= shows.count - prefetchThreshold else { return }
        await loadNextPage()
    }

    func retryLoadNextPage() async {
        await loadNextPage()
    }

    private func loadNextPage() async {
        guard canLoadMore, !isLoadingNextPage else { return }
        guard case .success(let shows) = state else { return }

        isLoadingNextPage = true
        nextPageErrorMessage = nil
        defer { isLoadingNextPage = false }

        let nextPage = currentPage + 1
        do {
            let newShows = try await api.fetchShows(page: nextPage)
            if newShows.isEmpty {
                canLoadMore = false
            } else {
                currentPage = nextPage
                state = .success(shows + newShows)
            }
        } catch {
            // TVMaze returns a 404 once you page past the last page of
            // shows — that's "end of the list," not a real error.
            if case APIError.invalidResponse(404) = error {
                canLoadMore = false
            } else {
                nextPageErrorMessage = Self.message(for: error)
            }
        }
    }

    private static func message(for error: Error) -> String {
        (error as? APIError)?.errorDescription ?? error.localizedDescription
    }
}
