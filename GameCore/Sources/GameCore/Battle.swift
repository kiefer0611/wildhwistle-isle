import Foundation

/// What the encounter screen should show at one moment.
public struct BattleView: Equatable, Sendable {
    public var foe: Creature
    public var me: Creature
    public var actIndex: Int
    public var foeNumber: Int
    public var foeTotal: Int
}

public enum BattleSide: Sendable {
    case foe, me
}

/// One line of the encounter log, with the state to show while it is on screen.
public struct BattleEvent: Sendable {
    public let text: String
    public let view: BattleView
    /// Which side was just struck, if any.
    public let flash: BattleSide?
    /// True when the player's portrait changed (swap or growth).
    public let portraitChanged: Bool
}

public struct WhistleZone: Equatable, Sendable {
    /// The band, as fractions of the bar.
    public let a: Double
    public let b: Double
    /// Seconds for the marker to cross the bar and come back.
    public let period: Double

    public init(a: Double, b: Double, period: Double) {
        self.a = a
        self.b = b
        self.period = period
    }

    public func contains(_ pos: Double) -> Bool { pos >= a && pos <= b }
}

public enum StrongState: Equatable, Sendable {
    case locked(level: Int)
    case recharging(turns: Int)
    case ready
}

public struct BagOption: Equatable, Sendable, Identifiable {
    public let kind: ItemKind
    /// Roster index, or nil for the Honeyreed.
    public let index: Int?
    public var id: String { "\(kind.rawValue)-\(index ?? -1)" }
}

/// One encounter with a wild creature or a guardian's team.
public final class Battle {
    public enum Kind: Sendable { case wild, guardian }
    public enum Result: Sendable { case win, friend, blackout, left }
    public enum After: Sendable { case ending, complete }
    public enum Move: Sendable { case nudge, element, strong, brace }

    public let kind: Kind
    public let intro: String
    public private(set) var foe: Creature
    public private(set) var act: Int
    public private(set) var over = false
    public private(set) var result: Result? = nil
    public private(set) var after: After? = nil
    public private(set) var notes: [String] = []
    /// True when the active companion is worn out and another must step up before anything else.
    public private(set) var needsSwap = false
    public private(set) var reed = false
    public private(set) var queueIndex = 0
    public let queueCount: Int

    private unowned let game: Game
    private var queue: [Creature] = []
    private let wildId: Int?
    private var cd: [Int: Int] = [:]
    private var foeCd = 0
    private var foeBraced = false
    private var braceP = false
    private var braceF = false
    private var events: [BattleEvent] = []
    private var portraitDirty = false

    init(game: Game, wild w: Wild, act: Int) {
        self.game = game
        kind = .wild
        wildId = w.id
        self.act = act
        foe = Rules.makeWild(w.sp, level: w.level)
        queueCount = 1
        intro = "You meet a wild \(foe.name) \(game.isleInfo.habitat(w.slot).whereText)."
    }

    init(game: Game, guardianAct act: Int) {
        self.game = game
        kind = .guardian
        wildId = nil
        self.act = act
        let info = game.isleInfo
        let team = info.guardianTeam.map { Rules.makeWild($0.species, level: $0.level) }
        queue = team
        foe = team[0]
        queueCount = team.count
        intro = "\(info.guardianName) rises. \(team[0].name) steps forward."
    }

    // MARK: What the screen needs to know

    public var me: Creature { game.roster[act] }
    public var view: BattleView {
        BattleView(foe: foe, me: game.roster[act], actIndex: act, foeNumber: queueIndex + 1, foeTotal: queueCount)
    }
    public var foeLabel: String { (kind == .guardian ? "" : "The wild ") + foe.name }
    public var foeOwned: Bool { game.owned.contains(foe.sp) }
    public var canWhistle: Bool { !over && !needsSwap && kind == .wild && !foeOwned }

    public var strongState: StrongState {
        let c = me
        if !c.knowsStrong { return .locked(level: c.species.strongLevel) }
        let left = cd[act] ?? 0
        return left > 0 ? .recharging(turns: left) : .ready
    }

    /// Party members who could step in for the active one.
    public var swapChoices: [Int] {
        var out: [Int] = []
        for i in 0..<game.partyCount where i != act && game.roster[i].hp > 0 { out.append(i) }
        return out
    }

    public var bagOptions: [BagOption] {
        var o: [BagOption] = []
        if game.count(.berry) > 0 {
            for i in 0..<game.partyCount where game.roster[i].hp > 0 && game.roster[i].hp < game.roster[i].maxHp {
                o.append(BagOption(kind: .berry, index: i))
            }
        }
        if game.count(.root) > 0 {
            for i in 0..<game.partyCount where game.roster[i].hp <= 0 { o.append(BagOption(kind: .root, index: i)) }
        }
        if game.count(.reed) > 0 && kind == .wild && !reed && !foeOwned { o.append(BagOption(kind: .reed, index: nil)) }
        return o
    }

    // MARK: Turns

