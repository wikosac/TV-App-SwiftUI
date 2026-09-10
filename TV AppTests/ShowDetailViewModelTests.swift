//
//  ShowDetailViewModelTests.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import XCTest

@testable import TV_App

@MainActor
final class ShowDetailViewModelTests: XCTestCase {

    func test_loadDetail_success_replacesSeedWithFullDetail() async {
        let mock = MockTVMazeAPIService()
        let seed = Show(
            id: 42,
            name: "Seed Title",
            image: nil,
            rating: nil,
            summary: nil,
            premiered: nil,
            genres: nil,
            embedded: nil
        )
        let fullDetail = Show(
            id: 42,
            name: "Full Title",
            image: nil,
            rating: Rating(average: 7.8),
            summary: "<p>Full summary</p>",
            premiered: "2015-03-01",
            genres: nil,
            embedded: nil
        )
        mock.detailResult = .success(fullDetail)
        let sut = ShowDetailViewModel(seed: seed, api: mock)

        await sut.loadDetail()

        guard case .success(let show) = sut.state else {
            return XCTFail("Expected .success state, got \(sut.state)")
        }
        XCTAssertEqual(show.name, "Full Title")
        XCTAssertEqual(mock.fetchDetailCallCount, 1)
    }

    func test_loadDetail_failure_keepsSeedDataInsteadOfShowingError() async {
        let mock = MockTVMazeAPIService()
        let seed = Show(
            id: 42,
            name: "Seed Title",
            image: nil,
            rating: nil,
            summary: nil,
            premiered: nil,
            genres: nil,
            embedded: nil
        )
        mock.detailResult = .failure(APIError.invalidResponse(404))
        let sut = ShowDetailViewModel(seed: seed, api: mock)

        await sut.loadDetail()

        // Seeded success state should be preserved on a background refresh failure.
        guard case .success(let show) = sut.state else {
            return XCTFail(
                "Expected seed .success state to be preserved, got \(sut.state)"
            )
        }
        XCTAssertEqual(show.name, "Seed Title")
    }

    func test_loadDetail_noSeed_failure_updatesStateToError() async {
        let mock = MockTVMazeAPIService()
        mock.detailResult = .failure(APIError.invalidResponse(500))
        let sut = ShowDetailViewModel(showID: 99, api: mock)

        await sut.loadDetail()

        guard case .error = sut.state else {
            return XCTFail("Expected .error state, got \(sut.state)")
        }
    }
}

final class HTMLStringExtensionTests: XCTestCase {

    func test_strippingHTML_removesTagsAndKeepsText() {
        let html = "<p>A <b>great</b> show about chemistry.</p>"
        let result = html.strippingHTML
        XCTAssertEqual(result, "A great show about chemistry.")
    }

    func test_strippingHTML_handlesEmptyString() {
        XCTAssertEqual("".strippingHTML, "")
    }
}
