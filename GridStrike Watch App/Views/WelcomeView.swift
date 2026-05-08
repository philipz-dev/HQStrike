//
//  WelcomeView.swift
//  GridStrike Watch App
//

import SwiftUI

struct WelcomeView: View {
    @Environment(GameStore.self) private var store
    @State private var showHelp = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background visuals — purely decorative, hit-testing is disabled
            // so taps fall through to the dedicated dismiss layer below.
            // The previous black-dim overlay has been removed; the title text
            // gets its own black outline below for legibility against the
            // raw splash artwork instead.
            Assets.splashBackground
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, minHeight: 0)
                .clipped()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Tap-anywhere-to-start surface. Sits below the help button in the
            // ZStack so the button consumes its own taps; everywhere else
            // routes through here and dispatches `.dismissWelcome`.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { store.send(.dismissWelcome) }

            // Welcome label pinned to the bottom — also non-interactive so it
            // doesn't swallow the tap-to-start gesture above. Outlined in
            // black via stacked offset copies so the white fill stays
            // legible on any region of the splash.
            VStack {
                Spacer()
                OutlinedText(
                    "Welcome to GridStrike!",
                    font: .headline.weight(.bold)
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)

            // `?` glyph anchored to the very top-left corner. Bigger than the
            // previous icon (28 pt) so it's an obvious affordance, with
            // padding pulled all the way down so it sits flush against the
            // safe-area edge. Buttons consume taps inside their bounds, so
            // the dismiss gesture only fires when the user taps elsewhere.
            Button {
                showHelp = true
            } label: {
                // Outlined glyph (no filled disc behind the `?`) — the user
                // asked for the help affordance to lose its background plate
                // so the splash artwork shows through where the dark circle
                // used to sit. A plain shadow keeps the white strokes
                // readable against any region of the splash.
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, y: 1)
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
            .padding(.top, 0)
            // Pulls the glyph up into the bezel corner so it sits above the
            // splash artwork's reticle ring instead of overlapping it. Pure
            // visual offset — the safe-area padding above keeps the button's
            // hit-target on screen, the offset just shifts where the glyph
            // is drawn relative to that anchor.
            .offset(y: -20)
            .accessibilityLabel("How to play")
        }
        .sheet(isPresented: $showHelp) {
            // NavigationStack supplies the inline title bar + toolbar slot for
            // the Done button, and lets the sheet present as a proper modal
            // page instead of just bare scroll content.
            NavigationStack {
                HelpView()
            }
        }
    }
}

// `OutlinedText` lives in its own file (`OutlinedText.swift`) so the help
// screen header can reuse the same crisp black-edged label without the
// type having to live as a `private` helper inside the welcome view.
