//
//  Board.swift
//  GridStrike Watch App
//
//  Mutable, value-type board state. All cell lookups go through GridPosition.
//

import Foundation

struct Board: Equatable {
    var marks: [GridPosition: Unit]
    var bomberRotations: [GridPosition: Double]
    var didApplyEnemySpawn: Bool

    init(
        marks: [GridPosition: Unit] = [:],
        bomberRotations: [GridPosition: Double] = [:],
        didApplyEnemySpawn: Bool = false
    ) {
        self.marks = marks
        self.bomberRotations = bomberRotations
        self.didApplyEnemySpawn = didApplyEnemySpawn
    }

    static let empty = Board()

    func unit(at position: GridPosition) -> Unit? { marks[position] }

    /// Returns the enemy coastguard's column (the one on the northern water row), if any.
    var enemyCoastguardColumn: Int? {
        for col in Zones.allColumns where marks[GridPosition(Zones.coastguardEnemyRow, col)] == .coastguard {
            return col
        }
        return nil
    }

    /// Removes a southern unit at the given key if it's still present. Used after an attack
    /// or a coastguard interception to clear the launcher tile.
    mutating func removeSouthernUnit(at position: GridPosition, requiring unit: Unit) {
        guard Zones.isSouthGrass(position.row) else { return }
        guard marks[position] == unit else { return }
        marks.removeValue(forKey: position)
        if unit == .bomber { bomberRotations.removeValue(forKey: position) }
    }
}
