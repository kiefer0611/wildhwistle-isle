import Foundation

public struct Wild: Equatable, Sendable, Identifiable {
    public let id: Int
    public let sp: String
    public let level: Int
    public let grown: Bool
    public let slot: Int
    public var x: Int
    public var y: Int
}

public struct Pickup: Equatable, Sendable, Identifiable {
    public let id: Int
    public let x: Int
    public let y: Int
    public let kind: ItemKind
}

public struct TaskInfo: Sendable, Identifiable {
    public let id: String
    public let text: String
    public let goal: Int
    public let value: Int
    public let reward: [ItemKind: Int]
    public let done: Bool
}

public struct StepInfo: Equatable, Sendable {
    public var found: ItemKind? = nil
    /// nil when no camp was reached; true when someone needed the rest.
    public var restedTired: Bool? = nil
}

public enum StepResult: Equatable, Sendable {
    case blocked
    case shrine
    case encounter(wildId: Int)
    case moved(StepInfo)
}

/// Everything that is written to disk.
public struct SaveData: Codable, Equatable, Sendable {
    public var v: Int
    public var seed: UInt32
    public var isle: Int
    public var x: Int
    public var y: Int
    public var lastCamp: Int
    public var roster: [Creature]
    public var seen: [String]
    public var grownSeen: [String]
    public var items: [String: Int]
    public var unlocked: Int
    public var guardCalmed: [Bool]
    public var claimed: [String]
    public var winsBy: [Int]
    public var steps: Int
    public var wins: Int
    public var done: Bool
    public var ended: Bool
}

/// The whole game outside of an encounter: the islands, the player, the roster and the bag.
public final class Game {
    public static let population = 26
    public static let pickupTarget = 7
    static let W = IsleMap.width
    static let H = IsleMap.height
    static let dirs: [(Int, Int)] = [(1, 0), (-1, 0), (0, 1), (0, -1)]

    public let dice: Dice
    public internal(set) var seed: UInt32
    public internal(set) var isle: Int = 0
    private var maps: [Int: IsleMap] = [:]
    public internal(set) var map: IsleMap
    public internal(set) var x: Int = 0
    public internal(set) var y: Int = 0
    public var face: Int = 1
    public internal(set) var roster: [Creature] = []
    public internal(set) var seen: Set<String> = []
    public internal(set) var grownSeen: Set<String> = []
    public internal(set) var items: [ItemKind: Int] = [.berry: 0, .reed: 0, .root: 0]
    public internal(set) var unlocked: Int = 1
    public internal(set) var guardCalmed: [Bool] = [false, false, false, false]
    public internal(set) var claimed: Set<String> = []
    public internal(set) var winsBy: [Int] = [0, 0, 0, 0]
    public internal(set) var wilds: [Wild] = []
    public internal(set) var pickups: [Pickup] = []
    public internal(set) var lastCamp: Int = 0
    public internal(set) var steps: Int = 0
    public internal(set) var wins: Int = 0
    public internal(set) var done: Bool = false
    public internal(set) var ended: Bool = false
    private var nextId = 1

    // MARK: Starting and loading

    public init(starter: String, seed: UInt32, dice: Dice = Dice()) {
        self.dice = dice
        self.seed = seed
        let m = MapGen.make(seed: seed, isle: 0)
        map = m
        maps[0] = m
        roster = [Rules.make(starter, level: 5)]
        seen = [starter]
        items[.berry] = 2
        x = IsleMap.x(m.start)
        y = IsleMap.y(m.start)
        populate()
    }

