//
//  Demo_Grenade.swift
//  GridStrike Watch App
//
//  Grenade trailer: 1s delay (like Demo_Bomber), hand at row 12 col 2, scroll to row 3 col 2; orange outline, ExplosionMiss, then 1s later “No target hit!”.
//

import SwiftUI
import WatchKit

struct Demo_Grenade: View {
    let onClose: () -> Void

    private static let bottomCurveTapReserve: CGFloat = 10
    private static let handSize: CGFloat = 48
    private static let initialHandExtraOffsetY: CGFloat = 50

    /// Same board unit marks as the other scripted demos.
    private static let demoHQ = GridPosition(10, 3)
    private static let demoMissile1 = GridPosition(11, 0)
    private static let demoMissile2 = GridPosition(9, 1)
    private static let demoBomber = GridPosition(12, 2)
    private static let demoCoastguard = GridPosition(8, 3)

    /// Same first-frame reference as `Demo_Bomber` (row 12 col 2, shifted right of column centre).
    private static let handStartTile = GridPosition(12, 2)
    private static let handStartHorizontalOffsetTiles: CGFloat = 1.5

    /// Destination on opponent grass while scrolling.
    private static let grenadeHandTarget = GridPosition(3, 2)

    /// Scroll + hand motion to `grenadeHandTarget`.
    private static let scrollHandToTargetDuration: TimeInterval = 2

    /// Dwell on destination before scripted miss overlay + banner.
    private static let dwellAtDestinationBeforeMiss: TimeInterval = 1

    /// Orange outline on target tile before `ExplosionMiss` appears.
    private static let grenadeTargetOutlineBeforeMissDuration: TimeInterval = 0.35

    /// Pause after `ExplosionMiss` before the banner copy.
    private static let delayBeforeMissBanner: TimeInterval = 1

    @State private var didStart = false
    /// Hides the scroll content until the initial bottom pin scroll runs (avoids a top→bottom flash).
    @State private var isBoardVisible = false
    /// Circular close control appears only after the scripted beat finishes.
    @State private var showDemoFinished = false
    @State private var showHand = false
    @State private var handPosition = CGPoint.zero
    @State private var showGrenadeMissImpact = false
    @State private var showGrenadeMissBanner = false
    @State private var showGrenadeTargetOutline = false

