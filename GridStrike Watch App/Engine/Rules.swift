//
//  Rules.swift
//  GridStrike Watch App
//
//  Pure rule predicates. Easy to unit-test without any UI.
//

import Foundation

enum Rules {
    /// Bomber: 3 drops going north from `target`. Intercepted when the column matches the
    /// enemy coastguard column AND at least one drop cell sits north of that water row.
    static func bomberIntercepted(board: Board, target: GridPosition) -> Bool {
        guard let coastCol = board.enemyCoastguardColumn, coastCol == target.col else { return false }
        for i in 0..<3 {
            let r = target.row - i
            if r >= 0 && r < Zones.coastguardEnemyRow { return true }
        }
        return false
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
}
