import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // De header en OutlinedText zijn hier verwijderd
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    goalCard
                    setupCard
                    combatCard
                    tacticsCard
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.top, 20) // Iets meer ruimte bovenaan nu de header weg is
                .padding(.bottom, 44)
                .font(.system(.body, design: .serif).italic())
                .foregroundStyle(LetterPalette.ink)
                .background {
                    Assets.parchment
                        .resizable()
                }
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.black.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                // Kruisje linksbovenaan
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, LetterPalette.ink)
                        .font(.system(size: 24))
                }
            }
        }
    }

    // MARK: - Sections

    private var goalCard: some View {
        LetterCard(title: "Goal") {
            Text("Destroy enemy headquarter!")
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var setupCard: some View {
        LetterCard(title: "Setup") {
            VStack(alignment: .leading, spacing: 5) {
                Text("Place objects:")
                unitLine(count: 1, name: "Headquarter")
                unitLine(count: 2, name: "Missiles")
                unitLine(count: 1, name: "Bomber")
                unitLine(count: 1, name: "Coastguard")
            }
        }
    }

    private var combatCard: some View {
        LetterCard(title: "Combat") {
            VStack(alignment: .leading, spacing: 8) {
                actionRow(
                    verb: "Grenade",
                    instruction: "Tap any tile",
                    damage: "1-tile damage"
                )
                actionRow(
                    verb: "Missile",
                    instruction: "Select missile, then tile",
                    damage: "5 tiles in an X-shape"
                )
                actionRow(
                    verb: "Bomber",
                    instruction: "Select bomber, then tile",
                    damage: "3-tile damage, starting at the tapped tile"
                )
            }
        }
    }

    private var tacticsCard: some View {
        LetterCard(title: "Tactics") {
            VStack(alignment: .leading, spacing: 6) {
                Text("The coastguard defends against missiles and bombers.")
                Text("It is vulnerable to grenades.")
                Text("Tap a selected weapon again to deselect it.")
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Row helpers

    private func unitLine(count: Int, name: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(count)×")
                .monospacedDigit()
                .frame(minWidth: 20, alignment: .trailing)
            Text(name)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func actionRow(verb: String, instruction: String, damage: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            (Text(verb).bold() + Text(": \(instruction)"))
                .fixedSize(horizontal: false, vertical: true)
            Text(damage)
                .font(.system(.footnote, design: .serif).italic())
                .foregroundStyle(LetterPalette.ink.opacity(0.78))
                .padding(.leading, 14)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private enum LetterPalette {
    static let ink = Color(red: 0.18, green: 0.09, blue: 0.03)
}

private struct LetterCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.headline, design: .serif).weight(.bold))
                .italic()
                .foregroundStyle(LetterPalette.ink)
                .padding(.top, 18) // Behoud de padding van de vorige stap
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(LetterPalette.ink.opacity(0.45))
                        .frame(height: 0.5)
                        .offset(y: 4)
                }
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
