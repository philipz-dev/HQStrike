//
//  DestructionAlertOverlay.swift
//  GridStrike Watch App
//

import SwiftUI

struct DestructionAlertOverlay: View {
    let unit: Unit
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                Text(unit.destroyedAlertMessage)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 5, y: 2)
                Button(action: onDismiss) {
                    Text("OK")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.horizontal, 8)
            }
            .padding(16)
        }
        .allowsHitTesting(true)
    }
}
