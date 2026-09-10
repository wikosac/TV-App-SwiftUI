//
//  ShowDetailViewModel.swift
//  TVApp
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import Combine
import Foundation

@MainActor
final class ShowDetailViewModel: ObservableObject {
    @Published private(set) var state: ViewState<Show>

    private let api: TVMazeAPIServicing
    private let showID: Int

    /// Seeding with the show we already have (from the list) lets the detail
    /// screen render instantly while it refreshes in the background for the
    /// bonus embedded cast/episode data.
    init(seed: Show, api: TVMazeAPIServicing = TVMazeAPIService()) {
        self.showID = seed.id
        self.api = api
        self.state = .success(seed)
    }

    init(showID: Int, api: TVMazeAPIServicing = TVMazeAPIService()) {
        self.showID = showID
        self.api = api
        self.state = .loading
    }

    func loadDetail() async {
        do {
            let show = try await api.fetchShowDetail(id: showID)
            state = .success(show)
        } catch {
            // If we already have seeded data, keep showing it rather than
            // replacing a working screen with an error on a background refresh.
            if case .success = state { return }
            state = .error(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? APIError)?.errorDescription ?? error.localizedDescription
    }
}
