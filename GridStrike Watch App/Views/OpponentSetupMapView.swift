//
//  OpponentSetupMapView.swift
//  GridStrike Watch App
//
//  Post-game frozen snapshot at round start (`boardAtPlayStart`). Layout deliberately
//  mirrors `BoardView` (same tile width, no extra top/bottom gutter, same horizontal
//  padding) so the map renders in the **original grid colours** instead of looking
//  shrunken or ghosted inside a dark frame. Dismiss uses `PostGameCircularDismissButton`
//  (top-left ×), matching Victory/Defeat → map navigation.
//

import SwiftUI

struct OpponentSetupMapView: View {
    let frozenBoard: Board
    let onClose: () -> Void

    var body: some View {
        GeometryReader { geo in
            let tileWidth = BoardGridMetrics.tileWidth(forContainerWidth: geo.size.width)
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
                // own pan gesture sits *outside* this `.allowsHitTesting`
                // boundary so vertical scrolling continues to work, and the
                // close button is a sibling overlay so it stays interactive.
                .allowsHitTesting(false)
            }
            .scrollIndicators(.visible)
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            PostGameCircularDismissButton(
                accessibilityLabel: "Close and return to menu",
                action: onClose
            )
        }
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
            waterWreck: nil,
            wreckRotationDegrees: 0,
            border: .plain,
            isLastTurnHighlight: false,
            isDisabled: false
        )
    }
}
