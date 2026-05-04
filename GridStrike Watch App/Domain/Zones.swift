//
//  Zones.swift
//  GridStrike Watch App
//
//  All grid coordinates and ranges live here. Single source of truth — no more magic
//  numbers scattered across the view layer.
//

import Foundation

enum Zones {
    static let rowCount = 14
    static let columnCount = 5
    static let allRows: ClosedRange<Int> = 0...13
    static let allColumns: ClosedRange<Int> = 0...4

    /// 0…4 — northern grass (enemy zone, hidden during play).
    static let northGrass: ClosedRange<Int> = 0...4
    /// 5…8 — water rows.
    static let waterRows: ClosedRange<Int> = 5...8
    /// 9…13 — southern grass (player zone).
    static let southGrass: ClosedRange<Int> = 9...13

    /// Player's coastguard placement row (during setup).
    static let coastguardPlayerRow = 8
    /// Enemy coastguard sits one water row south of the top grass.
    static let coastguardEnemyRow = 5
    /// Plane / MissileInWater overlays sit one row south of the enemy coastguard.
    static let planeInWaterRow = 6

    /// Allowed rows for choosing a bombing target (3 cells north of choice → row 0..4).
    static let bombingTargetRows: ClosedRange<Int> = 2...4
    /// Allowed lower-left rows for a missile 2x2.
    static let missileTargetRows: ClosedRange<Int> = 1...4
    /// Allowed lower-left columns for a missile 2x2 (so c+1 stays in range).
    static let missileTargetColumns: ClosedRange<Int> = 0...3
    /// Rows the player can grenade-strike during play. Includes the enemy grass (0–4) and the enemy
    /// coastguard's water row (5) so the player can take out the coastguard before mounting a column attack.
    static let grenadeTargetRows: ClosedRange<Int> = 0...5

    static func isNorthGrass(_ row: Int) -> Bool { northGrass.contains(row) }
    static func isWater(_ row: Int) -> Bool { waterRows.contains(row) }
    static func isSouthGrass(_ row: Int) -> Bool { southGrass.contains(row) }
    static func isAnyGrass(_ row: Int) -> Bool { isNorthGrass(row) || isSouthGrass(row) }
    static func isGrenadeTarget(_ row: Int) -> Bool { grenadeTargetRows.contains(row) }

    static func isBombingTarget(_ pos: GridPosition) -> Bool {
        bombingTargetRows.contains(pos.row) && allColumns.contains(pos.col)
    }

    static func isMissileTarget(_ pos: GridPosition) -> Bool {
        missileTargetRows.contains(pos.row) && missileTargetColumns.contains(pos.col)
    }
}
