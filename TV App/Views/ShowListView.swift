//
//  ShowListView.swift
//  TVApp
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import Combine
import SwiftUI

struct ShowListView: View {
    @StateObject private var viewModel = ShowListViewModel()
    @State private var searchText = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.state {
            case .loading:
                BrowseSkeleton()

            case .error(let message):
                ErrorStateView(message: message) {
                    Task { await viewModel.loadShows() }
                }
                .foregroundStyle(.white)

            case .success(let shows):
                browseContent(shows: shows)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                logo
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search shows"
        )
        .navigationDestination(for: Show.self) { show in
            ShowDetailView(viewModel: ShowDetailViewModel(showID: show.id))
        }
        .task {
            if case .loading = viewModel.state {
                await viewModel.loadShows()
            }
        }
        .preferredColorScheme(.dark)
    }

    /// Small wordmark shown in the nav bar, standing in for a Netflix-style logo.
    private var logo: some View {
        HStack(spacing: 0) {
            Text("TV")
                .foregroundStyle(.red)

            Text("Shows")
                .foregroundStyle(.white)
        }
        .font(.system(size: 20, weight: .heavy, design: .rounded))
    }

    @ViewBuilder
    private func browseContent(shows: [Show]) -> some View {
        if !searchText.isEmpty {
            SearchResultsGrid(shows: filteredShows(shows))
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 28) {
                    let heroShows = topHeroShows(from: shows)
                    if !heroShows.isEmpty {
                        HeroCarousel(shows: heroShows)
                    }

                    ForEach(rows(from: shows), id: \.title) { row in
                        GenreRow(title: row.title, shows: row.shows)
                    }

                    // Invisible sentinel: once the last loaded show has been
                    // laid out (i.e. the user has scrolled this far), ask the
                    // ViewModel to fetch the next page.
                    if let lastShow = shows.last {
                        Color.clear
                            .frame(height: 1)
                            .task {
                                await viewModel.loadMoreIfNeeded(
                                    currentShow: lastShow
                                )
                            }
                    }

                    paginationFooter
                }
                .padding(.bottom, 24)
            }
            .refreshable {
                await viewModel.loadShows()
            }
        }
    }

    private func filteredShows(_ shows: [Show]) -> [Show] {
        shows.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    @ViewBuilder
    private var paginationFooter: some View {
        if viewModel.isLoadingNextPage {
            HStack {
                Spacer()
                ProgressView()
                    .tint(.white)
                Spacer()
            }
            .padding(.vertical, 12)
        } else if let message = viewModel.nextPageErrorMessage {
            HStack {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .lineLimit(1)
                Spacer()
                Button("Retry") {
                    Task { await viewModel.retryLoadNextPage() }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
            }
            .padding(.horizontal)
        }
    }

    /// Up to 5 highest-rated shows with a backdrop image, for the hero carousel.
    private func topHeroShows(from shows: [Show]) -> [Show] {
        Array(
            shows
                .filter { $0.image?.original != nil }
                .sorted {
                    ($0.rating?.average ?? 0) > ($1.rating?.average ?? 0)
                }
                .prefix(5)
        )
    }

    /// Builds the Netflix-style row list: a computed "Top Rated" row first,
    /// then one row per genre (most populous genres first, capped so the
    /// screen doesn't turn into an endless row list).
    private func rows(from shows: [Show]) -> [(title: String, shows: [Show])] {
        var result: [(title: String, shows: [Show])] = []

        let topRated =
            shows
            .filter { ($0.rating?.average ?? 0) >= 7 }
            .sorted { ($0.rating?.average ?? 0) > ($1.rating?.average ?? 0) }
        if !topRated.isEmpty {
            result.append(("Top Rated", Array(topRated.prefix(20))))
        }

        var byGenre: [String: [Show]] = [:]
        for show in shows {
            for genre in show.genres ?? [] {
                byGenre[genre, default: []].append(show)
            }
        }
        let sortedGenres = byGenre.keys.sorted {
            (byGenre[$0]?.count ?? 0) > (byGenre[$1]?.count ?? 0)
        }
        for genre in sortedGenres.prefix(10) {
            if let genreShows = byGenre[genre] {
                result.append((genre, genreShows))
            }
        }

        return result
    }
}

// MARK: - Hero carousel

private struct HeroCarousel: View {
    let shows: [Show]
    @State private var selection = 0

    private let bannerHeight: CGFloat = 480
    private let autoAdvance = Timer.publish(every: 5, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                ForEach(Array(shows.enumerated()), id: \.element.id) {
                    index,
                    show in
                    HeroBanner(show: show, height: bannerHeight)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: bannerHeight)
            .onReceive(autoAdvance) { _ in
                withAnimation(.easeInOut) {
                    selection = (selection + 1) % shows.count
                }
            }

            if shows.count > 1 {
                HStack(spacing: 6) {
                    ForEach(shows.indices, id: \.self) { index in
                        Capsule()
                            .fill(
                                index == selection
                                    ? Color.white : Color.white.opacity(0.35)
                            )
                            .frame(
                                width: index == selection ? 16 : 6,
                                height: 6
                            )
                            .animation(.easeInOut, value: selection)
                    }
                }
                .padding(.bottom, 14)
            }
        }
    }
}

