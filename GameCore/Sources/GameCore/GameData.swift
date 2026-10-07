// Generated from the tested reference build by tools/gen-swift.js. Edit the source data, not this file.
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
    /// Four habitats; habitat number `n` (1...4) is `habitats[n - 1]`.
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
    public static let rarityNames = ["Common","Uncommon","Rare","Legend"]
    public static let starters = ["plipple", "whiffet", "burrbit"]

    public static let elements: [Element: ElementInfo] = [
        .tide: ElementInfo(name: "Tide", colorHex: "#2C8DB5", beats: [.flint, .ember], strongMove: "Riptide"),
        .flint: ElementInfo(name: "Flint", colorHex: "#9B7355", beats: [.gale, .frost], strongMove: "Rockfall"),
        .gale: ElementInfo(name: "Gale", colorHex: "#7B7FD1", beats: [.thorn, .ember], strongMove: "Cyclone"),
        .thorn: ElementInfo(name: "Thorn", colorHex: "#4C9A4E", beats: [.tide, .flint], strongMove: "Overgrowth"),
        .ember: ElementInfo(name: "Ember", colorHex: "#D9622B", beats: [.thorn, .frost], strongMove: "Wildfire"),
        .frost: ElementInfo(name: "Frost", colorHex: "#5FA9CB", beats: [.tide, .gale], strongMove: "Whiteout"),
    ]

    public static let items: [ItemKind: ItemInfo] = [
        .berry: ItemInfo(singular: "Sunberry", plural: "Sunberries", blurb: "Restores half of one companion\u{2019}s health."),
        .reed: ItemInfo(singular: "Honeyreed", plural: "Honeyreeds", blurb: "Widens the band for your next whistle in this encounter."),
        .root: ItemInfo(singular: "Wakeroot", plural: "Wakeroots", blurb: "Wakes a worn-out companion at half health."),
    ]

    public static let isles: [IsleInfo] = [
        IsleInfo(name: "Hearth Isle", base: 1, sea: ["#3E8FB0","#4797B7"], guardianName: "The Hearth Guardian", guardianTeam: [GuardianMember(species: "morrowfin", level: 10), GuardianMember(species: "elderbriar", level: 11), GuardianMember(species: "oldscarp", level: 12)], habitats: [
            HabitatInfo(name: "Shore", whereText: "on the shore", element: .tide, palette: ["#E6D5A3","#DECC98"], deco: "pebble", decoColor: "#C9B67F", obstacle: "rock", obstacleColors: ["#A79A80","#B9AD95"], density: 0.03, pool: ["plipple","bracklet","morrowfin"]),
            HabitatInfo(name: "Meadow", whereText: "in the meadow", element: .gale, palette: ["#9CCB6B","#94C363"], deco: "grass", decoColor: "#7FB24F", obstacle: "bush", obstacleColors: ["#5F9E46","#6CAB52"], density: 0.04, pool: ["whiffet","skirlow","aerowen"]),
            HabitatInfo(name: "Grove", whereText: "in the grove", element: .thorn, palette: ["#5E9E5A","#579552"], deco: "litter", decoColor: "#4C8648", obstacle: "tree", obstacleColors: ["#2F6B3A","#3F8249"], density: 0.2, pool: ["burrbit","nettlekin","elderbriar"]),
            HabitatInfo(name: "Crag", whereText: "on the crag", element: .flint, palette: ["#B9AFA2","#AFA598"], deco: "crack", decoColor: "#998F82", obstacle: "boulder", obstacleColors: ["#857B70","#9D9388"], density: 0.16, pool: ["pebbrix","gravelope","oldscarp"]),
        ]),
        IsleInfo(name: "Cinder Isle", base: 11, sea: ["#2F7482","#377C8A"], guardianName: "The Cinder Guardian", guardianTeam: [GuardianMember(species: "mistmantle", level: 20), GuardianMember(species: "pyrelune", level: 21), GuardianMember(species: "basaltusk", level: 22)], habitats: [
            HabitatInfo(name: "Black Sand", whereText: "on the black sand", element: .flint, palette: ["#57525E","#4F4A56"], deco: "pebble", decoColor: "#6E6876", obstacle: "obsidian", obstacleColors: ["#2A2730","#6A6478"], density: 0.05, pool: ["obsidit","slagmite","basaltusk"]),
            HabitatInfo(name: "Ashfield", whereText: "in the ashfield", element: .ember, palette: ["#A9A198","#A0988F"], deco: "ash", decoColor: "#8A8279", obstacle: "vent", obstacleColors: ["#7A7168","#F1EEE8"], density: 0.05, pool: ["cindrel","ashwick","pyrelune"]),
            HabitatInfo(name: "Charwood", whereText: "in the charwood", element: .ember, palette: ["#7A6453","#70594A"], deco: "ash", decoColor: "#5E4A3C", obstacle: "deadtree", obstacleColors: ["#3A2A20","#FF8A3D"], density: 0.2, pool: ["smoldit","charrow","kilnhart"]),
            HabitatInfo(name: "Steam Pools", whereText: "by the steam pools", element: .tide, palette: ["#8CC0B8","#84B8B0"], deco: "bubble", decoColor: "#DDF2EE", obstacle: "boulder", obstacleColors: ["#6F8F8A","#8DAAA5"], density: 0.12, pool: ["bublet","geysling","mistmantle"]),
        ]),
        IsleInfo(name: "Rime Isle", base: 21, sea: ["#3F7FA6","#4787AD"], guardianName: "The Rime Guardian", guardianTeam: [GuardianMember(species: "borealune", level: 30), GuardianMember(species: "evermoss", level: 31), GuardianMember(species: "cryolith", level: 32)], habitats: [
            HabitatInfo(name: "Ice Shelf", whereText: "on the ice shelf", element: .frost, palette: ["#E3EEF4","#DAE8EF"], deco: "snow", decoColor: "#FFFFFF", obstacle: "icespike", obstacleColors: ["#7FBAD6","#F4FBFE"], density: 0.05, pool: ["floebit","rimewhisk","bergamoth"]),
            HabitatInfo(name: "Tundra", whereText: "on the tundra", element: .gale, palette: ["#BFCDAE","#B6C5A5"], deco: "grass", decoColor: "#9DB08A", obstacle: "rock", obstacleColors: ["#9AA39A","#B3BBB3"], density: 0.05, pool: ["driftlet","howlkin","borealune"]),
            HabitatInfo(name: "Pinewood", whereText: "in the pinewood", element: .thorn, palette: ["#5E8C78","#57846F"], deco: "litter", decoColor: "#4A7361", obstacle: "pine", obstacleColors: ["#2E5C4A","#EAF3F0"], density: 0.2, pool: ["needlet","conifawn","evermoss"]),
            HabitatInfo(name: "Glacier", whereText: "on the glacier", element: .frost, palette: ["#C5DCEA","#BBD4E3"], deco: "crack", decoColor: "#9DBFD2", obstacle: "icespike", obstacleColors: ["#8CC0D8","#E8F6FB"], density: 0.16, pool: ["shardlet","hoarhop","cryolith"]),
        ]),
        IsleInfo(name: "Tempest Isle", base: 31, sea: ["#2F4F73","#36577B"], guardianName: "The Storm Guardian", guardianTeam: [GuardianMember(species: "maelstrix", level: 37), GuardianMember(species: "glassmander", level: 38), GuardianMember(species: "fulgurwing", level: 39), GuardianMember(species: "skyvane", level: 40)], habitats: [
            HabitatInfo(name: "Stormbeach", whereText: "on the stormbeach", element: .tide, palette: ["#B9B3C6","#B0AABD"], deco: "pebble", decoColor: "#948DA3", obstacle: "rock", obstacleColors: ["#7F7890","#9992A8"], density: 0.04, pool: ["bublet","geysling","maelstrix"]),
            HabitatInfo(name: "Thunder Plain", whereText: "on the thunder plain", element: .gale, palette: ["#93A072","#8A976A"], deco: "grass", decoColor: "#74825A", obstacle: "bush", obstacleColors: ["#5F6E48","#6B7A53"], density: 0.04, pool: ["driftlet","howlkin","fulgurwing"]),
            HabitatInfo(name: "Glasswood", whereText: "in the glasswood", element: .ember, palette: ["#62748F","#5A6C87"], deco: "litter", decoColor: "#4D5E78", obstacle: "crystal", obstacleColors: ["#9FD8E8","#E6FAFF"], density: 0.2, pool: ["smoldit","charrow","glassmander"]),
            HabitatInfo(name: "Skyspire", whereText: "on the skyspire", element: .flint, palette: ["#8D8799","#857F91"], deco: "crack", decoColor: "#6F697B", obstacle: "boulder", obstacleColors: ["#6A6476","#8A8496"], density: 0.16, pool: ["obsidit","hoarhop","cryolith"]),
        ]),
    ]

    public static let species: [SpeciesInfo] = [
        SpeciesInfo(id: "plipple", name: "Plipple", element: .tide, isle: 0, slot: 1, rarity: 0, hp: 30, atk: 9, def: 9, spd: 10, move: "Splash", grownName: "Ploomarin", blurb: "Hops between rock pools and hums when the tide turns.", growLevel: 9, strongLevel: 6),
        SpeciesInfo(id: "bracklet", name: "Bracklet", element: .tide, isle: 0, slot: 1, rarity: 1, hp: 36, atk: 11, def: 12, spd: 7, move: "Brine Jet", grownName: "Brackmoor", blurb: "Carries a shell it has outgrown twice and refuses to swap.", growLevel: 11, strongLevel: 6),
        SpeciesInfo(id: "morrowfin", name: "Morrowfin", element: .tide, isle: 0, slot: 1, rarity: 2, hp: 42, atk: 14, def: 11, spd: 12, move: "Undertow", grownName: "", blurb: "Seen only at the waterline. Leaves long straight tracks in wet sand.", growLevel: 0, strongLevel: 6),
        SpeciesInfo(id: "whiffet", name: "Whiffet", element: .gale, isle: 0, slot: 2, rarity: 0, hp: 28, atk: 10, def: 8, spd: 14, move: "Gust", grownName: "Whifflorn", blurb: "Light enough to be carried off by a sneeze. Usually its own.", growLevel: 9, strongLevel: 6),
        SpeciesInfo(id: "skirlow", name: "Skirlow", element: .gale, isle: 0, slot: 2, rarity: 1, hp: 32, atk: 12, def: 9, spd: 13, move: "Crosswind", grownName: "Skirlanthe", blurb: "Glides a hand above the grass and whistles through its ears.", growLevel: 11, strongLevel: 6),
        SpeciesInfo(id: "aerowen", name: "Aerowen", element: .gale, isle: 0, slot: 2, rarity: 2, hp: 38, atk: 15, def: 10, spd: 15, move: "Squall", grownName: "", blurb: "Arrives ahead of weather. Meadow flowers lean toward it.", growLevel: 0, strongLevel: 6),
        SpeciesInfo(id: "burrbit", name: "Burrbit", element: .thorn, isle: 0, slot: 3, rarity: 0, hp: 32, atk: 9, def: 10, spd: 8, move: "Prickle", grownName: "Burrowick", blurb: "Collects burrs on purpose and is proud of every one.", growLevel: 9, strongLevel: 6),
        SpeciesInfo(id: "nettlekin", name: "Nettlekin", element: .thorn, isle: 0, slot: 3, rarity: 1, hp: 36, atk: 12, def: 11, spd: 9, move: "Briar Lash", grownName: "Nettlemere", blurb: "Grows a new leaf each spring and naps under the old ones.", growLevel: 11, strongLevel: 6),
        SpeciesInfo(id: "elderbriar", name: "Elderbriar", element: .thorn, isle: 0, slot: 3, rarity: 2, hp: 46, atk: 13, def: 14, spd: 6, move: "Root Surge", grownName: "", blurb: "Stands so still that moss settles on it. It does not mind.", growLevel: 0, strongLevel: 6),
        SpeciesInfo(id: "pebbrix", name: "Pebbrix", element: .flint, isle: 0, slot: 4, rarity: 0, hp: 34, atk: 8, def: 13, spd: 6, move: "Pebble Toss", grownName: "Pebbrock", blurb: "Rolls downhill for fun and walks back up complaining.", growLevel: 9, strongLevel: 6),
        SpeciesInfo(id: "gravelope", name: "Gravelope", element: .flint, isle: 0, slot: 4, rarity: 1, hp: 38, atk: 11, def: 14, spd: 8, move: "Rockslide", grownName: "Gravelorn", blurb: "Sure-footed on scree. Sharpens its horns on the same boulder daily.", growLevel: 11, strongLevel: 6),
        SpeciesInfo(id: "oldscarp", name: "Oldscarp", element: .flint, isle: 0, slot: 4, rarity: 2, hp: 50, atk: 13, def: 16, spd: 5, move: "Landfall", grownName: "", blurb: "Mistaken for an outcrop until it yawns.", growLevel: 0, strongLevel: 6),
        SpeciesInfo(id: "obsidit", name: "Obsidit", element: .flint, isle: 1, slot: 1, rarity: 0, hp: 34, atk: 10, def: 13, spd: 7, move: "Shard Flick", grownName: "Obsidarch", blurb: "Naps on black sand until it is too hot, then naps in the surf.", growLevel: 19, strongLevel: 16),
        SpeciesInfo(id: "slagmite", name: "Slagmite", element: .flint, isle: 1, slot: 1, rarity: 1, hp: 38, atk: 12, def: 14, spd: 6, move: "Slag Toss", grownName: "Slagmaw", blurb: "Chews cooled lava and spits out perfectly round pebbles.", growLevel: 21, strongLevel: 16),
        SpeciesInfo(id: "basaltusk", name: "Basaltusk", element: .flint, isle: 1, slot: 1, rarity: 2, hp: 50, atk: 14, def: 16, spd: 6, move: "Column Crash", grownName: "", blurb: "Its tusks grow in six-sided columns, one ring a year.", growLevel: 0, strongLevel: 16),
        SpeciesInfo(id: "cindrel", name: "Cindrel", element: .ember, isle: 1, slot: 2, rarity: 0, hp: 28, atk: 11, def: 8, spd: 13, move: "Spark", grownName: "Cindralis", blurb: "Skips across warm ash and leaves tiny glowing footprints.", growLevel: 19, strongLevel: 16),
        SpeciesInfo(id: "ashwick", name: "Ashwick", element: .ember, isle: 1, slot: 2, rarity: 1, hp: 33, atk: 13, def: 9, spd: 12, move: "Ash Flare", grownName: "Ashwarden", blurb: "Keeps one ember lit on its head and guards it from rain.", growLevel: 21, strongLevel: 16),
        SpeciesInfo(id: "pyrelune", name: "Pyrelune", element: .ember, isle: 1, slot: 2, rarity: 2, hp: 40, atk: 16, def: 10, spd: 14, move: "Moonfire", grownName: "", blurb: "Burns pale at night. Travellers once steered by its glow.", growLevel: 0, strongLevel: 16),
        SpeciesInfo(id: "smoldit", name: "Smoldit", element: .ember, isle: 1, slot: 3, rarity: 0, hp: 32, atk: 10, def: 10, spd: 9, move: "Smolder", grownName: "Smoldane", blurb: "Sleeps inside hollow charred logs and snores smoke rings.", growLevel: 19, strongLevel: 16),
        SpeciesInfo(id: "charrow", name: "Charrow", element: .ember, isle: 1, slot: 3, rarity: 1, hp: 36, atk: 13, def: 11, spd: 10, move: "Cinder Dart", grownName: "Charrowen", blurb: "Sharpens burnt twigs into darts and never throws them at friends.", growLevel: 21, strongLevel: 16),
        SpeciesInfo(id: "kilnhart", name: "Kilnhart", element: .ember, isle: 1, slot: 3, rarity: 2, hp: 46, atk: 15, def: 13, spd: 8, move: "Kiln Roar", grownName: "", blurb: "Its antlers glow from within when it is content.", growLevel: 0, strongLevel: 16),
        SpeciesInfo(id: "bublet", name: "Bublet", element: .tide, isle: 1, slot: 4, rarity: 0, hp: 30, atk: 9, def: 10, spd: 10, move: "Bubble Pop", grownName: "Bubbloon", blurb: "Floats on hot springs and pops when startled, then reforms.", growLevel: 19, strongLevel: 16),
        SpeciesInfo(id: "geysling", name: "Geysling", element: .tide, isle: 1, slot: 4, rarity: 1, hp: 35, atk: 12, def: 11, spd: 9, move: "Steam Jet", grownName: "Geysarch", blurb: "Times its leaps to the geysers and lands dry every time.", growLevel: 21, strongLevel: 16),
        SpeciesInfo(id: "mistmantle", name: "Mistmantle", element: .tide, isle: 1, slot: 4, rarity: 2, hp: 42, atk: 14, def: 12, spd: 12, move: "Scald Veil", grownName: "", blurb: "Wears the steam like a cloak and is rarely seen whole.", growLevel: 0, strongLevel: 16),
        SpeciesInfo(id: "floebit", name: "Floebit", element: .frost, isle: 2, slot: 1, rarity: 0, hp: 31, atk: 9, def: 11, spd: 8, move: "Ice Chip", grownName: "Floeberg", blurb: "Rides drifting ice and waves at everything it passes.", growLevel: 29, strongLevel: 26),
        SpeciesInfo(id: "rimewhisk", name: "Rimewhisk", element: .frost, isle: 2, slot: 1, rarity: 1, hp: 34, atk: 12, def: 10, spd: 12, move: "Rime Lash", grownName: "Rimewhorl", blurb: "Its whiskers grow frost overnight and ring like glass.", growLevel: 31, strongLevel: 26),
        SpeciesInfo(id: "bergamoth", name: "Bergamoth", element: .frost, isle: 2, slot: 1, rarity: 2, hp: 52, atk: 13, def: 15, spd: 5, move: "Calving Slam", grownName: "", blurb: "Nine tenths of it is usually out of sight below the ice.", growLevel: 0, strongLevel: 26),
        SpeciesInfo(id: "driftlet", name: "Driftlet", element: .gale, isle: 2, slot: 2, rarity: 0, hp: 27, atk: 10, def: 8, spd: 14, move: "Snow Flurry", grownName: "Driftwing", blurb: "Tumbles with the snow and is always surprised to stop.", growLevel: 29, strongLevel: 26),
        SpeciesInfo(id: "howlkin", name: "Howlkin", element: .gale, isle: 2, slot: 2, rarity: 1, hp: 33, atk: 13, def: 9, spd: 13, move: "Howl", grownName: "Howlgale", blurb: "Sings to the wind at dusk. The wind sometimes answers.", growLevel: 31, strongLevel: 26),
        SpeciesInfo(id: "borealune", name: "Borealune", element: .gale, isle: 2, slot: 2, rarity: 2, hp: 39, atk: 15, def: 11, spd: 15, move: "Aurora Sweep", grownName: "", blurb: "Trails green light across the tundra on clear nights.", growLevel: 0, strongLevel: 26),
        SpeciesInfo(id: "needlet", name: "Needlet", element: .thorn, isle: 2, slot: 3, rarity: 0, hp: 31, atk: 10, def: 10, spd: 9, move: "Needle Jab", grownName: "Needlorn", blurb: "Sheds needles when nervous and counts them when calm.", growLevel: 29, strongLevel: 26),
        SpeciesInfo(id: "conifawn", name: "Conifawn", element: .thorn, isle: 2, slot: 3, rarity: 1, hp: 36, atk: 12, def: 12, spd: 10, move: "Cone Volley", grownName: "Conifern", blurb: "Hides pine cones for winter and forgets most of them.", growLevel: 31, strongLevel: 26),
        SpeciesInfo(id: "evermoss", name: "Evermoss", element: .thorn, isle: 2, slot: 3, rarity: 2, hp: 47, atk: 13, def: 15, spd: 6, move: "Deep Root", grownName: "", blurb: "Older than the wood around it. Snow never settles on its back.", growLevel: 0, strongLevel: 26),
        SpeciesInfo(id: "shardlet", name: "Shardlet", element: .frost, isle: 2, slot: 4, rarity: 0, hp: 29, atk: 11, def: 9, spd: 11, move: "Shard Toss", grownName: "Shardmane", blurb: "Catches the light and scatters small rainbows on the ice.", growLevel: 29, strongLevel: 26),
        SpeciesInfo(id: "hoarhop", name: "Hoarhop", element: .frost, isle: 2, slot: 4, rarity: 1, hp: 35, atk: 12, def: 12, spd: 9, move: "Hoar Stomp", grownName: "Hoarleap", blurb: "Jumps crevasses for no reason other than that they are there.", growLevel: 31, strongLevel: 26),
        SpeciesInfo(id: "cryolith", name: "Cryolith", element: .frost, isle: 2, slot: 4, rarity: 2, hp: 48, atk: 14, def: 16, spd: 6, move: "Glacier Break", grownName: "", blurb: "Moves a hand-width a year unless someone whistles.", growLevel: 0, strongLevel: 26),
        SpeciesInfo(id: "maelstrix", name: "Maelstrix", element: .tide, isle: 3, slot: 1, rarity: 2, hp: 46, atk: 16, def: 13, spd: 13, move: "Maelstrom", grownName: "", blurb: "Circles offshore before a storm and comes in with the surge.", growLevel: 0, strongLevel: 36),
        SpeciesInfo(id: "fulgurwing", name: "Fulgurwing", element: .gale, isle: 3, slot: 2, rarity: 2, hp: 40, atk: 17, def: 11, spd: 16, move: "Thunderclap", grownName: "", blurb: "Outruns its own thunder across the open plain.", growLevel: 0, strongLevel: 36),
        SpeciesInfo(id: "glassmander", name: "Glassmander", element: .ember, isle: 3, slot: 3, rarity: 2, hp: 44, atk: 16, def: 14, spd: 11, move: "Fuse Flash", grownName: "", blurb: "Born where lightning met sand. Warm to the touch for hours after.", growLevel: 0, strongLevel: 36),
        SpeciesInfo(id: "skyvane", name: "Skyvane", element: .gale, isle: 3, slot: 4, rarity: 3, hp: 56, atk: 18, def: 15, spd: 16, move: "Stormsong", grownName: "", blurb: "Turns to face every wind at once. The storm over the spire is its song.", growLevel: 0, strongLevel: 36),
    ]

    public static let speciesById: [String: SpeciesInfo] = {
        var d: [String: SpeciesInfo] = [:]
        for s in species { d[s.id] = s }
        return d
    }()

    public static func sp(_ id: String) -> SpeciesInfo {
        guard let s = speciesById[id] else { preconditionFailure("unknown species \(id)") }
        return s
    }

    public static let art: [String: ArtInfo] = [
        "plipple": ArtInfo(shape: "drop", body: "#4FB3D9", belly: "#D9F2FA", line: "#1F6F92", ears: "fin", pattern: "none", eyes: "wide", extras: ""),
        "bracklet": ArtInfo(shape: "wide", body: "#2E8C9E", belly: "#BFE6DF", line: "#17505C", ears: "none", pattern: "shell", eyes: "dot", extras: ""),
        "morrowfin": ArtInfo(shape: "tall", body: "#3A5FB8", belly: "#CAD8F7", line: "#1E2F6B", ears: "fin", pattern: "stripe", eyes: "sleepy", extras: "t"),
        "whiffet": ArtInfo(shape: "round", body: "#F2EFE6", belly: "#FFFFFF", line: "#8E99B8", ears: "tuft", pattern: "none", eyes: "dot", extras: ""),
        "skirlow": ArtInfo(shape: "egg", body: "#B9A6E0", belly: "#EFE8FB", line: "#6A54A3", ears: "point", pattern: "none", eyes: "wide", extras: "w"),
        "aerowen": ArtInfo(shape: "tall", body: "#F0C24B", belly: "#FFF2C2", line: "#A8741A", ears: "long", pattern: "stripe", eyes: "sleepy", extras: "w"),
        "burrbit": ArtInfo(shape: "round", body: "#8CBF4F", belly: "#E3F2C4", line: "#4C7A22", ears: "long", pattern: "burr", eyes: "dot", extras: ""),
        "nettlekin": ArtInfo(shape: "egg", body: "#4E9A5B", belly: "#CFEBCB", line: "#235C33", ears: "leaf", pattern: "spots", eyes: "wide", extras: ""),
        "elderbriar": ArtInfo(shape: "wide", body: "#6B7F3A", belly: "#DDE3B5", line: "#3A4720", ears: "horn", pattern: "moss", eyes: "sleepy", extras: ""),
        "pebbrix": ArtInfo(shape: "round", body: "#B79C82", belly: "#EADCCB", line: "#7A614B", ears: "none", pattern: "spots", eyes: "dot", extras: ""),
        "gravelope": ArtInfo(shape: "tall", body: "#9A8F86", belly: "#E2DCD4", line: "#5B524B", ears: "horn", pattern: "crack", eyes: "wide", extras: ""),
        "oldscarp": ArtInfo(shape: "wide", body: "#7D6A63", belly: "#D8C9BF", line: "#473A35", ears: "crest", pattern: "crack", eyes: "sleepy", extras: ""),
        "obsidit": ArtInfo(shape: "round", body: "#4A4458", belly: "#B9B2C9", line: "#211D2B", ears: "crest", pattern: "frost", eyes: "dot", extras: ""),
        "slagmite": ArtInfo(shape: "wide", body: "#6B5A5A", belly: "#E0B48A", line: "#352A2A", ears: "none", pattern: "ember", eyes: "wide", extras: ""),
        "basaltusk": ArtInfo(shape: "pear", body: "#4F5560", belly: "#C5CBD4", line: "#23272E", ears: "horn", pattern: "crack", eyes: "sleepy", extras: "c"),
        "cindrel": ArtInfo(shape: "drop", body: "#F08A3C", belly: "#FFE1B8", line: "#9A3F12", ears: "flame", pattern: "none", eyes: "wide", extras: ""),
        "ashwick": ArtInfo(shape: "egg", body: "#B9B0A6", belly: "#F3EEE7", line: "#5E554C", ears: "flame", pattern: "spots", eyes: "dot", extras: "f"),
        "pyrelune": ArtInfo(shape: "tall", body: "#E9E2F5", belly: "#FFFFFF", line: "#8B6FB8", ears: "flame", pattern: "ring", eyes: "sleepy", extras: "w"),
        "smoldit": ArtInfo(shape: "bean", body: "#8A4B3A", belly: "#F2C29B", line: "#4A2116", ears: "tuft", pattern: "ember", eyes: "sleepy", extras: ""),
        "charrow": ArtInfo(shape: "egg", body: "#5A3E36", belly: "#E8B48C", line: "#2A1A15", ears: "point", pattern: "ember", eyes: "wide", extras: "f"),
        "kilnhart": ArtInfo(shape: "tall", body: "#B5563A", belly: "#FBD9A8", line: "#5C2413", ears: "antler", pattern: "ember", eyes: "dot", extras: "c"),
        "bublet": ArtInfo(shape: "round", body: "#9FE0DA", belly: "#F1FFFD", line: "#3F8F8A", ears: "antenna", pattern: "ring", eyes: "wide", extras: ""),
        "geysling": ArtInfo(shape: "pear", body: "#5DB7C4", belly: "#D9F6F4", line: "#1F6C78", ears: "fin", pattern: "stripe", eyes: "dot", extras: "t"),
        "mistmantle": ArtInfo(shape: "tall", body: "#C9E3E8", belly: "#FFFFFF", line: "#5A8E9A", ears: "curl", pattern: "ring", eyes: "sleepy", extras: "w"),
        "floebit": ArtInfo(shape: "wide", body: "#D4ECF5", belly: "#FFFFFF", line: "#5E9AB5", ears: "none", pattern: "frost", eyes: "dot", extras: ""),
        "rimewhisk": ArtInfo(shape: "egg", body: "#A9D4E8", belly: "#F3FBFF", line: "#3F7C99", ears: "point", pattern: "frost", eyes: "wide", extras: "c"),
        "bergamoth": ArtInfo(shape: "pear", body: "#8FC2DA", belly: "#EAF7FC", line: "#2F6682", ears: "ice", pattern: "crack", eyes: "sleepy", extras: ""),
        "driftlet": ArtInfo(shape: "round", body: "#EDF3F7", belly: "#FFFFFF", line: "#93A8BA", ears: "curl", pattern: "none", eyes: "wide", extras: "w"),
        "howlkin": ArtInfo(shape: "tall", body: "#9FB0C9", belly: "#EEF3FA", line: "#4B5E7D", ears: "point", pattern: "stripe", eyes: "dot", extras: "c"),
        "borealune": ArtInfo(shape: "egg", body: "#6FD3B0", belly: "#E3FBF2", line: "#2A7F68", ears: "antler", pattern: "ring", eyes: "sleepy", extras: "w"),
        "needlet": ArtInfo(shape: "round", body: "#5F9C7A", belly: "#DDF0E4", line: "#2B5C43", ears: "none", pattern: "burr", eyes: "dot", extras: ""),
        "conifawn": ArtInfo(shape: "bean", body: "#A07A52", belly: "#F1E2CC", line: "#5A3F24", ears: "antler", pattern: "spots", eyes: "wide", extras: ""),
        "evermoss": ArtInfo(shape: "wide", body: "#4F7F5E", belly: "#D9EBD9", line: "#234530", ears: "horn", pattern: "moss", eyes: "sleepy", extras: "c"),
        "shardlet": ArtInfo(shape: "drop", body: "#BFE6F2", belly: "#FFFFFF", line: "#4F97B2", ears: "ice", pattern: "none", eyes: "wide", extras: ""),
        "hoarhop": ArtInfo(shape: "bean", body: "#E3EEF4", belly: "#FFFFFF", line: "#6D95AA", ears: "long", pattern: "frost", eyes: "dot", extras: ""),
        "cryolith": ArtInfo(shape: "pear", body: "#7FB3CC", belly: "#E6F5FB", line: "#2A5C74", ears: "crest", pattern: "scale", eyes: "sleepy", extras: ""),
        "maelstrix": ArtInfo(shape: "tall", body: "#2F6FA8", belly: "#CFE6F7", line: "#143A60", ears: "fin", pattern: "scale", eyes: "wide", extras: "tw"),
        "fulgurwing": ArtInfo(shape: "egg", body: "#7C6BD0", belly: "#E9E4FF", line: "#3A2E7A", ears: "crest", pattern: "bolt", eyes: "wide", extras: "w"),
        "glassmander": ArtInfo(shape: "bean", body: "#E0705A", belly: "#FFE3D0", line: "#7A2A1C", ears: "ice", pattern: "bolt", eyes: "dot", extras: "f"),
        "skyvane": ArtInfo(shape: "tall", body: "#F4E9B8", belly: "#FFFFFF", line: "#7A6A2C", ears: "antler", pattern: "bolt", eyes: "wide", extras: "wc"),
    ]
}
