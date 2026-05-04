//
//  GameReducer.swift
//  GridStrike Watch App
//
//  Pure reducer driven by the typed `UIMode` enum and the explicit `Phase` machine.
//  No bool flags — every gameplay decision falls out of an exhaustive switch.
//
//  Strike/overlay writes go through the symmetric `PerSide` maps in `GameState`;
//  player-initiated attacks write to `[.opponent]`, leaving the `[.player]` half
//  ready for the AI turn implementation.
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

        switch action {

        // MARK: Always-on actions (work even while a modal is up)

        case .newGame:
            return (.newGame(), [])

        case .acknowledgeDestructionAlert:
            if !s.pendingDestructionAlerts.isEmpty {
                s.pendingDestructionAlerts.removeFirst()
            }
            return (s, [])

        case .advanceBombDrop:
            // Internal scheduled action — runs regardless of modal so a HQ-hit during
            // a drop sequence can't strand the remaining drops behind an alert.
            if case .play(.bombingDrops(let src, let target, let n)) = s.phase {
                handleAdvanceBombDrop(
                    state: &s,
                    source: src,
                    target: target,
                    dropsApplied: n,
                    effects: &effects
                )
            }
            return (s, effects)

        case .dismissWelcome:
            if case .welcome = s.phase {
                s.phase = .setup(.placeHeadquarter)
            }
            return (s, [])

        // MARK: Tap routing

        case .tap(let pos):
            switch s.mode {
            case .destructionAlert, .victory:
                return (s, [])  // modal blocks user input
            case .welcome:
                s.phase = .setup(.placeHeadquarter)
                return (s, [])
            case .setup(let step):
                handleSetupTap(state: &s, step: step, pos: pos, rng: &rng)
                return (s, [])
            case .play(let play):
                handlePlayTap(state: &s, playState: play, pos: pos, effects: &effects)
                return (s, effects)
            }
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

    // MARK: - Play tap dispatch

    private static func handlePlayTap(
        state s: inout GameState,
        playState: PlayState,
        pos: GridPosition,
        effects: inout [SideEffect]
    ) {
        switch playState {
        case .idle, .shotDown:
            handleIdleTap(state: &s, pos: pos, effects: &effects)
        case .choosingBombTarget(let src):
            handleConfirmBombTap(state: &s, source: src, pos: pos, effects: &effects)
        case .choosingMissileTarget(let src):
            handleConfirmMissileTap(state: &s, source: src, pos: pos, effects: &effects)
        case .bombingDrops:
            // Drops in flight; ignore taps.
            break
        }
    }

    // MARK: - Idle / shot-down (player attacks the opponent)

    private static func handleIdleTap(
        state s: inout GameState,
        pos: GridPosition,
        effects: inout [SideEffect]
    ) {
        let mark = s.board.unit(at: pos)

        // Tap own bomber / missile to start an attack — phase change implicitly clears
        // any `.shotDown` banner.
        if Zones.isSouthGrass(pos.row), mark == .bomber {
            s.phase = .play(.choosingBombTarget(source: pos))
            return
        }
        if Zones.isSouthGrass(pos.row), mark == .missile {
            s.phase = .play(.choosingMissileTarget(source: pos))
            return
        }

        // Grenade strike — rows 0–5 (opponent grass + opponent coastguard row).
        guard Zones.isGrenadeTarget(pos, attacker: .player) else { return }
        guard s.grenadeStrikes[.opponent][pos] == nil else { return }

        // Drop any `.shotDown` banner now that a real strike is happening.
        s.phase = .play(.idle)

        let isHit = mark != nil
        s.grenadeStrikes[.opponent][pos] = isHit ? .hit : .miss
        effects.append(.haptic(.notification))
        if let unit = mark {
            s.pendingDestructionAlerts.append(unit)
            if unit == .coastguard {
                // Coastguard is the only unit a grenade can actually remove from play —
                // the tile reverts to empty water and bomber/missile attacks on its column
                // are no longer intercepted.
                s.board.marks.removeValue(forKey: pos)
            }
        }
        if Rules.includesHQ(s.board, of: .opponent, in: [pos]) {
            s.phase = .victory
        }
    }

    // MARK: - Bombing

    private static func handleConfirmBombTap(
        state s: inout GameState,
        source: GridPosition,
        pos: GridPosition,
        effects: inout [SideEffect]
    ) {
        guard Zones.isBombingTarget(pos, attacker: .player) else { return }

        if Rules.bomberIntercepted(board: s.board, target: pos, attacker: .player) {
            let wreckRow = Zones.shotDownRow(attacker: .player)
            s.planeInWater[.player] = GridPosition(wreckRow, pos.col)
            s.board.removeLauncher(at: source, requiring: .bomber, attacker: .player)
            s.phase = .play(.shotDown(.bomber))
            effects.append(.haptic(.notification))
            return
        }

        applyBombDrop(state: &s, position: pos, defender: .opponent)
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
        let drops = Rules.bombingPositions(target: target, attacker: .player)
        if n < drops.count {
            applyBombDrop(state: &s, position: drops[n], defender: .opponent)
        }
        effects.append(.haptic(.notification))

        let next = n + 1
        if next < 3 {
            s.phase = .play(.bombingDrops(source: source, target: target, dropsApplied: next))
            effects.append(.scheduleAdvanceBombDrop(afterSeconds: 1))
        } else {
            s.board.removeLauncher(at: source, requiring: .bomber, attacker: .player)
            s.phase = Rules.includesHQ(s.board, of: .opponent, in: drops) ? .victory : .play(.idle)
        }
    }

    private static func applyBombDrop(
        state s: inout GameState,
        position: GridPosition,
        defender: Side
    ) {
        if let unit = s.board.unit(at: position) {
            s.bombingOverlays[defender][position] = .hit
            s.pendingDestructionAlerts.append(unit)
        } else {
            s.bombingOverlays[defender][position] = .miss
        }
    }

    // MARK: - Missile

    private static func handleConfirmMissileTap(
        state s: inout GameState,
        source: GridPosition,
        pos: GridPosition,
        effects: inout [SideEffect]
    ) {
        guard Zones.isMissileTarget(pos, attacker: .player) else { return }

        if Rules.missileIntercepted(board: s.board, anchor: pos, attacker: .player) {
            let wreckRow = Zones.shotDownRow(attacker: .player)
            s.missileInWater[.player] = GridPosition(wreckRow, pos.col)
            s.board.removeLauncher(at: source, requiring: .missile, attacker: .player)
            s.phase = .play(.shotDown(.missile))
            effects.append(.haptic(.notification))
            return
        }

        let cells = Rules.missilePositions(anchor: pos, attacker: .player)
        for c in cells {
            if let unit = s.board.unit(at: c) {
                s.missileOverlays[.opponent][c] = .hit
                s.pendingDestructionAlerts.append(unit)
            } else {
                s.missileOverlays[.opponent][c] = .miss
            }
        }
        effects.append(.haptic(.notification))
        s.board.removeLauncher(at: source, requiring: .missile, attacker: .player)
        s.phase = Rules.includesHQ(s.board, of: .opponent, in: cells) ? .victory : .play(.idle)
    }
}
