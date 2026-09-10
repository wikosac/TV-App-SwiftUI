//
//  Shimmer.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import SwiftUI

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.25), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 1.5)
                    .offset(
                        x: phase * proxy.size.width * 2 - proxy.size.width * 0.5
                    )
                }
                .clipped()
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4).repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Applies an animated shimmer sweep, meant for use on top of a solid
    /// placeholder shape while real content is still loading.
    func shimmering() -> some View {
        modifier(Shimmer())
    }
}
