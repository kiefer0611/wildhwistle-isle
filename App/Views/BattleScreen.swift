import SwiftUI
import GameCore

/// An encounter: the two creatures, what just happened, and what you can do next.
struct BattleScreen: View {
    @ObservedObject var model: GameModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let v = model.shown, let b = model.battle {
                    foeCard(v, b)
                    meCard(v)
                    log
                    controls(v, b)
                }
            }
            .padding(16)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .accessibilityIdentifier("battle")
    }

    private func foeCard(_ v: BattleView, _ b: Battle) -> some View {
        let foe = v.foe
        let tag = b.kind == .guardian ? "Guardian \(v.foeNumber) of \(v.foeTotal)" : GameData.rarityNames[min(3, foe.species.rarity)]
        return Card {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(foe.name).font(Theme.display(.headline)).accessibilityIdentifier("foeName")
                        Text("Lv \(foe.level) \u{00B7} \(tag)").font(Theme.mono(.caption2)).foregroundColor(Theme.muted)
                    }
                    ElementTag(element: foe.element, extra: " \u{00B7} weak to " + weakTo(foe.element))
                    HealthBar(fraction: Double(foe.hp) / Double(foe.maxHp))
                    Text("\(foe.hp) / \(foe.maxHp) health").font(Theme.mono(.caption2)).foregroundColor(Theme.muted)
                }
                CreaturePicture(foe, size: 84)
            }
        }
        .modifier(Shake(animatableData: CGFloat(model.flashFoe)))
        .animation(.linear(duration: 0.28), value: model.flashFoe)
    }

    private func meCard(_ v: BattleView) -> some View {
        let me = v.me
        let xp: Double = me.level >= GameData.maxLevel ? 1 : Double(me.xp) / Double(Rules.need(me.level))
        return Card {
            HStack(spacing: 12) {
                CreaturePicture(me, size: 84)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(me.name).font(Theme.display(.headline)).accessibilityIdentifier("meName")
                        Text("Lv \(me.level)").font(Theme.mono(.caption2)).foregroundColor(Theme.muted)
                    }
                    ElementTag(element: me.element)
                    HealthBar(fraction: Double(me.hp) / Double(me.maxHp))
                    Text("\(me.hp) / \(me.maxHp) health").font(Theme.mono(.caption2)).foregroundColor(Theme.muted)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.track)
                            Capsule().fill(Theme.accent).frame(width: geo.size.width * CGFloat(min(1, max(0, xp))))
                        }
                    }
                    .frame(height: 4)
                    .accessibilityHidden(true)
                }
            }
        }
        .modifier(Shake(animatableData: CGFloat(model.flashMe)))
        .animation(.linear(duration: 0.28), value: model.flashMe)
    }

    private var log: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(model.lines.enumerated()), id: \.offset) { item in
                let last = item.offset == model.lines.count - 1
                Text(item.element)
                    .font(last ? Font.subheadline.weight(.semibold) : Font.footnote)
                    .foregroundColor(last ? Theme.ink : Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .bottomLeading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
        .accessibilityIdentifier("battleLog")
    }

    @ViewBuilder
    private func controls(_ v: BattleView, _ b: Battle) -> some View {
        switch model.battleMode {
        case .choose:
            actions(v, b)
        case .whistle:
            whistle
        case .swap:
            swapList(b)
        case .bag:
            bagList(b)
        case .done:
            Button("Continue") { model.continueAfterBattle() }
                .buttonStyle(KitButtonStyle(primary: true))
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("continue")
        }
    }

    private func actions(_ v: BattleView, _ b: Battle) -> some View {
        let me = v.me
        let foe = v.foe
        let m = Rules.mult(me.element, foe.element)
        let fit = m > 1 ? " \u{00B7} strong here" : (m < 1 ? " \u{00B7} weak here" : "")
        let elName = GameData.elements[me.element]!.name
        let strong = b.strongState
        let strongText: String
        switch strong {
        case .locked(let level): strongText = "Learned at level \(level)"
        case .recharging(let turns): strongText = "Recharging, \(turns) " + (turns == 1 ? "turn" : "turns")
        case .ready: strongText = "Big hit" + fit
        }
        let guardian = b.kind == .guardian
        let known = b.foeOwned
        let whistleTitle = known && !guardian ? "Already friends" : "Whistle"
        let whistleText = guardian ? "Not with a guardian" : (known ? "Nothing to do" : (b.reed ? "Band widened" : "Make friends"))
        let g = model.game
        let bagText = "\(g?.count(.berry) ?? 0) berry \u{00B7} \(g?.count(.reed) ?? 0) reed \u{00B7} \(g?.count(.root) ?? 0) root"
        let busy = model.busy
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        return LazyVGrid(columns: columns, spacing: 8) {
            ActionButton(title: "Nudge", subtitle: "Gentle, never knocks out", id: "act.nudge") { model.act(.nudge) }
                .disabled(busy)
            ActionButton(title: me.species.move, subtitle: elName + fit, id: "act.element") { model.act(.element) }
                .disabled(busy)
            ActionButton(title: GameData.elements[me.element]!.strongMove, subtitle: strongText, id: "act.strong") { model.act(.strong) }
                .disabled(busy || strong != .ready)
            ActionButton(title: "Brace", subtitle: "Halve a hit, recover", id: "act.brace") { model.act(.brace) }
                .disabled(busy)
            ActionButton(title: whistleTitle, subtitle: whistleText, primary: true, id: "act.whistle") { model.openWhistle() }
                .disabled(busy || !b.canWhistle)
            ActionButton(title: "Bag", subtitle: bagText, id: "act.bag") { model.openBag() }
                .disabled(busy || b.bagOptions.isEmpty)
            ActionButton(title: "Swap", subtitle: "Change companion", id: "act.swap") { model.openSwap() }
                .disabled(busy || b.swapChoices.isEmpty)
            ActionButton(title: "Leave", subtitle: "Always works", id: "act.leave") { model.leaveBattle() }
                .disabled(busy)
        }
    }

    private var whistle: some View {
        VStack(alignment: .leading, spacing: 10) {
            Note("Stop the marker inside the band. The band grows as the creature tires.")
            TimelineView(.animation) { context in
                GeometryReader { geo in
                    let z = model.zone ?? WhistleZone(a: 0.4, b: 0.6, period: 1.6)
                    let w = geo.size.width
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8).fill(Theme.track)
                        Rectangle().fill(Theme.good)
                            .frame(width: CGFloat(z.b - z.a) * w)
                            .offset(x: CGFloat(z.a) * w)
                        Rectangle().fill(Theme.ink)
                            .frame(width: 4)
                            .offset(x: CGFloat(model.markerPosition(at: context.date)) * w - 2)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
                }
                .frame(height: 36)
            }
            .accessibilityHidden(true)
            HStack(spacing: 8) {
                Button("Whistle now") { model.whistleNow() }
                    .buttonStyle(KitButtonStyle(primary: true))
                    .accessibilityIdentifier("whistleNow")
                Button("Back") { model.backToChoices() }
                    .buttonStyle(KitButtonStyle())
                    .accessibilityIdentifier("whistleBack")
                Spacer(minLength: 0)
            }
        }
    }

    private func swapList(_ b: Battle) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Note(b.needsSwap ? "Choose who steps up next." : "Choose who steps up. The other side gets a turn.")
            ForEach(b.swapChoices, id: \.self) { i in
                if let g = model.game, i < g.roster.count {
                    let c = g.roster[i]
                    Button("\(c.name)  Lv \(c.level)  \(c.hp)/\(c.maxHp)  \(GameData.elements[c.element]!.name)") { model.swap(to: i) }
                        .buttonStyle(KitButtonStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("swap.\(i)")
                }
            }
            if !b.needsSwap {
                Button("Back") { model.backToChoices() }
                    .buttonStyle(KitButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bagList(_ b: Battle) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Note("Using an item takes your turn.")
            ForEach(b.bagOptions) { option in
                Button(bagTitle(option)) { model.useInBattle(option) }
                    .buttonStyle(KitButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("bag." + option.id)
            }
            Button("Back") { model.backToChoices() }
                .buttonStyle(KitButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bagTitle(_ o: BagOption) -> String {
        guard let g = model.game else { return "" }
        let left = g.count(o.kind)
        if o.kind == .reed { return "Honeyreed: widen the band for your next whistle (\(left) left)" }
        guard let i = o.index, i < g.roster.count else { return "" }
        let c = g.roster[i]
        return "\(GameData.items[o.kind]!.singular) for \(c.name) (\(c.hp)/\(c.maxHp)), \(left) left"
    }
}
