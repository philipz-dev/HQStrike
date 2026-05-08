//
//  DefeatOverlay.swift
//  GridStrike Watch App
//
//  Mirror of VictoryOverlay for the lose path. Uses `defeatBackground` as the
//  full-bleed illustration and keeps the subtitle that explains *why* the
//  game ended (the only end-game phrasing that isn't already obvious from
//  the on-board explosion).
//

import SwiftUI

struct DefeatOverlay: View {
    let onNewGame: () -> Void
    let onShowMap: () -> Void

    var body: some View {
        ZStack {
            // Solid underlay so the play container is fully obscured even if
            // the image takes a frame to materialise — see VictoryOverlay
            // for the matching rationale.
            Color.black
                .ignoresSafeArea()

            Assets.defeatBackground
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            Color.black.opacity(0.30)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Text("Defeat")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 5, y: 2)
                Text("The enemy destroyed your headquarter.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.85), radius: 3, y: 1)
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)

                // Same layout language as VictoryOverlay so the two end-game
                // screens feel like a paired set; only the primary tint
                // changes. Muted reds / greys keep the buttons obviously
                // tappable without out-shouting the artwork.
                HStack(spacing: 8) {
                    Button(action: onNewGame) {
                        Text("New")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(EndGamePalette.mutedRed)

                    Button(action: onShowMap) {
                        Text("Map")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(EndGamePalette.mutedGray)
                }
                .padding(.horizontal, 8)
                // Generous bottom inset — see the matching note in
                // VictoryOverlay; keeps the pills above the curved bezel.
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(true)
    }
}
