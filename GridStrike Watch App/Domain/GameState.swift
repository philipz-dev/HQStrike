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

    /// Whose attack is currently being resolved. Player-initiated taps are only
    /// honoured when this equals `.player`; the opponent-driven AI/peer turn flips
    /// it back to `.player` once its attack fully resolves.
    var currentTurn: Side

    var board: Board

    /// Grenade strikes against each side. `grenadeStrikes[.opponent]` holds the
    /// player's grenade taps on rows 0…5; `grenadeStrikes[.player]` holds the
    /// opponent's grenade taps on rows 8…13.
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
            currentTurn: .player,
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

/// What the user is seeing right now. Combines `phase` + alert queue + end-game into
/// one enum so views and the reducer can use a single exhaustive switch instead of
/// chained bool checks (`if !queue.isEmpty …`, `if victory …`, `if phase == .play …`).
enum UIMode: Equatable {
    case welcome
    case setup(SetupStep)
    case play(PlayState)
    case destructionAlert(Unit)
    case victory
    case defeat
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
        case .defeat: return .defeat
        }
    }

    /// Convenience derived from `mode`. The grid does not respond to taps in any
    /// modal state. Replaces the previous `victory || !queue.isEmpty` pair.
    var isModalActive: Bool {
        switch mode {
        case .destructionAlert, .victory, .defeat: return true
        case .welcome, .setup, .play: return false
        }
    }

    /// True iff the human player can interact with the board right now: in-game,
    /// no modal, and it's the player's turn.
    var acceptsPlayerInput: Bool {
        guard !isModalActive else { return false }
        guard case .play = phase else { return false }
        return currentTurn == .player
    }
}
