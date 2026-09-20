# TypingMirror

A native macOS app that analyses **how** you type, not **what** you type.

It measures rhythm, bursts, pauses, corrections and speed, then shows how your
typing style changes between coding, writing, messaging and homework.

## The privacy claim, and why it holds

Every keystroke is reduced to two things: **when** it happened and **what kind**
of key it was (letter, digit, space, punctuation, backspace, navigation…).

The keycode is resolved to a class *inside the event-tap callback* and discarded
there, so character identity never outlives a single stack frame and never
reaches the ring buffer, let alone disk. That is a property of the data
structures rather than a setting, which is what makes it checkable rather than
promised — see `Capture/RawKeyEvent.swift`, which has nowhere to put a character.

macOS never delivers keystrokes to any app while a password field has focus, so
passwords cannot reach TypingMirror even by accident. Password managers and Mail
are excluded by default on top of that.

One feature is an exception, and it is opt-in, off by default, and requires
typing a confirmation: **Rhythm and words** stores the words themselves so
hesitation can be reported per word. Even then, words are filtered for anything
credential-shaped (digits, internal capitals, addresses, paths, low-vowel
strings), deleted after 14 days, listed in full in an inspector you can open, and
destroyed the moment the tier is switched off.

Nothing is ever uploaded. There is no account, no sync, no network call, and no
background agent — the app only watches while it is open.

## Features

- **Live rhythm graph** — typing speed rising and falling as you type
- **Speed test** — monkeytype-style, with net and raw accuracy reported separately
- **Practice pad** — free typing that records a real session
- **Session detail** — duration, speed, fastest burst, corrections, longest pause
- **Typing styles** — steady / fast bursts / careful / rapid editing, each explaining itself
- **Correction heatmap** — how far into a word your backspaces land
- **Compare** — coding vs writing vs messaging
- **Replay** — the rhythm of a session played back, with a "skip the thinking" mode
- **Daily fingerprint** — a generative mark per day, deterministic from that day's style
- **Hesitations** — words you slow down on (opt-in tier only)
- **⌘K palette** — fuzzy search over everything

## Requirements

- macOS 26.0 or later
- Xcode 27
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build and run

```bash
xcodegen generate
xcodebuild -project TypingMirror.xcodeproj -scheme TypingMirror \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build build
open build/Build/Products/Debug/TypingMirror.app
```

Run the core tests (no host app needed):

```bash
cd Packages/TypingMirrorKit && swift test
```

## Architecture

```
Packages/TypingMirrorKit/   UI-free core, independently testable
  Capture/    event tap, ring buffer, key classification, segmentation
  Codec/      TMK1 binary format for keystroke streams
  Metrics/    speed, intervals, bursts, pauses, test scoring
  Analysis/   rule-based typing-style classifier
  Fingerprint/ deterministic visual parameters
  Replay/     playback track and clock
  Privacy/    tiers, word filter, capture settings
  Model/      SwiftData models and the store actor
Sources/                    the app
  DesignSystem/  tokens and glass components
  Input/         NSTextInputClient keystroke capture
  Palette/       ⌘K command palette
  Features/      one folder per screen
```

### Notes on a few decisions

**Global capture cannot be sandboxed.** `CGEvent.tapCreate` for keyboard events
fails under App Sandbox and no entitlement enables it, so the app ships
non-sandboxed and cannot go to the Mac App Store. Everything in-app works with no
permission at all; global capture is strictly additive.

**The tap runs on its own thread.** On the main run loop a long layout pass
starves the callback and macOS disables the tap with
`kCGEventTapDisabledByTimeout` — the most common way tap-based capture silently
stops working. It is also `.listenOnly`, so it can never drop or delay a
keystroke.

**The live graph does not observe the keystroke buffer.** `RhythmBuffer` is
deliberately not `@Observable`: typing mutates it with zero SwiftUI
invalidations, and the `Canvas` redraws on the display's own schedule. Input rate
and draw rate are decoupled.

**Style labels are rules, not a model.** There is no ground-truth dataset for
"burst-heavy", the system must work on your first session, it has to explain
itself, and a retrained model would silently relabel your whole history.

**Ad-hoc signing resets the Accessibility grant.** macOS ties the grant to the
code signature, so you will need to re-approve after most rebuilds. Only global
capture is affected.
