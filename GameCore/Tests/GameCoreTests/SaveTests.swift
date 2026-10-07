import XCTest
@testable import GameCore

final class SaveTests: XCTestCase {
    func testRoundTrip() throws {
        let game = Game(starter: "whiffet", seed: 31337, dice: Dice(seed: 5))
        let bot = Bot(game: game)
        _ = bot.run(maxEncounters: 25)
        let save = game.serialize()
        let data = try JSONEncoder().encode(save)
        let back = try JSONDecoder().decode(SaveData.self, from: data)
        XCTAssertEqual(back, save)
        let again = Game(save: back, dice: Dice(seed: 6))
        XCTAssertNotNil(again)
        XCTAssertEqual(again?.serialize(), save)
    }

    func testBrokenSavesAreRefused() {
        let base = Game(starter: "plipple", seed: 1, dice: Dice(seed: 1)).serialize()
        var a = base
        a.v = 1
        XCTAssertNil(Game(save: a))
        var b = base
        b.roster = []
        XCTAssertNil(Game(save: b))
        var c = base
        c.roster[0].sp = "nope"
        XCTAssertNil(Game(save: c))
        var d = base
        d.roster[0].level = 999
        XCTAssertNil(Game(save: d))
        XCTAssertThrowsError(try JSONDecoder().decode(SaveData.self, from: Data("{not json".utf8)))
    }

    func testOddSavesAreRepaired() {
        var s = Game(starter: "plipple", seed: 77, dice: Dice(seed: 1)).serialize()
        s.isle = 9
        s.x = -5
        s.y = 900
        s.lastCamp = 99
        s.unlocked = 99
        s.guardCalmed = [true, false]
        s.items = ["berry": 999, "reed": -4]
        s.claimed = ["0a", "toolongid"]
        s.roster = [Creature(sp: "plipple", level: 4, xp: 3, hp: 99999, grown: true),
                    Creature(sp: "plipple", level: 9, xp: 0, hp: 1),
                    Creature(sp: "morrowfin", level: 12, xp: -7, hp: 5, grown: true)]
        s.seen = ["zzz"]
        s.steps = -4
        guard let g = Game(save: s, dice: Dice(seed: 2)) else { return XCTFail("save refused") }
        XCTAssertEqual(g.roster.count, 2)
        XCTAssertEqual(g.roster[0].hp, g.roster[0].maxHp)
        XCTAssertTrue(g.roster[0].grown)
        XCTAssertFalse(g.roster[1].grown)
        XCTAssertEqual(g.roster[1].xp, 0)
        XCTAssertTrue(g.map.canWalk(g.x, g.y))
        XCTAssertEqual(g.steps, 0)
        XCTAssertLessThanOrEqual(g.isle, 3)
        XCTAssertEqual(g.unlocked, 4)
        XCTAssertEqual(g.count(.berry), 30)
        XCTAssertEqual(g.count(.reed), 0)
        XCTAssertEqual(g.claimed, ["0a"])
        XCTAssertEqual(g.seen, ["plipple", "morrowfin"])
    }

    func testItemsAndNotes() {
        let g = Game(starter: "burrbit", seed: 5, dice: Dice(seed: 3))
        XCTAssertEqual(g.count(.berry), 2)
        XCTAssertNil(g.applyItem(.berry, on: 0), "full health needs no berry")
        XCTAssertNil(g.applyItem(.root, on: 0))
        g.roster[0].hp = 3
        XCTAssertNotNil(g.applyItem(.berry, on: 0))
        XCTAssertEqual(g.count(.berry), 1)
        XCTAssertGreaterThan(g.roster[0].hp, 3)
        let t = g.tasks(isle: 0)
        XCTAssertEqual(t.count, 7)
        XCTAssertEqual(t[0].value, 1)
        XCTAssertFalse(t.contains { $0.done })
        XCTAssertFalse(g.sail(to: 1))
        XCTAssertFalse(g.sail(to: 0))
        XCTAssertEqual(Game.itemText([.berry: 1, .root: 2]), "1 Sunberry, 2 Wakeroots")
    }
}
