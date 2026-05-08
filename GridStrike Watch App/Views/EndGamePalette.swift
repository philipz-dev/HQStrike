//
//  EndGamePalette.swift
//  GridStrike Watch App
//
//  Shared muted colour palette used by VictoryOverlay and DefeatOverlay so the
//  New / Map pills read as solid (not translucent) but stay deliberately less
//  bright than the watchOS system greens / reds — the goal is for the buttons
//  to support the artwork rather than out-shouting it.
//

import SwiftUI

enum EndGamePalette {
    /// Forest-style green — desaturated and a touch darker than `.green` so
    /// the primary "New" button on the victory screen reads as celebratory
    /// without competing with the soldier silhouette behind it.
    static let mutedGreen = Color(red: 0.20, green: 0.50, blue: 0.25)

    /// Brick-style red — dimmer than system `.red` so the primary "New"
    /// button on the defeat screen still reads as the destructive primary
    /// action without overwhelming the muted sunset palette.
    static let mutedRed = Color(red: 0.55, green: 0.20, blue: 0.20)

    /// Slate grey — solid (not translucent) but visibly darker than system
    /// `.gray`, so the secondary "Map" button looks like a deliberate dim
    /// counterpart to the primary action rather than a glassy chip.
    static let mutedGray = Color(red: 0.34, green: 0.34, blue: 0.38)
}
