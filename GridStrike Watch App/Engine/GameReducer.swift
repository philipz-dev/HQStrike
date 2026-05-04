//
//  GameReducer.swift
//  GridStrike Watch App
//
//  Pure reducer driven by the typed `UIMode` enum and the explicit `Phase` machine.
//  Every attack is parameterised on `state.currentTurn`, so the same code path
//  handles player and opponent offensives. After each attack fully resolves the
//  reducer flips the turn and — if the opponent is up next — schedules its move.
//

import Foundation

enum GameReducer {
    /// Delay before the opponent makes its first move after an attack fully resolves.
    private static let opponentPostAttackDelay: Double = 0.5
    /// Slightly longer pause after a shoot-down so the player can read the banner.
    private static let opponentPostShotDownDelay: Double = 1.5
    /// Delay between sequential opponent taps within the same turn (e.g. bomber
    /// source-tap → target-tap).
    private static let opponentInterTapDelay: Double = 0.5

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
            // After the last alert, the next opponent step (if any) might have been
            // waiting — re-evaluate the scheduling tail before returning.
            appendOpponentSchedulingIfNeeded(state: s, effects: &effects)
            return (s, effects)

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
            appendOpponentSchedulingIfNeeded(state: s, effects: &effects)
            return (s, effects)

        case .dismissWelcome:
            if case .welcome = s.phase {
                s.phase = .setup(.placeHeadquarter)
            }
            return (s, [])

        // MARK: Tap routing