    /// Restores a saved game, repairing anything out of range. Returns nil when the save cannot be used.
    public init?(save d: SaveData, dice: Dice = Dice()) {
        guard d.v == 2, !d.roster.isEmpty else { return nil }
        for c in d.roster {
            guard GameData.speciesById[c.sp] != nil, c.level >= 1, c.level <= GameData.maxLevel else { return nil }
        }
        self.dice = dice
        seed = d.seed
        var had: Set<String> = []
        var list: [Creature] = []
        for c in d.roster where !had.contains(c.sp) {
            had.insert(c.sp)
            var m = Creature(sp: c.sp, level: c.level, xp: max(0, c.xp), hp: 0, grown: c.grown && GameData.sp(c.sp).canGrow)
            m.hp = clampI(c.hp, 0, m.maxHp)
            list.append(m)
        }
        var calm = [false, false, false, false]
        for i in 0..<min(4, d.guardCalmed.count) { calm[i] = d.guardCalmed[i] }
        var open = clampI(d.unlocked, 1, 4)
        for i in 0..<3 where calm[i] { open = max(open, i + 2) }
        let here = clampI(d.isle, 0, open - 1)
        let m = MapGen.make(seed: d.seed &+ UInt32(here) &* 104729, isle: here)
        map = m
        maps[here] = m
        isle = here
        unlocked = open
        guardCalmed = calm
        roster = list
        for s in d.seen where GameData.speciesById[s] != nil { seen.insert(s) }
        for s in d.grownSeen where GameData.speciesById[s]?.canGrow == true { grownSeen.insert(s) }
        for c in list {
            seen.insert(c.sp)
            if c.grown { grownSeen.insert(c.sp) }
        }
        for k in ItemKind.allCases { items[k] = clampI(d.items[k.rawValue] ?? 0, 0, 30) }
        for s in d.claimed where s.count < 4 { claimed.insert(s) }
        for i in 0..<min(4, d.winsBy.count) { winsBy[i] = max(0, d.winsBy[i]) }
        steps = max(0, d.steps)
        wins = max(0, d.wins)
        done = d.done
        ended = d.ended && guardCalmed[3]
        lastCamp = clampI(d.lastCamp, 0, m.camps.count - 1)
        var px = d.x
        var py = d.y
        if !(m.canWalk(px, py) && m.main[IsleMap.index(px, py)]) {
            let c0 = m.camps[lastCamp]
            px = IsleMap.x(c0)
            py = IsleMap.y(c0)
        }
        x = px
        y = py
        if !roster.contains(where: { $0.hp > 0 }) { healAll() }
        populate()
    }

    public func serialize() -> SaveData {
        var bag: [String: Int] = [:]
        for k in ItemKind.allCases { bag[k.rawValue] = items[k] ?? 0 }
        return SaveData(v: 2, seed: seed, isle: isle, x: x, y: y, lastCamp: lastCamp, roster: roster, seen: seen.sorted(),
                        grownSeen: grownSeen.sorted(), items: bag, unlocked: unlocked, guardCalmed: guardCalmed,
                        claimed: claimed.sorted(), winsBy: winsBy, steps: steps, wins: wins, done: done, ended: ended)
    }

    // MARK: Queries

    public var isleInfo: IsleInfo { GameData.isles[isle] }
    public var owned: Set<String> { Set(roster.map { $0.sp }) }
    public var partyCount: Int { min(4, roster.count) }
    public var tileIndex: Int { IsleMap.index(x, y) }

    public func count(_ k: ItemKind) -> Int { items[k] ?? 0 }
    public func wildAt(_ tx: Int, _ ty: Int) -> Wild? { wilds.first { $0.x == tx && $0.y == ty } }
    public func pickupAt(_ tx: Int, _ ty: Int) -> Pickup? { pickups.first { $0.x == tx && $0.y == ty } }

    /// The first party member still on its feet, if any.
    public func firstAble() -> Int? {
        for i in 0..<partyCount where roster[i].hp > 0 { return i }
        return nil
    }

    public func healAll() {
        for i in roster.indices { roster[i].hp = roster[i].maxHp }
    }

    func mapFor(_ i: Int) -> IsleMap {
        if let m = maps[i] { return m }
        let m = MapGen.make(seed: seed &+ UInt32(i) &* 104729, isle: i)
        maps[i] = m
        return m
    }

    func addItems(_ r: [ItemKind: Int]) {
        for (k, n) in r { items[k] = min(30, (items[k] ?? 0) + n) }
    }

    public static func itemText(_ r: [ItemKind: Int]) -> String {
        var out: [String] = []
        for k in ItemKind.allCases {
            if let n = r[k], n > 0 {
                let info = GameData.items[k]!
                out.append("\(n) \(n == 1 ? info.singular : info.plural)")
            }
        }
        return out.joined(separator: ", ")
    }

