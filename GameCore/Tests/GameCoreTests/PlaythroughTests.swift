import XCTest
@testable import GameCore

/// A simple automated player. It walks, fights, whistles, uses items, rests, challenges guardians and sails,
/// checking the game's state for nonsense after every action.
final class Bot {
    let game: Game
    var issues: [String] = []
    var encounters = 0
    var turns = 0
    var blackouts = 0
    var friends = 0
    var itemsUsed = 0
    var guardianTries = [0, 0, 0, 0]
    var walked = 0

    init(game: Game) { self.game = game }

    func check(_ place: String) {
        var seen: Set<String> = []
        for c in game.roster {
            if c.hp < 0 || c.hp > c.maxHp { issues.append("\(place): hp out of range \(c.sp) \(c.hp)/\(c.maxHp)") }
            if c.level < 1 || c.level > 40 { issues.append("\(place): bad level \(c.sp) \(c.level)") }
            if c.xp < 0 { issues.append("\(place): bad xp \(c.sp)") }
            if !seen.insert(c.sp).inserted { issues.append("\(place): duplicate \(c.sp)") }
            if c.grown && !c.species.canGrow { issues.append("\(place): grown without a grown form \(c.sp)") }
            if !c.grown && c.species.canGrow && c.level >= c.species.growLevel { issues.append("\(place): should have grown \(c.sp) L\(c.level)") }
        }
        for k in ItemKind.allCases where game.count(k) < 0 || game.count(k) > 30 { issues.append("\(place): bad item count \(k)") }
        let m = game.map
        let i = game.tileIndex
        if !m.canWalk(game.x, game.y) || !m.main[i] { issues.append("\(place): player on a bad tile") }
        var occ: Set<Int> = []
        let base = game.isleInfo.base
        for w in game.wilds {
            let j = IsleMap.index(w.x, w.y)
            if !occ.insert(j).inserted { issues.append("\(place): two wilds on one tile") }
            if !m.canWalk(w.x, w.y) || !m.main[j] { issues.append("\(place): wild on a bad tile") }
            if w.x == game.x && w.y == game.y { issues.append("\(place): wild on the player") }
            if Int(m.biome[j]) != w.slot { issues.append("\(place): wild left its habitat") }
            if w.level < base || w.level > base + 9 { issues.append("\(place): wild level out of range \(w.level)") }
        }
        if game.wilds.count > Game.population { issues.append("\(place): too many wilds") }
    }

    func sortParty() {
        for _ in 0..<6 {
            var i = game.roster.count - 1
            while i >= 1 {
                if game.roster[i].level > game.roster[i - 1].level { game.moveMember(i, by: -1) }
                i -= 1
            }
        }
    }

    /// Walks toward a tile and returns what stopped the walk.
    func walk(toX tx: Int, y ty: Int) -> StepResult {
        var guardSteps = 0
        while guardSteps < 400 {
            guardSteps += 1
            if game.x == tx && game.y == ty { return .moved(StepInfo()) }
            guard var path = game.findPath(toX: tx, y: ty, avoidWilds: true) ?? game.findPath(toX: tx, y: ty, avoidWilds: false), !path.isEmpty else {
                return .blocked
            }
            // take one step, then let the island move, as the real game does
            let next = path.removeFirst()
            let r = game.step(dx: IsleMap.x(next) - game.x, dy: IsleMap.y(next) - game.y)
            walked += 1
            if walked % 7 == 0 { game.tick() }
            switch r {
            case .moved: continue
            default: return r
            }
        }
        return .blocked
    }

    func fight(_ b: Battle) {
        encounters += 1
        var mine = 0
        var usedReed = false
        while !b.over {
            mine += 1
            turns += 1
            if mine > 200 {
                issues.append("encounter exceeded 200 turns vs \(b.foe.sp)")
                b.leave()
                break
            }
            if b.needsSwap {
                guard let first = b.swapChoices.first else {
                    issues.append("forced swap with nobody to swap to")
                    break
                }
                XCTAssertFalse(b.swap(to: first).isEmpty)
                continue
            }
            // actions that must be refused while they are not allowed
            if b.strongState != .ready { XCTAssertTrue(b.perform(.strong).isEmpty) }
            let me = b.me
            let foe = b.foe
            let own = game.owned.contains(foe.sp)
            if b.kind == .wild && !own {
                let frac = Double(foe.hp) / Double(foe.maxHp)
                if frac <= 0.5 {
                    if !usedReed, foe.species.rarity >= 2, let reed = b.bagOptions.first(where: { $0.kind == .reed }) {
                        usedReed = true
                        itemsUsed += 1
                        XCTAssertFalse(b.useItem(reed).isEmpty)
                        continue
                    }
                    let zone = b.makeWhistleZone()
                    XCTAssertTrue(zone.a >= 0 && zone.b <= 1 && zone.b - zone.a >= 0.0999, "whistle band \(zone)")
                    let events = b.whistle(hit: game.dice.chance(0.85))
                    XCTAssertFalse(events.isEmpty)
                    continue
                }
            }
            if Double(me.hp) < 0.3 * Double(me.maxHp), let berry = b.bagOptions.first(where: { $0.kind == .berry && $0.index == b.act }) {
                itemsUsed += 1
                XCTAssertFalse(b.useItem(berry).isEmpty)
                continue
            }
            if Double(me.hp) < 0.25 * Double(me.maxHp), let other = b.swapChoices.first {
                XCTAssertFalse(b.swap(to: other).isEmpty)
                continue
            }
            if game.dice.chance(0.06) {
                _ = b.perform(.brace)
                continue
            }
            let m = Rules.mult(me.element, foe.element)
            let careful = b.kind == .wild && !own
            var move: Battle.Move = careful ? .nudge : (m >= 1 ? .element : (foe.hp <= 1 ? .element : .nudge))
            if !careful && b.kind == .wild && move == .nudge && Double(foe.hp) / Double(foe.maxHp) < 0.4 { move = .element }
            if !careful && m >= 1 && b.strongState == .ready { move = .strong }
            let before = foe.hp
            let events = b.perform(move)
            XCTAssertFalse(events.isEmpty)
            if careful && move == .nudge && !b.over && b.foe.sp == foe.sp {
                XCTAssertGreaterThanOrEqual(b.foe.hp, 1, "nudge knocked out a wild creature from \(before)")
            }
        }
        if b.result == .blackout { blackouts += 1 }
        if b.result == .friend { friends += 1 }
        // nothing may happen once the encounter is decided
        XCTAssertTrue(b.perform(.nudge).isEmpty)
        XCTAssertTrue(b.whistle(hit: true).isEmpty)
        game.afterEncounter()
        check("after encounter")
    }

