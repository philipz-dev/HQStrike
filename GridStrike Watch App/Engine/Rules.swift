//
//  Rules.swift
//  GridStrike Watch App
//
//  Pure rule predicates and attack geometry. Easy to unit-test without any UI.
//  Every helper is parameterised on the attacking `Side` so the same logic drives
//  both the player's and the AI's offensives.
//

import Foundation

enum Rules {
    // MARK: - Attack footprints

    /// 3-drop column starting at `target` and walking back toward the attacker's
    /// home — i.e. drops fall *away* from the attacker. Out-of-bounds rows are
    /// filtered out.
    static func bombingPositions(target: GridPosition, attacker: Side) -> [GridPosition] {
        var result: [GridPosition] = []
        result.reserveCapacity(3)
        let direction: Int = (attacker == .player) ? -1 : +1
        for i in 0..<3 {
            let r = target.row + direction * i
            if Zones.allRows.contains(r) {
                result.append(GridPosition(r, target.col))
            }
        }
        return result
    }

    /// 2x2 missile footprint anchored at the lower-left for the player, upper-left
    /// for the opponent (so the 2x2 always extends "into" the defender's half).
    static func missilePositions(anchor pos: GridPosition, attacker: Side) -> [GridPosition] {
        let dr: Int = (attacker == .player) ? -1 : +1
        return [
            pos,
            GridPosition(pos.row, pos.col + 1),
            GridPosition(pos.row + dr, pos.col),
            GridPosition(pos.row + dr, pos.col + 1),
        ]
    }

    // MARK: - Coastguard interception

    /// Bomber: intercepted when the column matches the defender's coastguard column AND
    /// at least one drop cell falls past that water row (i.e. on the defender's grass).
    static func bomberIntercepted(board: Board, target: GridPosition, attacker: Side) -> Bool {
        let defender = attacker.opposite
        guard let coastCol = board.coastguardColumn(of: defender), coastCol == target.col else { return false }
        let coastRow = Zones.coastguardRow(of: defender)
        return bombingPositions(target: target, attacker: attacker).contains { pos in
            switch attacker {
            case .player: return pos.row < coastRow      // drops go up → past = strictly less
            case .opponent: return pos.row > coastRow    // drops go down → past = strictly greater
            }
        }
    }

    /// Missile 2x2 anchored at lower-left (player) / upper-left (opponent). The
    /// coastguard defends a single column. Intercept when the salvo is anchored
    /// on that column (`c == coastCol`); the rightmost-column edge case
    /// (coastCol == 4 ⇒ c == 3) keeps the only 2x2 that includes column 4.
    static func missileIntercepted(board: Board, anchor: GridPosition, attacker: Side) -> Bool {
        let defender = attacker.opposite
        guard let coastCol = board.coastguardColumn(of: defender) else { return false }
        let lastCol = Zones.columnCount - 1
        if coastCol == anchor.col { return true }
        if coastCol == lastCol && anchor.col == lastCol - 1 { return true }
        return false
    }

    // MARK: - Victory

    /// True iff any of the affected positions hosts the requested side's HQ.
    static func includesHQ(_ board: Board, of side: Side, in positions: [GridPosition]) -> Bool {
        let grass = Zones.grassRows(of: side)
        return positions.contains { pos in
            grass.contains(pos.row) && board.unit(at: pos) == .headquarters
        }
    }

    // MARK: - Back-compat (player-attacks-opponent only)

    static func bombingPositions(target: GridPosition) -> [GridPosition] {
        bombingPositions(target: target, attacker: .player)
    }

    static func missilePositions(lowerLeft pos: GridPosition) -> [GridPosition] {
        missilePositions(anchor: pos, attacker: .player)
    }

    static func bomberIntercepted(board: Board, target: GridPosition) -> Bool {
        bomberIntercepted(board: board, target: target, attacker: .player)
    }

    static func missileIntercepted(board: Board, lowerLeft: GridPosition) -> Bool {
        missileIntercepted(board: board, anchor: lowerLeft, attacker: .player)
    }

    static func includesEnemyHQ(_ board: Board, in positions: [GridPosition]) -> Bool {
        includesHQ(board, of: .opponent, in: positions)
    }
}