    // MARK: Wild creatures and pickups

    func levelAt(_ tx: Int, _ ty: Int, rarity: Int) -> Int {
        let b = isleInfo.base
        let d = hypot(Double(tx - IsleMap.x(map.start)), Double(ty - IsleMap.y(map.start)))
        let extra = dice.chance(0.3) ? 1 : 0
        return clampI(b + Int((d / 4.5).rounded(.down)) + min(rarity, 2) + extra, b, b + 9)
    }

    @discardableResult
    func spawnOne(initial: Bool) -> Bool {
        let own = owned
        let present = Set(wilds.map { $0.sp })
        let info = isleInfo
        var slot = 0
        var chosen: SpeciesInfo? = nil
        search: for sl in 1...4 {
            for id in info.habitat(sl).pool where !own.contains(id) && !present.contains(id) {
                chosen = GameData.sp(id)
                slot = sl
                break search
            }
        }
        if chosen == nil {
            let t = map.tilesBy
            let tot = t[1].count + t[2].count + t[3].count + t[4].count
            var r = dice.unit() * Double(tot)
            slot = 1
            while slot < 4 {
                if r < Double(t[slot].count) { break }
                r -= Double(t[slot].count)
                slot += 1
            }
            let pool = info.habitat(slot).pool
            let q = dice.unit()
            chosen = GameData.sp(q < 0.6 ? pool[0] : (q < 0.9 ? pool[1] : pool[2]))
        }
        guard let s = chosen else { return false }
        let tiles = map.tilesBy[slot]
        let minD: Double = initial ? 4 : 7
        for _ in 0..<60 {
            let j = tiles[dice.int(tiles.count)]
            let tx = IsleMap.x(j)
            let ty = IsleMap.y(j)
            if hypot(Double(tx - x), Double(ty - y)) < minD || wildAt(tx, ty) != nil || pickupAt(tx, ty) != nil { continue }
            let lv = levelAt(tx, ty, rarity: s.rarity)
            wilds.append(Wild(id: nextId, sp: s.id, level: lv, grown: s.canGrow && lv >= s.growLevel, slot: slot, x: tx, y: ty))
            nextId += 1
            return true
        }
        return false
    }

    @discardableResult
    func spawnPickup() -> Bool {
        for _ in 0..<40 {
            let sl = 1 + dice.int(4)
            let tiles = map.tilesBy[sl]
            let j = tiles[dice.int(tiles.count)]
            let tx = IsleMap.x(j)
            let ty = IsleMap.y(j)
            if hypot(Double(tx - x), Double(ty - y)) < 5 || wildAt(tx, ty) != nil || pickupAt(tx, ty) != nil { continue }
            let q = dice.unit()
            pickups.append(Pickup(id: nextId, x: tx, y: ty, kind: q < 0.6 ? .berry : (q < 0.85 ? .reed : .root)))
            nextId += 1
            return true
        }
        return false
    }

    func populate() {
        wilds = []
        pickups = []
        var g = 0
        while g < 400 && wilds.count < Game.population {
            spawnOne(initial: true)
            g += 1
        }
        g = 0
        while g < 60 && pickups.count < Game.pickupTarget {
            spawnPickup()
            g += 1
        }
    }

    func removeWild(id: Int) {
        wilds.removeAll { $0.id == id }
    }

    /// Lets the wild creatures wander a little. Returns true when anything moved or appeared.
    @discardableResult
    public func tick() -> Bool {
        var moved = false
        for i in wilds.indices {
            if dice.unit() > 0.3 { continue }
            let d = Game.dirs[dice.int(4)]
            let nx = wilds[i].x + d.0
            let ny = wilds[i].y + d.1
            if !map.canWalk(nx, ny) { continue }
            let j = IsleMap.index(nx, ny)
            if !map.main[j] || map.isCamp[j] || Int(map.biome[j]) != wilds[i].slot { continue }
            if (nx == x && ny == y) || wildAt(nx, ny) != nil || pickupAt(nx, ny) != nil { continue }
            wilds[i].x = nx
            wilds[i].y = ny
            moved = true
        }
        if wilds.count < Game.population && dice.chance(0.4) {
            if spawnOne(initial: false) { moved = true }
        }
        return moved
    }

