import SwiftUI
import TypingMirrorKit

/// Replays the rhythm of a session as an animated timeline.
///
/// Playback is derived from a clock rather than a moving cursor: there is no
/// mutable "current index" that could drift out of sync with the scrubber, and
/// seeking is just moving the anchor.
struct ReplayView: View {
    let session: SessionRecord
    @Environment(AppModel.self) private var model

    @State private var track: ReplayTrack?
    @State private var clock = PlaybackClock()
    @State private var isLoading = true
    @State private var compressPauses = false

    var body: some View {
        VStack(alignment: .leading, spacing: Tk.S.s6) {
            header

            if isLoading {
                Text("Loading…").font(Tk.F.body).foregroundStyle(Tk.C.textTertiary)
            } else if let track {
                timeline(track)
                transport(track)
            } else {
                EmptyHint(
                    title: "This session has no replay",
                    detail: "Sessions recorded before replay was available cannot be played back."
                )
            }
        }
        .padding(.horizontal, Tk.S.s7)
        .padding(.vertical, Tk.S.s6)
        .frame(maxWidth: Tk.L.contentMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task(id: session.id) { await load() }
        .onDisappear { clock.setRate(0, host: CACurrentMediaTime()) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tk.S.s1) {
            Text("Replay")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Tk.C.textPrimary)
            Text("The rhythm of this session, played back. No text is stored or shown.")
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)
        }
    }

    private func timeline(_ track: ReplayTrack) -> some View {
        TimelineView(.animation) { context in
            let now = context.date.timeIntervalSinceReferenceDate
            let position = clock.mediaMs(atHost: now)
            let clamped = min(max(0, position), Double(track.durationMs))
            let progress = track.durationMs > 0 ? clamped / Double(track.durationMs) : 0

            VStack(alignment: .leading, spacing: Tk.S.s3) {
                Canvas(rendersAsynchronously: false) { canvasContext, size in
                    var canvasContext = canvasContext
                    let buckets = RhythmRenderer.barCount(for: size.width)
                    let samples = track.samples(buckets: buckets)
                    let played = Int(Double(samples.count) * progress)

                    RhythmRenderer.draw(
                        into: &canvasContext,
                        size: size,
                        samples: samples.enumerated().map { index, value in
                            index <= played ? value : value * 0.22
                        }
                    )

                    let x = size.width * progress
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: 0))
                    line.addLine(to: CGPoint(x: x, y: size.height))
                    canvasContext.stroke(line, with: .color(Tk.C.accent), lineWidth: 1)
                }
                .frame(height: 140)
                .contentShape(Rectangle())
                .overlay {
                    // The gesture is read in the canvas's own coordinate space so
                    // scrubbing stays accurate at any window width.
                    GeometryReader { geometry in
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        seek(
                                            x: value.location.x,
                                            width: geometry.size.width,
                                            track: track
                                        )
                                    }
                            )
                    }
                }

                HStack {
                    Text(Fmt.duration(ms: clamped))
                    Spacer()
                    Text(Fmt.duration(ms: Double(track.durationMs)))
                }
                .font(Tk.F.monoSm)
                .foregroundStyle(Tk.C.textTertiary)
            }
        }
    }

    private func transport(_ track: ReplayTrack) -> some View {
        HStack(spacing: Tk.S.s3) {
            Button(clock.rate == 0 ? "Play" : "Pause") {
                let now = CACurrentMediaTime()
                clock.setRate(clock.rate == 0 ? 1 : 0, host: now)
            }
            .buttonStyle(.glassProminent)
            .tint(Tk.C.accent)
            .foregroundStyle(Tk.C.bgBase)

            Button("Restart") {
                clock.seek(toMs: 0, host: CACurrentMediaTime())
            }
            .buttonStyle(.glass)

            ForEach([1.0, 2.0, 4.0, 8.0], id: \.self) { rate in
                Button("\(Int(rate))×") {
                    clock.setRate(rate, host: CACurrentMediaTime())
                }
                .buttonStyle(.glass)
            }

            Toggle("Skip the thinking", isOn: $compressPauses)
                .toggleStyle(.switch)
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textSecondary)
                .onChange(of: compressPauses) { _, _ in
                    Task { await load() }
                }

            Spacer()
        }
    }

    private func seek(x: CGFloat, width: CGFloat, track: ReplayTrack) {
        let progress = min(max(0, Double(x) / Double(max(width, 1))), 1)
        clock.seek(toMs: progress * Double(track.durationMs), host: CACurrentMediaTime())
    }

    private func load() async {
        isLoading = true
        let events = await model.events(for: session.id)
        track = events.isEmpty ? nil : ReplayTrack(events: events, compressPauses: compressPauses)
        clock = PlaybackClock()
        clock.seek(toMs: 0, host: CACurrentMediaTime())
        isLoading = false
    }
}