    /// Plays one of the active companion's moves and returns the lines to show.
    public func perform(_ move: Move) -> [BattleEvent] {
        guard !over, !needsSwap else { return [] }
        if move == .strong && strongState != .ready { return [] }
        events = []
        let fm = foeMove()
        if move == .brace {
            braceP = true
            let h = Rules.healFrac(&game.roster[act], 0.15)
            say("\(me.name) braces" + (h > 0 ? " and recovers \(h) health." : "."))
        }
        if fm == .brace {
            braceF = true
            foeBraced = true
            let h = Rules.healFrac(&foe, 0.12)
            say("\(foeLabel) braces" + (h > 0 ? " and recovers \(h) health." : "."))
        }
        let playerActs = move != .brace
        let foeActs = fm != .brace
        var order: [Bool] = []
        if playerActs && foeActs {
            order = Rules.stat(me, .spd) >= Rules.stat(foe, .spd) ? [true, false] : [false, true]
        } else {
            if playerActs { order.append(true) }
            if foeActs { order.append(false) }
        }
        for playerTurn in order {
            if playerTurn {
                strike(byPlayer: true, move)
                if foe.hp <= 0 {
                    if foeDown() { return take() }
                    break
                }
            } else {
                strike(byPlayer: false, fm)
                if game.roster[act].hp <= 0 {
                    onFaint()
                    return take()
                }
            }
        }
        endTurn()
        return take()
    }

    /// Picks where the whistle band sits for this attempt.
    public func makeWhistleZone() -> WhistleZone {
        let frac = Double(foe.hp) / Double(foe.maxHp)
        let rarityCost: [Double] = [0, 0.02, 0.04, 0.04]
        let raw: Double = 0.14 + 0.5 * (1 - frac) - rarityCost[min(3, foe.species.rarity)] + (reed ? 0.15 : 0)
        let w = clampD(raw, 0.1, 0.7)
        let c = w / 2 + game.dice.unit() * (1 - w)
        return WhistleZone(a: c - w / 2, b: c + w / 2, period: 1.6 - Double(game.isle) * 0.12)
    }

    /// Resolves a whistle. `hit` is whether the marker was stopped inside the band.
    public func whistle(hit: Bool) -> [BattleEvent] {
        guard canWhistle else { return [] }
        events = []
        reed = false
        say("You whistle to the wild \(foe.name).")
        if hit {
            game.roster.append(foe)
            if let id = wildId { game.removeWild(id: id) }
            if foe.grown { game.grownSeen.insert(foe.sp) }
            say("It whistles back. \(foe.name) is your friend now.")
            giveXp(8 + foe.level * 7, foeLevel: foe.level)
            if game.roster.count > 4 { say("\(foe.name) waits in reserve. Change your party in Team.") }
            finish(.friend)
            return take()
        }
        say("The note lands off-key. It is not convinced yet.")
        if foeTurn() { endTurn() }
        return take()
    }

    /// Brings another party member in. Costs the turn unless the active one was worn out.
    public func swap(to i: Int) -> [BattleEvent] {
        guard !over, swapChoices.contains(i) else { return [] }
        events = []
        let forced = needsSwap
        needsSwap = false
        act = i
        portraitDirty = true
        say("\(me.name) steps up.")
        if forced {
            braceP = false
            braceF = false
            return take()
        }
        if foeTurn() { endTurn() }
        return take()
    }

    public func useItem(_ option: BagOption) -> [BattleEvent] {
        guard !over, !needsSwap, bagOptions.contains(option) else { return [] }
        events = []
        if option.kind == .reed {
            game.items[.reed] = game.count(.reed) - 1
            reed = true
            say("You play the Honeyreed. The wild \(foe.name) leans in to listen.")
        } else if let i = option.index, let text = game.applyItem(option.kind, on: i) {
            say(text)
        } else {
            return []
        }
        if foeTurn() { endTurn() }
        return take()
    }

    /// Walks away. Always works unless the encounter is already decided.
    @discardableResult
    public func leave() -> Bool {
        guard !over else { return false }
        over = true
        result = .left
        return true
    }

    // MARK: Internals

    private func take() -> [BattleEvent] {
        let e = events
        events = []
        return e
    }

    private func say(_ text: String, flash: BattleSide? = nil) {
        events.append(BattleEvent(text: text, view: view, flash: flash, portraitChanged: portraitDirty))
        portraitDirty = false
    }

    private func foeMove() -> Move {
        if !foeBraced && Double(foe.hp) < Double(foe.maxHp) * 0.35 && game.dice.chance(0.5) { return .brace }
        if foe.knowsStrong && foeCd <= 0 && game.dice.chance(0.4) { return .strong }
        return game.dice.chance(0.65) ? .element : .nudge
    }

