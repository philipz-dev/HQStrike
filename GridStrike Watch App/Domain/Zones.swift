//
//  Zones.swift
//  GridStrike Watch App
//
//  All grid coordinates and ranges live here. Single source of truth — no more magic
//  numbers scattered across the view layer. Helpers come in two flavours: absolute
//  ones (kept for the original "player attacks opponent" code paths) and Side-
//  parametric ones (used by the symmetric reducer/renderer that drives the AI turn).
//

import Foundation

enum Zones {
    static let rowCount = 14
    static let columnCount = 5
    static let allRows: ClosedRange<Int> = 0...13
    static let allColumns: ClosedRange<Int> = 0...4

    /// 0…4 — northern grass (opponent zone, hidden during play).
    static let northGrass: ClosedRange<Int> = 0...4
    /// 5…8 — water rows.
    static let waterRows: ClosedRange<Int> = 5...8
    /// 9…13 — southern grass (player zone).
    static let southGrass: ClosedRange<Int> = 9...13

    /// Player's coastguard placement row (during setup).
    static let coastguardPlayerRow = 8
    /// Enemy coastguard sits one water row south of the top grass.
    static let coastguardEnemyRow = 5
    /// Plane / MissileInWater overlays sit one row south of the enemy coastguard
    /// (the wreckage drifts down toward the player after a shoot-down).
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

    // MARK: - Side-parametric helpers

    /// Which half of the board a tile belongs to. The two mid-water rows (6, 7) sit
    /// outside both home halves and so don't carry an owner.
    static func side(forRow row: Int) -> Side? {
        if row <= coastguardEnemyRow { return .opponent }      // 0…5
        if row >= coastguardPlayerRow { return .player }       // 8…13
        return nil                                             // 6, 7
    }

    /// Home grass for a side (where its HQ / non-coastguard units sit).
    static func grassRows(of side: Side) -> ClosedRange<Int> {
        switch side {
        case .opponent: return northGrass     // 0…4
        case .player: return southGrass       // 9…13
        }
    }

    /// Coastguard water row for a side.
    static func coastguardRow(of side: Side) -> Int {
        switch side {
        case .opponent: return coastguardEnemyRow   // 5
        case .player: return coastguardPlayerRow    // 8
        }
    }

    /// Wreckage row used when `attacker`'s plane/missile is shot down — one water
    /// row "outward" from the defender's coastguard (toward the attacker).
    /// Player attacks → wreck on row 6 (south of the enemy coastguard).
    /// Opponent attacks → wreck on row 7 (north of the player coastguard).
    static func shotDownRow(attacker: Side) -> Int {
        switch attacker {
        case .player: return 6
        case .opponent: return 7
        }
    }

    /// Rows where a grenade tap from `attacker` is valid — the defender's grass
    /// plus that defender's coastguard row.
    static func grenadeTargetRows(attacker: Side) -> ClosedRange<Int> {
        let defender = attacker.opposite
        switch defender {
        case .opponent: return 0...5    // attacker = player
        case .player: return 8...13     // attacker = opponent
        }
    }

    static func isGrenadeTarget(_ pos: GridPosition, attacker: Side) -> Bool {
        grenadeTargetRows(attacker: attacker).contains(pos.row)
    }

    /// Allowed bombing-target rows for an attacker. Drops fall away from the
    /// attacker's home; we pick the three rows of the defender's grass closest to
    /// the water so all 3 drops land on the defender's grass.
    static func bombingTargetRows(attacker: Side) -> ClosedRange<Int> {
        switch attacker {
        case .player: return 2...4      // drops go north → rows 0/1/2..2/3/4
        case .opponent: return 9...11   // drops go south → rows 9/10/11..11/12/13
        }
    }

    static func isBombingTarget(_ pos: GridPosition, attacker: Side) -> Bool {
        bombingTargetRows(attacker: attacker).contains(pos.row) && allColumns.contains(pos.col)
    }

    /// Allowed lower-left rows for an attacker's 2x2 missile. The 2x2 hugs the
    /// defender's water edge so it always covers the coastguard row + 1 grass row.
    static func missileTargetRows(attacker: Side) -> ClosedRange<Int> {
        switch attacker {
        case .player: return 1...4       // 2x2 anchored at lower-left rows 1..4
        case .opponent: return 9...12    // mirrored: 2x2 anchored at upper-left rows 9..12
        }
    }

    static func isMissileTarget(_ pos: GridPosition, attacker: Side) -> Bool {
        missileTargetRows(attacker: attacker).contains(pos.row)
            && missileTargetColumns.contains(pos.col)
    }
}
