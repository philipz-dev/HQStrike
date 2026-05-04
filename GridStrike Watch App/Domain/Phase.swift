//
//  Phase.swift
//  GridStrike Watch App
//
//  Explicit state machine for the whole game flow. Replaces the loose collection of
//  bool flags (bombingRunActive, missileChoosingTarget, …) so impossible combinations
//  cannot exist.
//

import Foundation

enum SetupStep: CaseIterable, Equatable {
    case placeHeadquarter
    case placeMissile1
    case placeMissile2
    case placeBomber
    case placeCoastguard

    var unit: Unit {
        switch self {
        case .placeHeadquarter: return .headquarters
        case .placeMissile1, .placeMissile2: return .missile
        case .placeBomber: return .bomber
        case .placeCoastguard: return .coastguard
        }
    }

    var next: SetupStep? {
        switch self {
        case .placeHeadquarter: return .placeMissile1
        case .placeMissile1: return .placeMissile2
        case .placeMissile2: return .placeBomber
        case .placeBomber: return .placeCoastguard
        case .placeCoastguard: return nil
        }
    }

    var instruction: String {
        switch self {
        case .placeHeadquarter: return "Place headquarter"
        case .placeMissile1: return "Place missile 1"
        case .placeMissile2: return "Place missile 2"
        case .placeBomber: return "Place bomber"
        case .placeCoastguard: return "Place coastguard"
        }
    }

    /// Allowed placement rows for this step.
    func isValidPlacement(_ row: Int) -> Bool {
        switch self {
        case .placeHeadquarter:
            return Zones.isSouthGrass(row)
        case .placeMissile1, .placeMissile2, .placeBomber:
            return Zones.isAnyGrass(row)
        case .placeCoastguard:
            return row == Zones.coastguardPlayerRow
        }
    }
}

enum PlayState: Equatable {
    case idle
    case choosingBombTarget(source: GridPosition)
    case bombingDrops(source: GridPosition, target: GridPosition, dropsApplied: Int)
    case choosingMissileTarget(source: GridPosition)
}

enum Phase: Equatable {
    case welcome
    case setup(SetupStep)
    case play(PlayState)
}
