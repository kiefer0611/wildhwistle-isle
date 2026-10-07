import UIKit
import GameCore

/// Draws the islands: ground, decorations, obstacles, camps, the shrine, pickups and the wanderer.
enum TileArt {
    static let tile: CGFloat = 44
    static let chunk = 11

    private static func renderer(_ size: CGSize, scale: CGFloat) -> UIGraphicsImageRenderer {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format)
    }

    /// One 11 by 11 block of island tiles as a picture.
    static func chunkImage(map: IsleMap, chunkX: Int, chunkY: Int) -> UIImage {
        let ts = tile
        let side = CGFloat(chunk) * ts
        let r = renderer(CGSize(width: side, height: side), scale: min(UIScreen.main.scale, 2))
        return r.image { ctx in
            let p = Pen(ctx.cgContext)
            for ty in 0..<chunk {
                for tx in 0..<chunk {
                    let x = chunkX * chunk + tx
                    let y = chunkY * chunk + ty
                    if x >= IsleMap.width || y >= IsleMap.height { continue }
                    drawTile(p, map: map, x: x, y: y, X: CGFloat(tx) * ts, Y: CGFloat(ty) * ts, ts: ts)
                }
            }
        }
    }

    static func drawTile(_ p: Pen, map: IsleMap, x: Int, y: Int, X: CGFloat, Y: CGFloat, ts: CGFloat) {
        let i = IsleMap.index(x, y)
        let isle = GameData.isles[map.isle]
        let b = Int(map.biome[i])
        let v = CGFloat(map.vary[i])
        let pi = CGFloat.pi
        if b == 0 {
            p.setFill(isle.sea[v > 0.5 ? 1 : 0])
            p.fillRect(X, Y, ts, ts)
            if v < 0.2 {
                p.setStroke("rgba(255,255,255,0.3)")
                p.lineWidth(max(1, ts * 0.04))
                p.begin()
                p.arc(X + ts * 0.5, Y + ts * (0.3 + v), ts * 0.2, 0.2 * pi, 0.8 * pi)
                p.stroke()
            }
            p.setFill("rgba(255,255,255,0.3)")
            let f = max(2, (ts * 0.09).rounded())
            let W = IsleMap.width
            let H = IsleMap.height
            if x > 0 && map.biome[i - 1] != 0 { p.fillRect(X, Y, f, ts) }
            if x < W - 1 && map.biome[i + 1] != 0 { p.fillRect(X + ts - f, Y, f, ts) }
            if y > 0 && map.biome[i - W] != 0 { p.fillRect(X, Y, ts, f) }
            if y < H - 1 && map.biome[i + W] != 0 { p.fillRect(X, Y + ts - f, ts, f) }
            return
        }
        let s = isle.habitat(b)
        p.setFill(s.palette[v > 0.5 ? 1 : 0])
        p.fillRect(X, Y, ts, ts)
        drawDeco(p, s, v, X, Y, ts)
        if map.block[i] { drawObstacle(p, s, X, Y, ts) }
        if map.isCamp[i] {
            p.setFill("rgba(0,0,0,0.15)")
            p.begin()
            p.ellipse(X + ts * 0.5, Y + ts * 0.86, ts * 0.38, ts * 0.08)
            p.fill()
            p.setStroke("#6A2E12")
            p.lineWidth(max(1, ts * 0.04))
            p.begin()
            p.move(X + ts * 0.5, Y + ts * 0.16)
            p.line(X + ts * 0.9, Y + ts * 0.84)
            p.line(X + ts * 0.1, Y + ts * 0.84)
            p.close()
            p.fillStroke("#D9743C")
            p.begin()
            p.move(X + ts * 0.5, Y + ts * 0.46)
            p.line(X + ts * 0.62, Y + ts * 0.84)
            p.line(X + ts * 0.38, Y + ts * 0.84)
            p.close()
            p.fill("#6A2E12")
        }
    }

    private static func drawDeco(_ p: Pen, _ s: HabitatInfo, _ v: CGFloat, _ X: CGFloat, _ Y: CGFloat, _ ts: CGFloat) {
        switch s.deco {
        case "pebble":
            if v < 0.22 {
                p.setFill(s.decoColor)
                p.begin()
                p.circle(X + ts * (0.25 + v), Y + ts * 0.6, ts * 0.05)
                p.circle(X + ts * 0.7, Y + ts * (0.2 + v), ts * 0.04)
                p.fill()
            }
        case "grass":
            if v < 0.3 {
                p.setStroke(s.decoColor)
                p.lineWidth(max(1, ts * 0.05))
                p.begin()
                let gx = X + ts * (0.25 + v)
                let gy = Y + ts * 0.68
                p.move(gx, gy)
                p.line(gx - ts * 0.06, gy - ts * 0.16)
                p.move(gx + ts * 0.1, gy)
                p.line(gx + ts * 0.12, gy - ts * 0.2)
                p.move(gx + ts * 0.2, gy)
                p.line(gx + ts * 0.27, gy - ts * 0.15)
                p.stroke()
            } else if v > 0.92 {
                p.begin()
                p.circle(X + ts * 0.5, Y + ts * 0.5, ts * 0.07)
                p.fill(v > 0.96 ? "#F6E27A" : "#F5B5CC")
            }
        case "litter":
            if v < 0.35 {
                p.setFill(s.decoColor)
                p.begin()
                p.circle(X + ts * (0.2 + v), Y + ts * 0.7, ts * 0.06)
                p.circle(X + ts * 0.7, Y + ts * (0.15 + v), ts * 0.05)
                p.fill()
            }
        case "crack":
            if v < 0.3 {
                p.setStroke(s.decoColor)
                p.lineWidth(max(1, ts * 0.04))
                p.begin()
                p.move(X + ts * 0.2, Y + ts * (0.3 + v))
                p.line(X + ts * 0.45, Y + ts * 0.55)
                p.line(X + ts * 0.4, Y + ts * 0.8)
                p.stroke()
            }
        case "ash":
            if v < 0.3 {
                p.setFill(s.decoColor)
                p.begin()
                p.circle(X + ts * (0.2 + v), Y + ts * 0.65, ts * 0.05)
                p.circle(X + ts * 0.72, Y + ts * (0.2 + v), ts * 0.04)
                p.fill()
            } else if v > 0.93 {
                p.begin()
                p.circle(X + ts * 0.5, Y + ts * 0.55, ts * 0.05)
                p.fill("#FF8A3D")
            }
        case "bubble":
            if v < 0.3 {
                p.setStroke(s.decoColor)
                p.lineWidth(max(1, ts * 0.035))
                p.begin()
                p.circle(X + ts * (0.3 + v), Y + ts * 0.6, ts * 0.08)
                p.stroke()
                p.begin()
                p.circle(X + ts * 0.72, Y + ts * 0.3, ts * 0.05)
                p.stroke()
            }
        case "snow":
            if v < 0.3 {
                p.setFill(s.decoColor)
                p.begin()
                p.circle(X + ts * (0.25 + v), Y + ts * 0.6, ts * 0.04)
                p.circle(X + ts * 0.7, Y + ts * (0.2 + v), ts * 0.03)
                p.circle(X + ts * 0.4, Y + ts * 0.25, ts * 0.025)
                p.fill()
            }
        default:
            break
        }
    }

    private static func drawObstacle(_ p: Pen, _ s: HabitatInfo, _ X: CGFloat, _ Y: CGFloat, _ ts: CGFloat) {
        let a = s.obstacleColors[0]
        let b = s.obstacleColors[1]
        switch s.obstacle {
        case "tree":
            p.setFill("#6B4A2E")
            p.fillRect(X + ts * 0.44, Y + ts * 0.55, ts * 0.12, ts * 0.35)
            p.begin()
            p.circle(X + ts * 0.5, Y + ts * 0.4, ts * 0.36)
            p.fill(a)
            p.begin()
            p.circle(X + ts * 0.4, Y + ts * 0.3, ts * 0.16)
            p.fill(b)
        case "pine":
            p.setFill("#5A4030")
            p.fillRect(X + ts * 0.45, Y + ts * 0.7, ts * 0.1, ts * 0.22)
            p.setFill(a)
            for i in 0..<3 {
                let o = CGFloat(i) * 0.2
                p.begin()
                p.move(X + ts * 0.5, Y + ts * (0.04 + o))
                p.line(X + ts * 0.82, Y + ts * (0.42 + o))
                p.line(X + ts * 0.18, Y + ts * (0.42 + o))
                p.close()
                p.fill()
            }
            p.begin()
            p.move(X + ts * 0.5, Y + ts * 0.04)
            p.line(X + ts * 0.62, Y + ts * 0.2)
            p.line(X + ts * 0.38, Y + ts * 0.2)
            p.close()
            p.fill(b)
        case "deadtree":
            p.setStroke(a)
            p.lineWidth(max(2, ts * 0.1))
            p.roundCaps()
            p.begin()
            p.move(X + ts * 0.5, Y + ts * 0.9)
            p.line(X + ts * 0.5, Y + ts * 0.3)
            p.move(X + ts * 0.5, Y + ts * 0.55)
            p.line(X + ts * 0.25, Y + ts * 0.3)
            p.move(X + ts * 0.5, Y + ts * 0.45)
            p.line(X + ts * 0.76, Y + ts * 0.2)
            p.stroke()
            p.buttCaps()
            p.begin()
            p.circle(X + ts * 0.5, Y + ts * 0.86, ts * 0.06)
            p.fill(b)
        case "boulder":
            p.begin()
            p.ellipse(X + ts * 0.5, Y + ts * 0.58, ts * 0.38, ts * 0.3)
            p.fill(a)
            p.begin()
            p.ellipse(X + ts * 0.42, Y + ts * 0.48, ts * 0.18, ts * 0.11)
            p.fill(b)
        case "bush":
            p.begin()
            p.circle(X + ts * 0.38, Y + ts * 0.6, ts * 0.24)
            p.circle(X + ts * 0.64, Y + ts * 0.56, ts * 0.26)
            p.fill(a)
        case "obsidian", "crystal", "icespike":
            p.begin()
            p.move(X + ts * 0.2, Y + ts * 0.88)
            p.line(X + ts * 0.36, Y + ts * 0.3)
            p.line(X + ts * 0.52, Y + ts * 0.88)
            p.close()
            p.fill(a)
            p.begin()
            p.move(X + ts * 0.42, Y + ts * 0.88)
            p.line(X + ts * 0.62, Y + ts * 0.12)
            p.line(X + ts * 0.84, Y + ts * 0.88)
            p.close()
            p.fill(a)
            p.begin()
            p.move(X + ts * 0.62, Y + ts * 0.12)
            p.line(X + ts * 0.7, Y + ts * 0.6)
            p.line(X + ts * 0.6, Y + ts * 0.88)
            p.line(X + ts * 0.56, Y + ts * 0.5)
            p.close()
            p.fill(b)
        case "vent":
            p.begin()
            p.ellipse(X + ts * 0.5, Y + ts * 0.72, ts * 0.36, ts * 0.2)
            p.fill(a)
            p.begin()
            p.ellipse(X + ts * 0.5, Y + ts * 0.66, ts * 0.16, ts * 0.07)
            p.fill("#3A332E")
            p.alpha(0.75)
            p.begin()
            p.circle(X + ts * 0.46, Y + ts * 0.42, ts * 0.12)
            p.circle(X + ts * 0.58, Y + ts * 0.24, ts * 0.09)
            p.fill(b)
            p.alpha(1)
        default:
            p.begin()
            p.ellipse(X + ts * 0.5, Y + ts * 0.6, ts * 0.3, ts * 0.2)
            p.fill(a)
            p.begin()
            p.ellipse(X + ts * 0.44, Y + ts * 0.54, ts * 0.13, ts * 0.07)
            p.fill(b)
        }
    }

    /// The guardian's shrine: a stone arch with an orb that glows until the guardian is calm.
    static func shrineImage(calm: Bool) -> UIImage {
        let ts = tile
        let r = renderer(CGSize(width: ts, height: ts), scale: min(UIScreen.main.scale, 3))
        return r.image { ctx in
            let p = Pen(ctx.cgContext)
            p.setFill("rgba(0,0,0,0.18)")
            p.begin()
            p.ellipse(ts * 0.5, ts * 0.9, ts * 0.44, ts * 0.08)
            p.fill()
            p.setFill("#D7D2C4")
            p.setStroke("#5C574B")
            p.lineWidth(max(1, ts * 0.04))
            let stones: [[CGFloat]] = [[0.12, 0.3, 0.16, 0.6], [0.72, 0.3, 0.16, 0.6], [0.04, 0.14, 0.92, 0.18]]
            for rect in stones {
                p.fillRect(ts * rect[0], ts * rect[1], ts * rect[2], ts * rect[3])
                p.strokeRect(ts * rect[0], ts * rect[1], ts * rect[2], ts * rect[3])
            }
            p.begin()
            p.circle(ts * 0.5, ts * 0.62, ts * 0.15)
            p.fill(calm ? "#B9C4BE" : "#F2B63A")
            if !calm {
                p.begin()
                p.circle(ts * 0.46, ts * 0.57, ts * 0.05)
                p.fill("rgba(255,255,255,0.75)")
            }
        }
    }

    /// The sparkle that marks an item lying on the ground.
    static func sparkleImage() -> UIImage {
        let ts = tile
        let r = renderer(CGSize(width: ts, height: ts), scale: min(UIScreen.main.scale, 3))
        return r.image { ctx in
            let p = Pen(ctx.cgContext)
            let cx = ts * 0.5
            let cy = ts * 0.55
            let radius = ts * 0.22
            p.setStroke("#B8860B")
            p.lineWidth(max(1, ts * 0.035))
            p.begin()
            for a in 0..<8 {
                let rr = a % 2 == 1 ? radius * 0.38 : radius
                let an = CGFloat(a) * CGFloat.pi / 4 - CGFloat.pi / 2
                p.line(cx + cos(an) * rr, cy + sin(an) * rr)
            }
            p.close()
            p.fillStroke("#FFF4B8")
        }
    }

    /// The wanderer, facing right. Flip the sprite to face left.
    static func walkerImage() -> UIImage {
        let side = tile * 1.05
        let r = renderer(CGSize(width: side, height: side), scale: min(UIScreen.main.scale, 3))
        return r.image { ctx in
            let p = Pen(ctx.cgContext)
            p.save()
            p.translate(side / 2, side / 2)
            p.scale(side, side)
            p.roundLines()
            p.lineWidth(0.032)
            p.setStroke("#3B1A12")
            p.setFill("rgba(0,0,0,0.18)")
            p.begin()
            p.ellipse(0, 0.45, 0.2, 0.045)
            p.fill()
            p.begin()
            p.move(-0.1, -0.02)
            p.line(0.1, -0.02)
            p.line(0.21, 0.42)
            p.line(-0.21, 0.42)
            p.close()
            p.fillStroke("#C7452F")
            p.begin()
            p.circle(0, -0.13, 0.15)
            p.fillStroke("#F1D2B0")
            p.setStroke("#18233A")
            p.begin()
            p.ellipse(0, -0.2, 0.25, 0.055)
            p.fillStroke("#2B3A55")
            p.begin()
            p.move(-0.14, -0.2)
            p.quad(0, -0.47, 0.14, -0.2)
            p.close()
            p.fillStroke("#2B3A55")
            p.setStroke("#E8B23A")
            p.lineWidth(0.03)
            p.begin()
            p.move(-0.08, -0.33)
            p.line(-0.2, -0.42)
            p.stroke()
            p.setFill("#1B1F23")
            p.begin()
            p.circle(0.06, -0.1, 0.022)
            p.fill()
            p.begin()
            p.circle(-0.04, -0.1, 0.022)
            p.fill()
            p.restore()
        }
    }

    /// A small overview of the whole isle for the Map panel.
    static func minimap(map: IsleMap, playerX: Int, playerY: Int) -> UIImage {
        let cell: CGFloat = 8
        let side = CGFloat(IsleMap.width) * cell
        let isle = GameData.isles[map.isle]
        let r = renderer(CGSize(width: side, height: side), scale: 1)
        return r.image { ctx in
            let p = Pen(ctx.cgContext)
            for y in 0..<IsleMap.height {
                for x in 0..<IsleMap.width {
                    let i = IsleMap.index(x, y)
                    let b = Int(map.biome[i])
                    p.setFill(b == 0 ? isle.sea[0] : isle.habitat(b).palette[0])
                    p.fillRect(CGFloat(x) * cell, CGFloat(y) * cell, cell, cell)
                    if map.block[i] {
                        p.setFill("rgba(0,0,0,0.22)")
                        p.fillRect(CGFloat(x) * cell + 2, CGFloat(y) * cell + 2, 4, 4)
                    }
                }
            }
            for j in map.camps {
                let cx = CGFloat(IsleMap.x(j)) * cell
                let cy = CGFloat(IsleMap.y(j)) * cell
                p.setFill("#D9743C")
                p.fillRect(cx - 2, cy - 2, 12, 12)
                p.setStroke("#6A2E12")
                p.lineWidth(2)
                p.strokeRect(cx - 2, cy - 2, 12, 12)
            }
            let sx = CGFloat(IsleMap.x(map.shrine)) * cell
            let sy = CGFloat(IsleMap.y(map.shrine)) * cell
            p.setStroke("#3A3528")
            p.lineWidth(2)
            p.begin()
            p.move(sx + 4, sy - 7)
            p.line(sx + 14, sy + 12)
            p.line(sx - 6, sy + 12)
            p.close()
            p.fillStroke("#F2B63A")
            p.setStroke("#C7452F")
            p.lineWidth(4)
            p.begin()
            p.circle(CGFloat(playerX) * cell + 4, CGFloat(playerY) * cell + 4, 8)
            p.fillStroke("#FFFFFF")
        }
    }
}
