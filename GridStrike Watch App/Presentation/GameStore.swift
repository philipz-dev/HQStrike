//
//  GameStore.swift
//  GridStrike Watch App
//
//  Observable host for the game. The store holds the current `GameState`, applies
//  reducer outputs, and interprets side effects (haptics + bomb-drop timer).
//

import Foundation
import Observation
import SwiftUI
import WatchKit

@MainActor
@Observable
final class GameStore {
    private(set) var state: GameState
    @ObservationIgnored private var rng = SystemRandomNumberGenerator()

    init(initial: GameState = .newGame()) {
        self.state = initial
    }

    func send(_ action: Action) {
        let (next, effects) = GameReducer.reduce(state: state, action: action, rng: &rng)
        state = next
        for effect in effects { run(effect) }
    }

    // MARK: - Effect interpreter

    private func run(_ effect: SideEffect) {
        switch effect {
        case .haptic(let kind):
            WKInterfaceDevice.current().play(kind.watchHaptic)
        case .scheduleAdvanceBombDrop(let delay):
            Task { [weak self] in
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                await MainActor.run { self?.send(.advanceBombDrop) }
            }
        }
    }
}
