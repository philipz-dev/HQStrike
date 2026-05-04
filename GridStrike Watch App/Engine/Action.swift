//
//  Action.swift
//  GridStrike Watch App
//
//  All gameplay intents. The reducer is exhaustive over (Phase, Action).
//

import Foundation

enum Action: Equatable {
    case dismissWelcome
    case tap(GridPosition)
    /// Internal — the store schedules this 1 s after the previous bomb drop.
    case advanceBombDrop
    case acknowledgeDestructionAlert
    case newGame
}
