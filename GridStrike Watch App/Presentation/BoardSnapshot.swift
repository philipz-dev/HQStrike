//
//  BoardSnapshot.swift
//  GridStrike Watch App
//
//  One-pass projection from GameState → render data for every tile + banner + modal.
//  Driven entirely by `phase` / `mode`; no bool flags. Strike/overlay reads are
//  side-aware so the same renderer covers both halves of the board once AI turns
//  start writing into `[.player]`.
//

import Foundation

struct BoardSnapshot: Equatable {
    let tiles: [GridPosition: TileRenderModel]
    let banner: BannerKind
    let modal: Modal?

    enum Modal: Equatable {
        case destructionAlert(Unit)
        case victory
    }

    static func compute(_ state: GameState) -> BoardSnapshot {
        var tiles: [GridPosition: TileRenderModel] = [:]
        tiles.reserveCapacity(Zones.rowCount * Zones.columnCount)
        for row in Zones.allRows {
            for col in Zones.allColumns {
                let pos = GridPosition(row, col)
                tiles[pos] = makeTile(at: pos, state: state)
            }
        }

        let modal: Modal? = {
            switch state.mode {
            case .destructionAlert(let unit): return .destructionAlert(unit)
            case .victory: return .victory
            case .welcome, .setup, .play: return nil
            }
        }()

        return BoardSnapshot(tiles: tiles, banner: state.banner, modal: modal)
    }

    // MARK: - Per-tile decision

    private static func makeTile(at pos: GridPosition, state: GameState) -> TileRenderModel {
        let mark = state.board.unit(at: pos)
        let hideEnemyArt = hidesEnemyUnitArt(at: pos, state: state)

        let background: TileBackground = {
            if hideEnemyArt {
                return Zones.isWater(pos.row) ? .water : .grass
            }
            if let mark = mark {
                return .unit(mark)
            }
            return Zones.isWater(pos.row) ? .water : .grass
        }()

        let bomberRotation: Double = {
            guard mark == .bomber, !hideEnemyArt else { return 0 }
            return state.board.bomberRotations[pos] ?? 0
        }()

        let dim = ghostMode(at: pos, state: state)
        let offCoastguard = isPlaceCoastguardOffFocus(at: pos, state: state)

        let strikeOverlay: ExplosionKind? = {
            guard state.phase.isInGame else { return nil }
            // Each tile only ever carries strikes against its own side. Mid-water
            // rows (6, 7) belong to no side and stay clean.
            guard let side = Zones.side(forRow: pos.row) else { return nil }
            // Grenade strikes are valid on the defender's grass + their coastguard row.
            // For .opponent that's rows 0–5; for .player rows 8–13. We inspect both
            // dimensions here so the original "rows 0–5" check still holds.
            let grenadeAttacker = side.opposite
            guard Zones.isGrenadeTarget(pos, attacker: grenadeAttacker) else { return nil }
            return state.grenadeStrikes[side][pos]
        }()

        let dropOverlay: ExplosionKind? = {
            guard state.phase.isInGame else { return nil }
            guard let side = Zones.side(forRow: pos.row) else { return nil }
            return state.bombingOverlays[side][pos] ?? state.missileOverlays[side][pos]
        }()

        let wreck: WaterWreck? = {
            guard state.phase.isInGame else { return nil }
            // Plane/missile-in-water sits on the *attacker*'s wreck row, which
            // belongs to a `Side` keyed by attacker.
            for attacker in Side.allCases {
                if state.planeInWater[attacker] == pos { return .plane }
                if state.missileInWater[attacker] == pos { return .missile }
            }
            return nil
        }()

        let isSelected = state.phase.targetingSource == pos

        let border: TileBorder = {
            if isSelected { return .selected }
            if dim != .none { return .dim }
            return .plain
        }()

        let isDisabled = isTileDisabled(
            at: pos,
            state: state,
            mark: mark,
            isSelected: isSelected
        )

        return TileRenderModel(
            position: pos,
            background: background,
            bomberRotationDegrees: bomberRotation,
            dim: dim,
            offCoastguardFocusRow: offCoastguard,
            northStrikeOverlay: strikeOverlay,
            dropOverlay: dropOverlay,
            waterWreck: wreck,
            border: border,
            isDisabled: isDisabled
        )
    }

    // MARK: - Per-tile helpers

    /// During play (and post-victory while the modal is up), opponent tiles on rows 0–5
    /// hide their unit graphics — strike/bomb logic still runs against `state.board`.
    private static func hidesEnemyUnitArt(at pos: GridPosition, state: GameState) -> Bool {
        state.phase.isInGame && pos.row <= Zones.coastguardEnemyRow
    }

    private static func isPlaceCoastguardOffFocus(at pos: GridPosition, state: GameState) -> Bool {
        if case .setup(.placeCoastguard) = state.phase {
            return pos.row != Zones.coastguardPlayerRow
        }
        return false
    }

    private static func ghostMode(at pos: GridPosition, state: GameState) -> DimMode {
        switch state.phase {
        case .play(.choosingBombTarget(let src)):
            if pos == src { return .none }
            return Zones.bombingTargetRows.contains(pos.row) ? .none : .normal

        case .play(.choosingMissileTarget(let src)):
            if pos == src { return .none }
            return Zones.isMissileTarget(pos) ? .none : .normal

        case .play, .victory:
            return .none

        case .setup(.placeCoastguard):
            return pos.row != Zones.coastguardPlayerRow ? .coastguardOffRow : .none

        case .setup(let step):
            if state.board.marks[pos] != nil { return .none }
            return step.isValidPlacement(pos.row) ? .none : .normal

        case .welcome:
            return .none
        }
    }

    private static func isTileDisabled(
        at pos: GridPosition,
        state: GameState,
        mark: Unit?,
        isSelected: Bool
    ) -> Bool {
        if state.isModalActive { return true }

        switch state.phase {
        case .welcome, .victory:
            return false
        case .setup(let step):
            if mark != nil { return false }
            return !step.isValidPlacement(pos.row)
        case .play(let play):
            switch play {
            case .choosingMissileTarget:
                return !(Zones.isMissileTarget(pos) || isSelected)
            case .choosingBombTarget:
                return !(Zones.isBombingTarget(pos) || isSelected)
            case .idle, .shotDown, .bombingDrops:
                return false
            }
        }
    }
}
