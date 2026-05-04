//
//  GameState.swift
//  GridStrike Watch App
//
//  Single source of truth for the whole game. All UI is derived from this struct.
//  Strike/overlay maps are split per side so the symmetric AI turn (phase 3) can
//  write to its own half without touching the player-attacks-opponent path.
//

import Foundation

struct GameState: Equatable {
    var phase: Phase
    var board: Board

    /// Grenade strikes against each side. `grenadeStrikes[.opponent]` holds the
    /// player's grenade taps on rows 0…5; `grenadeStrikes[.player]` will hold the
    /// opponent's grenade taps on rows 8…13 once AI turns are wired up.
    var grenadeStrikes: PerSide<[GridPosition: ExplosionKind]>

    /// Bomber drop overlays per defender side.
    var bombingOverlays: PerSide<[GridPosition: ExplosionKind]>

    /// Missile 2x2 overlays per defender side.
    var missileOverlays: PerSide<[GridPosition: ExplosionKind]>

    /// Plane-in-water wreckage when an attacker's bomber is shot down. Indexed by
    /// the attacker so we know which water row to render it on.
    var planeInWater: PerSide<GridPosition?>

    /// Missile-in-water wreckage when an attacker's missile is shot down.
    var missileInWater: PerSide<GridPosition?>

    var pendingDestructionAlerts: [Unit]
    var scrollTarget: Int?

    static func newGame() -> GameState {
        GameState(
            phase: .welcome,
            board: .empty,
            grenadeStrikes: PerSide(both: [:]),
            bombingOverlays: PerSide(both: [:]),
            missileOverlays: PerSide(both: [:]),
            planeInWater: PerSide(both: nil),
            missileInWater: PerSide(both: nil),
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
