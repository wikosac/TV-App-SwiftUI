//
//  ShowDetailView.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import SwiftUI

struct ShowDetailView: View {
    @StateObject private var viewModel: ShowDetailViewModel
    @State private var isShowingShareSheet = false

    init(viewModel: ShowDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .error(let message):
                ErrorStateView(message: message) {
                    Task { await viewModel.loadDetail() }
                }

            case .success(let show):
                content(for: show)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDetail()
        }
    }

    @ViewBuilder
    private func content(for show: Show) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PosterImage(
                    url: URL(
                        string: show.image?.original ?? show.image?.medium ?? ""
                    ),
                    cornerRadius: 0
                )
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .clipped()

                VStack(alignment: .leading, spacing: 8) {
                    Text(show.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 12) {
                        RatingBadge(show: show)
                        if let premiered = show.premiered {
                            Label(premiered, systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let seasonEpisodeText = seasonEpisodeSummary(
                            for: show
                        ) {
                            Text(seasonEpisodeText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let genres = show.genres, !genres.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(genres, id: \.self) { genre in
                                Text(genre)
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Color.secondary.opacity(0.15),
                                        in: Capsule()
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal)

                if let summary = show.summary, !summary.isEmpty {
                    Text(summary.htmlToAttributedString)
                        .font(.body)
                        .padding(.horizontal)
                }

                if let cast = show.embedded?.cast, !cast.isEmpty {
                    castSection(cast)
                }

                if let episodes = show.embedded?.episodes, !episodes.isEmpty {
                    EpisodesSection(episodes: episodes)
                }
            }
            .padding(.vertical)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareSheet(items: shareItems(for: show))
        }
    }

    private func castSection(_ cast: [CastMember]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cast")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(cast.prefix(15)) { member in
                        VStack(spacing: 6) {
                            PosterImage(
                                url: URL(
                                    string: member.person.image?.medium ?? ""
                                ),
                                cornerRadius: 40
                            )
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            Text(member.person.name)
                                .font(.caption2)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: 76)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func seasonEpisodeSummary(for show: Show) -> String? {
        guard let episodes = show.embedded?.episodes, !episodes.isEmpty else {
            return nil
        }
        let seasonCount = Set(episodes.map(\.season)).count
        let episodeCount = episodes.count
        let seasonWord = seasonCount == 1 ? "season" : "seasons"
        let episodeWord = episodeCount == 1 ? "episode" : "episodes"
        return "\(seasonCount) \(seasonWord) · \(episodeCount) \(episodeWord)"
    }

    private func shareItems(for show: Show) -> [Any] {
        var text = show.name
        if let summary = show.summary, !summary.isEmpty {
            text += "\n\n" + summary.strippingHTML
        }
        var items: [Any] = [text]
        if let url = show.shareURL {
            items.append(url)
        }
        return items
    }
}
