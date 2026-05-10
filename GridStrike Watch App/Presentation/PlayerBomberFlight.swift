//
//  PlayerBomberFlight.swift
//  GridStrike Watch App
//
//  Same motion model as `Demo_Bomber`: mid-board scroll pin, linear scroll to row 0 while
//  `bomber_transparent` crosses the viewport, with impact times from `tauWhenCrossingRow`.
//

import SwiftUI

struct LiveBomberFlightSpec: Equatable {
    let startTime: Date
    let duration: TimeInterval
    let cx: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let halfHeight: CGFloat
    /// Content Y at viewport top at flight start (after pinning row 6 bottom).
    let O0: CGFloat
}

enum LivePlayerBomberFlight {
    static let scrollToMidBoardDuration: TimeInterval = 1.1
    static let flightDuration: TimeInterval = 3.35
    static let spriteTileFactor: CGFloat = 1.22

    /// Scroll offset when the bottom of `rowIndex` aligns with the viewport bottom.
    static func clampedScrollOffsetPinningBottomOfRow(
        rowIndex: Int,
        tileWidth tw: CGFloat,
        viewportHeight: CGFloat,
        maxScroll: CGFloat
    ) -> CGFloat {
        let yBottom = CGFloat(rowIndex + 1) * tw
        let raw = yBottom - viewportHeight
        return min(max(0, raw), maxScroll)
    }

    /// Time within `[0, T]` when the plane’s vertical path crosses the tile midline, accounting for scroll `O0 → O1`.
    static func tauWhenCrossingRow(
        row: Int,
        tileWidth tw: CGFloat,
        O0: CGFloat,
        O1: CGFloat,
        startY: CGFloat,
        endY: CGFloat,
        T: TimeInterval
    ) -> TimeInterval {
        let yTileMid = CGFloat(row) * tw + tw / 2
        let num = yTileMid - O0 - startY
        let den = (endY - startY) + (O1 - O0)
        guard abs(den) > 0.5 else {
            return T * TimeInterval((yTileMid - startY) / (endY - startY))
        }
        let p = num / den
        return T * TimeInterval(max(0, min(1, p)))
    }

    /// Runs scroll + sprite timeline and fires `advanceBombDrop` at demo-aligned beats (player only).
    @MainActor
    static func run(
        store: GameStore,
        proxy: ScrollViewProxy,
        viewportSize: CGSize,
        pullDown: CGFloat,
        updateFlightSpec: @MainActor (LiveBomberFlightSpec?) -> Void
    ) async {
        guard store.state.currentTurn == .player else { return }
        guard case .play(.bombingDrops(_, let anchor, _)) = store.state.phase else { return }

        let tw = BoardGridMetrics.tileWidth(forContainerWidth: viewportSize.width)
        let hp = BoardGridMetrics.horizontalPadding
        let col = anchor.col
        let cx = hp + CGFloat(col) * tw + tw / 2
        let sprite = tw * Self.spriteTileFactor
        let half = sprite / 2
        let startY = viewportSize.height + half + 28
        let endY = -half - 28
        let T = Self.flightDuration

        let drops = Rules.bombingPositions(target: anchor, attacker: .player)

        withAnimation(.easeInOut(duration: Self.scrollToMidBoardDuration)) {
            proxy.scrollTo("row-6", anchor: .bottom)
        }
        try? await Task.sleep(for: .seconds(Self.scrollToMidBoardDuration))

        guard !Task.isCancelled else { return }
        guard store.state.currentTurn == .player,
              case .play(.bombingDrops(_, let anchor2, _)) = store.state.phase,
              anchor2 == anchor else { return }

        let contentH = CGFloat(Zones.rowCount) * tw + pullDown
        let maxScroll = max(0, contentH - viewportSize.height)
        let O0 = Self.clampedScrollOffsetPinningBottomOfRow(
            rowIndex: 6,
            tileWidth: tw,
            viewportHeight: viewportSize.height,
            maxScroll: maxScroll
        )
        let O1: CGFloat = 0

        let spec = LiveBomberFlightSpec(
            startTime: Date(),
            duration: T,
            cx: cx,
            startY: startY,
            endY: endY,
            halfHeight: half,
            O0: O0
        )
        updateFlightSpec(spec)

        withAnimation(.linear(duration: T)) {
            proxy.scrollTo("row-0", anchor: .top)
        }

        var previousTau: TimeInterval = 0
        for pos in drops {
            guard !Task.isCancelled else { break }
            let targetTau = Self.tauWhenCrossingRow(
                row: pos.row,
                tileWidth: tw,
                O0: O0,
                O1: O1,
                startY: startY,
                endY: endY,
                T: T
            )
            let delta = max(0, targetTau - previousTau)
            previousTau = targetTau
            if delta > 0 {
                try? await Task.sleep(for: .seconds(delta))
            }
            guard !Task.isCancelled else { break }
            store.send(.advanceBombDrop)
        }

        let remaining = max(0, T - previousTau)
        if remaining > 0 {
            try? await Task.sleep(for: .seconds(remaining))
        }

        updateFlightSpec(nil)
    }
}
