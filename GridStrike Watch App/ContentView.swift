//
//  ContentView.swift
//  GridStrike Watch App
//
//  Thin shell — the entire game lives in `GameRootView` (welcome splash first).
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GameRootView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environment(GameStore())
}
