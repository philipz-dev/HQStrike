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
    case bomberShotDown
    case missileShotDown
    case setupComplete

    var localized: String {
        switch self {
        case .none: return ""
        case .place(let step): return step.instruction
        case .defineBombArea: return "Define bombing area!"
        case .defineMissileStrike: return "Define missile strike!"
        case .bomberShotDown: return Weapon.bomber.shotDownText
        case .missileShotDown: return Weapon.missile.shotDownText
        case .setupComplete: return "Setup complete"
        }
    }
}

extension GameState {
    var banner: BannerKind {
        switch mode {
        case .destructionAlert, .victory, .welcome:
            return .none
        case .setup(let step):
            return .place(step)
        case .play(let play):
            switch play {
            case .idle:
                return .setupComplete
            case .shotDown(.bomber):
                return .bomberShotDown
            case .shotDown(.missile):
                return .missileShotDown
            case .choosingBombTarget:
                return .defineBombArea
            case .choosingMissileTarget:
                return .defineMissileStrike
            case .bombingDrops:
                return .none
            }
        }
    }
}
