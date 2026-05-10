//
//  OpponentSetupMapView.swift
//  GridStrike Watch App
//
//  Post-game frozen snapshot at round start (`boardAtPlayStart`). Layout deliberately
//  mirrors `BoardView` (same tile width, no extra top/bottom gutter, same horizontal
//  padding) so the map renders in the **original grid colours** instead of looking
//  shrunken or ghosted inside a dark frame. The close button rides as a non-flow
//  overlay anchored to the top-left corner — sized for a comfortable fingertip
//  target and nudged up into the safe-area top inset so it sits high on screen.
//

import SwiftUI

struct OpponentSetupMapView: View {
    let frozenBoard: Board
    let onClose: () -> Void

    /// Diameter of the floating close-X. Sized for an easy fingertip target
    /// on the 41/45/49 mm watches; the visual circle and the hit region both
    /// scale with this value.
    private static let closeButtonSize: CGFloat = 40
    /// Vertical nudge applied to the close button. Pulls the X up into the
    /// safe-area top inset so it sits high on the screen as a proper corner
    /// control instead of floating below the watch's status chrome.
    private static let closeButtonTopOffset: CGFloat = -6
    /// Tiny inset from the leading edge so the button clears the watch's
    /// curved corner — without this, the left side of the circle gets
    /// cropped by the bezel and taps near that edge are swallowed by the
    /// system swipe-back gesture instead of hitting the button.
    private static let closeButtonLeadingInset: CGFloat = 2

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
            // Floating close button — pinned to the top-left of the screen
            // and nudged up into the safe-area top inset so it reads as a
            // proper corner control rather than floating inside the grid.
            // Hit-testing uses a square `contentShape` covering the whole
            // 40×40 frame (instead of just the visible circle) so finger
            // taps at the curved corner still register, and the leading
            // inset keeps the circle clear of the bezel where watchOS would
            // otherwise hijack the touch for its swipe-back gesture.
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: Self.closeButtonSize, height: Self.closeButtonSize)
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.25))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, Self.closeButtonLeadingInset)
            .padding(.top, Self.closeButtonTopOffset)
            .accessibilityLabel("Close")
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
