import UIKit
import CoreGraphics

/// A small drawing helper whose calls mirror the ones the reference art was written with,
/// so the creature and island drawings port across line for line.
final class Pen {
    let c: CGContext
    private var path = CGMutablePath()

    init(_ c: CGContext) { self.c = c }

    // State (all of it lives in the graphics state, so save/restore covers it)
    func save() { c.saveGState() }
    func restore() { c.restoreGState() }
    func translate(_ x: CGFloat, _ y: CGFloat) { c.translateBy(x: x, y: y) }
    func scale(_ x: CGFloat, _ y: CGFloat) { c.scaleBy(x: x, y: y) }
    func lineWidth(_ w: CGFloat) { c.setLineWidth(w) }
    func alpha(_ a: CGFloat) { c.setAlpha(a) }
    func roundLines() {
        c.setLineJoin(.round)
        c.setLineCap(.round)
    }
    func buttCaps() { c.setLineCap(.butt) }
    func roundCaps() { c.setLineCap(.round) }
    func setFill(_ s: String) { c.setFillColor(Pen.color(s)) }
    func setStroke(_ s: String) { c.setStrokeColor(Pen.color(s)) }

    // Paths
    func begin() { path = CGMutablePath() }
    func move(_ x: CGFloat, _ y: CGFloat) { path.move(to: CGPoint(x: x, y: y)) }
    func line(_ x: CGFloat, _ y: CGFloat) {
        if path.isEmpty { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    func quad(_ cx: CGFloat, _ cy: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cx, y: cy))
    }
    func bezier(_ ax: CGFloat, _ ay: CGFloat, _ bx: CGFloat, _ by: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: ax, y: ay), control2: CGPoint(x: bx, y: by))
    }
    func close() { path.closeSubpath() }
    /// Arc drawn in the direction of increasing angle, like the reference art.
    func arc(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ a0: CGFloat, _ a1: CGFloat) {
        path.addArc(center: CGPoint(x: x, y: y), radius: r, startAngle: a0, endAngle: a1, clockwise: false)
    }
    func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        path.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }
    func ellipse(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ rotation: CGFloat = 0) {
        let t = CGAffineTransform(translationX: x, y: y).rotated(by: rotation)
        path.addEllipse(in: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2), transform: t)
    }
    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        path.addRect(CGRect(x: x, y: y, width: w, height: h))
    }

    // Painting
    func fill() {
        c.addPath(path)
        c.fillPath()
    }
    func stroke() {
        c.addPath(path)
        c.strokePath()
    }
    func clip() {
        c.addPath(path)
        c.clip()
    }
    func fill(_ color: String) {
        setFill(color)
        fill()
    }
    func fillStroke(_ color: String) {
        setFill(color)
        fill()
        stroke()
    }
    func fillRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        c.fill(CGRect(x: x, y: y, width: w, height: h))
    }
    func strokeRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        c.stroke(CGRect(x: x, y: y, width: w, height: h))
    }

    // Colours: "#RRGGBB", "#RGB" or "rgba(r,g,b,a)".
    private static var cache: [String: CGColor] = [:]

    static func color(_ s: String) -> CGColor {
        if let hit = cache[s] { return hit }
        let made = parse(s)
        cache[s] = made
        return made
    }

    static func uiColor(_ s: String) -> UIColor { UIColor(cgColor: color(s)) }

    private static func parse(_ s: String) -> CGColor {
        if s.hasPrefix("#") {
            var hex = String(s.dropFirst())
            if hex.count == 3 { hex = hex.map { "\($0)\($0)" }.joined() }
            let v = UInt32(hex, radix: 16) ?? 0
            let r = CGFloat((v >> 16) & 255) / 255
            let g = CGFloat((v >> 8) & 255) / 255
            let b = CGFloat(v & 255) / 255
            return UIColor(red: r, green: g, blue: b, alpha: 1).cgColor
        }
        if s.hasPrefix("rgba("), s.hasSuffix(")") {
            let inner = s.dropFirst(5).dropLast()
            let parts = inner.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
            if parts.count == 4 {
                return UIColor(red: CGFloat(parts[0] / 255), green: CGFloat(parts[1] / 255), blue: CGFloat(parts[2] / 255), alpha: CGFloat(parts[3])).cgColor
            }
        }
        return UIColor.magenta.cgColor
    }
}
