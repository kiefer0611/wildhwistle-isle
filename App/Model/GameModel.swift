import SwiftUI
import UIKit
import GameCore

/// Connects the game rules to the screen: what is showing, walking, saving and playing encounters back line by line.
@MainActor
final class GameModel: ObservableObject {
    enum Panel: Equatable {
        case team, guide, notes, map, help, shrine, ending, complete
    }

    enum Screen: Equatable {
        case start
        case explore
        case battle
        case panel(Panel)
    }

    enum BattleMode: Equatable {
        case choose, whistle, swap, bag, done
    }

    @Published private(set) var screen: Screen = .start {
        didSet { scene.isPaused = screen != .explore }
    }
    /// Bumped whenever anything in the game changes, so views redraw.
    @Published private(set) var revision = 0
    @Published var toast: String? = nil
    @Published var pick: String = GameData.starters[0]
    @Published var confirmingReset = false

    // Encounter presentation
    @Published private(set) var lines: [String] = []
    @Published private(set) var shown: BattleView? = nil
    @Published private(set) var busy = false
    @Published private(set) var battleMode: BattleMode = .choose
    @Published private(set) var flashFoe = 0
    @Published private(set) var flashMe = 0
    @Published private(set) var zone: WhistleZone? = nil
    private(set) var zoneStart = Date()

    private(set) var game: Game?
    private(set) var battle: Battle?
    let scene: MapScene
    /// Test runs skip the reading pauses and use fixed dice.
    let fast: Bool
    private var path: [Int] = []
    private(set) var dest: Int? = nil
    private var toastToken = 0
    private var playToken = 0
    private let saveKey = "wildwhistle.save.v2"
    private let hitFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let noteFeedback = UINotificationFeedbackGenerator()

    init() {
        let args = ProcessInfo.processInfo.arguments
        fast = args.contains("-uitest")
        scene = MapScene(size: CGSize(width: 390, height: 600))
        scene.scaleMode = .resizeFill
        scene.model = self
        if args.contains("-reset") { UserDefaults.standard.removeObject(forKey: saveKey) }
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let save = try? JSONDecoder().decode(SaveData.self, from: data),
           let g = Game(save: save, dice: makeDice()) {
            game = g
            screen = .explore
            scene.reload()
        }
        if let i = args.firstIndex(of: "-demo"), i + 1 < args.count { applyDemo(args[i + 1]) }
    }

    private func makeDice() -> Dice { fast ? Dice(seed: 20261007) : Dice() }

    private func touch() { revision &+= 1 }

    // MARK: Starting, saving

    func setOut() {
        guard screen == .start else { return }
        let seed: UInt32 = fast ? 424242 : UInt32.random(in: 1...UInt32.max - 1)
        game = Game(starter: pick, seed: seed, dice: makeDice())
        screen = .explore
        path = []
        dest = nil
        scene.reload()
        save()
        showToast("Tap the map to walk. Walk into a creature to meet it.")
        touch()
    }

    func save() {
        guard let g = game else { return }
        if let data = try? JSONEncoder().encode(g.serialize()) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    func eraseAndRestart() {
        UserDefaults.standard.removeObject(forKey: saveKey)
        game = nil
        battle = nil
        path = []
        dest = nil
        confirmingReset = false
        screen = .start
        scene.reload()
        touch()
    }

    func showToast(_ text: String, seconds: Double = 2.8) {
        toast = text
        toastToken += 1
        let token = toastToken
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self = self, self.toastToken == token else { return }
            self.toast = nil
        }
    }

    // MARK: Walking

    var isWalking: Bool { !path.isEmpty }

    /// A tap on the map: walk there, or explain why not.
    func tap(tileX tx: Int, tileY ty: Int) {
        guard screen == .explore, let g = game else { return }
        if tx == g.x && ty == g.y { return }
        guard g.isDestination(tx, ty) else {
            showToast("You can\u{2019}t walk there.")
            return
        }
        guard let route = g.findPath(toX: tx, y: ty, avoidWilds: true) ?? g.findPath(toX: tx, y: ty, avoidWilds: false) else {
            showToast("No way through to that spot.")
            return
        }
        path = route
        dest = IsleMap.index(tx, ty)
        scene.showDestination(dest)
    }

