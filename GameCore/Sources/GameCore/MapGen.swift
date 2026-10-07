import Foundation

/// One generated island: terrain, obstacles, camps and the guardian's shrine.
public struct IsleMap: Sendable {
    public static let width = 44
    public static let height = 44
    public static let water: UInt8 = 0

    public let seed: UInt32
    public let isle: Int
    /// 0 is sea; 1...4 are the isle's four habitats.
    public let biome: [UInt8]
    public let block: [Bool]
    /// Per-tile value in [0, 1) used only to vary how tiles are drawn.
    public let vary: [Float]
    /// Tiles the player can reach from the first camp.
    public let main: [Bool]
    public let camps: [Int]
    public let isCamp: [Bool]
    public let start: Int
    public let shrine: Int
    /// Reachable, non-camp tiles for each habitat (index 0 is unused).
    public let tilesBy: [[Int]]
    public let mainCount: Int

    @inline(__always) public static func index(_ x: Int, _ y: Int) -> Int { y * width + x }
    @inline(__always) public static func x(_ i: Int) -> Int { i % width }
    @inline(__always) public static func y(_ i: Int) -> Int { i / width }

    public func inBounds(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < IsleMap.width && y < IsleMap.height }

    /// Solid ground with nothing standing on it. The shrine tile is never walkable.
    public func canWalk(_ x: Int, _ y: Int) -> Bool {
        guard inBounds(x, y) else { return false }
        let i = IsleMap.index(x, y)
        return biome[i] != IsleMap.water && !block[i] && i != shrine
    }
}

public enum MapGen {
    static let W = IsleMap.width
    static let H = IsleMap.height

    static func noiseField(_ r: inout Mulberry32, cell: Int) -> [Float] {
        let gw = Int((Double(W) / Double(cell)).rounded(.up)) + 2
        let gh = Int((Double(H) / Double(cell)).rounded(.up)) + 2
        var g = [Float](repeating: 0, count: gw * gh)
        for i in 0..<g.count { g[i] = Float(r.next()) }
        var out = [Float](repeating: 0, count: W * H)
        for y in 0..<H {
            for x in 0..<W {
                let fx = Double(x) / Double(cell)
                let fy = Double(y) / Double(cell)
                let x0 = Int(fx)
                let y0 = Int(fy)
                var tx = fx - Double(x0)
                var ty = fy - Double(y0)
                tx = tx * tx * (3 - 2 * tx)
                ty = ty * ty * (3 - 2 * ty)
                let a = Double(g[y0 * gw + x0])
                let b = Double(g[y0 * gw + x0 + 1])
                let c = Double(g[(y0 + 1) * gw + x0])
                let d = Double(g[(y0 + 1) * gw + x0 + 1])
                let top: Double = a + (b - a) * tx
                let bottom: Double = c + (d - c) * tx
                let v: Double = top * (1 - ty) + bottom * ty
                out[y * W + x] = Float(v)
            }
        }
        return out
    }

    struct Flood {
        var seen: [Bool]
        var list: [Int]
    }

    static func flood(biome: [UInt8], block: [Bool], from: Int, skip: Int) -> Flood {
        let n = W * H
        var seen = [Bool](repeating: false, count: n)
        var list: [Int] = []
        if biome[from] == IsleMap.water || block[from] || from == skip { return Flood(seen: seen, list: list) }
        var queue = [Int](repeating: 0, count: n)
        var head = 0
        var tail = 0
        seen[from] = true
        queue[tail] = from
        tail += 1
        while head < tail {
            let c = queue[head]
            head += 1
            list.append(c)
            let cx = c % W
            let cy = c / W
            let nb = [cx > 0 ? c - 1 : -1, cx < W - 1 ? c + 1 : -1, cy > 0 ? c - W : -1, cy < H - 1 ? c + W : -1]
            for j in nb where j >= 0 {
                if !seen[j] && j != skip && biome[j] != IsleMap.water && !block[j] {
                    seen[j] = true
                    queue[tail] = j
                    tail += 1
                }
            }
        }
        return Flood(seen: seen, list: list)
    }

    static func d2(_ a: Int, _ b: Int) -> Int {
        let dx = a % W - b % W
        let dy = a / W - b / W
        return dx * dx + dy * dy
    }

