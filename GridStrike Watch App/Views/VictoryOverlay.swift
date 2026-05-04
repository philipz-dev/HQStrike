//
//  VictoryOverlay.swift
//  GridStrike Watch App
//

import SwiftUI

struct VictoryOverlay: View {
    let onNewGame: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                Text("Victory!")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 5, y: 2)
                Button(action: onNewGame) {
                    Text("New game")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.horizontal, 8)
            }
            .padding(16)
        }
        .allowsHitTesting(true)
    }
}
