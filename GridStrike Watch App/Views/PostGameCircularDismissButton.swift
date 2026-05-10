//
//  PostGameCircularDismissButton.swift
//  GridStrike Watch App
//
//  Shared top-leading circular × control for post-game flows — same visuals and
//  hit target as `OpponentSetupMapView`’s close control.
//

import SwiftUI

struct PostGameCircularDismissButton: View {
    let accessibilityLabel: String
    let action: () -> Void

    private static let diameter: CGFloat = 40
    private static let topOffset: CGFloat = -6
    private static let leadingInset: CGFloat = 2

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: Self.diameter, height: Self.diameter)
                .background(Color.black.opacity(0.7))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.25))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, Self.leadingInset)
        .padding(.top, Self.topOffset)
        .accessibilityLabel(accessibilityLabel)
    }
}
