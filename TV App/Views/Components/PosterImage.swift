//
//  PosterImage.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import SwiftUI

struct PosterImage: View {
    let url: URL?
    var cornerRadius: CGFloat = 10

    var body: some View {
        AsyncImage(
            url: url,
            transaction: Transaction(animation: .easeOut(duration: 0.25))
        ) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            case .failure:
                placeholder(systemImage: "film")
            case .empty:
                placeholder(systemImage: nil)
                    .shimmering()
            @unknown default:
                placeholder(systemImage: "film")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func placeholder(systemImage: String?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.25))
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
