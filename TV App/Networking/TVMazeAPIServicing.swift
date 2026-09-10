//
//  TVMazeAPIServicing.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import Alamofire
import Foundation

protocol TVMazeAPIServicing {
    func fetchShows(page: Int) async throws -> [Show]
    func fetchShowDetail(id: Int) async throws -> Show
}

// The whole class is marked `nonisolated` so this type — and its async
// network calls — never get implicitly pinned to the main actor, even on
// projects with "Default Actor Isolation" set to MainActor (Xcode 16
// "approachable concurrency"). That also keeps the initializer safely
// callable from default-argument positions like
// `ShowListViewModel(api: TVMazeAPIService())`, since default-argument
// expressions are evaluated in a nonisolated context.
nonisolated final class TVMazeAPIService: TVMazeAPIServicing {
    private let session: Session
    private let baseURL = "https://api.tvmaze.com"

    init(session: Session = .default) {
        self.session = session
    }

    func fetchShows(page: Int = 0) async throws -> [Show] {
        try await request("\(baseURL)/shows", parameters: ["page": page])
    }

    func fetchShowDetail(id: Int) async throws -> Show {
        // Embed cast & episodes for the bonus detail info (season/episode/cast).
        // Alamofire's URLEncoding turns an Array value into repeated
        // `embed[]=...` query items, matching what the TVMaze API expects.
        try await request(
            "\(baseURL)/shows/\(id)",
            parameters: ["embed": ["episodes", "cast"]]
        )
    }

    private func request<T: Decodable>(_ url: String, parameters: Parameters)
        async throws -> T
    {
        do {
            return
                try await session
                .request(url, parameters: parameters)
                .validate()
                .serializingDecodable(T.self)
                .value
        } catch let error as AFError {
            throw Self.map(error)
        } catch {
            throw APIError.network(error.localizedDescription)
        }
    }

    /// Preserves the same `APIError` shape the rest of the app (notably
    /// `ShowListViewModel`'s pagination "stop on 404" logic) already relies
    /// on, regardless of which networking library sits underneath.
    private static func map(_ error: AFError) -> APIError {
        if let statusCode = error.responseCode {
            return .invalidResponse(statusCode)
        }
        if error.isResponseSerializationError {
            return .decoding(error.localizedDescription)
        }
        return .network(error.localizedDescription)
    }
}