    /// Takes the next step of the current walk. Called by the scene when the previous step has finished.
    func advance() {
        guard screen == .explore, let g = game, !path.isEmpty else { return }
        let next = path[0]
        let nx = IsleMap.x(next)
        let ny = IsleMap.y(next)
        if path.count > 1, g.wildAt(nx, ny) != nil, let d = dest,
           let alt = g.findPath(toX: IsleMap.x(d), y: IsleMap.y(d), avoidWilds: true), !alt.isEmpty {
            path = alt
            return
        }
        path.removeFirst()
        handle(g.step(dx: nx - g.x, dy: ny - g.y))
    }

    private func stopWalking() {
        path = []
        dest = nil
        scene.showDestination(nil)
    }

    private func handle(_ result: StepResult) {
        guard let g = game else { return }
        switch result {
        case .blocked:
            stopWalking()
        case .shrine:
            stopWalking()
            scene.facePlayer()
            open(.shrine)
        case .encounter(let id):
            stopWalking()
            scene.facePlayer()
            startBattle(wildId: id)
        case .moved(let info):
            scene.playerStepped()
            if path.isEmpty { stopWalking() }
            if let tired = info.restedTired {
                showToast(tired ? "Camp. Your whole team is rested." : "Camp. You wake here if your party tires out.")
                save()
            } else if let kind = info.found {
                showToast("You found a \(GameData.items[kind]!.singular).")
                scene.syncPickups()
                save()
            } else if g.steps % 8 == 0 {
                save()
            }
            if g.steps % 45 == 0 { scene.syncPickups() }
            touch()
        }
    }

    /// Lets the island's creatures wander. Called by the scene about once a second.
    func tick() {
        guard screen == .explore, let g = game else { return }
        if g.tick() { scene.syncWilds(animated: true) }
    }

    // MARK: Panels

    func open(_ p: Panel) {
        guard screen == .explore, game != nil else { return }
        stopWalking()
        confirmingReset = false
        screen = .panel(p)
        touch()
    }

    func closePanel() {
        guard case .panel = screen else { return }
        screen = .explore
        touch()
    }

    func moveMember(_ i: Int, by d: Int) {
        guard case .panel = screen, let g = game else { return }
        g.moveMember(i, by: d)
        save()
        touch()
    }

    func useItem(_ k: ItemKind, on i: Int) {
        guard case .panel = screen, let g = game else { return }
        if let text = g.applyItem(k, on: i) {
            save()
            showToast(text)
            touch()
        }
    }

    func sail(to i: Int) {
        guard case .panel = screen, let g = game else { return }
        if g.sail(to: i) {
            screen = .explore
            scene.reload()
            save()
            showToast("You sail to \(g.isleInfo.name) and wake rested at camp.")
            touch()
        }
    }

    // MARK: Encounters

    private func begin(_ b: Battle) {
        battle = b
        lines = [b.intro]
        shown = b.view
        busy = false
        battleMode = .choose
        zone = nil
        screen = .battle
        touch()
    }

    private func startBattle(wildId: Int) {
        guard let g = game else { return }
        guard let b = g.startWildBattle(wildId: wildId) else {
            showToast("Your party is too tired. Rest at a camp, or change your party in Team.")
            return
        }
        begin(b)
    }

    func challengeGuardian() {
        guard screen == .panel(.shrine), let g = game else { return }
        guard let b = g.startGuardianBattle() else {
            showToast("Your party is too tired. Rest at a camp first.")
            return
        }
        begin(b)
    }

    /// Shows the lines of a turn one after another, then hands control back.
    private func play(_ events: [BattleEvent]) {
        guard !events.isEmpty else { return }
        busy = true
        battleMode = .choose
        playToken += 1
        playNext(events, 0, playToken)
    }

