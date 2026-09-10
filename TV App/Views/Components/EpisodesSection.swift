//
//  EpisodesSection.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import SwiftUI

struct SeasonSection: Identifiable {

    let season: Int
    let episodes: [Episode]

    var id: Int {
        season
    }

}

struct EpisodesSection: View {

    let episodes: [Episode]

    @State private var selectedSeason: Int = 1

    private var sections: [SeasonSection] {
        Dictionary(grouping: episodes, by: \.season)
            .map {
                SeasonSection(
                    season: $0.key,
                    episodes: $0.value.sorted { $0.number < $1.number }
                )
            }
            .sorted { $0.season < $1.season }
    }

    private var currentEpisodes: [Episode] {
        sections.first(where: { $0.season == selectedSeason })?.episodes ?? []
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 20) {

            Text("Episodes")
                .font(.title3.bold())
                .padding(.horizontal)

            SeasonTabBar(
                seasons: sections.map(\.season),
                selectedSeason: $selectedSeason
            )

            LazyVStack(spacing: 16) {

                ForEach(currentEpisodes) { episode in
                    EpisodeCard(episode: episode)
                }

            }
            .padding(.horizontal)

        }
        .onAppear {
            selectedSeason = sections.first?.season ?? 1
        }

    }

}

struct SeasonTabBar: View {

    let seasons: [Int]

    @Binding var selectedSeason: Int

    var body: some View {

        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: 10) {

                ForEach(seasons, id: \.self) { season in

                    Button {

                        withAnimation(.snappy) {
                            selectedSeason = season
                        }

                    } label: {

                        Text("Season \(season)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(
                                selectedSeason == season
                                    ? .white
                                    : .secondary
                            )
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        selectedSeason == season
                                            ? Color.gray
                                            : Color.gray.opacity(0.12)
                                    )
                            )

                    }

                }

            }
            .padding(.horizontal)

        }

    }

}

struct EpisodeCard: View {

    let episode: Episode

    var body: some View {

        HStack(alignment: .top, spacing: 16) {

            AsyncImage(url: URL(string: episode.image?.medium ?? "")) { image in

                image
                    .resizable()
                    .scaledToFill()

            } placeholder: {

                Color.gray.opacity(0.2)

            }
            .frame(width: 120, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 6) {

                Text(episode.name)
                    .font(.headline)

                Text(episode.airdate ?? "")
                    .font(.caption)
                    .foregroundStyle(.gray)
 
                Text(episode.summary?.strippingHTML ?? "")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .lineLimit(3)

            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }

}