    var body: some View {
        GeometryReader { geo in
            let tileWidth = BoardGridMetrics.tileWidth(forContainerWidth: geo.size.width)
            let bottomInset = geo.safeAreaInsets.bottom
            let pullDown = max(0, bottomInset - Self.bottomCurveTapReserve)
            let tiles = makeTileMap(
                showGrenadeMissOnTarget: showGrenadeMissImpact,
                outlineGrenadeTarget: showGrenadeTargetOutline
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
                    .opacity(isBoardVisible ? 1 : 0)
                    .onAppear {
                        guard !didStart else { return }
                        didStart = true
                        let bottomId = "row-\(BoardGridMetrics.rowCount - 1)"
                        DispatchQueue.main.async {
                            var t = Transaction()
                            t.disablesAnimations = true
                            withTransaction(t) {
                                proxy.scrollTo(bottomId, anchor: .bottom)
                            }
                            DispatchQueue.main.async {
                                isBoardVisible = true
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
                }

                VStack(spacing: 0) {
                    if showGrenadeMissBanner {
                        Text("No target hit!")
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

                Color.clear
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture { onClose() }
                    .accessibilityLabel("Dismiss grenade demo")
            }
            .overlay(alignment: .topLeading) {
                DemoTopCloseButton(
                    isVisible: showDemoFinished,
                    onClose: onClose,
                    screenHeight: geo.size.height
                )
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    @MainActor
    private func runSequence(
        proxy: ScrollViewProxy,
        size: CGSize,
        pullDown: CGFloat
    ) async {
        showDemoFinished = false
        showGrenadeMissImpact = false
        showGrenadeMissBanner = false
        showGrenadeTargetOutline = false

        try? await Task.sleep(for: .seconds(1))

        let tw = BoardGridMetrics.tileWidth(forContainerWidth: size.width)

        let contentH = CGFloat(Zones.rowCount) * tw + pullDown
        let maxScroll = max(0, contentH - size.height)

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

        showHand = true
        handPosition = startPos

        let scrollTop = Self.clampedScrollOffsetCenteringRow(
            rowIndex: Self.grenadeHandTarget.row,
            tileWidth: tw,
            viewportHeight: size.height,
            maxScroll: maxScroll
        )

        let endPos = Self.handCentreAtTileLowerThird(
            row: Self.grenadeHandTarget.row,
            col: Self.grenadeHandTarget.col,
            viewportSize: size,
            scrollTopContentY: scrollTop
        )

        withAnimation(.linear(duration: Self.scrollHandToTargetDuration)) {
            proxy.scrollTo("row-\(Self.grenadeHandTarget.row)", anchor: .center)
            handPosition = endPos
        }

        try? await Task.sleep(for: .seconds(Self.scrollHandToTargetDuration))

        try? await Task.sleep(for: .seconds(Self.dwellAtDestinationBeforeMiss))

        Self.playOutlineTapHaptic()
        withAnimation(.easeOut(duration: 0.15)) {
            showGrenadeTargetOutline = true
        }

        try? await Task.sleep(for: .seconds(Self.grenadeTargetOutlineBeforeMissDuration))

        withAnimation(.easeOut(duration: 0.2)) {
            showGrenadeTargetOutline = false
            showGrenadeMissImpact = true
        }

        try? await Task.sleep(for: .seconds(Self.delayBeforeMissBanner))

        withAnimation(.easeOut(duration: 0.2)) {
            showGrenadeMissBanner = true
        }

        showDemoFinished = true
    }

    /// Light tactile “tap” when orange selection outlines appear (watch speaker silent).
    private static func playOutlineTapHaptic() {
        WKInterfaceDevice.current().play(.click)
    }

    /// Content offset **Y** with `rowIndex` centred vertically (clamped).
    private static func clampedScrollOffsetCenteringRow(
        rowIndex: Int,
        tileWidth tw: CGFloat,
        viewportHeight: CGFloat,
        maxScroll: CGFloat
    ) -> CGFloat {
        let rowMidY = CGFloat(rowIndex) * tw + tw / 2
        let raw = rowMidY - viewportHeight / 2
        return min(max(0, raw), maxScroll)
    }

    /// Same geometry as `Demo_Bomber` for the home-zone hand pose (scroll pinned to bottom of content).
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

    /// Lower-third hand anchor when content top is **`scrollTopContentY`** below the viewport top.
    private static func handCentreAtTileLowerThird(
        row: Int,
        col: Int,
        viewportSize: CGSize,
        scrollTopContentY O: CGFloat
    ) -> CGPoint {
        let tw = BoardGridMetrics.tileWidth(forContainerWidth: viewportSize.width)
        let hp = BoardGridMetrics.horizontalPadding
        let cx = hp + CGFloat(col) * tw + tw / 2
        let yTopOfLowerThirdInContent = CGFloat(row) * tw + (2.0 / 3.0) * tw
        let yTopViewport = yTopOfLowerThirdInContent - O
        let yCentre = yTopViewport + handSize / 2
        return CGPoint(x: cx, y: yCentre)
    }

    private func makeTileMap(
        showGrenadeMissOnTarget: Bool,
        outlineGrenadeTarget: Bool
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

                let dropOverlay: ExplosionKind? = {
                    if pos == GridPosition(0, 1) { return .hit }
                    if pos == GridPosition(1, 1) || pos == GridPosition(2, 1) { return .miss }
                    if showGrenadeMissOnTarget && pos == Self.grenadeHandTarget { return .miss }
                    return nil
                }()

                let orangeTargetOutline =
                    outlineGrenadeTarget && pos == Self.grenadeHandTarget && dropOverlay == nil

                tiles[pos] = TileRenderModel(
                    position: pos,
                    background: bg,
                    bomberRotationDegrees: 0,
                    dim: .none,
                    offCoastguardFocusRow: false,
                    northStrikeOverlay: nil,
                    dropOverlay: dropOverlay,
                    dropOverlayScale: 1,
                    waterWreck: nil,
                    wreckRotationDegrees: 0,
                    border: .plain,
                    isLastTurnHighlight: orangeTargetOutline,
                    isDisabled: false
                )
            }
        }
        return tiles
    }
}

#if DEBUG
#Preview {
    Demo_Grenade(onClose: {})
}
#endif
