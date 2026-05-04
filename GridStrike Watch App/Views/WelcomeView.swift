//
//  WelcomeView.swift
//  GridStrike Watch App
//

import SwiftUI

struct WelcomeView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack(alignment: .bottom) {
            Assets.splashBackground
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, minHeight: 0)
                .clipped()
                .ignoresSafeArea()
            Color.black.opacity(0.42)
                .ignoresSafeArea()
            Text("Welcome to GridStrike!")
                .font(.headline.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 6, y: 2)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            store.send(.dismissWelcome)
        }
    }
}
