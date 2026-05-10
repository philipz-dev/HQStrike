//
//  VictoryOverlay.swift
//  GridStrike Watch App
//
//  End-of-game celebration screen. The full-bleed `victoryBackground`
//  illustration ignores the safe area so it completely covers the play
//  container behind it. Title sits toward the bottom; the top-left × matches
//  `OpponentSetupMapView` and advances to the round-start map.
//

import SwiftUI

struct VictoryOverlay: View {
    let onContinue: () -> Void

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
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .topLeading) {
            PostGameCircularDismissButton(
                accessibilityLabel: "Continue to opponent starting positions",
                action: onContinue
            )
        }
        .allowsHitTesting(true)
    }
}
