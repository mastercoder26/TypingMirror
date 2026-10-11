# TypingMirror

A macOS app for seeing your typing habits.

## Description

A words-per-minute score only tells part of the story. TypingMirror shows the
pauses, bursts and corrections that happen while typing. There's a speed test
and a practice pad. You can also turn on capture in other apps to see how your
typing changes while coding, writing or messaging.

Open a saved session to see its rhythm, replay it, or see where you backspace.
TypingMirror also makes a daily fingerprint from your typing stats.

### Screenshots

![TypingMirror's speed test, with speed, accuracy, progress and live rhythm](docs/images/speed-test.jpg)

The speed test starts timing when you press the first key.

### Privacy

The default setting records timing and key types, such as letters, spaces and
backspaces. It does not record the text you type. Capture in other apps is off by
default and pauses when macOS Secure Input is active. Password managers,
Messages and Mail are excluded by default.

Everything stays on your Mac. There is no account or sync, and capture runs only
while the app is open.

If you want to see which words you hesitate on in a speed test, you can enable
**Rhythm and words** in Settings. This is the only mode that stores actual words,
and you must type `ALLOW` to turn it on. The filter rejects words that look like
credentials. Expired words are cleared when the app starts; the retention window
defaults to 14 days. Turning this mode off also clears stored words. You can
inspect or delete them in Settings.

## Getting Started

### Dependencies

- macOS 26.0 or later
- Xcode 27
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

### Installing

Clone the repository and install XcodeGen:

```bash
git clone https://github.com/mastercoder26/TypingMirror.git
cd TypingMirror
brew install xcodegen
```

Generate the Xcode project:

```bash
xcodegen generate
```

### Executing program

Open `TypingMirror.xcodeproj` in Xcode, select the `TypingMirror` scheme and run
it. You can also build and launch it from the terminal:

```bash
xcodebuild -project TypingMirror.xcodeproj -scheme TypingMirror \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build build
open build/Build/Products/Debug/TypingMirror.app
```

Begin with **Speed test** or **Practice pad**. Both work without permission to
monitor other apps. If you want to record typing in other apps, open Settings
and enable **Watch typing in other apps**. macOS will request Input Monitoring permission.
Use `⌘K` to jump between screens.

### Tests

The core package contains its own tests. From the repository root, run:

```bash
cd Packages/TypingMirrorKit
swift test
```

The SwiftUI app lives in `Sources/`. Capture, metrics, storage and replay live in
`Packages/TypingMirrorKit/`, so you can work on the core without running the app.
Typing-style labels use rules that you can read in the package's `Analysis/`
folder.

## Help

If capture in other apps is not working:

- Check **System Settings → Privacy & Security → Input Monitoring**. You may
  have to give permission again after you rebuild.
- Capture pauses during Secure Input and skips excluded apps. Check the capture
  status and exclusion list in Settings.
- The speed test and practice pad still work when global capture is off.

The app runs without App Sandbox because global keyboard capture requires it.

For other problems, [open an issue](https://github.com/mastercoder26/TypingMirror/issues)
with what happened and the steps to reproduce it.

## License

This repository does not yet contain a license file.