    private func playNext(_ events: [BattleEvent], _ i: Int, _ token: Int) {
        guard token == playToken, let b = battle else { return }
        if i >= events.count {
            busy = false
            if b.over {
                battleMode = .done
                if b.result == .friend { noteFeedback.notificationOccurred(.success) }
                save()
            } else if b.needsSwap {
                battleMode = .swap
            } else {
                battleMode = .choose
            }
            touch()
            return
        }
        let e = events[i]
        lines.append(e.text)
        if lines.count > 3 { lines.removeFirst(lines.count - 3) }
        shown = e.view
        if let side = e.flash {
            if side == .foe { flashFoe += 1 } else { flashMe += 1 }
            if !fast { hitFeedback.impactOccurred() }
        }
        let pause: Double = fast ? 0.01 : 0.62
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
            self?.playNext(events, i + 1, token)
        }
    }

    func act(_ move: Battle.Move) {
        guard screen == .battle, !busy, battleMode == .choose, let b = battle else { return }
        play(b.perform(move))
    }

    func openWhistle() {
        guard screen == .battle, !busy, battleMode == .choose, let b = battle, b.canWhistle else { return }
        zone = b.makeWhistleZone()
        zoneStart = Date()
        battleMode = .whistle
    }

    /// Where the whistle marker is right now, from 0 to 1.
    func markerPosition(at date: Date = Date()) -> Double {
        guard let z = zone else { return 0 }
        return Rules.tri(date.timeIntervalSince(zoneStart) / z.period)
    }

    func whistleNow() {
        guard screen == .battle, !busy, battleMode == .whistle, let b = battle, let z = zone else { return }
        let hit = z.contains(markerPosition())
        play(b.whistle(hit: hit))
    }

    func openSwap() {
        guard screen == .battle, !busy, battleMode == .choose, let b = battle, !b.swapChoices.isEmpty else { return }
        battleMode = .swap
    }

    func openBag() {
        guard screen == .battle, !busy, battleMode == .choose, let b = battle, !b.bagOptions.isEmpty else { return }
        battleMode = .bag
    }

    /// Back out of the whistle, swap or bag choice without spending the turn.
    func backToChoices() {
        guard screen == .battle, !busy, let b = battle, !b.needsSwap, !b.over else { return }
        battleMode = .choose
    }

    func swap(to i: Int) {
        guard screen == .battle, !busy, battleMode == .swap, let b = battle else { return }
        play(b.swap(to: i))
    }

    func useInBattle(_ option: BagOption) {
        guard screen == .battle, !busy, battleMode == .bag, let b = battle else { return }
        play(b.useItem(option))
    }

    func leaveBattle() {
        guard screen == .battle, !busy, let b = battle, !b.over else { return }
        b.leave()
        finishBattle(message: "You step back and leave it be.")
    }

    func continueAfterBattle() {
        guard screen == .battle, !busy, let b = battle, b.over else { return }
        var message: String? = nil
        var seconds = 2.8
        if b.result == .blackout {
            message = "You wake at camp. Everyone is rested."
        } else if !b.notes.isEmpty {
            message = b.notes.joined(separator: " ")
            seconds = 4.2 + Double(b.notes.count) * 1.8
        }
        finishBattle(message: message, seconds: seconds)
    }

    private func finishBattle(message: String?, seconds: Double = 2.8) {
        guard let g = game, let b = battle else { return }
        let after = b.after
        battle = nil
        shown = nil
        lines = []
        zone = nil
        playToken += 1
        g.afterEncounter()
        screen = .explore
        scene.syncAll()
        save()
        if let m = message { showToast(m, seconds: seconds) }
        if after == .ending {
            screen = .panel(.ending)
        } else if after == .complete {
            screen = .panel(.complete)
        }
        touch()
    }

    // MARK: Screens for automated screenshots

    private func applyDemo(_ name: String) {
        if name == "start" { return }
        if game == nil {
            pick = "burrbit"
            setOut()
        }
        guard let g = game else { return }
        toast = nil
        switch name {
        case "team": screen = .panel(.team)
        case "guide": screen = .panel(.guide)
        case "notes": screen = .panel(.notes)
        case "islemap": screen = .panel(.map)
        case "help": screen = .panel(.help)
        case "shrine": screen = .panel(.shrine)
        case "battle":
            if let w = g.wilds.first(where: { !g.owned.contains($0.sp) }) ?? g.wilds.first, let b = g.startWildBattle(wildId: w.id) {
                begin(b)
            }
        case "guardian":
            if let b = g.startGuardianBattle() { begin(b) }
        default:
            break
        }
    }
}
