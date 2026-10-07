import XCTest
@testable import GameCore

final class DataTests: XCTestCase {
    func testFortySpeciesWithArt() {
        XCTAssertEqual(GameData.species.count, 40)
        var names: Set<String> = []
        for s in GameData.species {
            XCTAssertNotNil(GameData.art[s.id], "art for \(s.id)")
            XCTAssertTrue(names.insert(s.name).inserted, "duplicate name \(s.name)")
            if s.canGrow {
                XCTAssertTrue(names.insert(s.grownName).inserted, "duplicate name \(s.grownName)")
                XCTAssertGreaterThan(s.growLevel, GameData.isles[s.isle].base)
            }
        }
    }

    func testPoolsAndGuardians() {
        XCTAssertEqual(GameData.isles.count, 4)
        for isle in GameData.isles {
            XCTAssertEqual(isle.habitats.count, 4)
            for h in isle.habitats {
                XCTAssertEqual(h.pool.count, 3)
                XCTAssertEqual(h.palette.count, 2)
                XCTAssertEqual(h.obstacleColors.count, 2)
                for id in h.pool { XCTAssertNotNil(GameData.speciesById[id], id) }
            }
            for g in isle.guardianTeam { XCTAssertNotNil(GameData.speciesById[g.species], g.species) }
        }
        for s in GameData.species where s.rarity < 3 {
            XCTAssertTrue(GameData.isles[s.isle].habitat(s.slot).pool.contains(s.id), "\(s.id) missing from its home habitat")
        }
    }

    func testElementChartIsBalanced() {
        for a in Element.allCases {
            let info = GameData.elements[a]!
            XCTAssertEqual(info.beats.count, 2)
            var beatenBy = 0
            for b in Element.allCases where GameData.elements[b]!.beats.contains(a) {
                beatenBy += 1
                XCTAssertFalse(info.beats.contains(b), "\(a) and \(b) beat each other")
            }
            XCTAssertEqual(beatenBy, 2, "\(a)")
        }
        XCTAssertEqual(Rules.mult(.tide, .flint), 1.5)
        XCTAssertEqual(Rules.mult(.flint, .tide), 0.67)
        XCTAssertEqual(Rules.mult(.tide, .gale), 1)
        XCTAssertEqual(Rules.mult(nil, .gale), 1)
    }

    func testGrowthAndLevelCap() {
        var c = Rules.make("plipple", level: 8)
        XCTAssertFalse(Rules.tryGrow(&c))
        XCTAssertEqual(Rules.addXp(&c, Rules.need(8)), 1)
        XCTAssertEqual(c.level, 9)
        XCTAssertTrue(Rules.tryGrow(&c))
        XCTAssertEqual(c.name, "Ploomarin")
        XCTAssertFalse(Rules.tryGrow(&c))
        var top = Rules.make("oldscarp", level: 39)
        Rules.addXp(&top, 1_000_000)
        XCTAssertEqual(top.level, 40)
        XCTAssertEqual(top.xp, 0)
        XCTAssertLessThanOrEqual(top.hp, top.maxHp)
        XCTAssertFalse(Rules.makeWild("plipple", level: 8).grown)
        XCTAssertTrue(Rules.makeWild("plipple", level: 9).grown)
        XCTAssertFalse(Rules.makeWild("morrowfin", level: 40).grown)
    }

    func testEveryIslandIsPlayable() {
        for s in 1...40 {
            for isle in 0..<4 {
                let seed = UInt32(truncatingIfNeeded: s &* 2654435761) &+ UInt32(isle) &* 104729
                let m = MapGen.make(seed: seed, isle: isle)
                XCTAssertEqual(Set(m.camps).count, 4)
                XCTAssertFalse(m.main[m.shrine])
                XCTAssertFalse(m.camps.contains(m.shrine))
                let sx = IsleMap.x(m.shrine)
                let sy = IsleMap.y(m.shrine)
                let reach = [(1, 0), (-1, 0), (0, 1), (0, -1)].contains { m.inBounds(sx + $0.0, sy + $0.1) && m.main[IsleMap.index(sx + $0.0, sy + $0.1)] }
                XCTAssertTrue(reach, "shrine unreachable for seed \(seed)")
                for b in 1...4 {
                    XCTAssertGreaterThanOrEqual(m.tilesBy[b].count, 34)
                    for j in m.tilesBy[b] {
                        XCTAssertTrue(m.main[j] && Int(m.biome[j]) == b && !m.block[j])
                    }
                }
            }
        }
    }
}
