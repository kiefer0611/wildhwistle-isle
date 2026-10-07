// Generates GameData.swift and Fixtures.swift for the native build from the tested web build's data.
const fs = require('fs'); const path = require('path');
const F = JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures.json'), 'utf8'));
const repo = '/home/claude/wildhwistle-isle';
const q = s => JSON.stringify(s).replace(/’/g, '\\u{2019}');
let o = `// Generated from the tested reference build by tools/gen-swift.js. Edit the source data, not this file.
import Foundation

public enum Element: String, Codable, CaseIterable, Sendable {
    case tide, flint, gale, thorn, ember, frost
}

public enum ItemKind: String, Codable, CaseIterable, Sendable {
    case berry, reed, root
}

public struct ElementInfo: Sendable {
    public let name: String
    public let colorHex: String
    public let beats: [Element]
    public let strongMove: String
}

public struct ItemInfo: Sendable {
    public let singular: String
    public let plural: String
    public let blurb: String
}

public struct HabitatInfo: Sendable {
    public let name: String
    public let whereText: String
    public let element: Element
    public let palette: [String]
    public let deco: String
    public let decoColor: String
    public let obstacle: String
    public let obstacleColors: [String]
    public let density: Double
    public let pool: [String]
}

public struct GuardianMember: Sendable {
    public let species: String
    public let level: Int
}

public struct IsleInfo: Sendable {
    public let name: String
    public let base: Int
    public let sea: [String]
    public let guardianName: String
    public let guardianTeam: [GuardianMember]
    /// Four habitats; habitat number \`n\` (1...4) is \`habitats[n - 1]\`.
    public let habitats: [HabitatInfo]

    public func habitat(_ slot: Int) -> HabitatInfo { habitats[slot - 1] }
}

public struct SpeciesInfo: Sendable {
    public let id: String
    public let name: String
    public let element: Element
    public let isle: Int
    public let slot: Int
    public let rarity: Int
    public let hp: Int
    public let atk: Int
    public let def: Int
    public let spd: Int
    public let move: String
    /// Empty when the species has no grown form.
    public let grownName: String
    public let blurb: String
    public let growLevel: Int
    public let strongLevel: Int

    public var canGrow: Bool { !grownName.isEmpty }
}

public struct ArtInfo: Sendable {
    public let shape: String
    public let body: String
    public let belly: String
    public let line: String
    public let ears: String
    public let pattern: String
    public let eyes: String
    public let extras: String
}

public enum GameData {
    public static let maxLevel = 40
    public static let rarityNames = ${q(['Common', 'Uncommon', 'Rare', 'Legend'])}
    public static let starters = ["plipple", "whiffet", "burrbit"]

    public static let elements: [Element: ElementInfo] = [
`;
for (const k of Object.keys(F.EL)) { const e = F.EL[k]; o += `        .${k}: ElementInfo(name: ${q(e.n)}, colorHex: ${q(e.c)}, beats: [${e.beats.map(b => '.' + b).join(', ')}], strongMove: ${q(e.strong)}),\n`; }
o += `    ]

    public static let items: [ItemKind: ItemInfo] = [
`;
for (const k of Object.keys(F.ITEM)) { const e = F.ITEM[k]; o += `        .${k}: ItemInfo(singular: ${q(e[0])}, plural: ${q(e[1])}, blurb: ${q(e[2])}),\n`; }
o += `    ]

    public static let isles: [IsleInfo] = [
`;
for (const I of F.ISL) {
  o += `        IsleInfo(name: ${q(I.name)}, base: ${I.base}, sea: ${q(I.sea)}, guardianName: ${q(I.guardian.name)}, guardianTeam: [${I.guardian.team.map(t => `GuardianMember(species: ${q(t[0])}, level: ${t[1]})`).join(', ')}], habitats: [\n`;
  for (let s = 1; s <= 4; s++) { const S = I.slots[s]; o += `            HabitatInfo(name: ${q(S.name)}, whereText: ${q(S.where)}, element: .${S.el}, palette: ${q(S.pal)}, deco: ${q(S.deco)}, decoColor: ${q(S.dc)}, obstacle: ${q(S.obst)}, obstacleColors: ${q(S.oc)}, density: ${S.dens}, pool: ${q(S.pool)}),\n`; }
  o += `        ]),\n`;
}
o += `    ]

    public static let species: [SpeciesInfo] = [
`;
for (const s of F.SPL) o += `        SpeciesInfo(id: ${q(s.id)}, name: ${q(s.name)}, element: .${s.el}, isle: ${s.isle}, slot: ${s.slot}, rarity: ${s.rar}, hp: ${s.hp}, atk: ${s.atk}, def: ${s.def}, spd: ${s.spd}, move: ${q(s.move)}, grownName: ${q(s.g)}, blurb: ${q(s.blurb)}, growLevel: ${s.gl}, strongLevel: ${s.sl}),\n`;
o += `    ]

    public static let speciesById: [String: SpeciesInfo] = {
        var d: [String: SpeciesInfo] = [:]
        for s in species { d[s.id] = s }
        return d
    }()

    public static func sp(_ id: String) -> SpeciesInfo {
        guard let s = speciesById[id] else { preconditionFailure("unknown species \\(id)") }
        return s
    }

    public static let art: [String: ArtInfo] = [
`;
for (const k of Object.keys(F.ART)) { const a = F.ART[k]; o += `        ${q(k)}: ArtInfo(shape: ${q(a[0])}, body: ${q(a[1])}, belly: ${q(a[2])}, line: ${q(a[3])}, ears: ${q(a[4])}, pattern: ${q(a[5])}, eyes: ${q(a[6])}, extras: ${q(a[7])}),\n`; }
o += `    ]
}
`;
fs.mkdirSync(path.join(repo, 'GameCore/Sources/GameCore'), { recursive: true });
fs.writeFileSync(path.join(repo, 'GameCore/Sources/GameCore/GameData.swift'), o);

