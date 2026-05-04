//
//  GameRootView.swift
//  GridStrike Watch App
//
//  Top-level switch — welcome vs. play container, plus the modal overlays. Uses one
//  exhaustive switch over `UIMode` instead of separate optional/bool checks.
//

import SwiftUI

struct GameRootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let snapshot = BoardSnapshot.compute(store.state)

        ZStack {
            switch store.state.mode {
            case .welcome:
                WelcomeView()

            case .destructionAlert(let unit):
                PlayContainerView(snapshot: snapshot)
                DestructionAlertOverlay(unit: unit) {
                    store.send(.acknowledgeDestructionAlert)
                }

            case .victory:
                PlayContainerView(snapshot: snapshot)
                VictoryOverlay {
                    store.send(.newGame)
                }

            case .defeat:
                PlayContainerView(snapshot: snapshot)
                DefeatOverlay {
                    store.send(.newGame)
                }

            case .setup, .play:
                PlayContainerView(snapshot: snapshot)
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
