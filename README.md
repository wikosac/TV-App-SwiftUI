# TV App (Alamofire edition)

A SwiftUI TV show browser built against the [TVMaze API](https://www.tvmaze.com/api),
networked with [Alamofire](https://github.com/Alamofire/Alamofire) instead of
raw `URLSession`, with a Netflix-inspired browse screen: an auto-advancing
hero carousel, genre rows, live search, and shimmer loading placeholders.

## Features

- Browse TV shows
- View show details
- Display rating and premiere date
- Cast and episodes (using embedded API)
- Share show (title, summary, and URL)
- Loading, error, and retry states
- Unit tests

## Requirements

- Xcode 15+
- iOS 26+
- Swift 6

## Installation

Clone the repository:

```bash
git clone https://github.com/wikosac/TV-App-SwiftUI.git
```

Open the project:

```bash
cd TV-App-SwiftUI
open TV-App-SwiftUI.xcodeproj
```

Build and run using Xcode on a simulator or physical device.

No additional configuration or API key is required.

## API

- List Shows

```
GET https://api.tvmaze.com/shows?page=0
```

- Show Detail

```
GET https://api.tvmaze.com/shows/{id}?embed[]=episodes&embed[]=cast
```

Documentation:

https://www.tvmaze.com/api

## Architecture decisions

- **MVVM, unchanged from the URLSession version.** The point of this variant
  is proving the networking layer is swappable: `TVMazeAPIServicing` is the
  only thing ViewModels, views, and tests depend on. Switching the concrete
  implementation from `URLSession` to Alamofire touched exactly one file
  (`TVMazeAPIService.swift`) — not a single ViewModel, view, or test changed.
  That's the actual payoff of protocol-oriented networking, not just a
  talking point.
- **Alamofire usage is intentionally thin.** `session.request(...).validate().serializingDecodable(T.self).value`
  is the entire integration surface — no custom interceptors, request
  adapters, or reachability manager, since the app's needs (two GET
  endpoints, no auth) don't call for them. `AFError` is mapped back into the
  app's own `APIError` in one place (`TVMazeAPIService.map(_:)`) so the rest
  of the app never sees an Alamofire type, including the pagination logic in
  `ShowListViewModel` that specifically checks for a 404 status code to know
  it's paged past the end of the list — that check works identically to the
  URLSession version because `AFError.responseCode` is extracted into the
  same `.invalidResponse(Int)` case.
- **`ViewState<T>`** (`loading` / `error(String)` / `success(T)`) is still the
  single source of truth per screen — unchanged from before.
- **UI pass over the previous "Netflix-style" screen:**
  - **Hero carousel** (`TabView(.page)`, auto-advancing every 5s via a
    `Timer.publish`) over the top 5 rated shows instead of one static hero,
    with custom capsule page-indicator dots (system dots don't match the
    dark banner well).
  - **Search** via `.searchable`, filtering the already-loaded shows
    client-side by name and switching to a `LazyVGrid` poster grid — no
    extra network round-trip, since the point of the spec's list endpoint is
    "load ~250 shows once."
  - **Shimmer skeleton** (`Shimmer.swift`, a reusable `ViewModifier`) replaces
    the plain `ProgressView` for both the first-page loading state and each
    poster's own async-image loading state — reads a lot closer to what an
    actual streaming app shows while content loads in.
  - **Genre chips** added to the detail screen (`show.genres`, now decoded
    since the list-screen redesign needed it anyway) — free bonus polish
    once the field existed on the model.
- **Pagination, HTML summary rendering, episodes/cast, and the share
  action** are otherwise unchanged from the previous iteration — see the
  inline doc comments in `ShowListViewModel`, `String+HTML.swift`,
  `EpisodesSection.swift`, and `ShowDetailView.swift` respectively.

## What I'd improve with more time

- **Debounce search** — right now every keystroke re-filters synchronously
  in-memory (cheap for ~250 shows, but I'd still debounce it and eventually
  swap to TVMaze's `/search/shows?q=` endpoint so search also reaches shows
  beyond the currently-loaded page).
- **Alamofire `EventMonitor` for logging** — in a real app I'd add a small
  `EventMonitor` for request/response logging in debug builds rather than
  relying on Xcode's network debugger, now that Alamofire's already in the
  dependency graph.
- **Image caching** — still relying on `AsyncImage`'s in-memory-only cache;
  I'd add `Alamofire`'s `AutoPurgingImageCache` or swap to `Kingfisher`/
  `Nuke` for proper disk caching of posters, since the same poster gets
  re-requested across the hero carousel, genre rows, and detail screen.
- **Retry policy** — Alamofire supports `RequestInterceptor`-based retry
  (exponential backoff, etc.) for free; right now retries are only
  manual (the pagination/error "Retry" buttons), not automatic for
  transient network blips.
- **Accessibility pass on the carousel** — auto-advancing content should
  pause for VoiceOver users and respect Reduce Motion; right now the timer
  runs unconditionally.
- **UI/snapshot tests** for the new carousel and search states, on top of
  the existing ViewModel/data-layer unit tests.

## Walkthrough Video

https://drive.google.com/file/d/1dU4eGPwFhr0cgJRxuIfSs89doTxNduu-/view?usp=sharing
