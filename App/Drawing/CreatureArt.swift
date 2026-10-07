import UIKit
import GameCore

/// Draws the creatures. Every creature is built from the same small set of parts described in the game data.
enum CreatureArt {
    private static var cache: [String: UIImage] = [:]

    /// A square picture of a creature, cached by species, form and size.
    static func image(_ sp: String, grown: Bool, points: CGFloat) -> UIImage {
        let key = "\(sp)|\(grown)|\(Int(points))"
        if let hit = cache[key] { return hit }
        let format = UIGraphicsImageRendererFormat()
        format.scale = min(UIScreen.main.scale, 3)
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: points, height: points), format: format)
        let img = renderer.image { ctx in
            draw(Pen(ctx.cgContext), id: sp, cx: points / 2, cy: points / 2, s: points, grown: grown)
        }
        cache[key] = img
        return img
    }

    static func image(_ c: Creature, points: CGFloat) -> UIImage {
        image(c.sp, grown: c.grown, points: points)
    }

    static func draw(_ p: Pen, id: String, cx: CGFloat, cy: CGFloat, s: CGFloat, grown: Bool) {
        guard let a = GameData.art[id] else { return }
        let dims: [String: [CGFloat]] = [
            "drop": [0.30, 0.30], "round": [0.32, 0.30], "tall": [0.25, 0.35], "wide": [0.39, 0.27],
            "egg": [0.29, 0.32], "pear": [0.34, 0.31], "bean": [0.31, 0.28]
        ]
        let d = dims[a.shape] ?? [0.32, 0.30]
        let rx = d[0]
        let ry = d[1]
        let by: CGFloat = 0.42 - ry
        let top: CGFloat = by - ry
        let tau = CGFloat.pi * 2
        let pi = CGFloat.pi
        let k: CGFloat = grown ? 1 : 0.9
        let c1 = a.body
        let c2 = a.belly
        let c3 = a.line
        let dark = "#1B1F23"
        let signs: [CGFloat] = [-1, 1]
        let trio: [CGFloat] = [-1, 0, 1]

        p.save()
        p.translate(cx, cy + s * 0.44 * (1 - k))
        p.scale(s * k, s * k)
        p.roundLines()
        p.lineWidth(0.032)
        p.setStroke(c3)

        func body() {
            p.begin()
            if a.shape == "drop" {
                p.move(0, top - 0.1)
                p.bezier(rx * 0.55, top + 0.06, rx, by - 0.1, rx, by + 0.05)
                p.bezier(rx, by + ry * 1.25, -rx, by + ry * 1.25, -rx, by + 0.05)
                p.bezier(-rx, by - 0.1, -rx * 0.55, top + 0.06, 0, top - 0.1)
                p.close()
            } else if a.shape == "pear" {
                p.move(0, top)
                p.bezier(rx * 0.75, top, rx * 0.7, by - 0.05, rx, by + 0.1)
                p.bezier(rx * 1.05, by + ry * 1.15, -rx * 1.05, by + ry * 1.15, -rx, by + 0.1)
                p.bezier(-rx * 0.7, by - 0.05, -rx * 0.75, top, 0, top)
                p.close()
            } else if a.shape == "bean" {
                p.move(-rx * 0.2, top)
                p.bezier(rx * 0.9, top - 0.02, rx * 1.1, by + ry * 0.9, rx * 0.3, by + ry)
                p.bezier(-rx * 0.6, by + ry * 1.05, -rx * 1.15, by + ry * 0.4, -rx, by - 0.02)
                p.bezier(-rx * 0.95, top + 0.08, -rx * 0.6, top, -rx * 0.2, top)
                p.close()
            } else {
                p.ellipse(0, by, rx, ry)
            }
        }

        // ground shadow
        p.setFill("rgba(0,0,0,0.16)")
        p.begin()
        p.ellipse(0, 0.45, rx * 0.9, 0.045)
        p.fill()

        // a grown creature gets a ruff of spikes behind it
        if grown {
            for i in 0..<7 {
                let an: CGFloat = pi * (1.12 + CGFloat(i) * 0.127)
                p.begin()
                p.move(cos(an - 0.09) * rx * 0.9, by + sin(an - 0.09) * ry * 0.9)
                p.line(cos(an) * (rx + 0.085), by + sin(an) * (ry + 0.085))
                p.line(cos(an + 0.09) * rx * 0.9, by + sin(an + 0.09) * ry * 0.9)
                p.close()
                p.fillStroke(c3)
            }
        }

        // tails and wings sit behind the body
        if a.extras.contains("t") {
            p.begin()
            p.move(rx * 0.7, by + 0.12)
            p.quad(rx + 0.2, by - 0.02, rx + 0.17, by + 0.24)
            p.quad(rx + 0.05, by + 0.18, rx * 0.7, by + 0.2)
            p.close()
            p.fillStroke(c1)
        }
        if a.extras.contains("f") {
            p.begin()
            p.move(rx * 0.75, by + 0.18)
            p.quad(rx + 0.22, by + 0.14, rx + 0.12, by - 0.12)
            p.quad(rx + 0.06, by + 0.02, rx * 0.75, by + 0.06)
            p.close()
            p.fill("#F28C28")
            p.setStroke("#B8480F")
            p.stroke()
            p.setStroke(c3)
        }
        if a.extras.contains("c") {
            p.begin()
            p.lineWidth(0.05)
            p.arc(rx + 0.04, by + 0.12, 0.085, pi * 0.9, pi * 2.6)
            p.stroke()
            p.lineWidth(0.032)
        }
        if a.extras.contains("w") {
            for sg in signs {
                p.begin()
                p.move(sg * rx * 0.75, by - 0.06)
                p.quad(sg * (rx + 0.2), by - 0.26, sg * (rx + 0.15), by + 0.07)
                p.quad(sg * (rx + 0.04), by + 0.02, sg * rx * 0.75, by + 0.1)
                p.close()
                p.fillStroke(c2)
            }
        }
        if a.pattern == "burr" {
            for i in 0..<9 {
                let ab: CGFloat = pi * (1.08 + CGFloat(i) * 0.105)
                p.begin()
                p.move(cos(ab) * rx * 0.92, by + sin(ab) * ry * 0.92)
                p.line(cos(ab) * (rx + 0.07), by + sin(ab) * (ry + 0.07))
                p.stroke()
            }
        }

        // ears, horns and other headgear
        let et: CGFloat = a.shape == "drop" ? 0.08 : (a.shape == "bean" ? 0.02 : 0)
        switch a.ears {
        case "fin":
            p.begin()
            p.move(-0.09, top + 0.04 + et)
            p.quad(0.02, top - 0.2, 0.13, top + 0.06 + et)
            p.close()
            p.fillStroke(c3)
        case "tuft":
            for i in trio {
                p.begin()
                p.ellipse(i * 0.08, top - 0.02, 0.045, 0.085, i * 0.4)
                p.fillStroke(c1)
            }
        case "point":
            for sg in signs {
                p.begin()
                p.move(sg * rx * 0.25, top + 0.07)
                p.line(sg * rx * 0.78, top - 0.13)
                p.line(sg * rx * 0.9, top + 0.16)
                p.close()
                p.fillStroke(c1)
            }
        case "long":
            for sg in signs {
                p.begin()
                p.ellipse(sg * rx * 0.5, top - 0.04, 0.055, 0.15, sg * 0.3)
                p.fillStroke(c1)
            }
        case "leaf":
            p.begin()
            p.move(0, top + 0.03)
            p.line(0, top - 0.07)
            p.stroke()
            p.begin()
            p.move(0, top - 0.06)
            p.quad(0.2, top - 0.2, 0.2, top - 0.02)
            p.quad(0.08, top + 0.01, 0, top - 0.06)
            p.close()
            p.fillStroke("#7CC66A")
        case "horn":
            for sg in signs {
                p.begin()
                p.move(sg * rx * 0.3, top + 0.05)
                p.quad(sg * rx * 0.5, top - 0.16, sg * rx * 0.85, top - 0.1)
                p.quad(sg * rx * 0.6, top - 0.02, sg * rx * 0.62, top + 0.1)
                p.close()
                p.fillStroke(c2)
            }
        case "crest":
            for i in trio {
                p.begin()
                p.move(i * 0.14 - 0.07, top + 0.05)
                p.line(i * 0.14, top - 0.1 + abs(i) * 0.04)
                p.line(i * 0.14 + 0.07, top + 0.05)
                p.close()
                p.fillStroke(c3)
            }
        case "flame":
            for i in trio {
                let fh: CGFloat = i != 0 ? 0.11 : 0.18
                p.begin()
                p.move(i * 0.09 - 0.05, top + 0.05 + et)
                p.quad(i * 0.09 - 0.07, top - fh * 0.5, i * 0.09 + 0.01, top - fh)
                p.quad(i * 0.09 + 0.08, top - fh * 0.4, i * 0.09 + 0.05, top + 0.05 + et)
                p.close()
                p.fill(i != 0 ? "#F28C28" : "#FFD24A")
                p.setStroke("#B8480F")
                p.stroke()
                p.setStroke(c3)
            }
        case "ice":
            for i in trio {
                p.begin()
                p.move(i * 0.11 - 0.05, top + 0.06 + et)
                p.line(i * 0.13, top - (i != 0 ? 0.1 : 0.17))
                p.line(i * 0.11 + 0.05, top + 0.06 + et)
                p.close()
                p.fillStroke("#E6F7FD")
            }
        case "antler":
            for sg in signs {
                p.lineWidth(0.036)
                p.begin()
                p.move(sg * rx * 0.35, top + 0.04)
                p.quad(sg * rx * 0.45, top - 0.1, sg * rx * 0.95, top - 0.15)
                p.move(sg * rx * 0.52, top - 0.06)
                p.line(sg * rx * 0.5, top - 0.17)
                p.move(sg * rx * 0.72, top - 0.11)
                p.line(sg * rx * 0.78, top - 0.2)
                p.stroke()
                p.lineWidth(0.032)
            }
        case "antenna":
            for sg in signs {
                p.begin()
                p.move(sg * rx * 0.3, top + 0.03)
                p.quad(sg * rx * 0.4, top - 0.1, sg * rx * 0.7, top - 0.12)
                p.stroke()
                p.begin()
                p.circle(sg * rx * 0.7, top - 0.12, 0.035)
                p.fillStroke(c2)
            }
        case "curl":
            p.lineWidth(0.045)
            p.begin()
            p.arc(0.04, top - 0.05, 0.07, pi * 0.6, pi * 2.3)
            p.stroke()
            p.lineWidth(0.032)
        default:
            break
        }

        // body, then belly and markings clipped to it
        body()
        p.fillStroke(c1)
        p.save()
        body()
        p.clip()
        p.begin()
        p.ellipse(0, by + ry * 0.62, rx * 0.7, ry * 0.58)
        p.fill(c2)
        switch a.pattern {
        case "spots":
            p.setFill(c3)
            p.alpha(0.35)
            let spots: [[CGFloat]] = [[-0.6, -0.55, 0.05], [0.55, -0.6, 0.06], [0.72, -0.05, 0.04]]
            for q in spots {
                p.begin()
                p.circle(q[0] * rx, by + q[1] * ry, q[2])
                p.fill()
            }
            p.alpha(1)
        case "frost":
            p.setFill("#FFFFFF")
            p.alpha(0.85)
            let flecks: [[CGFloat]] = [[-0.55, -0.5, 0.03], [0.2, -0.72, 0.025], [0.62, -0.4, 0.035], [-0.75, 0, 0.025], [0.78, 0.1, 0.02]]
            for q in flecks {
                p.begin()
                p.circle(q[0] * rx, by + q[1] * ry, q[2])
                p.fill()
            }
            p.alpha(1)
        case "stripe":
            p.lineWidth(0.045)
            p.alpha(0.45)
            for i in 0..<2 {
                p.begin()
                p.arc(0, top - 0.16 + CGFloat(i) * 0.09, 0.24, 0.25 * pi, 0.75 * pi)
                p.stroke()
            }
            p.alpha(1)
            p.lineWidth(0.032)
        case "shell":
            p.alpha(0.5)
            for i in 1...3 {
                p.begin()
                p.arc(0, by - ry * 0.25, rx * 0.27 * CGFloat(i), 1.1 * pi, 1.9 * pi)
                p.stroke()
            }
            p.alpha(1)
        case "scale":
            p.alpha(0.4)
            p.lineWidth(0.022)
            for i in 0..<3 {
                for j in -2...2 {
                    let sx: CGFloat = CGFloat(j) * 0.11 + CGFloat(i % 2) * 0.055
                    p.begin()
                    p.arc(sx, top + 0.1 + CGFloat(i) * 0.07, 0.05, 0, pi)
                    p.stroke()
                }
            }
            p.alpha(1)
            p.lineWidth(0.032)
        case "ring":
            p.alpha(0.4)
            p.lineWidth(0.03)
            p.begin()
            p.ellipse(0, by + ry * 0.62, rx * 0.7, ry * 0.58)
            p.stroke()
            p.alpha(1)
            p.lineWidth(0.032)
        case "moss":
            p.setFill("#8FB04A")
            p.begin()
            p.ellipse(-rx * 0.2, top + 0.03, rx * 0.6, 0.075)
            p.fill()
            p.begin()
            p.circle(rx * 0.4, top + 0.07, 0.06)
            p.fill()
        case "crack", "ember", "bolt":
            p.save()
            p.alpha(a.pattern == "crack" ? 0.55 : 0.95)
            p.lineWidth(a.pattern == "crack" ? 0.022 : 0.03)
            p.setStroke(a.pattern == "ember" ? "#FF8A3D" : (a.pattern == "bolt" ? "#FFD84A" : c3))
            p.begin()
            p.move(-rx * 0.2, top + 0.02)
            p.line(-rx * 0.42, top + 0.13)
            p.line(-rx * 0.22, top + 0.17)
            p.line(-rx * 0.38, top + 0.26)
            if a.pattern != "crack" {
                p.move(rx * 0.5, top + 0.06)
                p.line(rx * 0.34, top + 0.15)
                p.line(rx * 0.52, top + 0.2)
            }
            p.stroke()
            p.restore()
        default:
            break
        }
        p.restore()

        // face
        let exx: CGFloat = rx * 0.42
        let ey: CGFloat = by - 0.03
        p.setFill("rgba(235,120,130,0.28)")
        for sg in signs {
            p.begin()
            p.circle(sg * rx * 0.66, by + 0.07, 0.045)
            p.fill()
        }
        for sg in signs {
            if a.eyes == "sleepy" {
                p.setStroke(dark)
                p.lineWidth(0.03)
                p.begin()
                p.arc(sg * exx, ey, 0.045, 0.15 * pi, 0.85 * pi)
                p.stroke()
            } else {
                if a.eyes == "wide" {
                    p.begin()
                    p.circle(sg * exx, ey, 0.068)
                    p.fill("#FFFFFF")
                }
                p.begin()
                p.circle(sg * exx, ey, a.eyes == "wide" ? 0.036 : 0.04)
                p.fill(dark)
                p.begin()
                p.circle(sg * exx + 0.013, ey - 0.014, 0.012)
                p.fill("#FFFFFF")
            }
        }
        p.setStroke(dark)
        p.lineWidth(0.024)
        p.begin()
        p.arc(0, by + 0.045, 0.04, 0.15 * pi, 0.85 * pi)
        p.stroke()
        if grown {
            p.lineWidth(0.026)
            p.setStroke(c3)
            for sg in signs {
                p.begin()
                p.move(sg * rx * 0.8, by - 0.02)
                p.line(sg * rx * 0.62, by + 0.01)
                p.move(sg * rx * 0.84, by + 0.05)
                p.line(sg * rx * 0.66, by + 0.06)
                p.stroke()
            }
        }
        p.setFill(c3)
        for sg in signs {
            p.begin()
            p.ellipse(sg * rx * 0.45, 0.43, 0.07, 0.035)
            p.fill()
        }
        _ = tau
        p.restore()
    }
}