    /// Plays until the last guardian is calm. Returns false when it ran out of patience.
    func run(maxEncounters: Int) -> Bool {
        check("start")
        var idle = 0
        while !game.ended && encounters < maxEncounters && issues.count < 20 && idle < 2000 {
            idle += 1
            sortParty()
            let isle = game.isle
            let info = game.isleInfo
            if game.guardCalmed[isle] {
                if isle < 3 {
                    XCTAssertFalse(game.sail(to: isle + 2), "sailed past a locked isle")
                    XCTAssertTrue(game.sail(to: isle + 1))
                    check("after sailing")
                    continue
                }
                break
            }
            let party = Array(game.roster.prefix(4))
            let healthy = party.filter { Double($0.hp) > 0.5 * Double($0.maxHp) }.count
            let own = game.owned
            let missing = info.habitats.flatMap { $0.pool }.filter { !own.contains($0) }
            let gLv = info.guardianTeam.last!.level
            let lv = party.map { $0.level }.sorted(by: >)
            let need = gLv - 2 + max(0, guardianTries[isle] - 1)
            let ready = missing.isEmpty && lv.count >= 3 && lv[2] >= min(40, need)
            if healthy == 0 || (ready && healthy < party.count) {
                var best = -1
                var bd = Int.max
                for c in game.map.camps {
                    let d = abs(IsleMap.x(c) - game.x) + abs(IsleMap.y(c) - game.y)
                    if d > 0 && d < bd { bd = d; best = c }
                }
                let r = walk(toX: IsleMap.x(best), y: IsleMap.y(best))
                if case .encounter(let id) = r, let b = game.startWildBattle(wildId: id) { fight(b) }
                check("after walking to camp")
                continue
            }
            if ready {
                let s = game.map.shrine
                let r = walk(toX: IsleMap.x(s), y: IsleMap.y(s))
                if r == .shrine {
                    guardianTries[isle] += 1
                    if let b = game.startGuardianBattle() {
                        XCTAssertEqual(b.kind, .guardian)
                        XCTAssertFalse(b.canWhistle)
                        fight(b)
                    } else {
                        issues.append("guardian would not start")
                    }
                } else if case .encounter(let id) = r, let b = game.startWildBattle(wildId: id) {
                    fight(b)
                }
                continue
            }
            let top = lv.first ?? 1
            var target: Wild? = nil
            var bs = Int.max
            for w in game.wilds {
                let d = abs(w.x - game.x) + abs(w.y - game.y)
                let s = d + (own.contains(w.sp) ? 60 - (w.level - info.base) * 3 : 0) + max(0, w.level - top - 1) * 25
                if s < bs { bs = s; target = w }
            }
            guard let t = target else {
                game.tick()
                continue
            }
            let r = walk(toX: t.x, y: t.y)
            if case .encounter(let id) = r {
                if let b = game.startWildBattle(wildId: id) { fight(b) } else { issues.append("encounter would not start") }
            }
            check("after walking")
        }
        return game.ended
    }
}

final class PlaythroughTests: XCTestCase {
    func testWholeGameCanBePlayedThrough() {
        let starters = GameData.starters
        for run in 0..<6 {
            let game = Game(starter: starters[run % 3], seed: UInt32(1000 + run * 7919), dice: Dice(seed: UInt32(77 + run)))
            let bot = Bot(game: game)
            let finished = bot.run(maxEncounters: 4000)
            XCTAssertTrue(bot.issues.isEmpty, "run \(run): \(bot.issues.prefix(5).joined(separator: " / "))")
            XCTAssertTrue(finished, "run \(run) did not finish: isle \(game.isle), owned \(game.owned.count), encounters \(bot.encounters), blackouts \(bot.blackouts)")
            XCTAssertEqual(game.owned.count, 40, "run \(run)")
            XCTAssertTrue(game.done, "run \(run)")
            XCTAssertEqual(game.guardCalmed, [true, true, true, true], "run \(run)")
            XCTAssertTrue(game.owned.contains("skyvane"))
            print("playthrough \(run): \(bot.encounters) encounters, \(bot.turns) turns, \(game.steps) steps, \(bot.blackouts) blackouts, \(bot.itemsUsed) items, guardian tries \(bot.guardianTries), top levels \(game.roster.prefix(4).map { $0.level })")
        }
    }

    func testSameSeedPlaysTheSame() {
        func play() -> SaveData {
            let game = Game(starter: "burrbit", seed: 4242, dice: Dice(seed: 9))
            let bot = Bot(game: game)
            _ = bot.run(maxEncounters: 60)
            return game.serialize()
        }
        XCTAssertEqual(play(), play())
    }
}
