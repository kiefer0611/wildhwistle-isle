import SwiftUI
import GameCore

/// The sheets that open over the map: Team, Guide, Notes, Map, Help, the shrine prompt and the two endings.
struct PanelScreen: View {
    @ObservedObject var model: GameModel
    let panel: GameModel.Panel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(title).font(Theme.display(.title2, .heavy)).accessibilityIdentifier("panelTitle")
                    Spacer()
                    Button("Close") { model.closePanel() }
                        .buttonStyle(KitButtonStyle())
                        .accessibilityIdentifier("panelClose")
                }
                if let g = model.game {
                    content(g)
                }
            }
            .padding(16)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var title: String {
        switch panel {
        case .team: return "Team"
        case .guide: return "Field guide"
        case .notes: return "Field notes"
        case .map: return model.game?.isleInfo.name ?? "Map"
        case .help: return "How to play"
        case .shrine: return "Shrine"
        case .ending: return "The storm breaks"
        case .complete: return "Field guide complete"
        }
    }

    @ViewBuilder
    private func content(_ g: Game) -> some View {
        switch panel {
        case .team: team(g)
        case .guide: guide(g)
        case .notes: notes(g)
        case .map: map(g)
        case .help: help
        case .shrine: shrine(g)
        case .ending: ending(g)
        case .complete: complete(g)
        }
    }

    // MARK: Team

    private func team(_ g: Game) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Note("The first four are your party and join encounters. Everyone else waits in reserve. Your party recovers slowly as you walk and fully at a camp.")
            Card {
                Text("Sunberries \(g.count(.berry))   Honeyreeds \(g.count(.reed))   Wakeroots \(g.count(.root))")
                    .font(Theme.mono(.footnote))
                    .accessibilityIdentifier("bagSummary")
            }
            ForEach(Array(g.roster.enumerated()), id: \.element.sp) { item in
                if item.offset == 4 {
                    Text("RESERVE").font(Theme.mono(.caption2)).foregroundColor(Theme.muted)
                }
                member(g, item.offset, item.element)
            }
        }
    }

    private func member(_ g: Game, _ i: Int, _ c: Creature) -> some View {
        let s = c.species
        let grows = s.canGrow && !c.grown ? " \u{00B7} grows at Lv \(s.growLevel)" : ""
        return Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    CreaturePicture(c, size: 52)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(c.name).font(Theme.display(.subheadline))
                            Text("Lv \(c.level)").font(Theme.mono(.caption2)).foregroundColor(Theme.muted)
                            if i == 0 { Text("LEAD").font(Theme.mono(.caption2)).foregroundColor(Theme.accent) }
                        }
                        ElementTag(element: c.element, extra: " \u{00B7} \(c.hp)/\(c.maxHp) health" + grows)
                        HealthBar(fraction: Double(c.hp) / Double(c.maxHp))
                    }
                }
                HStack(spacing: 6) {
                    if c.hp > 0 && c.hp < c.maxHp && g.count(.berry) > 0 {
                        Button("Sunberry") { model.useItem(.berry, on: i) }
                            .buttonStyle(KitButtonStyle())
                            .accessibilityLabel("Give \(c.name) a Sunberry")
                    }
                    if c.hp <= 0 && g.count(.root) > 0 {
                        Button("Wakeroot") { model.useItem(.root, on: i) }
                            .buttonStyle(KitButtonStyle())
                            .accessibilityLabel("Give \(c.name) a Wakeroot")
                    }
                    Spacer(minLength: 0)
                    Button("Up") { model.moveMember(i, by: -1) }
                        .buttonStyle(KitButtonStyle())
                        .disabled(i == 0)
                        .accessibilityLabel("Move \(c.name) up")
                        .accessibilityIdentifier("up.\(i)")
                    Button("Down") { model.moveMember(i, by: 1) }
                        .buttonStyle(KitButtonStyle())
                        .disabled(i == g.roster.count - 1)
                        .accessibilityLabel("Move \(c.name) down")
                        .accessibilityIdentifier("down.\(i)")
                }
            }
        }
    }

    // MARK: Guide

    private func guide(_ g: Game) -> some View {
        let own = g.owned
        return VStack(alignment: .leading, spacing: 12) {
            Note("\(own.count) of \(GameData.species.count) befriended. Each habitat holds a common, an uncommon and a rare creature. On the map, a plus sign marks one you have not befriended yet.")
            ForEach(0..<GameData.isles.count, id: \.self) { i in
                guideIsle(g, i, own)
            }
        }
    }

    private func guideIsle(_ g: Game, _ i: Int, _ own: Set<String>) -> some View {
        let isle = GameData.isles[i]
        let list = GameData.species.filter { $0.isle == i }
        let got = list.filter { own.contains($0.id) }.count
        let open = i < g.unlocked
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(isle.name).font(Theme.display(.headline))
                Spacer()
                Text(open ? "\(got)/\(list.count)" : "Uncharted").font(Theme.mono(.caption)).foregroundColor(Theme.muted)
            }
            Rectangle().fill(Theme.line).frame(height: 2)
            if open {
                ForEach(1...4, id: \.self) { slot in
                    guideHabitat(g, isle.habitat(slot), list.filter { $0.slot == slot }, own)
                }
            } else {
                Note("Calm the guardian of \(GameData.isles[i - 1].name) to sail here.")
            }
        }
    }

    @ViewBuilder
    private func guideHabitat(_ g: Game, _ h: HabitatInfo, _ list: [SpeciesInfo], _ own: Set<String>) -> some View {
        if !list.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(h.name).font(Theme.display(.subheadline))
                Text("\(GameData.elements[list[0].element]!.name) creatures").font(.footnote).foregroundColor(Theme.muted)
            }
            ForEach(list, id: \.id) { s in
                guideEntry(g, s, h, own)
            }
        }
    }

    private func guideEntry(_ g: Game, _ s: SpeciesInfo, _ h: HabitatInfo, _ own: Set<String>) -> some View {
        let state = own.contains(s.id) ? 2 : (g.seen.contains(s.id) ? 1 : 0)
        let grown = g.grownSeen.contains(s.id)
        let status = (state == 2 ? "FRIEND" : (state == 1 ? "SEEN" : "UNKNOWN")) + " \u{00B7} " + GameData.rarityNames[min(3, s.rarity)].uppercased()
        let name = state == 0 ? "Not yet seen" : (grown ? "\(s.name) / \(s.grownName)" : s.name)
        let line = state == 2 ? s.blurb : (s.rarity == 3 ? "Waits at the shrine." : "Lives \(h.whereText).")
        return Card {
            HStack(spacing: 10) {
                if state == 0 {
                    Text("?")
                        .font(Theme.display(.title2))
                        .foregroundColor(Theme.muted)
                        .frame(width: 64, height: 64)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                } else {
                    CreaturePicture(sp: s.id, grown: grown, size: 64).opacity(state == 1 ? 0.45 : 1)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(name).font(Theme.display(.subheadline))
                    Text(status).font(Theme.mono(.caption2)).foregroundColor(state == 2 ? Theme.good : Theme.muted)
                    Text(line).font(.footnote).foregroundColor(Theme.muted).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: Notes

    private func notes(_ g: Game) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Note("Things worth doing on each isle. Rewards arrive on their own when a note is complete.")
            ForEach(0..<g.unlocked, id: \.self) { i in
                let tasks = g.tasks(isle: i)
                HStack(alignment: .firstTextBaseline) {
                    Text(GameData.isles[i].name).font(Theme.display(.headline))
                    Spacer()
                    Text("\(tasks.filter { $0.done }.count)/\(tasks.count) done").font(Theme.mono(.caption)).foregroundColor(Theme.muted)
                }
                ForEach(tasks) { t in
                    taskRow(t)
                }
            }
            if g.unlocked < GameData.isles.count {
                Note("More notes open when you reach \(GameData.isles[g.unlocked].name).")
            }
        }
    }

    private func taskRow(_ t: TaskInfo) -> some View {
        let value = min(t.value, t.goal)
        let fraction: Double = t.done ? 1 : Double(value) / Double(max(1, t.goal))
        return Card {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.text).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                        Text("Reward: " + Game.itemText(t.reward)).font(.footnote).foregroundColor(Theme.muted)
                    }
                    Spacer(minLength: 8)
                    Text(t.done ? "Done" : "\(value)/\(t.goal)").font(Theme.mono(.caption)).foregroundColor(t.done ? Theme.good : Theme.muted)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.track)
                        Capsule().fill(t.done ? Theme.good : Theme.accent).frame(width: geo.size.width * CGFloat(fraction))
                    }
                }
                .frame(height: 6)
                .accessibilityHidden(true)
            }
        }
    }

    // MARK: Map

    private func map(_ g: Game) -> some View {
        let isle = g.isleInfo
        let slot = Int(g.map.biome[g.tileIndex])
        let here = slot >= 1 && slot <= 4 ? isle.habitat(slot).whereText : "at sea"
        return VStack(alignment: .leading, spacing: 12) {
            Note("You are \(here). Creatures here are levels \(isle.base) to \(isle.base + 9) and get stronger the farther you go from your first camp. The guardian waits at the shrine.")
            Image(uiImage: TileArt.minimap(map: g.map, playerX: g.x, playerY: g.y))
                .interpolation(.none)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 352)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
                .accessibilityLabel("Map of \(isle.name) showing habitats, camps, the shrine and your position")
            legend(isle)
            Text("Sail").font(Theme.display(.headline))
            ForEach(0..<GameData.isles.count, id: \.self) { i in
                sailRow(g, i)
            }
        }
    }

    private func legend(_ isle: IsleInfo) -> some View {
        var rows: [(String, String)] = isle.habitats.map { ($0.name, $0.palette[0]) }
        rows.append(("Camp (square)", "#D9743C"))
        rows.append(("Shrine (triangle)", "#F2B63A"))
        rows.append(("You (ring)", "#C7452F"))
        let columns = [GridItem(.adaptive(minimum: 130), spacing: 8, alignment: .leading)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(rows, id: \.0) { row in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(hexString: row.1)).frame(width: 11, height: 11)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.line, lineWidth: 1))
                    Text(row.0).font(.footnote).foregroundColor(Theme.muted)
                }
            }
        }
    }

    private func sailRow(_ g: Game, _ i: Int) -> some View {
        let isle = GameData.isles[i]
        let open = i < g.unlocked
        let state: String
        if i == g.isle {
            state = "You are here."
        } else if open {
            state = g.guardCalmed[i] ? "Guardian calmed." : "Open."
        } else {
            state = "Calm the guardian of \(GameData.isles[i - 1].name) first."
        }
        return Card {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isle.name).font(Theme.display(.subheadline))
                    Text("Levels \(isle.base) to \(isle.base + 9). \(state)").font(.footnote).foregroundColor(Theme.muted).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Button("Sail here") { model.sail(to: i) }
                    .buttonStyle(KitButtonStyle())
                    .disabled(!open || i == g.isle)
                    .accessibilityIdentifier("sail.\(i)")
            }
        }
    }

    // MARK: Shrine, help, endings

    @ViewBuilder
    private func shrine(_ g: Game) -> some View {
        let isle = g.isleInfo
        if g.guardCalmed[g.isle] {
            Note("The shrine is quiet. \(isle.guardianName) is calm.")
        } else {
            let team = isle.guardianTeam
            let best = g.roster.prefix(4).map { $0.level }.max() ?? 0
            Note("\(isle.guardianName) waits here with \(team.count) companions, levels \(team.first?.level ?? 0) to \(team.last?.level ?? 0). You face them one after another without a rest. Guardians cannot be whistled to, but you can leave at any time and try again.")
            Note("Your strongest party member is level \(best).")
            HStack(spacing: 8) {
                Button("Challenge") { model.challengeGuardian() }
                    .buttonStyle(KitButtonStyle(primary: true))
                    .accessibilityIdentifier("challenge")
                Button("Not yet") { model.closePanel() }
                    .buttonStyle(KitButtonStyle())
            }
        }
    }

    private var help: some View {
        let tips = [
            "Tap a spot on the map to walk there.",
            "Walk into a creature to meet it. Nothing jumps out at you.",
            "In an encounter, wear the creature down, then Whistle. Stop the marker inside the band and it joins you. The band grows as the creature tires.",
            "Nudge is gentle: it never knocks out a wild creature, so it is safe to use before whistling. Elemental moves do knock out, and a knocked-out creature gives experience instead of joining.",
            "Leave always works. Brace halves the next hit and restores a little health. Each creature learns a strong move that needs two turns to recharge.",
            "Commons and uncommons grow into a stronger form when they reach the level shown in Team.",
            "Sparkles on the map are items. Sunberries heal, Honeyreeds widen the whistle band, Wakeroots wake a worn-out companion.",
            "Your party slowly recovers as you walk, and stepping on a tent rests everyone at once. If your party tires out, you wake at the last camp with everyone rested and nothing lost.",
            "Each isle has a guardian at its shrine. Calm it to open the next isle, then sail from the Map."
        ]
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\u{2022}").foregroundColor(Theme.muted)
                    Text(tip).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                }
            }
            Text("What beats what").font(Theme.display(.headline))
            Card {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Element.allCases, id: \.self) { el in
                        let info = GameData.elements[el]!
                        Text("\(info.name) beats \(info.beats.map { GameData.elements[$0]!.name }.joined(separator: " and "))")
                            .font(Theme.mono(.footnote))
                    }
                    Text("A strong match deals half again as much; a weak one deals a third less.")
                        .font(.footnote)
                        .foregroundColor(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Text("Start over").font(Theme.display(.headline))
            if model.confirmingReset {
                Note("This erases your islands and team on this device.")
                HStack(spacing: 8) {
                    Button("Erase and start over") { model.eraseAndRestart() }
                        .buttonStyle(KitButtonStyle(danger: true))
                        .accessibilityIdentifier("resetYes")
                    Button("Keep playing") { model.confirmingReset = false }
                        .buttonStyle(KitButtonStyle())
                        .accessibilityIdentifier("resetNo")
                }
            } else {
                Button("Start over") { model.confirmingReset = true }
                    .buttonStyle(KitButtonStyle(danger: true))
                    .accessibilityIdentifier("reset")
            }
        }
    }

    private func ending(_ g: Game) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Note("The sky over Tempest Isle clears for the first time anyone remembers, and Skyvane walks with you. You calmed all four guardians in \(g.steps) steps and \(g.wins) won encounters.")
            CreaturePicture(sp: "skyvane", size: 128)
            Note(g.done ? "Your field guide is complete too: all \(GameData.species.count) creatures are your friends." : "Your field guide stands at \(g.owned.count) of \(GameData.species.count). Every isle stays open, so you can go back for the rest.")
        }
    }

    private func complete(_ g: Game) -> some View {
        let columns = [GridItem(.adaptive(minimum: 72), spacing: 8)]
        return VStack(alignment: .leading, spacing: 12) {
            Note("All \(GameData.species.count) creatures of the four isles walk with you. It took \(g.steps) steps and \(g.wins) won encounters.")
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(GameData.species, id: \.id) { s in
                    CreaturePicture(sp: s.id, grown: g.grownSeen.contains(s.id), size: 64)
                }
            }
            Note("The isles stay open. Keep exploring, or start new islands from Help.")
        }
    }
}
