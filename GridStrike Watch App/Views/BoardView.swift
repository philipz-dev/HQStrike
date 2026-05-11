//
//  BoardView.swift
//  GridStrike Watch App
//
//  Scrollable 14×5 grid. Reads only from the precomputed snapshot — every tap is
//  forwarded as `Action.tap(GridPosition)`. Reacts to `state.scrollRequest` so the
//  reducer can pull the camera to whichever half is in the spotlight (the
//  opponent's grass when the player is up, the player's grass when the AI is up).
//  No negative bottom padding on the scroll content — that extension into the watch chin
//  can misalign taps vs tiles on bottom rows. UIKit scroll/view bridges are not used here
//  because UIView and UIScrollView are unavailable on watchOS.
//
//  Player bomber strikes: after confirm, `LivePlayerBomberFlight` scrolls + overlays
//  `bomber_transparent` and sends `advanceBombDrop` on demo-aligned timings.
//
//  Player missile (not intercepted): `LivePlayerMissileFlight` / `LiveOpponentMissileFlight`
//  mirror that motion with `missiletransparent` + simultaneous X-pattern on `commitMissileFlightStrike`.
//
//  Coastguard intercept (player missile / bomber): `LiveMissileInterceptFlight` mirrors
//  `Demo_Coastguard`’s tail — scroll to row 6, flying weapon sprite, explosion + coastguard,
//  banner — then `finalizePlayerMissileIntercept` / `finalizePlayerBomberIntercept`
//  commits shot-down state (`missileInWater` / `planeInWater`, launcher removal).
//

import SwiftUI

struct BoardView: View {
    let snapshot: BoardSnapshot
    @Environment(GameStore.self) private var store
    @State private var didInitialScroll = false
    @State private var liveBomberFlight: LiveBomberFlightSpec?
    @State private var playerBomberFlightToken: UUID?

    @State private var liveMissileFlight: LiveBomberFlightSpec?
    @State private var missileFlightTaskToken: UUID?

    @State private var liveCoastguardInterceptFlight: LiveMissileFlightSpec?
    @State private var coastguardInterceptTaskToken: UUID?
    @State private var interceptAnchorColumn: Int?
    /// Captured when the intercept cutscene starts — phase becomes `.shotDown` before overlay state clears.
    @State private var coastguardInterceptShowsBomberSprite = false
    @State private var showInterceptExplosion = false
    @State private var interceptExplosionScale: CGFloat = 0.25
    @State private var interceptExplosionOpacity: CGFloat = 1
    @State private var showInterceptCoastguard = false
    @State private var interceptCoastguardOpacity: CGFloat = 0
    @State private var showInterceptBanner = false

    private static let rows = BoardGridMetrics.rowCount

    private var bottomRowScrollId: String { "row-\(Self.rows - 1)" }

    /// Stable for the whole missile run (`dropsApplied` advances don’t change src/anchor).
    private var missileRunIdentity: String? {
        guard case .play(.missileFlight(let src, let tgt, let attacker)) = store.state.phase else { return nil }
        let turnMatches =
            (attacker == .player && store.state.currentTurn == .player)
            || (attacker == .opponent && store.state.currentTurn == .opponent)
        guard turnMatches else { return nil }
        return "\(attacker)-\(src.row),\(src.col)-\(tgt.row),\(tgt.col)"
    }

    /// Stable for the whole player bomb run (dropsApplied advances don’t change src/tgt).
    private var playerBomberRunIdentity: String? {
        guard store.state.currentTurn == .player,
              case .play(.bombingDrops(let src, let tgt, _)) = store.state.phase else { return nil }
        return "\(src.row),\(src.col)-\(tgt.row),\(tgt.col)"
    }

    /// Stable for the coastguard intercept cutscene (source + strike anchor).
    private var coastguardInterceptRunIdentity: String? {
        switch store.state.phase {
        case .play(.missileInterceptFlight(let src, let anchor)):
            return "m:\(src.row),\(src.col)_\(anchor.row),\(anchor.col)"
        case .play(.bomberInterceptFlight(let src, let anchor)):
            return "b:\(src.row),\(src.col)_\(anchor.row),\(anchor.col)"
        default:
            return nil
        }
    }

    /// Matches `InstructionBanner` / `BannerKind` phrasing for the cutscene bar.
    private var interceptBannerTitle: String {
        if coastguardInterceptShowsBomberSprite {
            return "Bomber shot down by enemy coastguard!"
        }
        return "Missile intercepted by coastguard!"
    }

    private var interceptFlightUsesBomberArt: Bool {
        coastguardInterceptShowsBomberSprite
    }

