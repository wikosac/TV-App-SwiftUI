//
//  ShowListViewModelTests.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import XCTest

@testable import TV_App

@MainActor
final class ShowListViewModelTests: XCTestCase {

    func test_loadShows_success_updatesStateToSuccessWithShows() async {
        let mock = MockTVMazeAPIService()
        let shows = [
            Show(
                id: 1,
                name: "Breaking Bad",
                image: nil,
                rating: Rating(average: 9.4),
                summary: nil,
                premiered: "2008-01-20",
                genres: nil,
                embedded: nil
            ),
            Show(
                id: 2,
                name: "The Wire",
                image: nil,
                rating: nil,
                summary: nil,
                premiered: "2002-06-02",
                genres: nil,
                embedded: nil
            ),
        ]
        mock.showsResult = .success(shows)
        let sut = ShowListViewModel(api: mock)

        await sut.loadShows()

        guard case .success(let loadedShows) = sut.state else {
            return XCTFail("Expected .success state, got \(sut.state)")
        }
        XCTAssertEqual(loadedShows.count, 2)
        XCTAssertEqual(loadedShows.first?.name, "Breaking Bad")
        XCTAssertEqual(mock.fetchShowsCallCount, 1)
    }

    func test_loadShows_failure_updatesStateToErrorWithMessage() async {
        let mock = MockTVMazeAPIService()
        mock.showsResult = .failure(APIError.invalidResponse(500))
        let sut = ShowListViewModel(api: mock)

        await sut.loadShows()

        guard case .error(let message) = sut.state else {
            return XCTFail("Expected .error state, got \(sut.state)")
        }
        XCTAssertTrue(message.contains("500"))
    }

    func test_loadShows_handlesNullRatingGracefully() async {
        let mock = MockTVMazeAPIService()
        let show = Show(
            id: 3,
            name: "No Rating Yet",
            image: nil,
            rating: Rating(average: nil),
            summary: nil,
            premiered: nil,
            genres: nil,
            embedded: nil
        )
        mock.showsResult = .success([show])
        let sut = ShowListViewModel(api: mock)

        await sut.loadShows()

        guard case .success(let loadedShows) = sut.state else {
            return XCTFail("Expected .success state, got \(sut.state)")
        }
        XCTAssertEqual(loadedShows.first?.ratingText, "—")
    }

    // MARK: - Pagination

    func test_loadMoreIfNeeded_nearEndOfList_appendsNextPage() async {
        let mock = MockTVMazeAPIService()
        let pageZero = (1...20).map { makeShow(id: $0) }
        let pageOne = (21...30).map { makeShow(id: $0) }
        mock.showsResultsByPage = [0: .success(pageZero), 1: .success(pageOne)]
        let sut = ShowListViewModel(api: mock)

        await sut.loadShows()
        // Simulate scrolling to a row inside the prefetch threshold of the end.
        await sut.loadMoreIfNeeded(currentShow: pageZero[15])

        guard case .success(let loadedShows) = sut.state else {
            return XCTFail("Expected .success state, got \(sut.state)")
        }
        XCTAssertEqual(loadedShows.count, 30)
        XCTAssertEqual(mock.requestedPages, [0, 1])
    }

    func test_loadMoreIfNeeded_farFromEndOfList_doesNotFetchNextPage() async {
        let mock = MockTVMazeAPIService()
        let pageZero = (1...20).map { makeShow(id: $0) }
        mock.showsResultsByPage = [0: .success(pageZero)]
        let sut = ShowListViewModel(api: mock)

        await sut.loadShows()
        // Row is nowhere near the end (well outside the prefetch threshold).
        await sut.loadMoreIfNeeded(currentShow: pageZero[0])

        XCTAssertEqual(mock.requestedPages, [0])
    }

    func test_loadMoreIfNeeded_emptyNextPage_stopsPaginatingWithoutError() async
    {
        let mock = MockTVMazeAPIService()
        let pageZero = (1...20).map { makeShow(id: $0) }
        mock.showsResultsByPage = [0: .success(pageZero), 1: .success([])]
        let sut = ShowListViewModel(api: mock)

        await sut.loadShows()
        await sut.loadMoreIfNeeded(currentShow: pageZero[15])
        // A second scroll-to-end shouldn't issue a further request once
        // we've learned there's nothing more to load.
        await sut.loadMoreIfNeeded(currentShow: pageZero[15])

        guard case .success(let loadedShows) = sut.state else {
            return XCTFail("Expected .success state, got \(sut.state)")
        }
        XCTAssertEqual(loadedShows.count, 20)
        XCTAssertEqual(mock.requestedPages, [0, 1])
        XCTAssertNil(sut.nextPageErrorMessage)
    }

    func test_loadMoreIfNeeded_notFoundPage_stopsPaginatingWithoutError() async
    {
        let mock = MockTVMazeAPIService()
        let pageZero = (1...20).map { makeShow(id: $0) }
        mock.showsResultsByPage = [
            0: .success(pageZero), 1: .failure(APIError.invalidResponse(404)),
        ]
        let sut = ShowListViewModel(api: mock)

        await sut.loadShows()
        await sut.loadMoreIfNeeded(currentShow: pageZero[15])

        guard case .success(let loadedShows) = sut.state else {
            return XCTFail("Expected .success state, got \(sut.state)")
        }
        XCTAssertEqual(loadedShows.count, 20)
        XCTAssertNil(sut.nextPageErrorMessage)
    }

    func
        test_loadMoreIfNeeded_networkFailure_keepsExistingShowsAndSurfacesInlineError()
        async
    {
        let mock = MockTVMazeAPIService()
        let pageZero = (1...20).map { makeShow(id: $0) }
        mock.showsResultsByPage = [
            0: .success(pageZero), 1: .failure(APIError.network("offline")),
        ]
        let sut = ShowListViewModel(api: mock)

        await sut.loadShows()
        await sut.loadMoreIfNeeded(currentShow: pageZero[15])

        guard case .success(let loadedShows) = sut.state else {
            return XCTFail(
                "Expected existing shows to remain in .success state, got \(sut.state)"
            )
        }
        XCTAssertEqual(loadedShows.count, 20)
        XCTAssertNotNil(sut.nextPageErrorMessage)
    }

    func test_loadShows_resetsPaginationState() async {
        let mock = MockTVMazeAPIService()
        let pageZero = (1...20).map { makeShow(id: $0) }
        let pageOne = (21...30).map { makeShow(id: $0) }
        mock.showsResultsByPage = [0: .success(pageZero), 1: .success(pageOne)]
        let sut = ShowListViewModel(api: mock)

        await sut.loadShows()
        await sut.loadMoreIfNeeded(currentShow: pageZero[15])
        // Pull-to-refresh: should start again from page 0, not keep appending.
        await sut.loadShows()

        guard case .success(let loadedShows) = sut.state else {
            return XCTFail("Expected .success state, got \(sut.state)")
        }
        XCTAssertEqual(loadedShows.count, 20)
        XCTAssertEqual(mock.requestedPages, [0, 1, 0])
    }

    private func makeShow(id: Int) -> Show {
        Show(
            id: id,
            name: "Show \(id)",
            image: nil,
            rating: nil,
            summary: nil,
            premiered: nil,
            genres: nil,
            embedded: nil
        )
    }
}

extension ViewState: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .loading: return "loading"
        case .error(let message): return "error(\(message))"
        case .success: return "success"
        }
    }
}