    static func build(seed: UInt32, isle: Int) -> IsleMap? {
        var r = Mulberry32(seed: seed)
        let h = noiseField(&r, cell: 10)
        let h2 = noiseField(&r, cell: 4)
        let m = noiseField(&r, cell: 7)
        let k = noiseField(&r, cell: 9)
        let info = GameData.isles[isle]
        let n = W * H
        var biome = [UInt8](repeating: 0, count: n)
        var block = [Bool](repeating: false, count: n)
        var vary = [Float](repeating: 0, count: n)
        for y in 0..<H {
            for x in 0..<W {
                let i = y * W + x
                let nx: Double = Double(x) / Double(W - 1) * 2 - 1
                let ny: Double = Double(y) / Double(H - 1) * 2 - 1
                let dd: Double = nx * nx + ny * ny
                let e1: Double = Double(h[i]) * 0.55 + Double(h2[i]) * 0.2
                let e: Double = e1 + 0.5 - dd * 0.85
                var b: UInt8
                if x < 2 || y < 2 || x > W - 3 || y > H - 3 || e < 0.33 {
                    b = 0
                } else if e < 0.41 {
                    b = 1
                } else if Double(k[i]) + e * 0.35 > 0.82 {
                    b = 4
                } else {
                    b = Double(m[i]) > 0.5 ? 3 : 2
                }
                biome[i] = b
                vary[i] = Float(r.next())
                let roll = r.next()
                block[i] = b != 0 && roll < info.habitat(Int(b)).density
            }
        }

        var best: Flood? = nil
        var done = [Bool](repeating: false, count: n)
        for i in 0..<n {
            if done[i] || biome[i] == IsleMap.water || block[i] { continue }
            let f = flood(biome: biome, block: block, from: i, skip: -1)
            for j in f.list { done[j] = true }
            if best == nil || f.list.count > best!.list.count { best = f }
        }
        guard let land = best, land.list.count >= 420 else { return nil }

        var start = -1
        var bd = 1_000_000_000
        let c0 = (H / 2) * W + (W / 2)
        for j in land.list {
            let d = d2(j, c0) + (biome[j] == 2 ? 0 : 30)
            if d < bd { bd = d; start = j }
        }
        var shrine = -1
        var fd = -1
        for j in land.list {
            let d = d2(j, start)
            if d > fd { fd = d; shrine = j }
        }
        if fd < 100 { return nil }

        let mainF = flood(biome: biome, block: block, from: start, skip: shrine)
        let mainList = mainF.list
        if mainList.count < 400 { return nil }

        var camps = [start]
        while camps.count < 3 {
            var far = -1
            var fdd: Double = -1
            for j in mainList {
                var md: Double = Double(d2(j, shrine)) * 1.5
                for c in camps {
                    let d = Double(d2(j, c))
                    if d < md { md = d }
                }
                if md > fdd { fdd = md; far = j }
            }
            camps.append(far)
        }
        var near = -1
        var nd: Double = 1e9
        for j in mainList {
            let d = Double(d2(j, shrine)).squareRoot()
            if d < 2.2 || camps.contains(j) { continue }
            let s = abs(d - 3.5)
            if s < nd { nd = s; near = j }
        }
        if near < 0 { return nil }
        camps.append(near)

        var isCamp = [Bool](repeating: false, count: n)
        for j in camps { isCamp[j] = true }
        var tilesBy: [[Int]] = [[], [], [], [], []]
        for j in mainList where !isCamp[j] { tilesBy[Int(biome[j])].append(j) }
        for i in 1...4 where tilesBy[i].count < 34 { return nil }

        return IsleMap(seed: seed, isle: isle, biome: biome, block: block, vary: vary, main: mainF.seen, camps: camps,
                       isCamp: isCamp, start: start, shrine: shrine, tilesBy: tilesBy, mainCount: mainList.count)
    }

    /// Builds the island for a seed, nudging the seed until the island is playable.
    public static func make(seed: UInt32, isle: Int) -> IsleMap {
        for a in 0..<600 {
            if let m = build(seed: seed &+ UInt32(a) &* 7919, isle: isle) { return m }
        }
        preconditionFailure("map generation failed for seed \(seed) isle \(isle)")
    }
}