    /// Called when an encounter closes: keeps the island populated however fast encounters go.
    public func afterEncounter() {
        var g = 0
        while g < 2 && wilds.count < Game.population {
            spawnOne(initial: false)
            g += 1
        }
    }

    // MARK: Walking

    /// Shortest route to a tile as a list of tile indices, or nil when there is none.
    /// The goal itself may be a creature's tile or the shrine; walking into it starts that meeting.
    public func findPath(toX tx: Int, y ty: Int, avoidWilds: Bool) -> [Int]? {
        guard map.inBounds(tx, ty) else { return nil }
        let n = Game.W * Game.H
        var prev = [Int](repeating: -1, count: n)
        var queue = [Int](repeating: 0, count: n)
        var head = 0
        var tail = 0
        let s = IsleMap.index(x, y)
        let goal = IsleMap.index(tx, ty)
        var occ = [Bool](repeating: false, count: avoidWilds ? n : 0)
        if avoidWilds { for w in wilds { occ[IsleMap.index(w.x, w.y)] = true } }
        prev[s] = s
        queue[tail] = s
        tail += 1
        while head < tail {
            let c = queue[head]
            head += 1
            if c == goal { break }
            let cx = c % Game.W
            let cy = c / Game.W
            for d in Game.dirs {
                let nx = cx + d.0
                let ny = cy + d.1
                if !map.inBounds(nx, ny) { continue }
                let j = IsleMap.index(nx, ny)
                if prev[j] != -1 { continue }
                if j == goal {
                    if !map.canWalk(nx, ny) && j != map.shrine { continue }
                } else if !map.canWalk(nx, ny) || (avoidWilds && occ[j]) {
                    continue
                }
                prev[j] = c
                queue[tail] = j
                tail += 1
            }
        }
        if prev[goal] == -1 { return nil }
        var path: [Int] = []
        var k = goal
        while k != s {
            path.append(k)
            k = prev[k]
        }
        return path.reversed()
    }

    /// Whether a tap on this tile is somewhere the player could try to go.
    public func isDestination(_ tx: Int, _ ty: Int) -> Bool {
        guard map.inBounds(tx, ty) else { return false }
        return map.canWalk(tx, ty) || IsleMap.index(tx, ty) == map.shrine
    }

    public func step(dx: Int, dy: Int) -> StepResult {
        let nx = x + dx
        let ny = y + dy
        if dx != 0 { face = dx }
        if map.inBounds(nx, ny) && IsleMap.index(nx, ny) == map.shrine { return .shrine }
        if !map.canWalk(nx, ny) { return .blocked }
        if let w = wildAt(nx, ny) { return .encounter(wildId: w.id) }
        x = nx
        y = ny
        steps += 1
        var info = StepInfo()
        if let pi = pickups.firstIndex(where: { $0.x == nx && $0.y == ny }) {
            let p = pickups.remove(at: pi)
            addItems([p.kind: 1])
            info.found = p.kind
        }
        if let ci = map.camps.firstIndex(of: IsleMap.index(nx, ny)) {
            info.restedTired = rest(at: ci)
        } else {
            if steps % 3 == 0 {
                for i in 0..<partyCount {
                    let m = roster[i].maxHp
                    if roster[i].hp > 0 && roster[i].hp < m {
                        roster[i].hp = min(m, roster[i].hp + max(1, roundHalfUp(Double(m) * 0.02)))
                    }
                }
            }
            if steps % 45 == 0 && pickups.count < Game.pickupTarget { spawnPickup() }
        }
        return .moved(info)
    }

    /// Rests the whole team at a camp. Returns true when someone needed it.
    @discardableResult
    func rest(at camp: Int) -> Bool {
        let tired = roster.contains { $0.hp < $0.maxHp }
        lastCamp = camp
        healAll()
        return tired
    }

    func moveToLastCamp() {
        let c0 = map.camps[lastCamp]
        x = IsleMap.x(c0)
        y = IsleMap.y(c0)
    }

