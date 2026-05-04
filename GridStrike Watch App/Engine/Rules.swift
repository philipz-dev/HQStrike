//
//  Rules.swift
//  GridStrike Watch App
//
//  Pure rule predicates and attack geometry. Easy to unit-test without any UI.
//

import Foundation

enum Rules {
    // MARK: - Attack footprints

    /// 3-drop column going north from `target`. Out-of-bounds rows are filtered out.
    static func bombingPositions(target: GridPosition) -> [GridPosition] {
        var result: [GridPosition] = []
        result.reserveCapacity(3)
        for i in 0..<3 {
            let r = target.row - i
            if r >= 0 { result.append(GridPosition(r, target.col)) }
        }
        return result
    }

    /// 2x2 missile footprint anchored at the lower-left.
    static func missilePositions(lowerLeft pos: GridPosition) -> [GridPosition] {
        [
            pos,
            GridPosition(pos.row, pos.col + 1),
            GridPosition(pos.row - 1, pos.col),
            GridPosition(pos.row - 1, pos.col + 1),
        ]
    }

    // MARK: - Coastguard interception

    /// Bomber: intercepted when the column matches the enemy coastguard's column AND
    /// at least one drop cell is north of that water row.
    static func bomberIntercepted(board: Board, target: GridPosition) -> Bool {
        guard let coastCol = board.enemyCoastguardColumn, coastCol == target.col else { return false }
        return bombingPositions(target: target).contains { $0.row < Zones.coastguardEnemyRow }
    }

    /// Missile 2x2 anchored at lower-left. The coastguard defends a single column. Intercept
    /// only when the salvo is anchored on that column (`c == coastCol`); the rightmost-column
    /// edge case (coastCol == 4 ⇒ c == 3) keeps the only 2x2 that includes column 4.
    static func missileIntercepted(board: Board, lowerLeft: GridPosition) -> Bool {
        guard let coastCol = board.enemyCoastguardColumn else { return false }
        let lastCol = Zones.columnCount - 1
        if coastCol == lowerLeft.col { return true }
        if coastCol == lastCol && lowerLeft.col == lastCol - 1 { return true }
        return false
    }

    // MARK: - Victory

    /// True iff any of the affected positions had the enemy HQ on it.
    static func includesEnemyHQ(_ board: Board, in positions: [GridPosition]) -> Bool {
        positions.contains { board.unit(at: $0) == .headquarters }
    }
}