private struct HeroBanner: View {
    let show: Show
    let height: CGFloat

    var body: some View {
        NavigationLink(value: show) {
            ZStack(alignment: .bottomLeading) {
                PosterImage(
                    url: URL(
                        string: show.image?.original ?? show.image?.medium ?? ""
                    ),
                    cornerRadius: 0
                )
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .clipped()

                LinearGradient(
                    colors: [
                        .clear, .black.opacity(0.35), .black.opacity(0.95),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: height)

                VStack(alignment: .leading, spacing: 10) {
                    if let genres = show.genres, !genres.isEmpty {
                        Text(
                            genres.prefix(3).joined(separator: "  ·  ")
                                .uppercased()
                        )
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                    }

                    Text(show.name)
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .shadow(radius: 6)

                    HStack(spacing: 10) {
                        RatingBadge(show: show)
                        if let premiered = show.premiered, premiered.count >= 4
                        {
                            Text(String(premiered.prefix(4)))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }

                    Label("More Info", systemImage: "info.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .padding(.top, 4)
                }
                .padding(20)
                .padding(.bottom, 18)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Genre row

private struct GenreRow: View {
    let title: String
    let shows: [Show]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(shows) { show in
                        NavigationLink(value: show) {
                            PosterTile(show: show)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Poster tile

private struct PosterTile: View {
    let show: Show

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PosterImage(url: URL(string: show.image?.medium ?? ""))
                .frame(width: 120, height: 170)
                .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                .overlay(alignment: .topTrailing) {
                    if show.rating?.average != nil {
                        RatingBadge(show: show)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.65), in: Capsule())
                            .padding(6)
                    }
                }

            Text(show.name)
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)
        }
    }
}

// MARK: - Search results grid

private struct SearchResultsGrid: View {
    let shows: [Show]

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 130), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            if shows.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.gray)
                    Text("No shows found")
                        .foregroundStyle(.gray)
                }
                .padding(.top, 80)
                .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(shows) { show in
                        NavigationLink(value: show) {
                            PosterTile(show: show)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Loading skeleton

/// Shimmering placeholder shown while the first page is loading, roughly
/// matching the shape of the real browse layout (hero + a couple of rows)
/// so the transition into real content doesn't jump around.
private struct BrowseSkeleton: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 480)
                    .shimmering()

                ForEach(0..<2, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 16)
                            .shimmering()
                            .padding(.horizontal)

                        HStack(spacing: 10) {
                            ForEach(0..<4, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 120, height: 170)
                                    .shimmering()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    NavigationStack {
        ShowListView()
    }
}
