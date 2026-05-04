//
//  InstructionBanner.swift
//  GridStrike Watch App
//
//  Bound to a typed `BannerKind`; no game logic. Equatable so SwiftUI skips identical
//  redraws while overlays are running.
//

import SwiftUI

struct InstructionBanner: View, Equatable {
    let banner: BannerKind

    var body: some View {
        Text(banner.localized)
            .font(.caption.weight(.semibold))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.92), radius: 4, y: 2)
            .shadow(color: .black.opacity(0.55), radius: 1, y: 0)
    }
}
