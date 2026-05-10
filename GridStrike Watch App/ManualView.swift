//
//  ManualView.swift
//  GridStrike Watch App
//
//  Reference card with a board preview. Layout:
//   • Floating close X in the top-left (matches HelpView's affordance side).
//   • Two-column-style sections separated by thin red dividers.
//   • Board preview uses a slightly inset tile size so the orange zone
//     outlines never clip past the right edge of the watch.
//   • Zone bands (rows 0–5 enemy, 6–7 neutral, 8–13 home) are outlined in
//     orange with bigger centered labels. The outline is drawn with
//     `strokeBorder` so the full stroke (and every tile inside it) stays
//     visible inside the grid bounds.
//

import SwiftUI

struct ManualView: View {
    /// Invoked when the player taps the close X. The caller is responsible
    /// for both hiding the manual *and* advancing the game (the manual is
    /// never re-shown automatically; the X behaves as a "start the game now"
    /// button that happens to also close this screen).
    let onClose: () -> Void

    @AppStorage("showInGameTips") var showInGameTips = true

    /// Diameter of the floating close-X. Sized for an easy fingertip target
    /// on the 41/45/49 mm watches; the visual circle and the hit region both
    /// scale with this value, and the top spacer that reserves headroom for
    /// the X tracks it automatically.
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
    private static let outerHorizontalPadding: CGFloat = 10
    private static let zoneCornerRadius: CGFloat = 10
    /// Orange zone outline width. Picked thick enough to read clearly against
    /// busy tile art while still leaving the tiles inside fully visible.
    private static let zoneOutlineWidth: CGFloat = 3
    private static let zoneOutlineColor: Color = .orange

    /// Manual-only zone grouping (visual guide): rows 0–5 enemy, 6–7 neutral, 8–13 home.
    private enum ManualZone {
        static let enemyRowStart = 0
        static let enemyRowCount = 6
        static let neutralRowStart = 6
        static let neutralRowCount = 2
        static let homeRowStart = 8
        static let homeRowCount = 6
    }

    var body: some View {
        GeometryReader { geo in
            // Reserve the manual's outer horizontal gutter before computing
            // tile width so the resulting grid (and its red outline stroke)
            // sits comfortably inside the watch's safe area instead of
            // bleeding off the right edge.
            let usableWidth = max(0, geo.size.width - Self.outerHorizontalPadding * 2)
            let tileWidth = BoardGridMetrics.tileWidth(forContainerWidth: usableWidth)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Spacer().frame(height: Self.closeButtonSize + 4)

                    sectionTitle("Goal")
                    Text("Destroy the enemy headquarters.")
                        .font(.footnote)

                    sectionTitle("The Board")
                    boardPreview(tileWidth: tileWidth)
                        .frame(maxWidth: .infinity, alignment: .center)

                    sectionTitle("Setup")
                    bulletList([
                        "Place HQ, Missiles & Bomber in Home Zone. Space them out!",
                        "Place Coastguard on Coast Zone tile."
                    ])

                    sectionTitle("Weapons")
                    bulletList([
                        "2 Missiles: 5-tile X-strike",
                        "1 Bomber: 3-tile vertical strike",
                        "Coastguard: Intercepts air strikes",
                        "Unlimited Grenades"
                    ])

                    sectionTitle("Pro Tips")
                    bulletList([
                        "Coastguards only fear Grenades.",
                        "Avoid edges with Missiles.",
                        "Aim low with Bombers.",
                        "Don't hit destroyed tiles."
                    ])

                    HStack(spacing: 8) {
                        Text("In-game Tips")
                            .font(.footnote)
                        Spacer(minLength: 0)
                        Toggle("", isOn: $showInGameTips)
                            .labelsHidden()
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, Self.outerHorizontalPadding)
                .padding(.bottom, 12)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            // Floating close button — pinned to the top-left of the screen
            // and nudged up into the safe-area top inset so it reads as a
            // proper corner control rather than floating inside the manual.
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
            .accessibilityLabel("Close manual and start game")
        }
    }

    // MARK: - Sections

    private func sectionTitle(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.caption.weight(.bold))
                .foregroundStyle(.red)
            Rectangle()
                .fill(Color.red.opacity(0.55))
                .frame(height: 0.5)
        }
        .padding(.top, 2)
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(items, id: \.self) { line in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•")
                        .foregroundStyle(.red)
                    Text(line)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.footnote)
            }
        }
    }

    // MARK: - Board preview

    @ViewBuilder
    private func boardPreview(tileWidth: CGFloat) -> some View {
        let gridW = tileWidth * CGFloat(BoardGridMetrics.columnCount)

        ZStack(alignment: .topLeading) {
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

            zoneCap(
                tileWidth: tileWidth,
                gridWidth: gridW,
                rowStart: ManualZone.enemyRowStart,
                rowCount: ManualZone.enemyRowCount,
                label: "Enemy zone"
            )
            zoneCap(
                tileWidth: tileWidth,
                gridWidth: gridW,
                rowStart: ManualZone.neutralRowStart,
                rowCount: ManualZone.neutralRowCount,
                label: "Neutral zone"
            )
            zoneCap(
                tileWidth: tileWidth,
                gridWidth: gridW,
                rowStart: ManualZone.homeRowStart,
                rowCount: ManualZone.homeRowCount,
                label: "Home zone"
            )
        }
        .frame(width: gridW, height: tileWidth * CGFloat(BoardGridMetrics.rowCount))
        .allowsHitTesting(false)
    }

    /// Rounded outline around the tile rows in a zone. Uses `strokeBorder`
    /// so the full stroke sits inside the grid bounds (never clipped at the
    /// edges) and the tiles underneath remain fully visible. A black capsule
    /// pill behind the label keeps the zone name readable against tile art.
    private func zoneCap(
        tileWidth: CGFloat,
        gridWidth: CGFloat,
        rowStart: Int,
        rowCount: Int,
        label: String
    ) -> some View {
        let height = CGFloat(rowCount) * tileWidth
        let yOffset = CGFloat(rowStart) * tileWidth
        // Bigger zone labels — scale with tile size, capped so the text never
        // overruns the band even on the smaller 2-row neutral strip.
        let fontSize = max(13, min(17, tileWidth * 0.55))

        return ZStack {
            RoundedRectangle(cornerRadius: Self.zoneCornerRadius)
                .strokeBorder(Self.zoneOutlineColor, lineWidth: Self.zoneOutlineWidth)

            Text(label)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 2, y: 1)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(Color.black.opacity(0.55))
                )
        }
        .frame(width: gridWidth, height: height)
        .offset(y: yOffset)
    }

    private func makeModel(for pos: GridPosition) -> TileRenderModel {
        let background: TileBackground = Zones.isWater(pos.row) ? .water : .grass
        return TileRenderModel(
            position: pos,
            background: background,
            bomberRotationDegrees: 0,
            dim: .none,
            offCoastguardFocusRow: false,
            northStrikeOverlay: nil,
            dropOverlay: nil,
            waterWreck: nil,
            wreckRotationDegrees: 0,
            border: .plain,
            isLastTurnHighlight: false,
            isDisabled: false
        )
    }
}
