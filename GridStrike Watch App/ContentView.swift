//
//  ContentView.swift
//  GridStrike Watch App
//
//  Thin shell — the entire game now lives in `GameRootView` and below.
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
