import SpriteKit
import UIKit
import GameCore

/// The island: terrain, creatures, items and the wanderer, with a camera that follows the walk.
final class MapScene: SKScene {
    weak var model: GameModel?

    private let ts = TileArt.tile
    private let world = SKNode()
    private let cam = SKCameraNode()
    private let terrain = SKNode()
    private let things = SKNode()
    private var chunks: [Int: SKSpriteNode] = [:]
    private var wildNodes: [Int: SKNode] = [:]
    private var pickupNodes: [Int: SKSpriteNode] = [:]
    private var player: SKSpriteNode?
    private var shrine: SKSpriteNode?
    private var marker: SKShapeNode?
    private var built = false
    private var builtIsle = -1
    private var builtSeed: UInt32 = 0
    private var lastStep: TimeInterval = 0
    private var lastTick: TimeInterval = 0
    private var now: TimeInterval = 0
    private let stepTime: TimeInterval = 0.12

    override func didMove(to view: SKView) {
        if !built {
            built = true
            backgroundColor = Pen.uiColor("#3E8FB0")
            addChild(world)
            world.addChild(terrain)
            world.addChild(things)
            addChild(cam)
            camera = cam
        }
        view.isMultipleTouchEnabled = false
        reload()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        fitCamera()
        centerCamera(animated: false)
    }

    private func point(_ x: Int, _ y: Int) -> CGPoint {
        CGPoint(x: (CGFloat(x) + 0.5) * ts, y: -(CGFloat(y) + 0.5) * ts)
    }

    // MARK: Building

    /// Rebuilds everything for the current isle. Safe to call before the scene is on screen.
    func reload() {
        guard built else { return }
        terrain.removeAllChildren()
        things.removeAllChildren()
        chunks = [:]
        wildNodes = [:]
        pickupNodes = [:]
        player = nil
        shrine = nil
        marker = nil
        guard let g = model?.game else {
            builtIsle = -1
            return
        }
        builtIsle = g.isle
        builtSeed = g.seed
        backgroundColor = Pen.uiColor(g.isleInfo.sea[0])

        let s = SKSpriteNode(texture: SKTexture(image: TileArt.shrineImage(calm: g.guardCalmed[g.isle])))
        s.size = CGSize(width: ts, height: ts)
        s.position = point(IsleMap.x(g.map.shrine), IsleMap.y(g.map.shrine))
        s.zPosition = 5
        things.addChild(s)
        shrine = s

        let p = SKSpriteNode(texture: SKTexture(image: TileArt.walkerImage()))
        p.size = CGSize(width: ts * 1.05, height: ts * 1.05)
        p.position = playerPoint(g.x, g.y)
        p.zPosition = 20
        p.xScale = g.face < 0 ? -1 : 1
        things.addChild(p)
        player = p

        fitCamera()
        centerCamera(animated: false)
        ensureChunks()
        syncWilds(animated: false)
        syncPickups()
    }

    private func playerPoint(_ x: Int, _ y: Int) -> CGPoint {
        let c = point(x, y)
        return CGPoint(x: c.x, y: c.y + ts * 0.08)
    }

    /// Refreshes creatures, items, shrine and the wanderer after something changed away from the map.
    func syncAll() {
        guard built, let g = model?.game else { return }
        if g.isle != builtIsle || g.seed != builtSeed {
            reload()
            return
        }
        shrine?.texture = SKTexture(image: TileArt.shrineImage(calm: g.guardCalmed[g.isle]))
        player?.removeAllActions()
        player?.position = playerPoint(g.x, g.y)
        syncWilds(animated: false)
        syncPickups()
        centerCamera(animated: false)
        ensureChunks()
    }

    private func makeWildNode(_ w: Wild, new: Bool) -> SKNode {
        let node = SKNode()
        let size = ts * 1.1
        let sprite = SKSpriteNode(texture: SKTexture(image: CreatureArt.image(w.sp, grown: w.grown, points: 64)))
        sprite.size = CGSize(width: size, height: size)
        sprite.position = CGPoint(x: 0, y: ts * 0.08)
        node.addChild(sprite)
        let label = SKLabelNode(text: (new ? "+ " : "") + "Lv \(w.level)")
        label.fontName = "Menlo-Bold"
        label.fontSize = 11
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        let width = label.frame.width + 8
        let plate = SKShapeNode(rectOf: CGSize(width: width, height: 15), cornerRadius: 2)
        plate.fillColor = new ? UIColor(red: 0.06, green: 0.24, blue: 0.26, alpha: 0.9) : UIColor(red: 0.12, green: 0.15, blue: 0.13, alpha: 0.62)
        plate.strokeColor = .clear
        plate.position = CGPoint(x: 0, y: ts * 0.62)
        plate.zPosition = 1
        label.position = .zero
        label.zPosition = 2
        plate.addChild(label)
        node.addChild(plate)
        node.zPosition = 10
        return node
    }

