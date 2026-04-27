//
//  UndoToast.swift
//  KamFinAssetTrack
//
//  Toast overlay shown at the bottom of the Account list after a delete.
//  Offers a 5-second window to undo; tap the toast body to restore, or
//  let the countdown finalise the deletion.
//
//  Implements AC-6 (5-second undo) from the Scope Package and ADR-001.
//

import SwiftUI

struct UndoToast: View {

    let accountName: String
    let totalSeconds: Double
    let onUndo: () -> Void
    let onTimeout: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Seconds remaining, from `totalSeconds` down to 0.
    @State private var secondsRemaining: Double

    init(accountName: String,
         totalSeconds: Double = 5,
         onUndo: @escaping () -> Void,
         onTimeout: @escaping () -> Void)
    {
        self.accountName = accountName
        self.totalSeconds = totalSeconds
        self.onUndo = onUndo
        self.onTimeout = onTimeout
        _secondsRemaining = State(initialValue: totalSeconds)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                // Progress ring
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 2.5)
                    .frame(width: 28, height: 28)
                Circle()
                    .trim(from: 0, to: CGFloat(secondsRemaining / totalSeconds))
                    .stroke(Color(hex: "#C9A961"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 28, height: 28)
                    .animation(reduceMotion ? nil : .linear(duration: 0.25), value: secondsRemaining)
                Text("\(Int(secondsRemaining.rounded(.up)))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Deleted")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text(accountName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onUndo) {
                Text("Undo")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "#C9A961"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#C9A961").opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Undo deletion of \(accountName)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(hex: "#1F2937"), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 12)
        .task(id: accountName) {
            await runCountdown()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(accountName) deleted. Undo available for \(Int(totalSeconds)) seconds.")
    }

    // MARK: - Countdown

    private func runCountdown() async {
        secondsRemaining = totalSeconds
        // Tick every 0.25s for smooth ring animation; call onTimeout exactly once.
        let startedAt = Date()
        while secondsRemaining > 0 {
            try? await Task.sleep(nanoseconds: 250_000_000)
            let elapsed = Date().timeIntervalSince(startedAt)
            secondsRemaining = max(0, totalSeconds - elapsed)
            if Task.isCancelled { return }
        }
        onTimeout()
    }
}

#Preview {
    ZStack {
        Color(hex: "#0A1628").ignoresSafeArea()
        VStack {
            Spacer()
            UndoToast(accountName: "HL Stocks & Shares ISA", onUndo: {}, onTimeout: {})
        }
    }
}
