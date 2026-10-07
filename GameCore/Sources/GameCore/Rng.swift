import Foundation

/// Small deterministic generator. Map generation depends on its exact sequence,
/// so the arithmetic here must stay bit-for-bit as written.
public struct Mulberry32: Sendable {
    private var a: UInt32

    public init(seed: UInt32) { a = seed }

    /// Next value in [0, 1).
    public mutating func next() -> Double {
        Double(nextBits()) / 4294967296.0
    }

    public mutating func nextBits() -> UInt32 {
        a = a &+ 0x6D2B79F5
        var t: UInt32 = (a ^ (a >> 15)) &* (1 | a)
        t = (t &+ ((t ^ (t >> 7)) &* (61 | t))) ^ t
        return t ^ (t >> 14)
    }
}

/// Source of chance for gameplay. Seeded in tests so runs can be replayed; system randomness in the app.
public final class Dice {
    private var seeded: Mulberry32?

    public init(seed: UInt32? = nil) {
        if let s = seed { seeded = Mulberry32(seed: s) }
    }

    /// Uniform value in [0, 1).
    public func unit() -> Double {
        if seeded != nil { return seeded!.next() }
        return Double.random(in: 0..<1)
    }

    /// Uniform integer in 0..<n (n must be positive).
    public func int(_ n: Int) -> Int {
        let v = Int((unit() * Double(n)).rounded(.down))
        return min(max(v, 0), n - 1)
    }

    public func chance(_ p: Double) -> Bool { unit() < p }
}

@inline(__always) func clampD(_ v: Double, _ lo: Double, _ hi: Double) -> Double { v < lo ? lo : (v > hi ? hi : v) }
@inline(__always) func clampI(_ v: Int, _ lo: Int, _ hi: Int) -> Int { v < lo ? lo : (v > hi ? hi : v) }

/// Rounds half up, the way the reference build rounds.
@inline(__always) func roundHalfUp(_ x: Double) -> Int { Int((x + 0.5).rounded(.down)) }
