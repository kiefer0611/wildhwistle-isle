import XCTest
@testable import GameCore

/// Proves the native rules produce the same numbers as the tested reference build.
final class ParityTests: XCTestCase {
    func testRandomSequenceMatches() {
        for ref in Fixtures.rng {
            var r = Mulberry32(seed: ref.seed)
            for expected in ref.values {
                XCTAssertEqual(r.nextBits(), expected, "seed \(ref.seed)")
            }
        }
    }

    func testIslandsMatch() {
        for ref in Fixtures.maps {
            let m = MapGen.make(seed: ref.seedIn, isle: ref.isle)
            let tag = "seed \(ref.seedIn) isle \(ref.isle)"
            XCTAssertEqual(m.seed, ref.seed, tag)
            XCTAssertEqual(m.start, ref.start, tag)
            XCTAssertEqual(m.shrine, ref.shrine, tag)
            XCTAssertEqual(m.camps, ref.camps, tag)
            XCTAssertEqual(m.tilesBy.map { $0.count }, ref.counts, tag)
            XCTAssertEqual(m.mainCount, ref.mainCount, tag)
            var h: UInt32 = 0x811c9dc5
            func mix(_ b: UInt8) {
                h ^= UInt32(b)
                h = h &* 0x01000193
            }
            for b in m.biome { mix(b) }
            for b in m.block { mix(b ? 1 : 0) }
            for b in m.main { mix(b ? 1 : 0) }
            for b in m.isCamp { mix(b ? 1 : 0) }
            XCTAssertEqual(h, ref.hash, tag)
            var vsum = 0
            for v in m.vary { vsum += Int((Double(v) * 1000 + 0.5).rounded(.down)) }
            XCTAssertEqual(vsum, ref.vsum, tag)
        }
    }

    func testStatsMatch() {
        for ref in Fixtures.stats {
            let c = Creature(sp: ref.sp, level: ref.level, xp: 0, hp: 0, grown: ref.grown)
            let tag = "\(ref.sp) L\(ref.level) grown \(ref.grown)"
            XCTAssertEqual(Rules.stat(c, .hp), ref.hp, tag)
            XCTAssertEqual(Rules.stat(c, .atk), ref.atk, tag)
            XCTAssertEqual(Rules.stat(c, .def), ref.def, tag)
            XCTAssertEqual(Rules.stat(c, .spd), ref.spd, tag)
        }
    }

    func testExperienceCurveMatches() {
        for ref in Fixtures.need {
            XCTAssertEqual(Rules.need(ref.level), ref.xp, "level \(ref.level)")
        }
    }

    func testDamageMatches() {
        for ref in Fixtures.damage {
            let a = Rules.makeWild(ref.a, level: ref.al)
            let d = Rules.makeWild(ref.d, level: ref.dl)
            let el = ref.el.flatMap { Element(rawValue: $0) }
            let out = Rules.damage(attacker: a, defender: d, power: ref.pow, element: el, braced: ref.braced, rnd: ref.rnd)
            XCTAssertEqual(out, ref.out, "\(ref.a) L\(ref.al) vs \(ref.d) L\(ref.dl)")
        }
    }
}
