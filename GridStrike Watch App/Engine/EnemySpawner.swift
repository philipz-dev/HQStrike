//
//  EnemySpawner.swift
//  GridStrike Watch App
//
//  Computer opponent setup once the player finishes placing units. Uses a tiered
//  greedy strategy:
//    1. Bias HQ toward the corner columns. With the coastguard in HQ's column, corner
//       columns have only one 2x2 footprint that covers them — and the coastguard
//       intercepts that one — so HQ becomes fully missile-proof.
//    2. Place the bomber in the same column as HQ with row distance ≥ 2; any bomber
//       attack on that column then hits the coastguard, never an actual unit.
//    3. Drop the two missiles with Chebyshev distance ≥ 2 from every placed AI unit
//       and (when possible) in different columns, so neither a single 2x2 missile nor
//       a 3-cell bomber column can wipe two AI units at once.
//    4. Coastguard goes in HQ's column for maximum HQ protection.
//
//  Each placement is a tiered constraint pick (strictest → softest), so the spawner
//  always finds a valid spot even when the player blocked cells on rows 0–4 during
//  setup.
//

import Foundation

enum EnemySpawner {
    static func apply<R: RandomNumberGenerator>(board: inout Board, rng: inout R) {
        guard !board.didApplyEnemySpawn else { return }

        var available: Set<GridPosition> = []
        for row in Zones.northGrass {
            for col in Zones.allColumns {
                let p = GridPosition(row, col)
                if board.marks[p] == nil { available.insert(p) }
            }
        }
        guard available.count >= 4 else { return }
        board.didApplyEnemySpawn = true

        // 1) HQ — biased toward corner columns.
        guard let hq = pickHQPosition(available: available, rng: &rng) else { return }
        board.marks[hq] = .headquarters
        available.remove(hq)

        // 2) Bomber — same column as HQ when possible (so the coastguard absorbs any bomber attack on that column).
        let bomberConstraints: [(GridPosition) -> Bool] = [
            { p in p.col == hq.col && abs(p.row - hq.row) >= 2 },
            { p in chebyshev(p, hq) >= 2 },
            { p in chebyshev(p, hq) >= 1 },
        ]
        guard let bomber = pickPosition(from: available, constraints: bomberConstraints, rng: &rng) else { return }
        board.marks[bomber] = .bomber
        board.bomberRotations[bomber] = 180
        available.remove(bomber)

        // 3) Two missiles — spread out (Chebyshev ≥ 2) and ideally in unused columns.
        let placedAfterBomber: [GridPosition] = [hq, bomber]
        let usedColsAfterBomber: Set<Int> = [hq.col, bomber.col]
        let missile1Constraints: [(GridPosition) -> Bool] = [
            { p in placedAfterBomber.allSatisfy { chebyshev(p, $0) >= 2 } && !usedColsAfterBomber.contains(p.col) },
            { p in placedAfterBomber.allSatisfy { chebyshev(p, $0) >= 2 } },
            { p in placedAfterBomber.allSatisfy { chebyshev(p, $0) >= 1 } },
        ]
        guard let missile1 = pickPosition(from: available, constraints: missile1Constraints, rng: &rng) else { return }
        board.marks[missile1] = .missile
        available.remove(missile1)

        let placedAfterM1: [GridPosition] = [hq, bomber, missile1]
        let usedColsAfterM1: Set<Int> = usedColsAfterBomber.union([missile1.col])
        let missile2Constraints: [(GridPosition) -> Bool] = [
            { p in placedAfterM1.allSatisfy { chebyshev(p, $0) >= 2 } && !usedColsAfterM1.contains(p.col) },
            { p in placedAfterM1.allSatisfy { chebyshev(p, $0) >= 2 } },
            { p in placedAfterM1.allSatisfy { chebyshev(p, $0) >= 1 } },
        ]
        guard let missile2 = pickPosition(from: available, constraints: missile2Constraints, rng: &rng) else { return }
        board.marks[missile2] = .missile

        // 4) Coastguard always in HQ's column for full HQ protection vs bomber + missile.
        let coastPos = GridPosition(Zones.coastguardEnemyRow, hq.col)
        if board.marks[coastPos] == nil {
            board.marks[coastPos] = .coastguard
        }
    }

    // MARK: - Helpers

    private static func chebyshev(_ a: GridPosition, _ b: GridPosition) -> Int {
        max(abs(a.row - b.row), abs(a.col - b.col))
    }

    /// Try each predicate in order; return a random match from the first non-empty filter. The ultimate
    /// fallback is any available cell, so the spawner never deadlocks on a heavily-blocked board.
    private static func pickPosition<R: RandomNumberGenerator>(
        from available: Set<GridPosition>,
        constraints: [(GridPosition) -> Bool],
        rng: inout R
    ) -> GridPosition? {
        for predicate in constraints {
            let candidates = available.filter(predicate)
            if let pick = candidates.randomElement(using: &rng) { return pick }
        }
        return available.randomElement(using: &rng)
    }

    private static func pickHQPosition<R: RandomNumberGenerator>(
        available: Set<GridPosition>,
        rng: inout R
    ) -> GridPosition? {
        for col in weightedColumnOrder(rng: &rng) {
            let candidates = available.filter { $0.col == col }
            if let pick = candidates.randomElement(using: &rng) { return pick }
        }
        return available.randomElement(using: &rng)
    }

    /// 70% corner column (0 or 4), 30% interior. Remaining columns trail in random order so fallbacks
    /// stay unbiased when the preferred column is blocked.
    private static func weightedColumnOrder<R: RandomNumberGenerator>(rng: inout R) -> [Int] {
        let cols = Array(Zones.allColumns)
        guard let firstCol = cols.first, let lastCol = cols.last else { return cols }
        let corners: Set<Int> = [firstCol, lastCol]
        let interior = cols.filter { !corners.contains($0) }

        let pickCorner = Double.random(in: 0..<1, using: &rng) < 0.7 || interior.isEmpty
        let pool = pickCorner ? Array(corners) : interior
        let head = pool.randomElement(using: &rng) ?? firstCol

        var rest = cols.filter { $0 != head }
        rest.shuffle(using: &rng)
        return [head] + rest
    }
}
