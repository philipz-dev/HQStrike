//
//  ManualWeaponsMenuView.swift
//  GridStrike Watch App
//
//  Full-screen camouflage with a 2×2 weapon picker (Grenade, Missile, Bomber, Coastguard).
//

import SwiftUI

struct ManualWeaponsMenuView: View {
    enum Selection {
        case grenade
        case missile
        case bomber
        case coastguard
    }

    let onBack: () -> Void
    let onSelect: (Selection) -> Void

    /// Horizontal fine-tune vs camouflage template squares.
    private static let gridNudgeX: CGFloat = 0

    /// Soft max; layout picks `min(targetIconSize, width, height slots)`.
    private static let targetIconSize: CGFloat = 128

    private static let cellCornerRadius: CGFloat = 18
    private static let gridSpacing: CGFloat = 8

    private static let cellPadding: CGFloat = 5

    /// Title between the × row and weapon tiles.
    private static let guideTitleTopPadding: CGFloat = 4
    private static let guideTitleBlockHeight: CGFloat = 22

    /// Space below the Guide title before the 2×2 grid.
    private static let gridTopInsetBelowTopBar: CGFloat = 8

    /// Touch target row height for top controls (aligned with system time band).
    private static let topBarRowHeight: CGFloat = 32

    var body: some View {
        GeometryReader { geo in
            let topReserved =
                geo.safeAreaInsets.top + Self.topBarRowHeight
                + Self.guideTitleTopPadding + Self.guideTitleBlockHeight
                + Self.gridTopInsetBelowTopBar
            let bottomReserved = geo.safeAreaInsets.bottom + 4

            let widthSlot = (geo.size.width - 12 - Self.gridSpacing) / 2 - 4
            let usableHeight = geo.size.height - topReserved - bottomReserved
            let heightSlot = (usableHeight - Self.gridSpacing) / 2 - Self.cellPadding * 2
            let iconSide = min(
                Self.targetIconSize,
                max(44, min(widthSlot, heightSlot))
            )

            ZStack {
                Assets.manualMenuCamouflage
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    topBar
                        .padding(.top, geo.safeAreaInsets.top)
                        .padding(.horizontal, 8)

                    Text("Guide")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.top, Self.guideTitleTopPadding)

                    grid(iconSide: iconSide)
                        .frame(width: geo.size.width * 0.94)
                        .padding(.top, Self.gridTopInsetBelowTopBar)
                        .offset(x: Self.gridNudgeX)

                    Spacer(minLength: 0)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    /// Dismiss × on the leading edge, aligned with the watch time row.
    private var topBar: some View {
        HStack(alignment: .center, spacing: 0) {
            Button {
                onBack()
            } label: {
                Text("×")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                    .frame(width: Self.topBarRowHeight, height: Self.topBarRowHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityHint("Returns to Start game and Guide menu")

            Spacer(minLength: 0)
        }
        .frame(height: Self.topBarRowHeight)
    }

    private func grid(iconSide: CGFloat) -> some View {
        VStack(spacing: Self.gridSpacing) {
            HStack(spacing: Self.gridSpacing) {
                weaponCell(icon: Assets.manualMenuGrenade, title: "Grenade", iconSide: iconSide) {
                    onSelect(.grenade)
                }
                weaponCell(icon: Assets.manualMenuMissile, title: "Missile", iconSide: iconSide) {
                    onSelect(.missile)
                }
            }
            HStack(spacing: Self.gridSpacing) {
                weaponCell(icon: Assets.manualMenuBomber, title: "Bomber", iconSide: iconSide) {
                    onSelect(.bomber)
                }
                weaponCell(icon: Assets.manualMenuCoastguard, title: "Coastguard", iconSide: iconSide) {
                    onSelect(.coastguard)
                }
            }
        }
    }

    private func weaponCell(
        icon: Image,
        title: String,
        iconSide: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        let labelFontSize = min(22, max(11, iconSide * 0.24))

        return Button(action: action) {
            ZStack(alignment: .bottom) {
                icon
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: iconSide, height: iconSide)

                OutlinedText(
                    title,
                    font: .system(size: labelFontSize, weight: .semibold, design: .rounded),
                    fill: .white,
                    outline: .black,
                    outlineWidth: 1.25
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.62)
                .frame(maxWidth: iconSide + 4)
                .padding(.horizontal, 4)
                .padding(.bottom, 5)
            }
            .padding(Self.cellPadding)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Self.cellCornerRadius))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    ManualWeaponsMenuView(onBack: {}, onSelect: { _ in })
}
#endif
