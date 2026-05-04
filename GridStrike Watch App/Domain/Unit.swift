//
//  Unit.swift
//  GridStrike Watch App
//
//  Game pieces and their derived metadata. Pure domain — no SwiftUI imports.
//

import Foundation

enum Unit: Equatable, CaseIterable {
    case headquarters
    case missile
    case bomber
    case coastguard

    var symbol: String {
        switch self {
        case .headquarters: return "X"
        case .missile: return "M"
        case .bomber: return "B"
        case .coastguard: return "C"
        }
    }

    var destroyedAlertMessage: String {
        switch self {
        case .headquarters: return "Headquarters destroyed!"
        case .missile: return "Missile destroyed!"
        case .bomber: return "Bomber destroyed!"
        case .coastguard: return "Coastguard destroyed!"
        }
    }
}

/// Player-launched weapons that the enemy coastguard can intercept.
enum Weapon: Equatable {
    case bomber
    case missile

    var shotDownText: String {
        switch self {
        case .bomber: return "Bomber shot down by enemy coastguard!"
        case .missile: return "Missile shot down by enemy coastguard!"
        }
    }
}

/// Strike result on a tile (used for grenade taps and bombing/missile drops).
enum ExplosionKind: Equatable {
    case hit
    case miss
}

/// Sunk attacker overlay rendered on the row south of the enemy coastguard.
enum WaterWreck: Equatable {
    case plane
    case missile
}
