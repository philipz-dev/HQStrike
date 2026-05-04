//
//  BannerKind.swift
//  GridStrike Watch App
//
//  Typed instruction-text source. Consumes `UIMode` so the cascading `if`s that used
//  to live in `instructionText` collapse into one exhaustive switch.
//

import Foundation

enum BannerKind: Equatable {
    case none
    case place(SetupStep)
    case defineBombArea
    case defineMissileStrike
    case shotDown(Weapon, attacker: Side)
    case setupComplete
    case opponentThinking

    var localized: String {
        switch self {
        case .none:
            return ""
        case .place(let step):
            return step.instruction
        case .defineBombArea:
            return "Define bombing area!"
        case .defineMissileStrike:
            return "Define missile strike!"
        case .shotDown(let weapon, let attacker):
            switch (weapon, attacker) {
            case (.bomber, .player): return "Bomber shot down by enemy coastguard!"
            case (.missile, .player): return "Missile shot down by enemy coastguard!"
            case (.bomber, .opponent): return "Enemy bomber shot down by your coastguard!"
            case (.missile, .opponent): return "Enemy missile shot down by your coastguard!"
            }
        case .setupComplete:
            return "Setup complete"
        case .opponentThinking:
            return "Thinking…"
        }
    }
}

extension GameState {
    var banner: BannerKind {
        switch mode {
        case .destructionAlert, .victory, .defeat, .welcome:
            return .none
        case .setup(let step):
            return .place(step)
        case .play(let play):
            switch play {
            case .idle:
                return currentTurn == .player ? .setupComplete : .opponentThinking
            case .shotDown(let weapon, let attacker):
                return .shotDown(weapon, attacker: attacker)
            case .choosingBombTarget:
                return currentTurn == .player ? .defineBombArea : .opponentThinking
            case .choosingMissileTarget:
                return currentTurn == .player ? .defineMissileStrike : .opponentThinking
            case .bombingDrops:
                return .none
            }
        }
    }
}
