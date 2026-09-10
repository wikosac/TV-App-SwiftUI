//
//  MockTVMazeAPIService.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import Foundation

@testable import TV_App

final class MockTVMazeAPIService: TVMazeAPIServicing {
    /// Used when `showsResultsByPage` has no entry for the requested page.
    var showsResult: Result<[Show], Error> = .success([])

    /// Optional per-page overrides, so pagination tests can script what
    /// page 0, 1, 2… each return (e.g. page 1 succeeds, page 2 is empty).
    var showsResultsByPage: [Int: Result<[Show], Error>] = [:]

    var detailResult: Result<Show, Error> = .success(
        Show(
            id: 1,
            name: "Mock Show",
            image: nil,
            rating: nil,
            summary: nil,
            premiered: nil,
            genres: nil,
            embedded: nil
        )
    )

    private(set) var fetchShowsCallCount = 0
    private(set) var fetchDetailCallCount = 0
    private(set) var requestedPages: [Int] = []

    func fetchShows(page: Int) async throws -> [Show] {
        fetchShowsCallCount += 1
        requestedPages.append(page)
        let result = showsResultsByPage[page] ?? showsResult
        return try result.get()
    }

    func fetchShowDetail(id: Int) async throws -> Show {
        fetchDetailCallCount += 1
        return try detailResult.get()
    }
}
