// Generated reference values from the tested web build (tools/gen-swift.js). Used to prove the native rules match.
import Foundation

enum Fixtures {
    struct MapRef { let seedIn: UInt32; let isle: Int; let seed: UInt32; let start: Int; let shrine: Int; let camps: [Int]; let counts: [Int]; let mainCount: Int; let hash: UInt32; let vsum: Int }
    struct StatRef { let sp: String; let level: Int; let grown: Bool; let hp: Int; let atk: Int; let def: Int; let spd: Int }
    struct DamageRef { let a: String; let al: Int; let d: String; let dl: Int; let pow: Int; let el: String?; let braced: Bool; let rnd: Double; let out: Int }

    static let rng: [(seed: UInt32, values: [UInt32])] = [
        (42, [2581720956, 1925393290, 3661312704, 2876485805, 750819978]),
        (0, [1144304738, 1416247, 958946056, 627933444, 2007157716]),
        (4294967295, [3850105811, 813802916, 3073704848, 4054706436, 3630262831]),
        (2654435761, [2347010974, 1973779238, 1061036011, 2230376248, 3819464677]),
    ]

    static let maps: [MapRef] = [
        MapRef(seedIn: 1, isle: 0, seed: 1, start: 990, shrine: 117, camps: [990, 1446, 1777, 247], counts: [0, 136, 308, 220, 87], mainCount: 755, hash: 833712442, vsum: 949649),
        MapRef(seedIn: 104730, isle: 1, seed: 104730, start: 990, shrine: 478, camps: [990, 839, 1824, 608], counts: [0, 134, 151, 164, 263], mainCount: 716, hash: 1990725929, vsum: 958926),
        MapRef(seedIn: 209459, isle: 2, seed: 209459, start: 817, shrine: 1278, camps: [817, 1734, 490, 1148], counts: [0, 118, 191, 289, 191], mainCount: 793, hash: 2375317035, vsum: 963855),
        MapRef(seedIn: 314188, isle: 3, seed: 314188, start: 989, shrine: 789, camps: [989, 1727, 250, 919], counts: [0, 134, 213, 87, 411], mainCount: 849, hash: 1157550974, vsum: 973411),
        MapRef(seedIn: 2, isle: 0, seed: 2, start: 987, shrine: 1317, camps: [987, 250, 317, 1183], counts: [0, 118, 349, 135, 158], mainCount: 764, hash: 3244501751, vsum: 943111),
        MapRef(seedIn: 104731, isle: 1, seed: 104731, start: 990, shrine: 706, camps: [990, 433, 192, 840], counts: [0, 130, 217, 198, 280], mainCount: 829, hash: 2027909872, vsum: 971615),
        MapRef(seedIn: 209460, isle: 2, seed: 209460, start: 1078, shrine: 106, camps: [1078, 1835, 652, 240], counts: [0, 179, 125, 170, 200], mainCount: 678, hash: 155525854, vsum: 962379),
        MapRef(seedIn: 314189, isle: 3, seed: 314189, start: 990, shrine: 524, camps: [990, 706, 1779, 654], counts: [0, 175, 239, 131, 283], mainCount: 832, hash: 1942293913, vsum: 947976),
        MapRef(seedIn: 3, isle: 0, seed: 3, start: 905, shrine: 1102, camps: [905, 1597, 493, 1017], counts: [0, 122, 143, 150, 308], mainCount: 727, hash: 435485860, vsum: 969372),
        MapRef(seedIn: 104732, isle: 1, seed: 104732, start: 946, shrine: 104, camps: [946, 1745, 883, 238], counts: [0, 109, 161, 249, 319], mainCount: 842, hash: 4192062685, vsum: 965936),
        MapRef(seedIn: 209461, isle: 2, seed: 209461, start: 990, shrine: 1682, camps: [990, 204, 920, 1552], counts: [0, 143, 226, 130, 174], mainCount: 677, hash: 1892214436, vsum: 943860),
        MapRef(seedIn: 314190, isle: 3, seed: 314190, start: 948, shrine: 1146, camps: [948, 1779, 536, 1016], counts: [0, 141, 256, 76, 295], mainCount: 772, hash: 3188110710, vsum: 944041),
        MapRef(seedIn: 12345, isle: 0, seed: 12345, start: 990, shrine: 401, camps: [990, 434, 1368, 492], counts: [0, 113, 216, 231, 309], mainCount: 873, hash: 2923976508, vsum: 992101),
        MapRef(seedIn: 117074, isle: 1, seed: 117074, start: 993, shrine: 1104, camps: [993, 151, 1823, 1019], counts: [0, 98, 303, 330, 112], mainCount: 847, hash: 3814906632, vsum: 964560),
        MapRef(seedIn: 221803, isle: 2, seed: 221803, start: 990, shrine: 107, camps: [990, 795, 1823, 237], counts: [0, 128, 219, 174, 283], mainCount: 808, hash: 1289972549, vsum: 983327),
        MapRef(seedIn: 326532, isle: 3, seed: 326532, start: 990, shrine: 1833, camps: [990, 107, 1503, 1699], counts: [0, 98, 247, 175, 290], mainCount: 814, hash: 3025600796, vsum: 972171),
        MapRef(seedIn: 987654321, isle: 0, seed: 987654321, start: 1076, shrine: 161, camps: [1076, 1316, 323, 291], counts: [0, 109, 113, 162, 367], mainCount: 755, hash: 3524444737, vsum: 961123),
        MapRef(seedIn: 987759050, isle: 1, seed: 987759050, start: 1124, shrine: 317, camps: [1124, 1058, 205, 451], counts: [0, 93, 394, 194, 195], mainCount: 880, hash: 1648439590, vsum: 968813),
        MapRef(seedIn: 987863779, isle: 2, seed: 987863779, start: 990, shrine: 1789, camps: [990, 839, 432, 1655], counts: [0, 124, 123, 315, 175], mainCount: 741, hash: 3803872934, vsum: 982513),
        MapRef(seedIn: 987968508, isle: 3, seed: 987968508, start: 994, shrine: 1281, camps: [994, 236, 1778, 1151], counts: [0, 136, 248, 360, 150], mainCount: 898, hash: 1756107494, vsum: 963424),
        MapRef(seedIn: 4000000000, isle: 0, seed: 4000000000, start: 990, shrine: 116, camps: [990, 1102, 232, 201], counts: [0, 113, 360, 306, 178], mainCount: 961, hash: 100581889, vsum: 960318),
        MapRef(seedIn: 4000104729, isle: 1, seed: 4000104729, start: 946, shrine: 401, camps: [946, 1458, 1661, 535], counts: [0, 114, 238, 336, 263], mainCount: 955, hash: 2425665089, vsum: 964425),
        MapRef(seedIn: 4000209458, isle: 2, seed: 4000209458, start: 990, shrine: 143, camps: [990, 523, 839, 277], counts: [0, 130, 397, 146, 172], mainCount: 849, hash: 923724107, vsum: 989652),
        MapRef(seedIn: 4000314187, isle: 3, seed: 4000322106, start: 990, shrine: 1146, camps: [990, 1790, 201, 1061], counts: [0, 202, 182, 270, 138], mainCount: 796, hash: 281527797, vsum: 981208),
    ]

