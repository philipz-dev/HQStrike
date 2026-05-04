//
//  BannerKind.swift
//  GridStrike Watch App
//
//  Typed instruction-text source. Replaces the cascading `if`s that previously lived
//  inside `instructionText` in the view.
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
        if !pendingDestructionAlerts.isEmpty { return .none }
        if victory { return .none }
        switch phase {
        case .welcome:
            return .none
        case .setup(let step):
            return .place(step)
        case .play(let play):
            switch play {
            case .choosingBombTarget:
                return .defineBombArea
            case .choosingMissileTarget:
                return .defineMissileStrike
            case .bombingDrops:
                return .none
            case .idle:
                switch lastShotDown {
                case .bomber: return .bomberShotDown
                case .missile: return .missileShotDown
                case .none: return .setupComplete
                }
            }
        }
    }
}
