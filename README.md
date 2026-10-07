# Wildwhistle Isle

An original creature-collecting game for iPhone and iPad. Explore four islands, whistle to forty creatures,
raise them, and calm each isle's guardian to sail on. It plays offline, has no accounts and no purchases.

## What is in here

| Folder | What it is |
|---|---|
| `GameCore/` | The game rules as a Swift package: island generation, creatures, encounters, items, field notes, saving. No UI. |
| `App/` | The native app: SpriteKit map, SwiftUI screens, and the creature and island art drawn in code. |
| `UITests/` | Tests that drive the real app in a simulator. |
| `tools/` | Scripts that generate the Swift data tables and reference values from the tested reference build. |
| `.github/workflows/` | Builds and tests on every push. |

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen), so it is not checked in.

## Building

On a Mac with Xcode 16 or later:

```sh
brew install xcodegen
xcodegen generate
open WildwhistleIsle.xcodeproj
```

Rules tests alone run anywhere Swift does: `cd GameCore && swift test`.

## Automated checks

Every push to `main` runs:

- **Game rules (Linux)**: unit tests, exact-match checks against the reference build, and an automated player that
  finishes the whole game six times.
- **iPhone app (Mac)**: builds the app, runs the UI tests in an iPhone simulator and takes screenshots.

Results are published to two branches so they can be read without downloading artifacts:
`ci-core` (rule test log) and `ci-results` (build log, UI test summary, screenshots).

## Not done yet

- Signing and App Store upload. This needs an Apple Developer Program membership.
- Sound.
- Testing on a physical iPhone.
