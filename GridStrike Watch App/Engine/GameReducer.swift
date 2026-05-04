//
//  GameReducer.swift
//  GridStrike Watch App
//
//  Pure reducer. Every gameplay decision lives here. The only inputs are state, action
//  and an injected RNG; outputs are the next state and a (possibly empty) list of side
//  effects to be interpreted by the GameStore.
//

import Foundation

enum GameReducer {
    static func reduce<R: RandomNumberGenerator>(
        state: GameState,
        action: Action,
        rng: inout R
    ) -> (GameState, [SideEffect]) {
        var s = state
        var effects: [SideEffect] = []

        // MARK: Always-on actions

        switch action {
        case .newGame:
            return (.newGame(), [])
        case .acknowledgeDestructionAlert:
            if !s.pendingDestructionAlerts.isEmpty {
                s.pendingDestructionAlerts.removeFirst()
            }
            return (s, [])
        default:
            break
        }

        // While a modal is up, gameplay actions are dropped.
        if s.isModalActive { return (s, []) }

        // MARK: Phase × Action

        switch (s.phase, action) {
        case (.welcome, .dismissWelcome), (.welcome, .tap):
            s.phase = .setup(.placeHeadquarter)
            return (s, [])

        case (.setup(let step), .tap(let pos)):
            handleSetupTap(state: &s, step: step, pos: pos, rng: &rng)
            return (s, [])

        case (.play(.idle), .tap(let pos)):
            handleIdleTap(state: &s, pos: pos, effects: &effects)
            return (s, effects)

        case (.play(.choosingBombTarget(let src)), .tap(let pos)):
            handleConfirmBombTap(state: &s, source: src, pos: pos, effects: &effects)
            return (s, effects)

        case (.play(.choosingMissileTarget(let src)), .tap(let pos)):
            handleConfirmMissileTap(state: &s, source: src, pos: pos, effects: &effects)
            return (s, effects)

        case (.play(.bombingDrops), .tap):
            // Drops in flight; ignore taps.
            return (s, [])

        case (.play(.bombingDrops(let src, let target, let n)), .advanceBombDrop):
            handleAdvanceBombDrop(
                state: &s,
                source: src,
                target: target,
                dropsApplied: n,
                effects: &effects
            )
            return (s, effects)

        default:
            return (s, [])
        }
    }

    // MARK: - Setup

    private static func handleSetupTap<R: RandomNumberGenerator>(
        state s: inout GameState,
        step: SetupStep,
        pos: GridPosition,
        rng: inout R
    ) {
        guard step.isValidPlacement(pos.row) else { return }
        guard s.board.marks[pos] == nil else { return }

        s.board.marks[pos] = step.unit

        if let next = step.next {
            s.phase = .setup(next)
            if next == .placeCoastguard {
                s.scrollTarget = Zones.coastguardPlayerRow
            }
        } else {
            EnemySpawner.apply(board: &s.board, rng: &rng)
            s.phase = .play(.idle)
        }
    }

    // MARK: - Play / idle

    private static func handleIdleTap(
        state s: inout GameState,
        pos: GridPosition,
        effects: inout [SideEffect]
    ) {
        let mark = s.board.unit(at: pos)

        // Tap own bomber / missile to start an attack.
        if Zones.isSouthGrass(pos.row), mark == .bomber {
            s.lastShotDown = nil
            s.phase = .play(.choosingBombTarget(source: pos))
            return
        }
        if Zones.isSouthGrass(pos.row), mark == .missile {
            s.lastShotDown = nil
            s.phase = .play(.choosingMissileTarget(source: pos))
            return
        }

        // Northern grenade strike.
        guard Zones.isNorthGrass(pos.row) else { return }
        guard s.northernStrikes[pos] == nil else { return }
        s.lastShotDown = nil
        let isHit = mark == .headquarters || mark == .missile || mark == .bomber
        s.northernStrikes[pos] = isHit ? .hit : .miss
        effects.append(.haptic(.notification))
        if isHit, let unit = mark {
            s.pendingDestructionAlerts.append(unit)
        }
        if mark == .headquarters {
            s.victory = true
        }
    }

    // MARK: - Bombing

    private static func handleConfirmBombTap(
        state s: inout GameState,
        source: GridPosition,
        pos: GridPosition,
        effects: inout [SideEffect]
    ) {
        guard Zones.isBombingTarget(pos) else { return }
        s.lastShotDown = nil

        if Rules.bomberIntercepted(board: s.board, target: pos) {
            s.lastShotDown = .bomber
            s.planeInWater = GridPosition(Zones.planeInWaterRow, pos.col)
            s.board.removeSouthernUnit(at: source, requiring: .bomber)
            s.phase = .play(.idle)
            effects.append(.haptic(.notification))
            return
        }

        applyBombDrop(state: &s, position: pos)
        effects.append(.haptic(.notification))
        s.phase = .play(.bombingDrops(source: source, target: pos, dropsApplied: 1))
        effects.append(.scheduleAdvanceBombDrop(afterSeconds: 1))
    }

    private static func handleAdvanceBombDrop(
        state s: inout GameState,
        source: GridPosition,
        target: GridPosition,
        dropsApplied n: Int,
        effects: inout [SideEffect]
    ) {
        let r = target.row - n
        if r >= 0 {
            applyBombDrop(state: &s, position: GridPosition(r, target.col))
        }
        effects.append(.haptic(.notification))

        let next = n + 1
        if next < 3 {
            s.phase = .play(.bombingDrops(source: source, target: target, dropsApplied: next))
            effects.append(.scheduleAdvanceBombDrop(afterSeconds: 1))
        } else {
            s.board.removeSouthernUnit(at: source, requiring: .bomber)
            s.phase = .play(.idle)
        }
    }

    private static func applyBombDrop(state s: inout GameState, position: GridPosition) {
        if let unit = s.board.unit(at: position) {
            s.bombingOverlays[position] = .hit
            s.pendingDestructionAlerts.append(unit)
            if unit == .headquarters { s.victory = true }
        } else {
            s.bombingOverlays[position] = .miss
        }
    }

    // MARK: - Missile

    private static func handleConfirmMissileTap(
        state s: inout GameState,
        source: GridPosition,
        pos: GridPosition,
        effects: inout [SideEffect]
    ) {
        guard Zones.isMissileTarget(pos) else { return }
        s.lastShotDown = nil

        if Rules.missileIntercepted(board: s.board, lowerLeft: pos) {
            s.lastShotDown = .missile
            s.missileInWater = GridPosition(Zones.planeInWaterRow, pos.col)
            s.board.removeSouthernUnit(at: source, requiring: .missile)
            s.phase = .play(.idle)
            effects.append(.haptic(.notification))
            return
        }

        let cells: [GridPosition] = [
            pos,
            GridPosition(pos.row, pos.col + 1),
            GridPosition(pos.row - 1, pos.col),
            GridPosition(pos.row - 1, pos.col + 1),
        ]
        for c in cells {
            if let unit = s.board.unit(at: c) {
                s.missileOverlays[c] = .hit
                s.pendingDestructionAlerts.append(unit)
                if unit == .headquarters { s.victory = true }
            } else {
                s.missileOverlays[c] = .miss
            }
        }
        effects.append(.haptic(.notification))
        s.board.removeSouthernUnit(at: source, requiring: .missile)
        s.phase = .play(.idle)
    }
}
