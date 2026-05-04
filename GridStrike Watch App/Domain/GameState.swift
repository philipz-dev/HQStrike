//
//  GameState.swift
//  GridStrike Watch App
//
//  Single source of truth for the whole game. All UI is derived from this struct.
//

import Foundation

struct GameState: Equatable {
    var phase: Phase
    var board: Board
    var northernStrikes: [GridPosition: ExplosionKind]
    var bombingOverlays: [GridPosition: ExplosionKind]
    var missileOverlays: [GridPosition: ExplosionKind]
    var planeInWater: GridPosition?
    var missileInWater: GridPosition?
    var pendingDestructionAlerts: [Unit]
    var lastShotDown: Weapon?
    var victory: Bool
    var scrollTarget: Int?

    static func newGame() -> GameState {
        GameState(
            phase: .welcome,
            board: .empty,
            northernStrikes: [:],
            bombingOverlays: [:],
            missileOverlays: [:],
            planeInWater: nil,
            missileInWater: nil,
            pendingDestructionAlerts: [],
            lastShotDown: nil,
            victory: false,
            scrollTarget: nil
        )
    }

    /// While true the grid must not respond to taps (modal overlay covers it).
    var isModalActive: Bool {
        victory || !pendingDestructionAlerts.isEmpty
    }
}
