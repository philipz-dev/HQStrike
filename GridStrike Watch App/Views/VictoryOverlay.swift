//
//  VictoryOverlay.swift
//  GridStrike Watch App
//
//  End-of-game celebration screen. The full-bleed `victoryBackground`
//  illustration ignores the safe area so it completely covers the play
//  container behind it. Title sits toward the bottom; tap anywhere to advance
//  to the round-start map. After 5 seconds without a tap, “Tap to continue”
//  appears centered on the vertical axis.
//

import SwiftUI

struct VictoryOverlay: View {
    let onContinue: () -> Void

    @State private var showTapHint = false
    @State private var tapHintTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Assets.victoryBackground
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            Color.black.opacity(0.30)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Text("Victory!")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 5, y: 2)
                    .padding(.horizontal, 10)

                Spacer()
                    .frame(height: 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showTapHint {
                VStack {
                    Spacer()
                    Text("Tap to continue")
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.85), radius: 3, y: 1)
                        .padding(.horizontal, 10)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            tapHintTask?.cancel()
            tapHintTask = nil
            onContinue()
        }
        .onAppear {
            showTapHint = false
            tapHintTask?.cancel()
            tapHintTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                showTapHint = true
            }
        }
        .onDisappear {
            tapHintTask?.cancel()
            tapHintTask = nil
        }
        .allowsHitTesting(true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Victory")
        .accessibilityHint("Tap anywhere to continue.")
    }
}
