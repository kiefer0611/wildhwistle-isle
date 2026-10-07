import Foundation

public enum GameInfo {
    public static let name = "Wildwhistle Isle"
    public static let version = "0.2.0"
}

/// One creature, wild or befriended.
public struct Creature: Codable, Equatable, Sendable {
    public var sp: String
    public var level: Int
    public var xp: Int
    public var hp: Int
    public var grown: Bool

    public init(sp: String, level: Int, xp: Int = 0, hp: Int = 0, grown: Bool = false) {
        self.sp = sp
        self.level = level
        self.xp = xp
        self.hp = hp
        self.grown = grown
    }

    public var species: SpeciesInfo { GameData.sp(sp) }
    public var element: Element { species.element }
    /// The name to show: the grown form's name once it has grown.
    public var name: String { grown && species.canGrow ? species.grownName : species.name }
    public var maxHp: Int { Rules.stat(self, .hp) }
    public var knowsStrong: Bool { level >= species.strongLevel }
}

public enum StatKind: Sendable {
    case hp, atk, def, spd
}

/// The numbers behind the game. These mirror the tested reference build exactly.
public enum Rules {
    public static func stat(_ c: Creature, _ k: StatKind) -> Int {
        let s = c.species
        let b: Int
        switch k {
        case .hp: b = s.hp
        case .atk: b = s.atk
        case .def: b = s.def
        case .spd: b = s.spd
        }
        let rate: Double = k == .hp ? 0.12 : 0.10
        let grow: Double = Double(b) * rate * Double(c.level - 1)
        let v = b + Int(grow.rounded(.down))
        if c.grown {
            let g: Double = Double(v) * 1.2
            return Int(g.rounded(.down))
        }
        return v
    }

    public static func make(_ sp: String, level: Int) -> Creature {
        var c = Creature(sp: sp, level: level)
        c.hp = c.maxHp
        return c
    }

    /// A wild creature already has its grown form if it is at or past its growth level.
    public static func makeWild(_ sp: String, level: Int) -> Creature {
        var c = Creature(sp: sp, level: level)
        let s = c.species
        c.grown = s.canGrow && level >= s.growLevel
        c.hp = c.maxHp
        return c
    }

    /// Experience needed to go from `level` to the next.
    public static func need(_ level: Int) -> Int {
        let o = max(0, level - 8)
        let v: Double = 14 + Double(level) * 10 + Double(o * o) * 1.6
        return roundHalfUp(v)
    }

    /// Experience a creature actually receives: more from stronger foes, less from weaker ones.
    public static func xpFor(_ c: Creature, gain: Int, foeLevel: Int) -> Int {
        let k = clampD(1 + Double(foeLevel - c.level) * 0.08, 0.4, 1.4)
        return max(1, roundHalfUp(Double(gain) * k))
    }

    public static func mult(_ attack: Element?, _ defend: Element) -> Double {
        guard let a = attack else { return 1 }
        if GameData.elements[a]!.beats.contains(defend) { return 1.5 }
        if GameData.elements[defend]!.beats.contains(a) { return 0.67 }
        return 1
    }

    public static func damage(attacker a: Creature, defender d: Creature, power: Int, element: Element?, braced: Bool, rnd: Double) -> Int {
        let ratio: Double = Double(power) * Double(stat(a, .atk)) / Double(stat(d, .def))
        let levelPart: Double = 1 + Double(a.level) * 0.12
        var v: Double = ratio * levelPart * 0.62 * mult(element, d.element) * (0.9 + rnd * 0.2)
        if braced { v *= 0.5 }
        return max(1, roundHalfUp(v))
    }

    /// Adds experience and returns how many levels were gained.
    @discardableResult
    public static func addXp(_ c: inout Creature, _ amount: Int) -> Int {
        var ups = 0
        if c.level >= GameData.maxLevel {
            c.xp = 0
            return 0
        }
        c.xp += amount
        while c.level < GameData.maxLevel && c.xp >= need(c.level) {
            c.xp -= need(c.level)
            let before = c.maxHp
            c.level += 1
            ups += 1
            if c.hp > 0 { c.hp += c.maxHp - before }
        }
        if c.level >= GameData.maxLevel { c.xp = 0 }
        return ups
    }

    /// Grows the creature if it has reached its growth level. Returns true when it grew.
    public static func tryGrow(_ c: inout Creature) -> Bool {
        let s = c.species
        if c.grown || !s.canGrow || c.level < s.growLevel { return false }
        let before = c.maxHp
        c.grown = true
        if c.hp > 0 { c.hp += c.maxHp - before }
        return true
    }

    /// Heals by a fraction of full health (at least 1) and returns the amount healed.
    @discardableResult
    public static func healFrac(_ c: inout Creature, _ f: Double) -> Int {
        let m = c.maxHp
        var h = min(m - c.hp, max(1, roundHalfUp(Double(m) * f)))
        if h < 0 { h = 0 }
        c.hp += h
        return h
    }

    /// Triangle wave in [0, 1] used by the whistle marker.
    public static func tri(_ u: Double) -> Double {
        let f = u - u.rounded(.down)
        return f < 0.5 ? f * 2 : 2 - f * 2
    }
}
