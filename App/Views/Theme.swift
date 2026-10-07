import SwiftUI
import UIKit
import GameCore

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 255) / 255, green: CGFloat((rgb >> 8) & 255) / 255, blue: CGFloat(rgb & 255) / 255, alpha: 1)
    }
}

extension Color {
    /// A colour that follows the light or dark appearance.
    static func dyn(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light)
        })
    }

    init(hexString: String) {
        self.init(Pen.uiColor(hexString))
    }
}

enum Theme {
    static let bg = Color.dyn(0xEDF1EA, 0x0F1815)
    static let surface = Color.dyn(0xFAFCF8, 0x18241F)
    static let ink = Color.dyn(0x17231E, 0xE3EBE4)
    static let muted = Color.dyn(0x55645C, 0x9BAAA1)
    static let line = Color.dyn(0xC6D0C7, 0x2F3F37)
    static let accent = Color.dyn(0x0F6E78, 0x57C2C9)
    static let accentInk = Color.dyn(0xFFFFFF, 0x06282B)
    static let good = Color.dyn(0x2C7A39, 0x6CC27A)
    static let warn = Color.dyn(0x96650A, 0xE0B04A)
    static let bad = Color.dyn(0xB0382C, 0xEF7D6E)
    static let track = Color.dyn(0xD6DED6, 0x2A3832)

    static func display(_ style: Font.TextStyle, _ weight: Font.Weight = .bold) -> Font {
        Font.system(style, design: .rounded).weight(weight)
    }

    static func mono(_ style: Font.TextStyle) -> Font {
        Font.system(style, design: .monospaced).weight(.semibold)
    }
}

/// The standard bordered button.
struct KitButtonStyle: ButtonStyle {
    var primary = false
    var danger = false
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(minHeight: 40)
            .foregroundColor(primary ? Theme.accentInk : (danger ? Theme.bad : Theme.ink))
            .background(RoundedRectangle(cornerRadius: 9).fill(primary ? Theme.accent : Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(primary ? Theme.accent : (danger ? Theme.bad : Theme.line), lineWidth: 1))
            .opacity(enabled ? (configuration.isPressed ? 0.7 : 1) : 0.5)
    }
}

/// A button with a title and a smaller second line, used for encounter actions.
struct ActionButton: View {
    let title: String
    let subtitle: String
    var primary = false
    let id: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption2).opacity(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(KitButtonStyle(primary: primary))
        .accessibilityIdentifier(id)
    }
}

struct HealthBar: View {
    let fraction: Double
    var height: CGFloat = 10

    private var color: Color { fraction > 0.5 ? Theme.good : (fraction > 0.2 ? Theme.warn : Theme.bad) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                Capsule().fill(color).frame(width: max(0, min(1, CGFloat(fraction))) * geo.size.width)
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.35), value: fraction)
        .accessibilityHidden(true)
    }
}

struct CreaturePicture: View {
    let sp: String
    let grown: Bool
    let size: CGFloat

    init(_ c: Creature, size: CGFloat) {
        sp = c.sp
        grown = c.grown
        self.size = size
    }

    init(sp: String, grown: Bool = false, size: CGFloat) {
        self.sp = sp
        self.grown = grown
        self.size = size
    }

    var body: some View {
        Image(uiImage: CreatureArt.image(sp, grown: grown, points: 96))
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct ElementTag: View {
    let element: Element
    var extra: String = ""

    var body: some View {
        let info = GameData.elements[element]!
        HStack(spacing: 6) {
            Circle().fill(Color(hexString: info.colorHex)).frame(width: 9, height: 9)
            Text(info.name + extra).font(.footnote).foregroundColor(Theme.muted)
        }
    }
}

struct Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }
}

struct Note: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A brief sideways shake, used when a creature is struck.
struct Shake: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let phase = animatableData - animatableData.rounded(.down)
        return ProjectionTransform(CGAffineTransform(translationX: sin(phase * .pi * 4) * 5, y: 0))
    }
}

func weakTo(_ el: Element) -> String {
    Element.allCases.filter { GameData.elements[$0]!.beats.contains(el) }.map { GameData.elements[$0]!.name }.joined(separator: " and ")
}