    func syncWilds(animated: Bool) {
        guard built, let g = model?.game else { return }
        let own = g.owned
        var alive: Set<Int> = []
        for w in g.wilds {
            alive.insert(w.id)
            let target = point(w.x, w.y)
            if let node = wildNodes[w.id] {
                if node.position != target {
                    node.removeAllActions()
                    if animated {
                        let move = SKAction.move(to: target, duration: 0.26)
                        move.timingMode = .easeOut
                        node.run(move)
                    } else {
                        node.position = target
                    }
                }
            } else {
                let node = makeWildNode(w, new: !own.contains(w.sp))
                node.name = own.contains(w.sp) ? "known" : "new"
                node.position = target
                things.addChild(node)
                wildNodes[w.id] = node
            }
        }
        for (id, node) in wildNodes where !alive.contains(id) {
            node.removeFromParent()
            wildNodes[id] = nil
        }
        // a creature you have just befriended loses its "new" plate on its kin
        for w in g.wilds {
            if let node = wildNodes[w.id], node.name == "new", own.contains(w.sp) {
                let pos = node.position
                node.removeFromParent()
                let fresh = makeWildNode(w, new: false)
                fresh.name = "known"
                fresh.position = pos
                things.addChild(fresh)
                wildNodes[w.id] = fresh
            }
        }
    }

    func syncPickups() {
        guard built, let g = model?.game else { return }
        var alive: Set<Int> = []
        for q in g.pickups {
            alive.insert(q.id)
            if pickupNodes[q.id] == nil {
                let n = SKSpriteNode(texture: SKTexture(image: TileArt.sparkleImage()))
                n.size = CGSize(width: ts, height: ts)
                n.position = point(q.x, q.y)
                n.zPosition = 6
                things.addChild(n)
                pickupNodes[q.id] = n
            }
        }
        for (id, node) in pickupNodes where !alive.contains(id) {
            node.removeFromParent()
            pickupNodes[id] = nil
        }
    }

    func showDestination(_ tile: Int?) {
        marker?.removeFromParent()
        marker = nil
        guard built, let t = tile else { return }
        let ring = SKShapeNode(circleOfRadius: ts * 0.28)
        ring.strokeColor = UIColor(white: 1, alpha: 0.9)
        ring.lineWidth = 2
        ring.fillColor = .clear
        ring.position = point(IsleMap.x(t), IsleMap.y(t))
        ring.zPosition = 4
        things.addChild(ring)
        marker = ring
    }

    // MARK: Movement and camera

    func facePlayer() {
        guard let g = model?.game else { return }
        player?.xScale = g.face < 0 ? -1 : 1
    }

    /// The wanderer has just moved one tile in the game; glide the sprite there.
    func playerStepped() {
        guard let g = model?.game, let p = player else { return }
        lastStep = now
        p.xScale = g.face < 0 ? -1 : 1
        p.removeAllActions()
        let move = SKAction.move(to: playerPoint(g.x, g.y), duration: stepTime)
        move.timingMode = .linear
        p.run(move)
    }

    private func fitCamera() {
        guard size.width > 0 else { return }
        // show about 9 tiles across on a phone, never more than 13 on a wide screen
        let across = size.width / ts
        cam.setScale(across > 13 ? 13 / across : 1)
    }

    private func cameraTarget() -> CGPoint {
        guard let p = player else { return .zero }
        let halfW = size.width * cam.xScale / 2
        let halfH = size.height * cam.yScale / 2
        let mapW = CGFloat(IsleMap.width) * ts
        let mapH = CGFloat(IsleMap.height) * ts
        var x = p.position.x
        var y = p.position.y
        x = mapW <= halfW * 2 ? mapW / 2 : min(max(x, halfW), mapW - halfW)
        y = mapH <= halfH * 2 ? -mapH / 2 : max(min(y, -halfH), -(mapH - halfH))
        return CGPoint(x: x, y: y)
    }

    private func centerCamera(animated: Bool) {
        cam.position = cameraTarget()
    }

    /// Makes sure the terrain pictures around the camera exist.
    private func ensureChunks() {
        guard let g = model?.game else { return }
        let side = CGFloat(TileArt.chunk) * ts
        let halfW = size.width * cam.xScale / 2 + ts
        let halfH = size.height * cam.yScale / 2 + ts
        let minX = Int(floor((cam.position.x - halfW) / side))
        let maxX = Int(floor((cam.position.x + halfW) / side))
        let minY = Int(floor((-cam.position.y - halfH) / side))
        let maxY = Int(floor((-cam.position.y + halfH) / side))
        let count = IsleMap.width / TileArt.chunk
        let loY = max(0, minY)
        let hiY = min(count - 1, maxY)
        let loX = max(0, minX)
        let hiX = min(count - 1, maxX)
        if loY > hiY || loX > hiX { return }
        for cy in loY...hiY {
            for cx in loX...hiX {
                let key = cy * count + cx
                if chunks[key] != nil { continue }
                let node = SKSpriteNode(texture: SKTexture(image: TileArt.chunkImage(map: g.map, chunkX: cx, chunkY: cy)))
                node.anchorPoint = CGPoint(x: 0, y: 1)
                node.size = CGSize(width: side, height: side)
                node.position = CGPoint(x: CGFloat(cx) * side, y: -CGFloat(cy) * side)
                node.zPosition = 0
                terrain.addChild(node)
                chunks[key] = node
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        now = currentTime
        guard let m = model, m.game != nil else { return }
        if m.screen == .explore {
            if currentTime - lastStep >= stepTime && m.isWalking {
                m.advance()
            }
            if currentTime - lastTick >= 0.9 {
                lastTick = currentTime
                m.tick()
            }
        }
        cam.position = cameraTarget()
        ensureChunks()
    }

    // MARK: Touch

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, let m = model, m.screen == .explore else { return }
        let loc = t.location(in: world)
        let tx = Int(floor(loc.x / ts))
        let ty = Int(floor(-loc.y / ts))
        m.tap(tileX: tx, tileY: ty)
    }
}