        case .tap(let pos):
            switch s.mode {
            case .destructionAlert, .victory, .defeat:
                return (s, [])  // modal blocks input
            case .welcome:
                s.phase = .setup(.placeHeadquarter)
                return (s, [])
            case .setup(let step):
                handleSetupTap(state: &s, step: step, pos: pos, rng: &rng)
                return (s, [])
            case .play(let play):
                handlePlayTap(state: &s, playState: play, pos: pos, effects: &effects)
                appendOpponentSchedulingIfNeeded(state: s, effects: &effects)
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
            s.currentTurn = .player
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

    // MARK: - Idle / shot-down (attacker = state.currentTurn)

    private static func handleIdleTap(
        state s: inout GameState,
        pos: GridPosition,
        effects: inout [SideEffect]
    ) {
        let attacker = s.currentTurn
        let mark = s.board.unit(at: pos)
        let attackerGrass = Zones.grassRows(of: attacker)

        // Tap own bomber / missile to start an attack — phase change implicitly clears
        // any `.shotDown` banner.
        if attackerGrass.contains(pos.row), mark == .bomber {
            s.phase = .play(.choosingBombTarget(source: pos))
            return
        }
        if attackerGrass.contains(pos.row), mark == .missile {
            s.phase = .play(.choosingMissileTarget(source: pos))
            return
        }

        // Grenade strike on the defender's grass + coastguard row.
        guard Zones.isGrenadeTarget(pos, attacker: attacker) else { return }
        let defender = attacker.opposite
        guard s.grenadeStrikes[defender][pos] == nil else { return }

        // Drop any `.shotDown` banner now that a real strike is happening.
        s.phase = .play(.idle)

        let isHit = mark != nil
        s.grenadeStrikes[defender][pos] = isHit ? .hit : .miss
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
        if Rules.includesHQ(s.board, of: defender, in: [pos]) {
            s.phase = endGamePhase(forAttacker: attacker)
            return
        }
        endTurn(state: &s)
    }

    // MARK: - Bombing

    private static func handleConfirmBombTap(
        state s: inout GameState,
        source: GridPosition,
        pos: GridPosition,
        effects: inout [SideEffect]
    ) {
        let attacker = s.currentTurn
        guard Zones.isBombingTarget(pos, attacker: attacker) else { return }

        if Rules.bomberIntercepted(board: s.board, target: pos, attacker: attacker) {
            let wreckRow = Zones.shotDownRow(attacker: attacker)
            s.planeInWater[attacker] = GridPosition(wreckRow, pos.col)
            s.board.removeLauncher(at: source, requiring: .bomber, attacker: attacker)
            s.phase = .play(.shotDown(.bomber, attacker: attacker))
            effects.append(.haptic(.notification))
            endTurn(state: &s)
            return
        }

        applyBombDrop(state: &s, position: pos, defender: attacker.opposite)
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
        let attacker = s.currentTurn
        let drops = Rules.bombingPositions(target: target, attacker: attacker)
        if n < drops.count {
            applyBombDrop(state: &s, position: drops[n], defender: attacker.opposite)
        }
        effects.append(.haptic(.notification))

        let next = n + 1
        if next < 3 {
            s.phase = .play(.bombingDrops(source: source, target: target, dropsApplied: next))
            effects.append(.scheduleAdvanceBombDrop(afterSeconds: 1))
        } else {
            s.board.removeLauncher(at: source, requiring: .bomber, attacker: attacker)
            if Rules.includesHQ(s.board, of: attacker.opposite, in: drops) {
                s.phase = endGamePhase(forAttacker: attacker)
            } else {
                s.phase = .play(.idle)
                endTurn(state: &s)
            }
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
        let attacker = s.currentTurn
        guard Zones.isMissileTarget(pos, attacker: attacker) else { return }

        if Rules.missileIntercepted(board: s.board, anchor: pos, attacker: attacker) {
            let wreckRow = Zones.shotDownRow(attacker: attacker)
            s.missileInWater[attacker] = GridPosition(wreckRow, pos.col)
            s.board.removeLauncher(at: source, requiring: .missile, attacker: attacker)
            s.phase = .play(.shotDown(.missile, attacker: attacker))
            effects.append(.haptic(.notification))
            endTurn(state: &s)
            return
        }

        let defender = attacker.opposite
        let cells = Rules.missilePositions(anchor: pos, attacker: attacker)
        for c in cells {
            if let unit = s.board.unit(at: c) {
                s.missileOverlays[defender][c] = .hit
                s.pendingDestructionAlerts.append(unit)
            } else {
                s.missileOverlays[defender][c] = .miss
            }
        }
        effects.append(.haptic(.notification))
        s.board.removeLauncher(at: source, requiring: .missile, attacker: attacker)
        if Rules.includesHQ(s.board, of: defender, in: cells) {
            s.phase = endGamePhase(forAttacker: attacker)
        } else {
            s.phase = .play(.idle)
            endTurn(state: &s)
        }
    }

    // MARK: - Turn management

    /// Flips `currentTurn` after the active side has fully resolved an attack.
    private static func endTurn(state s: inout GameState) {
        s.currentTurn = s.currentTurn.opposite
    }

    /// HQ-hit terminal phase, picked from the perspective of the attacker.
    private static func endGamePhase(forAttacker attacker: Side) -> Phase {
        switch attacker {
        case .player: return .victory
        case .opponent: return .defeat
        }
    }

    /// Appends `scheduleOpponentTurn` whenever the resolved state expects the
    /// opponent to act next and no automatic timer (bomb-drop) is already running.
    /// Idempotent-ish: callers invoke it once per reducer entry, not per mutation.
    private static func appendOpponentSchedulingIfNeeded(
        state s: GameState,
        effects: inout [SideEffect]
    ) {
        guard s.currentTurn == .opponent else { return }
        // Don't dispatch the AI while a destruction alert is up — wait for the
        // player to acknowledge it first.
        guard !s.isModalActive else { return }
        guard case .play(let play) = s.phase else { return }

        let delay: Double
        switch play {
        case .bombingDrops:
            return                                     // advanceBombDrop drives this
        case .shotDown:
            delay = opponentPostShotDownDelay
        case .choosingBombTarget, .choosingMissileTarget:
            delay = opponentInterTapDelay              // mid-turn step
        case .idle:
            delay = opponentPostAttackDelay
        }
        effects.append(.scheduleOpponentTurn(afterSeconds: delay))
    }
}