    /// Sails to an open isle. The team arrives rested at that isle's first camp.
    @discardableResult
    public func sail(to i: Int) -> Bool {
        guard i >= 0, i < unlocked, i != isle else { return false }
        isle = i
        map = mapFor(i)
        lastCamp = 0
        x = IsleMap.x(map.start)
        y = IsleMap.y(map.start)
        healAll()
        populate()
        return true
    }

    // MARK: Team and bag

    public func moveMember(_ i: Int, by d: Int) {
        let j = i + d
        guard i >= 0, i < roster.count, j >= 0, j < roster.count else { return }
        roster.swapAt(i, j)
    }

    /// Uses a Sunberry or Wakeroot on a roster member. Returns the line to show, or nil when it cannot be used.
    public func applyItem(_ k: ItemKind, on i: Int) -> String? {
        guard i >= 0, i < roster.count else { return nil }
        let c = roster[i]
        if k == .berry && c.hp > 0 && c.hp < c.maxHp && count(.berry) > 0 {
            items[.berry] = count(.berry) - 1
            let h = Rules.healFrac(&roster[i], 0.5)
            return "\(c.name) eats a Sunberry and recovers \(h) health."
        }
        if k == .root && c.hp <= 0 && count(.root) > 0 {
            items[.root] = count(.root) - 1
            roster[i].hp = max(1, roundHalfUp(Double(c.maxHp) * 0.5))
            return "\(c.name) chews a Wakeroot and gets back up."
        }
        return nil
    }

    // MARK: Field notes

    public func tasks(isle i: Int) -> [TaskInfo] {
        let b = GameData.isles[i].base
        let home = GameData.species.filter { $0.isle == i }
        let own = owned
        let n = home.count
        let friends = home.filter { own.contains($0.id) }.count
        let maxLv = roster.map { $0.level }.max() ?? 0
        var t: [TaskInfo] = []
        func add(_ id: String, _ text: String, _ goal: Int, _ value: Int, _ reward: [ItemKind: Int]) {
            t.append(TaskInfo(id: id, text: text, goal: goal, value: value, reward: reward, done: claimed.contains(id)))
        }
        let few = i == 3 ? 2 : 3
        add("\(i)a", "Befriend \(few) creatures native to this isle", few, friends, [.berry: 3])
        if i < 3 {
            var cov = 0
            for sl in 1...4 where home.contains(where: { $0.slot == sl && own.contains($0.id) }) { cov += 1 }
            add("\(i)b", "Befriend a creature from each of the four habitats", 4, cov, [.reed: 2])
        }
        add("\(i)c", "Win \(8 + i * 2) encounters on this isle", 8 + i * 2, winsBy[i], [.berry: 2, .root: 1])
        add("\(i)d", "Raise a companion to level \(b + 7)", b + 7, maxLv, [.berry: 3])
        if i < 3 {
            add("\(i)e", "Raise a creature from this isle until it grows", 1, home.filter { grownSeen.contains($0.id) }.count, [.reed: 2, .root: 1])
        }
        add("\(i)g", "Calm the guardian at the shrine", 1, guardCalmed[i] ? 1 : 0, [.berry: 4, .root: 1])
        add("\(i)f", "Befriend all \(n) creatures native to this isle", n, friends, [.reed: 3, .root: 2])
        return t
    }

    /// Hands out rewards for any notes just completed and returns the lines to show.
    func checkTasks() -> [String] {
        var msgs: [String] = []
        for i in 0..<min(unlocked, GameData.isles.count) {
            for t in tasks(isle: i) where !t.done && t.value >= t.goal {
                claimed.insert(t.id)
                addItems(t.reward)
                msgs.append("Note complete: \(t.text). You receive \(Game.itemText(t.reward)).")
            }
        }
        return msgs
    }

    // MARK: Encounters

    public func startWildBattle(wildId: Int) -> Battle? {
        guard let w = wilds.first(where: { $0.id == wildId }), let a = firstAble() else { return nil }
        seen.insert(w.sp)
        return Battle(game: self, wild: w, act: a)
    }

    public func startGuardianBattle() -> Battle? {
        guard !guardCalmed[isle], let a = firstAble() else { return nil }
        let b = Battle(game: self, guardianAct: a)
        seen.insert(b.foe.sp)
        return b
    }
}