    static let stats: [StatRef] = [
        StatRef(sp: "plipple", level: 1, grown: false, hp: 30, atk: 9, def: 9, spd: 10),
        StatRef(sp: "plipple", level: 1, grown: true, hp: 36, atk: 10, def: 10, spd: 12),
        StatRef(sp: "plipple", level: 5, grown: false, hp: 44, atk: 12, def: 12, spd: 14),
        StatRef(sp: "plipple", level: 5, grown: true, hp: 52, atk: 14, def: 14, spd: 16),
        StatRef(sp: "plipple", level: 9, grown: false, hp: 58, atk: 16, def: 16, spd: 18),
        StatRef(sp: "plipple", level: 9, grown: true, hp: 69, atk: 19, def: 19, spd: 21),
        StatRef(sp: "plipple", level: 20, grown: false, hp: 98, atk: 26, def: 26, spd: 29),
        StatRef(sp: "plipple", level: 20, grown: true, hp: 117, atk: 31, def: 31, spd: 34),
        StatRef(sp: "plipple", level: 40, grown: false, hp: 170, atk: 44, def: 44, spd: 49),
        StatRef(sp: "plipple", level: 40, grown: true, hp: 204, atk: 52, def: 52, spd: 58),
        StatRef(sp: "oldscarp", level: 1, grown: false, hp: 50, atk: 13, def: 16, spd: 5),
        StatRef(sp: "oldscarp", level: 1, grown: false, hp: 50, atk: 13, def: 16, spd: 5),
        StatRef(sp: "oldscarp", level: 5, grown: false, hp: 74, atk: 18, def: 22, spd: 7),
        StatRef(sp: "oldscarp", level: 5, grown: false, hp: 74, atk: 18, def: 22, spd: 7),
        StatRef(sp: "oldscarp", level: 9, grown: false, hp: 98, atk: 23, def: 28, spd: 9),
        StatRef(sp: "oldscarp", level: 9, grown: false, hp: 98, atk: 23, def: 28, spd: 9),
        StatRef(sp: "oldscarp", level: 20, grown: false, hp: 164, atk: 37, def: 46, spd: 14),
        StatRef(sp: "oldscarp", level: 20, grown: false, hp: 164, atk: 37, def: 46, spd: 14),
        StatRef(sp: "oldscarp", level: 40, grown: false, hp: 284, atk: 63, def: 78, spd: 24),
        StatRef(sp: "oldscarp", level: 40, grown: false, hp: 284, atk: 63, def: 78, spd: 24),
        StatRef(sp: "skyvane", level: 1, grown: false, hp: 56, atk: 18, def: 15, spd: 16),
        StatRef(sp: "skyvane", level: 1, grown: false, hp: 56, atk: 18, def: 15, spd: 16),
        StatRef(sp: "skyvane", level: 5, grown: false, hp: 82, atk: 25, def: 21, spd: 22),
        StatRef(sp: "skyvane", level: 5, grown: false, hp: 82, atk: 25, def: 21, spd: 22),
        StatRef(sp: "skyvane", level: 9, grown: false, hp: 109, atk: 32, def: 27, spd: 28),
        StatRef(sp: "skyvane", level: 9, grown: false, hp: 109, atk: 32, def: 27, spd: 28),
        StatRef(sp: "skyvane", level: 20, grown: false, hp: 183, atk: 52, def: 43, spd: 46),
        StatRef(sp: "skyvane", level: 20, grown: false, hp: 183, atk: 52, def: 43, spd: 46),
        StatRef(sp: "skyvane", level: 40, grown: false, hp: 318, atk: 88, def: 73, spd: 78),
        StatRef(sp: "skyvane", level: 40, grown: false, hp: 318, atk: 88, def: 73, spd: 78),
        StatRef(sp: "whiffet", level: 1, grown: false, hp: 28, atk: 10, def: 8, spd: 14),
        StatRef(sp: "whiffet", level: 1, grown: true, hp: 33, atk: 12, def: 9, spd: 16),
        StatRef(sp: "whiffet", level: 5, grown: false, hp: 41, atk: 14, def: 11, spd: 19),
        StatRef(sp: "whiffet", level: 5, grown: true, hp: 49, atk: 16, def: 13, spd: 22),
        StatRef(sp: "whiffet", level: 9, grown: false, hp: 54, atk: 18, def: 14, spd: 25),
        StatRef(sp: "whiffet", level: 9, grown: true, hp: 64, atk: 21, def: 16, spd: 30),
        StatRef(sp: "whiffet", level: 20, grown: false, hp: 91, atk: 29, def: 23, spd: 40),
        StatRef(sp: "whiffet", level: 20, grown: true, hp: 109, atk: 34, def: 27, spd: 48),
        StatRef(sp: "whiffet", level: 40, grown: false, hp: 159, atk: 49, def: 39, spd: 68),
        StatRef(sp: "whiffet", level: 40, grown: true, hp: 190, atk: 58, def: 46, spd: 81),
    ]

    static let need: [(level: Int, xp: Int)] = [(1, 24), (5, 64), (8, 94), (9, 106), (10, 120), (20, 444), (30, 1088), (39, 1942)]

    static let damage: [DamageRef] = [
        DamageRef(a: "plipple", al: 5, d: "whiffet", dl: 3, pow: 10, el: nil, braced: false, rnd: 0.5, out: 13),
        DamageRef(a: "plipple", al: 5, d: "pebbrix", dl: 4, pow: 13, el: "tide", braced: false, rnd: 0, out: 13),
        DamageRef(a: "skyvane", al: 40, d: "cryolith", dl: 32, pow: 21, el: "gale", braced: true, rnd: 0.999, out: 38),
        DamageRef(a: "burrbit", al: 12, d: "cindrel", dl: 14, pow: 13, el: "thorn", braced: false, rnd: 0.25, out: 15),
        DamageRef(a: "whiffet", al: 1, d: "oldscarp", dl: 40, pow: 10, el: nil, braced: true, rnd: 0.1, out: 1),
    ]
}