    var body: some View {
        let scrollRequest = store.state.scrollRequest

        GeometryReader { geo in
            // Quantize to integer points: fractional row heights accumulate down the column and
            // can leave the hit-test rect off by ~1 pt on lower rows, which reads as "tapping a
            // tile selects the one below it". `floor` matches what SwiftUI draws after pixel snap.
            let tileSize = floor(BoardGridMetrics.tileWidth(forContainerWidth: geo.size.width))
            let interceptFlyingSprite = tileSize * LiveMissileInterceptFlight.missileFlightSpriteTileFactor
            let contentH = CGFloat(Zones.rowCount) * tileSize
            let maxScroll = max(0, contentH - geo.size.height)
            let scrollTopPinnedRow6 = LiveMissileInterceptFlight.clampedScrollOffsetPinningBottomOfRow(
                rowIndex: 6,
                tileWidth: tileSize,
                viewportHeight: geo.size.height,
                maxScroll: maxScroll
            )
            let interceptCol = interceptAnchorColumn ?? 0

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
                    }
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(!store.state.allowsPlayfieldScrolling)
                    // Keep scroll content flush with the viewport edges so OS-default
                    // scroll margins don’t shift visuals vs hit-testing coordinates.
                    .contentMargins(0, for: .scrollContent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

                    VStack(spacing: 0) {
                        if showInterceptBanner {
                            Text(interceptBannerTitle)
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

                    if showInterceptCoastguard {
                        let hp = BoardGridMetrics.horizontalPadding
                        let cgCentre = LiveMissileInterceptFlight.tileCentreScreen(
                            row: 5,
                            col: interceptCol,
                            tw: tileSize,
                            hp: hp,
                            scrollTopContentY: scrollTopPinnedRow6
                        )
                        Assets.coastguard
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: tileSize * 0.92, height: tileSize * 0.92)
                            .position(cgCentre)
                            .opacity(interceptCoastguardOpacity)
                            .allowsHitTesting(false)
                    }

                    if showInterceptExplosion {
                        let hp = BoardGridMetrics.horizontalPadding
                        let boomCentre = LiveMissileInterceptFlight.tileCentreScreen(
                            row: LiveMissileInterceptFlight.missileDismissRow,
                            col: interceptCol,
                            tw: tileSize,
                            hp: hp,
                            scrollTopContentY: scrollTopPinnedRow6
                        )
                        Assets.explosionImage(for: .hit)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: tileSize * 0.92, height: tileSize * 0.92)
                            .scaleEffect(interceptExplosionScale)
                            .opacity(interceptExplosionOpacity)
                            .position(boomCentre)
                            .allowsHitTesting(false)
                    }

                    if let flight = liveCoastguardInterceptFlight {
                        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                            let elapsed = timeline.date.timeIntervalSince(flight.startTime)
                            let p = min(1.0, elapsed / flight.duration)
                            let y = flight.startY + (flight.endY - flight.startY) * CGFloat(p)
                            let bottomOfMissile = y + flight.halfHeight
                            let showMissile = bottomOfMissile > flight.halfHeight

                            Group {
                                if interceptFlightUsesBomberArt {
                                    Image("bomber_transparent")
                                        .resizable()
                                        .interpolation(.high)
                                        .scaledToFit()
                                        .frame(width: interceptFlyingSprite, height: interceptFlyingSprite)
                                        .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                                        .position(x: flight.cx, y: y)
                                        .opacity(showMissile ? 1 : 0)
                                } else {
                                    Image("missiletransparent")
                                        .resizable()
                                        .interpolation(.high)
                                        .scaledToFit()
                                        .frame(width: interceptFlyingSprite, height: interceptFlyingSprite)
                                        .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                                        .position(x: flight.cx, y: y)
                                        .opacity(showMissile ? 1 : 0)
                                }
                            }
                            .allowsHitTesting(false)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .allowsHitTesting(false)
                    }

                    if let flight = liveMissileFlight {
                        let missileSprite = tileSize * LivePlayerMissileFlight.spriteTileFactor

                        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                            let elapsed = timeline.date.timeIntervalSince(flight.startTime)
                            let p = min(1.0, elapsed / flight.duration)
                            let y = flight.startY + (flight.endY - flight.startY) * CGFloat(p)
                            let topEdge = y - flight.halfHeight
                            let bottomEdge = y + flight.halfHeight
                            let showMissile = flight.missileFliesDownward
                                ? (bottomEdge > 0 && topEdge < geo.size.height)
                                : (bottomEdge > 0)

                            Image("missiletransparent")
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(width: missileSprite, height: missileSprite)
                                .rotationEffect(.degrees(flight.spriteRotationDegrees))
                                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                                .position(x: flight.cx, y: y)
                                .opacity(showMissile ? 1 : 0)
                                .allowsHitTesting(false)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .allowsHitTesting(false)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .task(id: missileFlightTaskToken) {
                    guard missileFlightTaskToken != nil else { return }
                    defer {
                        liveMissileFlight = nil
                        missileFlightTaskToken = nil
                    }
                    switch store.state.phase {
                    case .play(.missileFlight(_, _, let attacker)) where attacker == .player:
                        await LivePlayerMissileFlight.run(
                            store: store,
                            proxy: proxy,
                            viewportSize: geo.size,
                            updateFlightSpec: { liveMissileFlight = $0 }
                        )
                    case .play(.missileFlight(_, _, let attacker)) where attacker == .opponent:
                        await LiveOpponentMissileFlight.run(
                            store: store,
                            proxy: proxy,
                            viewportSize: geo.size,
                            updateFlightSpec: { liveMissileFlight = $0 }
                        )
                    default:
                        break
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
                        updateFlightSpec: { liveBomberFlight = $0 }
                    )
                }
                .task(id: coastguardInterceptTaskToken) {
                    guard coastguardInterceptTaskToken != nil else { return }
                    let finalize: Action
                    let anchorColumn: Int
                    switch store.state.phase {
                    case .play(.missileInterceptFlight(_, let anchor)):
                        finalize = .finalizePlayerMissileIntercept
                        anchorColumn = anchor.col
                    case .play(.bomberInterceptFlight(_, let anchor)):
                        finalize = .finalizePlayerBomberIntercept
                        anchorColumn = anchor.col
                    default:
                        coastguardInterceptTaskToken = nil
                        return
                    }
                    defer {
                        liveCoastguardInterceptFlight = nil
                        showInterceptExplosion = false
                        interceptExplosionScale = 0.25
                        interceptExplosionOpacity = 1
                        showInterceptCoastguard = false
                        interceptCoastguardOpacity = 0
                        showInterceptBanner = false
                        interceptAnchorColumn = nil
                        coastguardInterceptShowsBomberSprite = false
                        coastguardInterceptTaskToken = nil
                    }
                    await LiveMissileInterceptFlight.run(
                        proxy: proxy,
                        viewportSize: geo.size,
                        anchorColumn: anchorColumn,
                        updateMissileSpec: { liveCoastguardInterceptFlight = $0 },
                        updateInterceptExplosion: { show, scale, opacity in
                            showInterceptExplosion = show
                            interceptExplosionScale = scale
                            interceptExplosionOpacity = opacity
                        },
                        updateInterceptCoastguard: { show, opacity in
                            showInterceptCoastguard = show
                            interceptCoastguardOpacity = opacity
                        },
                        updateInterceptBanner: { showInterceptBanner = $0 }
                    )
                    store.send(finalize)
                }
                .onChange(of: missileRunIdentity) { old, new in
                    if new != nil, old == nil {
                        missileFlightTaskToken = UUID()
                    }
                }
                .onChange(of: playerBomberRunIdentity) { old, new in
                    if new != nil, old == nil {
                        playerBomberFlightToken = UUID()
                    }
                }
                .onChange(of: coastguardInterceptRunIdentity) { old, new in
                    if new != nil, old == nil {
                        switch store.state.phase {
                        case .play(.missileInterceptFlight(_, let anchor)),
                             .play(.bomberInterceptFlight(_, let anchor)):
                            interceptAnchorColumn = anchor.col
                        default:
                            break
                        }
                        if case .play(.bomberInterceptFlight) = store.state.phase {
                            coastguardInterceptShowsBomberSprite = true
                        } else {
                            coastguardInterceptShowsBomberSprite = false
                        }
                        coastguardInterceptTaskToken = UUID()
                    }
                }
                .onChange(of: store.state.phase) { _, phase in
                    if case .welcome = phase {
                        playerBomberFlightToken = nil
                        liveBomberFlight = nil
                        missileFlightTaskToken = nil
                        liveMissileFlight = nil
                        coastguardInterceptTaskToken = nil
                        liveCoastguardInterceptFlight = nil
                        interceptAnchorColumn = nil
                        coastguardInterceptShowsBomberSprite = false
                        showInterceptExplosion = false
                        interceptExplosionScale = 0.25
                        interceptExplosionOpacity = 1
                        showInterceptCoastguard = false
                        interceptCoastguardOpacity = 0
                        showInterceptBanner = false
                    }
                }
            }
        }
    }
}
