//
//  WelcomeView.swift
//  GridStrike Watch App
//
//  First screen: splash artwork. Tapping anywhere reveals a small in-place menu —
//  "Start game" (begins setup) and "Guide" (weapon picker on camouflage, then manual inline).
//
//  The guide hub is presented inline (not via `.fullScreenCover`) so the OS doesn't
//  layer system close chrome on top of our own X. That X returns to the Start / Guide menu.
//  Each weapon tile opens its scripted demo; a tap during a demo dismisses back to this
//  four-tile camouflage hub (not the splash).
//

import SwiftUI

struct WelcomeView: View {
    @Environment(GameStore.self) private var store
    @State private var showManualWeaponsMenu = false
    @State private var showStartMenu = false
    @State private var showMissileDemo = false
    @State private var showCoastguardDemo = false
    @State private var showBomberDemo = false
    @State private var showGrenadeDemo = false

    var body: some View {
        ZStack {
            if showGrenadeDemo {
                Demo_Grenade(onClose: dismissDemoReturningToWeaponMenu)
            } else if showBomberDemo {
                Demo_Bomber(onClose: dismissDemoReturningToWeaponMenu)
            } else if showCoastguardDemo {
                Demo_Coastguard(onClose: dismissDemoReturningToWeaponMenu)
            } else if showMissileDemo {
                Demo_Missile(onClose: dismissDemoReturningToWeaponMenu)
            } else if showManualWeaponsMenu {
                ManualWeaponsMenuView(
                    onBack: {
                        showManualWeaponsMenu = false
                        showStartMenu = true
                    },
                    onSelect: { selection in
                        showManualWeaponsMenu = false
                        showMissileDemo = false
                        showCoastguardDemo = false
                        showBomberDemo = false
                        showGrenadeDemo = false
                        switch selection {
                        case .grenade: showGrenadeDemo = true
                        case .missile: showMissileDemo = true
                        case .bomber: showBomberDemo = true
                        case .coastguard: showCoastguardDemo = true
                        }
                    }
                )
            } else {
                splashContent
            }
        }
        .onAppear {
            if store.state.welcomePresentStartMenu {
                showStartMenu = true
                store.send(.clearWelcomeStartMenuRequest)
            }
        }
    }

    // MARK: - Splash

    private var splashContent: some View {
        ZStack {
            Assets.splashBackground
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, minHeight: 0)
                .clipped()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Tap-anywhere surface — first tap reveals the start menu.
            // Once the menu is up, taps inside the menu's buttons take
            // precedence; taps outside dismiss the menu (handled by the
            // menu overlay's own background).
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { showStartMenu = true }

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
        }
        .overlay {
            if showStartMenu {
                startMenuOverlay
            }
        }
    }

    /// Two-button choice screen revealed by the first tap on the splash.
    /// Background is fully opaque so the splash artwork is hidden — the menu
    /// reads as its own dedicated screen rather than a translucent overlay.
    private var startMenuOverlay: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .contentShape(Rectangle())
                // Tap outside the buttons returns to the splash. The buttons
                // sit on top of this layer so their hits don't fall through.
                .onTapGesture { showStartMenu = false }

            VStack(spacing: 10) {
                Button {
                    showStartMenu = false
                    store.send(.dismissWelcome)
                } label: {
                    Text("Start game")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(EndGamePalette.mutedGreen)

                Button {
                    showStartMenu = false
                    showManualWeaponsMenu = true
                } label: {
                    Text("Guide")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(EndGamePalette.mutedGray)
            }
            .padding(.horizontal, 14)
        }
        .transition(.opacity)
    }

    /// Ends any active scripted demo and shows the camouflage weapon hub again.
    private func dismissDemoReturningToWeaponMenu() {
        showGrenadeDemo = false
        showBomberDemo = false
        showCoastguardDemo = false
        showMissileDemo = false
        showManualWeaponsMenu = true
    }
}

// `OutlinedText` lives in its own file (`OutlinedText.swift`) for reuse on the splash and elsewhere.
