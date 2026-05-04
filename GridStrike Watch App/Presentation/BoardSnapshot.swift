//
//  BoardSnapshot.swift
//  GridStrike Watch App
//
//  One-pass projection from GameState → render data for every tile + banner + modal.
//  Invoked once per BoardView body; replaces the inline conditional chains in the old
//  `tileView` / `isVisuallyGhosted` / `buttonDisabled` closures.
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

        let modal: Modal?
        if let unit = state.pendingDestructionAlerts.first {
            modal = .destructionAlert(unit)
        } else if state.victory {
            modal = .victory
        } else {
            modal = nil
        }

        return BoardSnapshot(tiles: tiles, banner: state.banner, modal: modal)
    }

    // MARK: - Per-tile decision

    private static func makeTile(at pos: GridPosition, state: GameState) -> TileRenderModel {
        let mark = state.board.unit(at: pos)
        let hideEnemyArt = hidesEnemyUnitArt(at: pos, state: state)

        // Background image
        let background: TileBackground = {
            if hideEnemyArt {
                return Zones.isWater(pos.row) ? .water : .grass
            }
            if let mark = mark {
                return .unit(mark)
            }
            return Zones.isWater(pos.row) ? .water : .grass
        }()

        // Bomber rotation only when bomber art is visible
        let bomberRotation: Double = {
            guard mark == .bomber, !hideEnemyArt else { return 0 }
            return state.board.bomberRotations[pos] ?? 0
        }()

        // Ghosting
        let dim = ghostMode(at: pos, state: state)
        let offCoastguard = isPlaceCoastguardOffFocus(at: pos, state: state)

        // Northern grenade overlay (rows 0–4) during play
        let strikeOverlay: ExplosionKind? = {
            if case .play = state.phase, Zones.isNorthGrass(pos.row) {
                return state.northernStrikes[pos]
            }
            return nil
        }()

        // Bombing or missile overlay (combined; missile takes precedence only when there's no bombing entry)
        let dropOverlay: ExplosionKind? = {
            guard case .play = state.phase else { return nil }
            return state.bombingOverlays[pos] ?? state.missileOverlays[pos]
        }()

        // Water wreck on the row south of the enemy coastguard
        let wreck: WaterWreck? = {
            guard case .play = state.phase else { return nil }
            if state.planeInWater == pos { return .plane }
            if state.missileInWater == pos { return .missile }
            return nil
        }()

        let isSelected: Bool = {
            switch state.phase {
            case .play(.choosingBombTarget(let src)) where src == pos: return true
            case .play(.choosingMissileTarget(let src)) where src == pos: return true
            default: return false
            }
        }()

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

    /// During play, opponent tiles on rows 0–5 hide their unit graphics.
    private static func hidesEnemyUnitArt(at pos: GridPosition, state: GameState) -> Bool {
        guard case .play = state.phase else { return false }
        return pos.row <= Zones.coastguardEnemyRow
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

        case .play:
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
        case .welcome:
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
            case .idle, .bombingDrops:
                return false
            }
        }
    }
}
