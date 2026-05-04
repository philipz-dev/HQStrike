//
//  BoardView.swift
//  GridStrike Watch App
//
//  Scrollable 14×5 grid. Reads only from the precomputed snapshot — every tap is
//  forwarded as `Action.tap(GridPosition)`.
//

import SwiftUI

struct BoardView: View {
    let snapshot: BoardSnapshot
    @Environment(GameStore.self) private var store
    @State private var didInitialScroll = false

    private static let columns = Zones.columnCount
    private static let rows = Zones.rowCount
    private static let bottomCurveTapReserve: CGFloat = 10
    private static let horizontalPadding: CGFloat = 2

    private var bottomRowScrollId: String { "row-\(Self.rows - 1)" }

    var body: some View {
        let scrollTarget = store.state.scrollTarget

        GeometryReader { geo in
            let tileSize = max(1, (geo.size.width - Self.horizontalPadding * 2) / CGFloat(Self.columns))
            let bottomInset = geo.safeAreaInsets.bottom
            let pullDown = max(0, bottomInset - Self.bottomCurveTapReserve)

            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(0..<Self.rows, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<Self.columns, id: \.self) { col in
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
                        }
                    }
                    .padding(.horizontal, Self.horizontalPadding)
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
                .onChange(of: scrollTarget) { _, newValue in
                    guard let row = newValue else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                        proxy.scrollTo("row-\(row)", anchor: .center)
                    }
                }
            }
        }
    }
}
