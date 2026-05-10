//
//  MissileDemo.swift
//  GridStrike Watch App
//
//  Scripted trailer: hand from row 12 (1.5 tiles right of col 2) → upper missile (outline after delay), scroll to
//  enemy zone + strike X — tap anywhere to dismiss.
//

import SwiftUI
import WatchKit

struct MissileDemo: View {
    let onClose: () -> Void

    private static let bottomCurveTapReserve: CGFloat = 10
    private static let handSize: CGFloat = 48
    /// First-frame home-zone position: nudge the hand down so the asset reads right on cold start.
    private static let initialHandExtraOffsetY: CGFloat = 50
    private static let handFlyToHomeMissileDuration: TimeInterval = 1.75
    private static let outlineDelayAfterHandAtMissile: TimeInterval = 1
    private static let scrollToTopDuration: TimeInterval = 2

    // MARK: - Demo layout (row, col)

    private static let demoHQ = GridPosition(10, 3)
    private static let demoMissile1 = GridPosition(11, 0)
    private static let demoMissile2 = GridPosition(9, 1)
    private static let demoBomber = GridPosition(12, 2)
    private static let demoCoastguard = GridPosition(8, 3)
    private static let enemyMissileAnchor = GridPosition(2, 3)
    /// Vertical / reference column for first hand pose (row 12, col 2 — bomber). Hand image is
    /// shifted **`handStartHorizontalOffsetTiles`** to the right of that column centre.
    private static let handStartTile = GridPosition(12, 2)
    private static let handStartHorizontalOffsetTiles: CGFloat = 1.5

    @State private var didStart = false
    @State private var showHand = false
    @State private var handPosition = CGPoint.zero
    @State private var highlightPlayerMissile = false
    @State private var highlightEnemyAnchor = false
    @State private var missileImpactOverlays: [GridPosition: ExplosionKind] = [:]
    @State private var showHitBanner = false

