//
//  TileRenderModel.swift
//  GridStrike Watch App
//
//  Equatable per-tile render data. TileView is `Equatable` over this so SwiftUI only
//  redraws tiles whose render model actually changed.
//

import Foundation

enum TileBackground: Equatable {
    case grass
    case water
    case unit(Unit)
}

enum TileBorder: Equatable {
    case plain
    case dim
    case selected
}

enum DimMode: Equatable {
    case none
    case normal
    case coastguardOffRow
}

struct TileRenderModel: Equatable {
    let position: GridPosition
    let background: TileBackground
    let bomberRotationDegrees: Double
    let dim: DimMode
    let offCoastguardFocusRow: Bool
    let northStrikeOverlay: ExplosionKind?
    let dropOverlay: ExplosionKind?
    let waterWreck: WaterWreck?
    let border: TileBorder
    let isDisabled: Bool
}
