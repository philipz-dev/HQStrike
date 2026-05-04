//
//  GameRootView.swift
//  GridStrike Watch App
//
//  Top-level switch — welcome vs. play container, plus the modal overlays. Reads from
//  the GameStore and forwards intents back via `send`.
//

import SwiftUI

struct GameRootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let snapshot = BoardSnapshot.compute(store.state)

        ZStack {
            Group {
                switch store.state.phase {
                case .welcome:
                    WelcomeView()
                default:
                    PlayContainerView(snapshot: snapshot)
                }
            }

            if let modal = snapshot.modal {
                switch modal {
                case .destructionAlert(let unit):
                    DestructionAlertOverlay(unit: unit) {
                        store.send(.acknowledgeDestructionAlert)
                    }
                case .victory:
                    VictoryOverlay {
                        store.send(.newGame)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PlayContainerView: View {
    let snapshot: BoardSnapshot
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack(alignment: .topLeading) {
            BoardView(snapshot: snapshot)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .allowsHitTesting(!store.state.isModalActive)

            // Banner pinned to top — VStack + Spacer keeps multi-line text top-anchored
            // (Text in a maxHeight overlay would otherwise vertically center).
            VStack(spacing: 0) {
                InstructionBanner(banner: snapshot.banner)
                    .padding(.horizontal, 4)
                    .padding(.top, 10)
                    .offset(y: -15)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
