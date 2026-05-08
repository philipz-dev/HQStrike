//
//  VictoryOverlay.swift
//  GridStrike Watch App
//
//  End-of-game celebration screen. The full-bleed `victoryBackground`
//  illustration ignores the safe area so it completely covers the play
//  container behind it (the live game board never peeks through the watch's
//  curved bezel). A small dark scrim keeps the title legible against lighter
//  parts of the art. Buttons sit anchored near the bottom edge, side-by-side
//  on muted tints so they read as solid pills without screaming brighter
//  than the artwork.
//

import SwiftUI

struct VictoryOverlay: View {
    let onNewGame: () -> Void
    let onShowMap: () -> Void

    var body: some View {
        ZStack {
            // Solid black underlay first so the play container behind us is
            // *guaranteed* covered even on the rare frames where the image is
            // still loading or the aspect ratio leaves any sliver uncovered.
            Color.black
                .ignoresSafeArea()

            // Full-bleed victory art. `scaledToFill` plus the explicit
            // `frame(maxWidth/maxHeight: .infinity)` and `clipped()` keep the
            // image edge-to-edge across every watch size; `ignoresSafeArea`
            // lets it reach the bezel curves on top and bottom.
            Assets.victoryBackground
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            // Light overall scrim — tuned just dark enough to keep the white
            // title and pill buttons legible without washing out the sunset.
            Color.black.opacity(0.30)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Text("Victory!")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 5, y: 2)
                Spacer(minLength: 0)

                // Side-by-side action buttons anchored toward the bottom of
                // the safe area. Each pill claims half the width via
                // `frame(maxWidth: .infinity)` so the row stays balanced
                // regardless of label length.
                HStack(spacing: 8) {
                    Button(action: onNewGame) {
                        Text("New")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(EndGamePalette.mutedGreen)

                    Button(action: onShowMap) {
                        Text("Map")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(EndGamePalette.mutedGray)
                }
                .padding(.horizontal, 8)
                // Generous bottom inset so the pills clear the watch's
                // curved bezel — the previous 2-pt padding had the bottom
                // half of each button clipped on smaller watch faces.
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(true)
    }
}
