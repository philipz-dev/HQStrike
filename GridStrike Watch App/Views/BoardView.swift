//
//  BoardView.swift
//  GridStrike Watch App
//
//  Scrollable 14×5 grid. Reads only from the precomputed snapshot — every tap is
//  forwarded as `Action.tap(GridPosition)`. Reacts to `state.scrollRequest` so the
//  reducer can pull the camera to whichever half is in the spotlight (the
//  opponent's grass when the player is up, the player's grass when the AI is up).
//
//  Player bomber strikes: after confirm, `LivePlayerBomberFlight` scrolls + overlays
//  `bomber_transparent` and sends `advanceBombDrop` on demo-aligned timings.
//

import SwiftUI

struct BoardView: View {
    let snapshot: BoardSnapshot
    @Environment(GameStore.self) private var store
    @State private var didInitialScroll = false
    @State private var liveBomberFlight: LiveBomberFlightSpec?
    @State private var playerBomberFlightToken: UUID?

    private static let rows = BoardGridMetrics.rowCount
    private static let bottomCurveTapReserve: CGFloat = 10

    private var bottomRowScrollId: String { "row-\(Self.rows - 1)" }

    /// Stable for the whole player bomb run (dropsApplied advances don’t change src/tgt).
    private var playerBomberRunIdentity: String? {
        guard store.state.currentTurn == .player,
              case .play(.bombingDrops(let src, let tgt, _)) = store.state.phase else { return nil }
        return "\(src.row),\(src.col)-\(tgt.row),\(tgt.col)"
    }

    var body: some View {
        let scrollRequest = store.state.scrollRequest

        GeometryReader { geo in
            let tileSize = BoardGridMetrics.tileWidth(forContainerWidth: geo.size.width)
            let bottomInset = geo.safeAreaInsets.bottom
            let pullDown = max(0, bottomInset - Self.bottomCurveTapReserve)

            ScrollViewReader { proxy in
                ZStack(alignment: .topLeading) {
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            ForEach(0..<Self.rows, id: \.self) { row in
                                HStack(spacing: 0) {
                                    ForEach(0..<BoardGridMetrics.columnCount, id: \.self) { col in
                                        let pos = GridPosition(row, col)
                                        if let model = snapshot.tiles[pos] {
                                            TileView(
                                                model: model,
                                                tileSize: tileSize,
                                                onTap: { store.send(.tap(pos)) }
                                            )
                                            .equatable()
                                        }
                                    }
                                }
                                .frame(height: tileSize)
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
                    .onAppear {
                        guard !didInitialScroll else { return }
                        didInitialScroll = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            proxy.scrollTo(bottomRowScrollId, anchor: .bottom)
                        }
                    }
                    .onChange(of: scrollRequest) { _, newValue in
                        guard let request = newValue else { return }
                        let anchor: UnitPoint = {
                            switch request.anchor {
                            case .center: return .center
                            case .bottom: return .bottom
                            }
                        }()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                            withAnimation(.easeInOut(duration: 0.45)) {
                                proxy.scrollTo(request.id, anchor: anchor)
                            }
                        }
                    }

                    if let flight = liveBomberFlight {
                        let bomberSprite = tileSize * LivePlayerBomberFlight.spriteTileFactor

                        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                            let elapsed = timeline.date.timeIntervalSince(flight.startTime)
                            let p = min(1.0, elapsed / flight.duration)
                            let y = flight.startY + (flight.endY - flight.startY) * CGFloat(p)
                            let bottomOfPlane = y + flight.halfHeight
                            let showPlane = bottomOfPlane > 0

                            Image("bomber_transparent")
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(width: bomberSprite, height: bomberSprite)
                                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                                .position(x: flight.cx, y: y)
                                .opacity(showPlane ? 1 : 0)
                                .allowsHitTesting(false)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .allowsHitTesting(false)
                    }
                }
                .task(id: playerBomberFlightToken) {
                    guard playerBomberFlightToken != nil else { return }
                    defer {
                        liveBomberFlight = nil
                        playerBomberFlightToken = nil
                    }
                    await LivePlayerBomberFlight.run(
                        store: store,
                        proxy: proxy,
                        viewportSize: geo.size,
                        pullDown: pullDown,
                        updateFlightSpec: { liveBomberFlight = $0 }
                    )
                }
                .onChange(of: playerBomberRunIdentity) { old, new in
                    if new != nil, old == nil {
                        playerBomberFlightToken = UUID()
                    }
                }
                .onChange(of: store.state.phase) { _, phase in
                    if case .welcome = phase {
                        playerBomberFlightToken = nil
                        liveBomberFlight = nil
                    }
                }
            }
        }
    }
}
