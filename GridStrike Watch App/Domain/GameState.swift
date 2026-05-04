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
            scrollTarget: nil
        )
    }
}

// MARK: - UIMode (single exhaustive switch over what the screen is showing)

/// What the user is seeing right now. Combines `phase` + alert queue + victory into one
/// enum so views and the reducer can use a single exhaustive switch instead of
/// chained bool checks (`if !queue.isEmpty …`, `if victory …`, `if phase == .play …`).
enum UIMode: Equatable {
    case welcome
    case setup(SetupStep)
    case play(PlayState)
    case destructionAlert(Unit)
    case victory
}

extension GameState {
    var mode: UIMode {
        if let unit = pendingDestructionAlerts.first {
            return .destructionAlert(unit)
        }
        switch phase {
        case .welcome: return .welcome
        case .setup(let step): return .setup(step)
        case .play(let play): return .play(play)
        case .victory: return .victory
        }
    }

    /// Convenience derived from `mode`. The grid does not respond to taps in either
    /// modal state. Replaces the previous `victory || !queue.isEmpty` pair.
    var isModalActive: Bool {
        switch mode {
        case .destructionAlert, .victory: return true
        case .welcome, .setup, .play: return false
        }
    }
}
