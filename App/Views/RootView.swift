import SwiftUI
import SpriteKit
import GameCore

@main
struct WildwhistleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @StateObject private var model = GameModel()
    @Environment(\.scenePhase) private var phase

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ExploreView(model: model)
            overlay
        }
        .foregroundColor(Theme.ink)
        .onChange(of: phase) { newPhase in
            if newPhase != .active { model.save() }
        }
    }

    @ViewBuilder
    private var overlay: some View {
        switch model.screen {
        case .start:
            StartView(model: model)
        case .battle:
            BattleScreen(model: model)
        case .panel(let p):
            PanelScreen(model: model, panel: p)
        case .explore:
            EmptyView()
        }
    }
}

/// The map with its top strip and companion strip.
struct ExploreView: View {
    @ObservedObject var model: GameModel

    var body: some View {
        VStack(spacing: 8) {
            header
            SpriteView(scene: model.scene)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
                .overlay(alignment: .top) { toast }
                .padding(.horizontal, 16)
                .accessibilityLabel("Island map. Tap a spot to walk there.")
                .accessibilityIdentifier("map")
            status
        }
        .padding(.vertical, 8)
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Wildwhistle Isle").font(Theme.display(.title3, .heavy))
                Text("Guide \(model.game?.owned.count ?? 0)/\(GameData.species.count)")
                    .font(Theme.mono(.caption))
                    .foregroundColor(Theme.muted)
                    .accessibilityIdentifier("guideCount")
                Spacer(minLength: 0)
            }
            HStack(spacing: 6) {
                nav("Team", .team)
                nav("Guide", .guide)
                nav("Notes", .notes)
                nav("Map", .map)
                nav("Help", .help)
            }
        }
        .padding(.horizontal, 16)
    }

    private func nav(_ title: String, _ panel: GameModel.Panel) -> some View {
        Button(title) { model.open(panel) }
            .buttonStyle(KitButtonStyle())
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("nav." + title.lowercased())
    }

    @ViewBuilder
    private var toast: some View {
        if let text = model.toast {
            Text(text)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.bg)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 9).fill(Theme.ink))
                .padding(.top, 12)
                .padding(.horizontal, 24)
                .allowsHitTesting(false)
                .accessibilityIdentifier("toast")
        }
    }

    @ViewBuilder
    private var status: some View {
        if let g = model.game, !g.roster.isEmpty {
            let lead = g.roster[g.firstAble() ?? 0]
            let tile = g.tileIndex
            let slot = Int(g.map.biome[tile])
            HStack(spacing: 12) {
                CreaturePicture(lead, size: 44)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(lead.name).font(Theme.display(.subheadline))
                        Text("Lv \(lead.level)  \(lead.hp)/\(lead.maxHp)").font(Theme.mono(.caption2)).foregroundColor(Theme.muted)
                    }
                    HealthBar(fraction: Double(lead.hp) / Double(lead.maxHp))
                    Text(place(g, tile: tile, slot: slot))
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.horizontal, 16)
            .accessibilityElement(children: .combine)
        } else {
            Color.clear.frame(height: 52)
        }
    }

    private func place(_ g: Game, tile: Int, slot: Int) -> String {
        if g.map.isCamp[tile] { return "\(g.isleInfo.name). Camp. Stepping here rests your team." }
        if slot >= 1 && slot <= 4 {
            let h = g.isleInfo.habitat(slot)
            return "\(g.isleInfo.name). \(h.name). \(GameData.elements[h.element]!.name) creatures live here."
        }
        return g.isleInfo.name
    }
}

struct StartView: View {
    @ObservedObject var model: GameModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Wildwhistle Isle")
                    .font(Theme.display(.largeTitle, .heavy))
                Note("Four islands, forty creatures and a field guide to fill. Walk the shores and woods, whistle to the creatures you meet, raise them, and calm the guardian of each isle to sail on.")
                Text("No account or server  \u{00B7}  No shop  \u{00B7}  Plays offline")
                    .font(Theme.mono(.caption2))
                    .foregroundColor(Theme.muted)
                Text("Choose who walks with you").font(Theme.display(.headline))
                ForEach(GameData.starters, id: \.self) { id in
                    starter(id)
                }
                Button("Set out") { model.setOut() }
                    .buttonStyle(KitButtonStyle(primary: true))
                    .accessibilityIdentifier("setOut")
            }
            .padding(16)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func starter(_ id: String) -> some View {
        let s = GameData.sp(id)
        let chosen = model.pick == id
        return Button {
            model.pick = id
        } label: {
            HStack(spacing: 12) {
                CreaturePicture(sp: id, size: 84)
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.name).font(Theme.display(.headline))
                    ElementTag(element: s.element)
                    Text(s.blurb).font(.footnote).foregroundColor(Theme.muted).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(chosen ? Theme.accent : Theme.line, lineWidth: chosen ? 3 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pick." + id)
        .accessibilityAddTraits(chosen ? [.isSelected] : [])
    }
}
