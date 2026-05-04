//
//  SideEffect.swift
//  GridStrike Watch App
//
//  Reducer-emitted effects interpreted by the GameStore. Keeps the engine pure and
//  free of WatchKit/Foundation timers.
//

import Foundation
import WatchKit

enum HapticType: Equatable {
    case notification

    var watchHaptic: WKHapticType {
        switch self {
        case .notification: return .notification
        }
    }
}

enum SideEffect: Equatable {
    case haptic(HapticType)
    case scheduleAdvanceBombDrop(afterSeconds: Double)
}
