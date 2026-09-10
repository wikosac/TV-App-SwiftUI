//
//  RatingBadge.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import SwiftUI

struct RatingBadge: View {
    let show: Show

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.caption2)
            Text(show.ratingText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(
            show.rating?.average == nil ? .secondary : Color.yellow
        )
    }
}
