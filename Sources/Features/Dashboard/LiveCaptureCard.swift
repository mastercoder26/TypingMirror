import SwiftUI
import TypingMirrorKit

/// What is being recorded right now.
///
/// Without this the app looks inert while you type, because nothing is written
/// until a session closes.
struct LiveCaptureCard: View {
    let coordinator: CaptureCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            SectionHeader("Recording now", trailing: statusText)

            if coordinator.isSecureInputActive {
                Text("Paused — a password field has focus, so macOS is not delivering "
                    + "these keystrokes to any app.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            MetricRow {
                Metric(
                    "This session",
                    value: "\(coordinator.openSegmentKeystrokes)",
                    unit: "keys",
                    prominent: true
                )
                MetricDivider()
                Metric("Seen this run", value: "\(coordinator.liveKeystrokeCount)")
                MetricDivider()
                Metric(
                    "Saved",
                    value: coordinator.lastSavedAt.map { DisplayFormat.clockTime($0) } ?? "—"
                )
            }

            LiveRhythmGraph(buffer: coordinator.rhythm, height: 72)

            Text("A session is written once you stop typing for "
                + "\(Int(MetricConstants.sessionBreakMs / 1000)) seconds.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.mutedText)
        }
    }

    private var statusText: String {
        switch coordinator.state {
        case .running: coordinator.isSecureInputActive ? "paused" : "watching"
        case .needsPermission: "needs permission"
        case .stopped: "off"
        }
    }
}
