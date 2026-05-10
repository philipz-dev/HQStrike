//
//  GridStrikeWatchApp.swift
//  GridStrike Watch App
//
//  App entry. Owns the single GameStore via @State and injects it into the view tree
//  through the new Observable-aware environment.
//

import SwiftUI

@main
struct GridStrikeWatchApp: App {
    @State private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
