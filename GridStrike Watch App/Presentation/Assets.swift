//
//  Assets.swift
//  GridStrike Watch App
//
//  Cached `Image` references and small lookup helpers. Avoids re-doing string-based
//  asset catalog lookups inside tile rendering.
//

import SwiftUI

enum Assets {
    static let grass = Image("grass")
    static let water = Image("water")
    static let headquarters = Image("HeadquarterTile")
    static let missile = Image("MissileTile")
    static let bomber = Image("BomberTile")
    static let coastguard = Image("CruiserTile")
    static let explosionHit = Image("ExplosionHit")
    static let explosionMiss = Image("ExplosionMiss")
    static let planeInWater = Image("PlaneInWater")
    static let missileInWater = Image("MissileInWater")
    static let splashBackground = Image("SplashBackground")

    static func tileImage(for background: TileBackground) -> Image {
        switch background {
        case .grass: return grass
        case .water: return water
        case .unit(let unit): return image(for: unit)
        }
    }

    static func image(for unit: Unit) -> Image {
        switch unit {
        case .headquarters: return headquarters
        case .missile: return missile
        case .bomber: return bomber
        case .coastguard: return coastguard
        }
    }

    static func explosionImage(for kind: ExplosionKind) -> Image {
        switch kind {
        case .hit: return explosionHit
        case .miss: return explosionMiss
        }
    }
}