    private func strike(byPlayer: Bool, _ move: Move) {
        let a = byPlayer ? game.roster[act] : foe
        var d = byPlayer ? foe : game.roster[act]
        let sp = a.species
        let el: Element? = move == .nudge ? nil : sp.element
        let braced = byPlayer ? braceF : braceP
        let power = move == .strong ? 21 : (move == .element ? 13 : 10)
        var dmg = Rules.damage(attacker: a, defender: d, power: power, element: el, braced: braced, rnd: game.dice.unit())
        let m = Rules.mult(el, d.element)
        if move == .strong {
            if byPlayer { cd[act] = 3 } else { foeCd = 3 }
        }
        let held = byPlayer && move == .nudge && kind == .wild && dmg >= d.hp && d.hp > 1
        if held { dmg = d.hp - 1 }
        d.hp = max(0, d.hp - dmg)
        if byPlayer { foe = d } else { game.roster[act] = d }
        let moveName: String
        switch move {
        case .strong: moveName = GameData.elements[sp.element]!.strongMove
        case .element: moveName = sp.move
        default: moveName = "Nudge"
        }
        let who = byPlayer ? a.name : foeLabel
        var text = "\(who) uses \(moveName). \(dmg) damage."
        if held {
            text += " It holds back at the last moment."
        } else if m > 1 {
            text += " It hits hard."
        } else if m < 1 {
            text += " It barely lands."
        }
        if braced { text += " The brace softens it." }
        say(text, flash: byPlayer ? .foe : .me)
    }

    private func endTurn() {
        if let left = cd[act], left > 0 { cd[act] = left - 1 }
        if foeCd > 0 { foeCd -= 1 }
        braceP = false
        braceF = false
    }

    private func giveXp(_ gain: Int, foeLevel: Int) {
        var list = [act]
        var shared = false
        for i in 0..<game.partyCount where i != act && game.roster[i].hp > 0 {
            shared = true
            list.append(i)
        }
        let mine = Rules.xpFor(game.roster[act], gain: gain, foeLevel: foeLevel)
        say("\(me.name) gains \(mine) experience." + (shared ? " The rest of the party shares in it." : ""))
        for i in list {
            let old = game.roster[i].name
            let amount = Rules.xpFor(game.roster[i], gain: i == act ? gain : gain / 2, foeLevel: foeLevel)
            let ups = Rules.addXp(&game.roster[i], amount)
            if ups > 0 { say("\(old) grew to level \(game.roster[i].level).") }
            if Rules.tryGrow(&game.roster[i]) {
                game.grownSeen.insert(game.roster[i].sp)
                if i == act { portraitDirty = true }
                say("\(old) is changing. It grew into \(game.roster[i].name).")
            }
        }
    }

    private func finish(_ r: Result) {
        result = r
        over = true
        needsSwap = false
        notes = game.checkTasks()
        if game.owned.count == GameData.species.count && !game.done {
            game.done = true
            if after == nil { after = .complete }
        }
    }

    private func onFaint() {
        braceP = false
        braceF = false
        say("\(me.name) is worn out.")
        if game.firstAble() != nil {
            needsSwap = true
            return
        }
        say("Your whole party is worn out. You carry them back to camp.")
        game.healAll()
        game.moveToLastCamp()
        finish(.blackout)
    }

    /// The other side acts on its own. Returns false when that ended the player's turn early.
    private func foeTurn() -> Bool {
        let fm = foeMove()
        if fm == .brace {
            foeBraced = true
            let h = Rules.healFrac(&foe, 0.12)
            say("\(foeLabel) braces" + (h > 0 ? " and recovers \(h) health." : "."))
            return true
        }
        strike(byPlayer: false, fm)
        if game.roster[act].hp <= 0 {
            onFaint()
            return false
        }
        return true
    }

    /// Handles the foe being worn out. Returns true when the encounter is over.
    private func foeDown() -> Bool {
        let i = game.isle
        if kind == .guardian {
            say("\(foe.name) bows out.")
            giveXp(roundHalfUp(Double(8 + foe.level * 7) * 1.5), foeLevel: foe.level)
            queueIndex += 1
            if queueIndex < queue.count {
                foe = queue[queueIndex]
                foeBraced = false
                foeCd = 0
                game.seen.insert(foe.sp)
                say("\(foe.name) steps forward.")
                return false
            }
            queueIndex = queue.count - 1
            game.guardCalmed[i] = true
            game.wins += 1
            game.winsBy[i] += 1
            let info = GameData.isles[i]
            if i < 3 {
                game.unlocked = max(game.unlocked, i + 2)
                say("\(info.guardianName) is calm. The way to \(GameData.isles[i + 1].name) is open.")
            } else {
                if !game.owned.contains("skyvane") { game.roster.append(Rules.make("skyvane", level: 40)) }
                game.seen.insert("skyvane")
                game.ended = true
                after = .ending
                say("The storm breaks. Skyvane lowers its head and joins you.")
            }
            finish(.win)
            return true
        }
        say("The wild \(foe.name) backs off, worn out.")
        if let id = wildId { game.removeWild(id: id) }
        game.wins += 1
        game.winsBy[i] += 1
        giveXp(8 + foe.level * 7, foeLevel: foe.level)
        finish(.win)
        return true
    }
}
