//
//  DefeatOverlay.swift
//  GridStrike Watch App
//
//  Mirror of VictoryOverlay for the lose path. Title and subtitle sit toward the
//  bottom; the top-left × matches `OpponentSetupMapView` and advances to the
//  round-start map.
//

import SwiftUI

struct DefeatOverlay: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
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
