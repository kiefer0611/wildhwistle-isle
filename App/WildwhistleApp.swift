import SwiftUI
import SpriteKit
import GameCore

@main
struct WildwhistleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: RootView.makeScene(size: geo.size))
                .ignoresSafeArea()
        }
    }

    static func makeScene(size: CGSize) -> SKScene {
        let scene = PlaceholderScene(size: size)
        scene.scaleMode = .resizeFill
        return scene
    }
}

/// First native scene: proves the SpriteKit pipeline builds and runs on the Mac build machine.
final class PlaceholderScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.24, green: 0.56, blue: 0.69, alpha: 1)
        let island = SKShapeNode(ellipseOf: CGSize(width: size.width * 0.7, height: size.width * 0.5))
        island.fillColor = SKColor(red: 0.61, green: 0.80, blue: 0.42, alpha: 1)
        island.strokeColor = SKColor(red: 0.90, green: 0.84, blue: 0.64, alpha: 1)
        island.lineWidth = 10
        island.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(island)

        let title = SKLabelNode(text: GameInfo.name)
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = 30
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height / 2)
        title.verticalAlignmentMode = .center
        addChild(title)

        let sub = SKLabelNode(text: "Native build \(GameInfo.version)")
        sub.fontName = "AvenirNext-Medium"
        sub.fontSize = 15
        sub.fontColor = SKColor(white: 1, alpha: 0.85)
        sub.position = CGPoint(x: size.width / 2, y: size.height / 2 - 34)
        addChild(sub)
    }
}
