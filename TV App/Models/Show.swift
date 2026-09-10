//
//  Show.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import Foundation

struct Show: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let image: ShowImage?
    let rating: Rating?
    let summary: String?
    let premiered: String?
    let genres: [String]?
    let embedded: Embedded?

    enum CodingKeys: String, CodingKey {
        case id, name, image, rating, summary, premiered, genres
        case embedded = "_embedded"
    }

    /// Convenience: rating.average can be null in the API, surface it safely.
    var ratingText: String {
        guard let average = rating?.average else { return "—" }
        return String(format: "%.1f", average)
    }

    /// A shareable URL. TVMaze doesn't return a "url" field on every payload
    /// variant we use, so we construct the canonical show page URL from the id.
    var shareURL: URL? {
        URL(string: "https://www.tvmaze.com/shows/\(id)")
    }
}

struct ShowImage: Codable, Hashable {
    let medium: String?
    let original: String?
}

struct Rating: Codable, Hashable {
    let average: Double?
}

struct Embedded: Codable, Hashable {
    let episodes: [Episode]?
    let cast: [CastMember]?
}

struct Episode: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let season: Int
    let number: Int
    let airdate: String?
    let summary: String?
    let image: ShowImage?
}

struct CastMember: Codable, Identifiable, Hashable {
    let person: Person

    var id: Int { person.id }

    struct Person: Codable, Hashable {
        let id: Int
        let name: String
        let image: ShowImage?
    }
}