let t = `// Generated reference values from the tested web build (tools/gen-swift.js). Used to prove the native rules match.
import Foundation

enum Fixtures {
    struct MapRef { let seedIn: UInt32; let isle: Int; let seed: UInt32; let start: Int; let shrine: Int; let camps: [Int]; let counts: [Int]; let mainCount: Int; let hash: UInt32; let vsum: Int }
    struct StatRef { let sp: String; let level: Int; let grown: Bool; let hp: Int; let atk: Int; let def: Int; let spd: Int }
    struct DamageRef { let a: String; let al: Int; let d: String; let dl: Int; let pow: Int; let el: String?; let braced: Bool; let rnd: Double; let out: Int }

    static let rng: [(seed: UInt32, values: [UInt32])] = [
${F.rng.map(r => `        (${r.seed}, [${r.v.join(', ')}]),`).join('\n')}
    ]

    static let maps: [MapRef] = [
${F.maps.map(m => `        MapRef(seedIn: ${m.seedIn}, isle: ${m.isle}, seed: ${m.seed}, start: ${m.start}, shrine: ${m.shrine}, camps: [${m.camps.join(', ')}], counts: [${m.counts.join(', ')}], mainCount: ${m.mainCount}, hash: ${m.hash}, vsum: ${m.vsum}),`).join('\n')}
    ]

    static let stats: [StatRef] = [
${F.stats.map(s => `        StatRef(sp: ${q(s.sp)}, level: ${s.level}, grown: ${s.grown}, hp: ${s.hp}, atk: ${s.atk}, def: ${s.def}, spd: ${s.spd}),`).join('\n')}
    ]

    static let need: [(level: Int, xp: Int)] = [${F.need.map(n => `(${n[0]}, ${n[1]})`).join(', ')}]

    static let damage: [DamageRef] = [
${F.damage.map(d => `        DamageRef(a: ${q(d.a)}, al: ${d.al}, d: ${q(d.d)}, dl: ${d.dl}, pow: ${d.pow}, el: ${d.el ? q(d.el) : 'nil'}, braced: ${d.braced}, rnd: ${d.rnd}, out: ${d.out}),`).join('\n')}
    ]
}
`;
fs.mkdirSync(path.join(repo, 'GameCore/Tests/GameCoreTests'), { recursive: true });
fs.writeFileSync(path.join(repo, 'GameCore/Tests/GameCoreTests/Fixtures.swift'), t);
console.log('wrote', o.length, t.length);
