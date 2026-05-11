//
//  OpponentSetupMapView.swift
//  GridStrike Watch App
//
//  Post-game frozen snapshot at round start (`boardAtPlayStart`). Layout deliberately
//  mirrors `BoardView` (same tile width, no extra top/bottom gutter, same horizontal
//  padding) so the map renders in the **original grid colours** instead of looking
//  shrunken or ghosted inside a dark frame. Tap anywhere to finish review and return
//  to the welcome menu (same action as the former top-left ×).
//
//  The top banner is a static **Map overview** label (shown from `GameRootView` after
//  victory/defeat).
//

import SwiftUI

struct OpponentSetupMapView: View {
    let frozenBoard: Board
    let onClose: () -> Void

    private let bannerTitle = "Map overview"

    var body: some View {
        GeometryReader { geo in
            let tileWidth = floor(BoardGridMetrics.tileWidth(forContainerWidth: geo.size.width))

            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(0..<BoardGridMetrics.rowCount, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<BoardGridMetrics.columnCount, id: \.self) { col in
                                let pos = GridPosition(row, col)
                                TileView(
                                    model: makeModel(for: pos),
                                    tileSize: tileWidth,
                                    onTap: {}
                                )
                                .equatable()
                            }
                        }
                        .frame(height: tileWidth)
                    }
                }
                .padding(.horizontal, BoardGridMetrics.horizontalPadding)
                // Tiles must read as a static map, not as buttons. Disabling
                // the underlying button (`isDisabled: true`) would dim the
                // artwork — instead we keep `isDisabled: false` for full
                // brightness and stop hit-testing the grid here so taps
                // never reach a tile in the first place. The ScrollView's
                // vertical drag gesture still receives scroll; a tap is handled
                // by `simultaneousGesture` on the outer container.
                .allowsHitTesting(false)
            }
            .scrollIndicators(.visible)
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(alignment: .top) {
            Text(bannerTitle)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .foregroundStyle(.white)
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.55))
                .allowsHitTesting(false)
        }
        .simultaneousGesture(
            TapGesture().onEnded { onClose() }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(bannerTitle)
        .accessibilityHint("Tap anywhere to return to the menu.")
    }

    /// Neutral map cells: no overlays, no ghost dim, no disabled-button
    /// dimming. Tap actions are no-ops (`onTap: {}`) so the map is read-only,
    /// but `isDisabled: false` keeps the artwork at full brightness instead
    /// of the muted half-opacity SwiftUI gives to a disabled plain Button.
    /// Opponent-zone unit art is suppressed when
    /// **`!GridStrikeDebug.showAllEnemyObjectsOnPostGameMap`** (DEBUG only).
    private func makeModel(for pos: GridPosition) -> TileRenderModel {
        let isOpponentZone = pos.row <= Zones.coastguardEnemyRow

#if DEBUG
        let obscureEnemyPieces = isOpponentZone && !GridStrikeDebug.showAllEnemyObjectsOnPostGameMap
#else
        let obscureEnemyPieces = false
#endif

        let mark: Unit? = obscureEnemyPieces ? nil : frozenBoard.unit(at: pos)

        let background: TileBackground = {
            if let mark = mark { return .unit(mark) }
            return Zones.isWater(pos.row) ? .water : .grass
        }()

        let bomberRotation: Double = {
            guard mark == .bomber else { return 0 }
            return frozenBoard.bomberRotations[pos] ?? 0
        }()

        return TileRenderModel(
            position: pos,
            background: background,
            bomberRotationDegrees: bomberRotation,
            dim: .none,
            offCoastguardFocusRow: false,
            northStrikeOverlay: nil,
            dropOverlay: nil,
            dropOverlayScale: 1,
            missileHitPulseToken: nil,
            waterWreck: nil,
            wreckRotationDegrees: 0,
            border: .plain,
            isLastTurnHighlight: false,
            isDisabled: false
        )
    }
}
