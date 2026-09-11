# AI Usage Log

Tool used: Claude (Sonnet, claude.ai chat interface). All entries below are
from one continuous conversation that started with the base TVApp
(URLSession/MVVM) and ended with this Alamofire + redesigned-UI variant.

---

### 1. Initial project scaffold (MVVM + networking layer)

**What I asked:** Build the whole TV App from the spec — list screen, detail
screen, share action, TVMaze API, loading/error/success states, MVVM, and at
least 2 unit tests — as a ready-to-open Xcode project.

**What it gave me:** A full file tree: `Show` Codable models, a
`TVMazeAPIServicing` protocol + `TVMazeAPIService` (URLSession)
implementation, `ViewState<T>` enum, ViewModels, SwiftUI views, an
`xcodegen` `project.yml`, and a mock-based test target.

**What I did:** Accepted the architecture as-is — protocol-based networking
for testability is exactly what I'd have written by hand.

**One thing it got wrong / I verified myself:** It never explicitly verified
that `AttributedString(html:)` (used later for the summary field) needs
iOS 15+ against docs — it stated the deployment target as "known," not
looked up. Turned out fine, but I noted it as an unverified claim at the time.

---

### 2. Swift 6 / MainActor compile error after pasting into Xcode

**What I asked:** Pasted the exact Xcode error:
`Call to main actor-isolated initializer 'init(session:)' in a synchronous
nonisolated context`, from `TVMazeAPIService()`'s default parameter value.

**What it gave me:** Correct diagnosis — the project's "Default Actor
Isolation" setting (Xcode 16) implicitly makes plain classes
`@MainActor`-isolated, breaking default-argument expressions. First fix
attempt only added `nonisolated` to the `init`.

**What I did:** Modified its fix — pointed out the async network methods
would still inherit main-actor isolation from the same setting, not just the
initializer. It agreed and marked the whole class `nonisolated` instead.

**One thing it got wrong / I verified myself:** It missed on the first pass
that this was a real functional bug (network I/O on the main thread), not
just a compiler complaint — I had to push it past "make the error go away"
to "fix the actual isolation."

---

### 3. Bonus feature: episodes + cast on the detail screen

**What I asked:** Implement the season/episode/cast bonus from the spec.

**What it gave me:** `?embed[]=episodes&embed[]=cast` on the detail request,
`Embedded`/`Episode`/`CastMember` models, a cast row, and a season-picker +
expandable-summary `EpisodesSection`.

**What I did:** Modified — first version only showed a one-line
"3 seasons · 62 episodes" string with no real episode list; I asked for the
actual list, which it added as a separate component.

**One thing it got wrong / I verified myself:** Its first `Episode` model
didn't decode `airdate`/`summary`, which TVMaze's `_embedded` payload does
provide — so the first version of `EpisodesSection` had nothing to expand.
I had to notice the UI was inert and ask for the richer fields explicitly.

---

### 4. Bug: episodes/cast fetched but UI never updates

**What I asked:** Reported the symptom (fetch completes, UI still shows
nil/empty episodes) without diagnosing the cause myself.

**What it gave me:** A refactor of `ShowDetailView` to build its own
`@StateObject` from a plain `Show` (`init(show:)`) instead of receiving an
already-constructed `ShowDetailViewModel` from the `navigationDestination`
closure — the documented-safe `@StateObject` pattern.

**What I did:** Accepted the refactor, but stayed skeptical of the
explanation.

**One thing it got wrong / I verified myself:** It explicitly admitted it
couldn't fully prove the original pattern was the root cause (per Apple's
own contract, `@StateObject` *should* have handled it correctly either way).
I had to actually run it in the simulator to confirm the fix worked, since
the AI's own reasoning stopped short of certainty.

---

### 5. Pagination + Netflix-style redesign

**What I asked:** Add pagination (`?page=N`), then later "make ShowListView
look like Netflix."

**What it gave me:** `loadMoreIfNeeded(currentShow:)`-driven pagination with
separate inline-error state so a failed page-2 fetch doesn't wipe out
page-1 data, 6 new tests — then a full redesign: hero banner, genre-grouped
horizontal rows, dark theme. The redesign required adding a new `genres`
field to the `Show` model.

**What I did:** Accepted the pagination design as-is. For the redesign, I
had it re-verify its own work — its first sweep for `Show(id:...)` call
sites to update with the new field used a `grep` pattern that missed a
multi-line `Show(\n  id: 42,\n  ...\n)` construction in a test file.

**One thing it got wrong / I verified myself:** The missed multi-line call
site above — it found and fixed it only after I asked it to double-check
rather than trust the first "all done" pass. Also flagged, unverified by me:
its assumption that TVMaze returns HTTP 404 (not just an empty array) once
you page past the last page — plausible, still unconfirmed against the
live API.

---

### 6. Swap URLSession → Alamofire

**What I asked:** Build a new variant of the same app using Alamofire for
networking, plus improve the UI further.

**What it gave me:** `TVMazeAPIService` rewritten on
`session.request(...).validate().serializingDecodable(T.self).value`, with
`AFError` mapped back to the app's existing `APIError` (preserving the
`.invalidResponse(404)` case the pagination logic depends on), an SPM
dependency added to `project.yml`, and — correctly — zero changes to any
ViewModel, view, or test file, since they only depend on the
`TVMazeAPIServicing` protocol.

**What I did:** Accepted as-is. This is the one entry where I didn't modify
or push back on anything technical — the protocol boundary did exactly what
it was supposed to do, which was itself worth confirming rather than
assuming.

**One thing it got wrong / I verified myself:** I have not yet actually
resolved the Alamofire package in Xcode myself (no Xcode/macOS available in
the AI's own sandbox to compile-check this against) — the `AFError` API
surface it used (`.responseCode`, `.isResponseSerializationError`) is
correct per Alamofire's public API from what I know of the library, but I'm
flagging this as unverified against an actual build until I open it locally.

---

### 7. UI polish: hero carousel, search, shimmer skeleton

**What I asked:** "Improve UI" alongside the Alamofire swap.

**What it gave me:** An auto-advancing `TabView(.page)` hero carousel over
the top 5 rated shows, `.searchable` client-side name filtering switching to
a `LazyVGrid`, and a reusable `Shimmer` `ViewModifier` replacing plain
`ProgressView`s for both the first-load skeleton and each poster's own
loading state.

**What I did:** Accepted as-is — reasonable, scoped additions that didn't
require new dependencies or architecture changes.

**One thing it got wrong / I verified myself:** The auto-advancing carousel
timer runs unconditionally with no Reduce Motion / VoiceOver consideration —
it flagged this itself under "what I'd improve" rather than me catching it,
which I'm noting because it's the kind of accessibility gap that's easy to
ship without a second pass.