    var body: some View {
        GeometryReader { geo in
            let tileWidth = BoardGridMetrics.tileWidth(forContainerWidth: geo.size.width)
            let bottomInset = geo.safeAreaInsets.bottom
            let pullDown = max(0, bottomInset - Self.bottomCurveTapReserve)
            let tiles = makeTileMap(
                highlightPlayerMissile: highlightPlayerMissile,
                highlightEnemyAnchor: highlightEnemyAnchor,
                missileImpactOverlays: missileImpactOverlays
            )

            ZStack(alignment: .topLeading) {
                Color.black.ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            ForEach(0..<BoardGridMetrics.rowCount, id: \.self) { row in
                                HStack(spacing: 0) {
                                    ForEach(0..<BoardGridMetrics.columnCount, id: \.self) { col in
                                        let pos = GridPosition(row, col)
                                        if let model = tiles[pos] {
                                            TileView(
                                                model: model,
                                                tileSize: tileWidth,
                                                onTap: {}
                                            )
                                            .equatable()
                                        }
                                    }
                                }
                                .frame(height: tileWidth)
                                .id("row-\(row)")

                                if row == 5 {
                                    Color.clear
                                        .frame(height: 0)
                                        .id(Zones.opponentDefenseSeamID)
                                }
                                if row == 7 {
                                    Color.clear
                                        .frame(height: 0)
                                        .id(Zones.playerDefenseSeamID)
                                }
                            }
                        }
                        .padding(.horizontal, BoardGridMetrics.horizontalPadding)
                        .padding(.bottom, -pullDown)
                    }
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
                    .allowsHitTesting(false)
                    .onAppear {
                        guard !didStart else { return }
                        didStart = true
                        let bottomId = "row-\(BoardGridMetrics.rowCount - 1)"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            proxy.scrollTo(bottomId, anchor: .bottom)
                            Task {
                                await runSequence(
                                    proxy: proxy,
                                    size: geo.size,
                                    pullDown: pullDown
                                )
                            }
                        }
                    }
                }

                // Same placement + typography as `InstructionBanner` / “Start attack!”
                VStack(spacing: 0) {
                    if showHitBanner {
                        Text("Missile destroyed!")
                            .font(.caption.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .foregroundStyle(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.55))
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)

                if showHand {
                    Image("hand")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: Self.handSize, height: Self.handSize)
                        .shadow(color: .black.opacity(0.45), radius: 3, y: 2)
                        .position(handPosition)
                        .allowsHitTesting(false)
                }

                // Top layer: dismiss on tap anywhere (tiles/hand/banner pass hits through).
                Color.clear
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture { onClose() }
                    .accessibilityLabel("Dismiss missile demo")
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Scripted timeline

    @MainActor
    private func runSequence(
        proxy: ScrollViewProxy,
        size: CGSize,
        pullDown: CGFloat
    ) async {
        try? await Task.sleep(for: .seconds(1))

        // Start: same row / vertical alignment as row 12 col 2, but hand sits 1.5 tiles right of col 2 centre.
        let tw = BoardGridMetrics.tileWidth(forContainerWidth: size.width)
        let handAtStartTile = Self.handCentreWithTopOfFrameAtTileLowerThird(
            row: Self.handStartTile.row,
            col: Self.handStartTile.col,
            viewportSize: size,
            pullDown: pullDown,
            scrollBottomPinned: true
        )
        let startPos = CGPoint(
            x: handAtStartTile.x + Self.handStartHorizontalOffsetTiles * tw,
            y: handAtStartTile.y + Self.initialHandExtraOffsetY
        )

        let handOnUpperMissile = Self.handCentreWithTopOfFrameAtTileLowerThird(
            row: Self.demoMissile2.row,
            col: Self.demoMissile2.col,
            viewportSize: size,
            pullDown: pullDown,
            scrollBottomPinned: true
        )
        let homeMissilePos = CGPoint(
            x: handOnUpperMissile.x,
            y: handOnUpperMissile.y + Self.initialHandExtraOffsetY
        )

        showHand = true
        handPosition = startPos

        withAnimation(.easeInOut(duration: Self.handFlyToHomeMissileDuration)) {
            handPosition = homeMissilePos
        }
        try? await Task.sleep(for: .seconds(Self.handFlyToHomeMissileDuration))

        try? await Task.sleep(for: .seconds(Self.outlineDelayAfterHandAtMissile))
        highlightPlayerMissile = true
        Self.playOutlineTapHaptic()

        try? await Task.sleep(for: .seconds(1))
        // Keep orange on the home missile through the upcoming scroll (don’t clear yet).

        // Final hand position (enemy zone, scroll pinned to top) — lower-third alignment on missile anchor tile.
        let handAtAnchor = Self.handCentreWithTopOfFrameAtTileLowerThird(
            row: Self.enemyMissileAnchor.row,
            col: Self.enemyMissileAnchor.col,
            viewportSize: size,
            pullDown: pullDown,
            scrollBottomPinned: false
        )

        // Scroll and hand move together: straight-line motion in screen space over the same duration.
        withAnimation(.linear(duration: Self.scrollToTopDuration)) {
            proxy.scrollTo("row-0", anchor: .top)
            handPosition = handAtAnchor
        }
        try? await Task.sleep(for: .seconds(Self.scrollToTopDuration))

        // Pause with hand on enemy tile before the scripted tap (outline + impact).
        try? await Task.sleep(for: .seconds(1))

        highlightPlayerMissile = false
        highlightEnemyAnchor = true
        Self.playOutlineTapHaptic()

        // Missile X / cross footprint — matches `Rules.missilePositions`; NW diagonal is a hit.
        let salvo = Rules.missilePositions(anchor: Self.enemyMissileAnchor, attacker: .player)
        let nw = GridPosition(Self.enemyMissileAnchor.row - 1, Self.enemyMissileAnchor.col - 1)
        var overlays: [GridPosition: ExplosionKind] = [:]
        salvo.forEach { pos in
            overlays[pos] = (pos == nw) ? .hit : .miss
        }
        withAnimation(.easeOut(duration: 0.2)) {
            missileImpactOverlays = overlays
            showHitBanner = true
        }
    }

    /// Light tactile “tap” when orange selection outlines appear (watch speaker silent).
    private static func playOutlineTapHaptic() {
        WKInterfaceDevice.current().play(.click)
    }

    // MARK: - Geometry (matches `BoardView` scroll padding)

    /// Centres the hand asset so the **top edge** of its fixed `handSize` square sits exactly
    /// on the **top edge of the tile's lower third** (the horizontal line at ⅔ down the cell).
    /// The upper opaque finger art in `hand.png` then lands in that bottom band. Horizontal:
    /// column centre.
    private static func handCentreWithTopOfFrameAtTileLowerThird(
        row: Int,
        col: Int,
        viewportSize: CGSize,
        pullDown: CGFloat,
        scrollBottomPinned: Bool
    ) -> CGPoint {
        let tw = BoardGridMetrics.tileWidth(forContainerWidth: viewportSize.width)
        let hp = BoardGridMetrics.horizontalPadding
        let cx = hp + CGFloat(col) * tw + tw / 2
        let yTopOfLowerThirdInContent = CGFloat(row) * tw + (2.0 / 3.0) * tw
        let contentH = CGFloat(Zones.rowCount) * tw + pullDown
        let offsetY = scrollBottomPinned ? max(0, contentH - viewportSize.height) : 0
        let yTopViewport = yTopOfLowerThirdInContent - offsetY
        let yCentre = yTopViewport + handSize / 2
        return CGPoint(x: cx, y: yCentre)
    }

    // MARK: - Tile map

    private func makeTileMap(
        highlightPlayerMissile: Bool,
        highlightEnemyAnchor: Bool,
        missileImpactOverlays: [GridPosition: ExplosionKind]
    ) -> [GridPosition: TileRenderModel] {
        let marks: [GridPosition: Unit] = [
            Self.demoHQ: .headquarters,
            Self.demoMissile1: .missile,
            Self.demoMissile2: .missile,
            Self.demoBomber: .bomber,
            Self.demoCoastguard: .coastguard,
        ]

        var tiles: [GridPosition: TileRenderModel] = [:]
        for row in Zones.allRows {
            for col in Zones.allColumns {
                let pos = GridPosition(row, col)
                let bg: TileBackground = {
                    if let u = marks[pos] { return .unit(u) }
                    return Zones.isWater(pos.row) ? .water : .grass
                }()

                let highlight =
                    (highlightPlayerMissile && pos == Self.demoMissile2)
                    || (highlightEnemyAnchor && pos == Self.enemyMissileAnchor)

                tiles[pos] = TileRenderModel(
                    position: pos,
                    background: bg,
                    bomberRotationDegrees: 0,
                    dim: .none,
                    offCoastguardFocusRow: false,
                    northStrikeOverlay: nil,
                    dropOverlay: missileImpactOverlays[pos],
                    waterWreck: nil,
                    wreckRotationDegrees: 0,
                    border: .plain,
                    isLastTurnHighlight: highlight,
                    isDisabled: false
                )
            }
        }
        return tiles
    }
}

#if DEBUG
#Preview {
    MissileDemo(onClose: {})
}
#endif
