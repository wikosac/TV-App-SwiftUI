//
//  APIError.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import Foundation

enum APIError: Error, LocalizedError, Equatable {
    case invalidURL
    case network(String)
    case decoding(String)
    case invalidResponse(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "That request couldn't be built. Please try again."
        case .network(let message):
            return "Network error: \(message)"
        case .decoding:
            return "Failed to read the server's response."
        case .invalidResponse(let code):
            return "Server returned an unexpected response (code \(code))."
        }
    }
}
