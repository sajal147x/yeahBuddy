import SwiftUI

/// The bottom of the workout screen: a mic button, and beside it whatever the current voice
/// action needs: the live transcript while listening, "Thinking…", or the result with Undo.
struct VoiceBar: View {
    /// The voice action being shown.
    let controller: VoiceController
    /// Called when the idle mic is tapped.
    let onListen: () -> Void
    /// Called when Undo is tapped.
    let onUndo: () -> Void

    // How long a result stays before folding away by itself.
    private static let bannerSeconds: Duration = .seconds(5)

    /// The panel (when there's something to say) and the mic, on glass.
    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            panel
                .frame(maxWidth: .infinity, alignment: .leading)
            micButton
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .animation(.snappy, value: phaseKey)
        // Results fold away on their own; a new phase restarts the countdown.
        .task(id: phaseKey) {
            if phaseKey == "done" || phaseKey == "failed" {
                try? await Task.sleep(for: Self.bannerSeconds)
                if !Task.isCancelled {
                    controller.dismissBanner()
                }
            }
        }
    }

    /// What to show beside the mic for the current phase; nothing when idle.
    @ViewBuilder
    private var panel: some View {
        switch controller.phase {
        case .idle:
            // Holds the mic on the right, where it stays when a panel appears.
            Spacer(minLength: 0)
        case .listening:
            bubble {
                Text(controller.listener.transcript.isEmpty ? "Listening… say “bench 100 for 8”" : controller.listener.transcript)
                    .foregroundStyle(controller.listener.transcript.isEmpty ? Color.textSecondary : Color.textPrimary)
                    .contentTransition(.opacity)
            }
        case .thinking:
            bubble {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                    Text("Thinking…")
                        .foregroundStyle(Color.textSecondary)
                }
            }
        case .done(let summary, _):
            bubble {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.textPrimary)
                    Text(summary)
                        .foregroundStyle(Color.textPrimary)
                    Spacer(minLength: Spacing.xs)
                    Button("Undo", action: onUndo)
                        .font(.chip)
                        .foregroundStyle(Color.textPrimary)
                }
            }
        case .failed(let message):
            bubble {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.textSecondary)
                    Text(message)
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
    }

    /// The round mic: starts listening when idle, cancels while listening or thinking.
    private var micButton: some View {
        Button {
            switch controller.phase {
            case .listening, .thinking:
                controller.cancel()
            case .idle, .done, .failed:
                onListen()
            }
        } label: {
            Image(systemName: isBusy ? "xmark" : "mic.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 60, height: 60)
                .symbolEffect(.pulse, isActive: phaseKey == "listening")
                .contentTransition(.symbolEffect(.replace))
        }
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel(isBusy ? "Stop listening" : "Log by voice")
    }

    /// A rounded glass panel around some content.
    ///
    /// - Parameter content: What goes inside.
    /// - Returns: The panel.
    private func bubble(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .font(.subheadline.weight(.medium))
            .lineLimit(3)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(minHeight: 60)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    /// Whether listening or thinking is under way, when the mic becomes a stop button.
    private var isBusy: Bool {
        switch controller.phase {
        case .listening, .thinking:
            return true
        case .idle, .done, .failed:
            return false
        }
    }

    /// The phase without its details, for animations and the banner timer to key on.
    private var phaseKey: String {
        switch controller.phase {
        case .idle:
            return "idle"
        case .listening:
            return "listening"
        case .thinking:
            return "thinking"
        case .done:
            return "done"
        case .failed:
            return "failed"
        }
    }
}
