//
//  DemoTopCloseButton.swift
//  GridStrike Watch App
//
//  Leading circular close placed in the upper fifth of the screen (not tied to large safe-area padding).
//

import SwiftUI

struct DemoTopCloseButton: View {
    let isVisible: Bool
    let onClose: () -> Void
    /// Full viewport height from the demo `GeometryReader` (`.ignoresSafeArea()` backdrop).
    let screenHeight: CGFloat

    var body: some View {
        Group {
            if isVisible {
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 0) {
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color.black.opacity(0.45))
                                .font(.system(size: 26))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close demo")
                        .accessibilityHint("Returns to weapon menu")

                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 8)
                    // Sit in the top ~20% band: ~6% from physical top (upper fifth), independent of oversized safe-area inset.
                    .padding(.top, screenHeight * 0.06)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
