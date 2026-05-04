//
//  EnemySpawner.swift
//  GridStrike Watch App
//
//  Computer opponent setup once the player finishes placing units. Mirrors the original
//  `applyPostSetupSpawnIfNeeded` exactly: random HQ + 2 missiles + bomber on rows 0–4
//  (bomber at 180°), plus a coastguard on row 5 sharing a column with HQ or bomber.
//

import Foundation

enum EnemySpawner {
    static func apply<R: RandomNumberGenerator>(board: inout Board, rng: inout R) {
        guard !board.didApplyEnemySpawn else { return }

        var emptyNorthern: [GridPosition] = []
        for row in Zones.northGrass {
            for col in Zones.allColumns {
                let pos = GridPosition(row, col)
                if board.marks[pos] == nil {
                    emptyNorthern.append(pos)
                }
            }
        }
        guard emptyNorthern.count >= 4 else { return }
        board.didApplyEnemySpawn = true

        emptyNorthern.shuffle(using: &rng)
        let picked = Array(emptyNorthern.prefix(4))
        var units: [Unit] = [.headquarters, .missile, .missile, .bomber]
        units.shuffle(using: &rng)

        var hqColumn: Int?
        var bomberColumn: Int?
        for i in 0..<4 {
            let pos = picked[i]
            let unit = units[i]
            board.marks[pos] = unit
            if unit == .headquarters { hqColumn = pos.col }
            if unit == .bomber {
                bomberColumn = pos.col
                board.bomberRotations[pos] = 180
            }
        }

        let coastColumns = Set([hqColumn, bomberColumn].compactMap { $0 })
        guard let coastCol = coastColumns.randomElement(using: &rng) else { return }
        let coastPos = GridPosition(Zones.coastguardEnemyRow, coastCol)
        if board.marks[coastPos] == nil {
            board.marks[coastPos] = .coastguard
        }
    }
}
