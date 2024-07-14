//
//  ContentView.swift
//  WatchWizard Watch App
//
//  Created by Alessandro Fadini on 7/5/24.
//
import SwiftUI
import ClockKit
import WatchKit
import Foundation
import Combine
import UserNotifications

// MARK: - Data Structures

class Wizard: ObservableObject, Equatable, Codable {
    @Published var name: String
    @Published var level: Int
    @Published var xp: Int64
    @Published var gold: Int64
    @Published var spells: [Spell]
    @Published var inventory: [Item]
    @Published var xpPerHour: Double = 0
    @Published var goldPerHour: Double = 0
    
    enum CodingKeys: String, CodingKey {
        case name, level, xp, gold, spells, inventory, xpPerHour, goldPerHour
    }
    init(name: String, level: Int, xp: Int64, gold: Int64, spells: [Spell], inventory: [Item]) {
        self.name = name
        self.level = level
        self.xp = xp
        self.gold = gold
        self.spells = spells
        self.inventory = inventory
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        level = try container.decode(Int.self, forKey: .level)
        xp = try container.decode(Int64.self, forKey: .xp)  // Change to Int64
        gold = try container.decode(Int64.self, forKey: .gold)  // Change to Int64
        spells = try container.decode([Spell].self, forKey: .spells)
        inventory = try container.decode([Item].self, forKey: .inventory)
        xpPerHour = try container.decode(Double.self, forKey: .xpPerHour)
        goldPerHour = try container.decode(Double.self, forKey: .goldPerHour)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(level, forKey: .level)
        try container.encode(xp, forKey: .xp)
        try container.encode(gold, forKey: .gold)
        try container.encode(spells, forKey: .spells)
        try container.encode(inventory, forKey: .inventory)
        try container.encode(xpPerHour, forKey: .xpPerHour)
        try container.encode(goldPerHour, forKey: .goldPerHour)
    }
    //        try container.encode(name, forKey: .name)
    //        try container.encode(level, forKey: .level)
    //        try container.encode(xp, forKey: .xp)
    //        try container.encode(gold, forKey: .gold)
    //        try container.encode(spells, forKey: .spells)
    //        try container.encode(inventory, forKey: .inventory)
    //        try container.encode(xpPerHour, forKey: .xpPerHour)
    //        try container.encode(goldPerHour, forKey: .goldPerHour)
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(shortName, forKey: .shortName)
//        try container.encode(fullName, forKey: .fullName)
//        try container.encode(description, forKey: .description)
//        try container.encode(requiredLevel, forKey: .requiredLevel)
//        try container.encode(missionMessage, forKey: .missionMessage)
//        try container.encode(baseXPLower, forKey: .baseXPLower)
//        try container.encode(baseXPUpper, forKey: .baseXPUpper)
//        try container.encode(baseGoldLower, forKey: .baseGoldLower)
//        try container.encode(baseGoldUpper, forKey: .baseGoldUpper)
//        try container.encode(difficulty, forKey: .difficulty)
//        try container.encode(runDurationLower, forKey: .runDurationLower)
//        try container.encode(runDurationUpper, forKey: .runDurationUpper)
//        try container.encode(itemTypes, forKey: .itemTypes)
//    }
    
    static func == (lhs: Wizard, rhs: Wizard) -> Bool {
        return lhs.name == rhs.name && lhs.level == rhs.level && lhs.xp == rhs.xp &&
               lhs.gold == rhs.gold && lhs.spells == rhs.spells && lhs.inventory == rhs.inventory
    }
}
struct Spell: Identifiable, Equatable, Codable {
    let id = UUID()
    var name: String
    var description: String
    var effect: String
    var requiredLevel: Int
    var goldCost: Int64
    var successChanceBonus: Double
    var xpPerHour: Double = 0
    var goldPerHour: Double = 0
    
    enum CodingKeys: String, CodingKey {
        case name, description, effect, requiredLevel, goldCost, successChanceBonus, xpPerHour, goldPerHour
        // Note: 'id' is not included here
    }
    
    static func == (lhs: Spell, rhs: Spell) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Item: Identifiable, Equatable, Codable {
    let id = UUID()
    var name: String
    var quantity: Int
    
    enum CodingKeys: String, CodingKey {
        case name, quantity
        // Note: 'id' is not included here
    }
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.quantity == rhs.quantity
    }
}

struct Run: Codable {
    var location: Location
    var duration: TimeInterval
    var xpGained: Int64
    var goldGained: Int64
    var itemsGained: [Item]
    var creaturesDefeated: [String]
    var succeeded: Bool
}



struct Location: Identifiable, Equatable, Codable {
    let id: UUID
    let shortName: String
    let fullName: String
    let description: String
    let requiredLevel: Int
    let missionMessage: String
    let baseXPLower: Int64
    let baseXPUpper: Int64
    let baseGoldLower: Int64
    let baseGoldUpper: Int64
    let difficulty: Double
    let runDurationLower: TimeInterval
    let runDurationUpper: TimeInterval
    let itemTypes: [ItemType]

    var baseXP: ClosedRange<Int64> {
        baseXPLower...baseXPUpper
    }

    var baseGold: ClosedRange<Int64> {
        baseGoldLower...baseGoldUpper
    }

    var runDuration: ClosedRange<TimeInterval> {
        runDurationLower...runDurationUpper
    }

    enum CodingKeys: String, CodingKey {
        case id, shortName, fullName, description, requiredLevel, missionMessage
        case baseXPLower, baseXPUpper, baseGoldLower, baseGoldUpper
        case difficulty, runDurationLower, runDurationUpper, itemTypes
    }

    init(id: UUID, shortName: String, fullName: String, description: String, requiredLevel: Int, missionMessage: String,
         baseXPLower: Int64, baseXPUpper: Int64, baseGoldLower: Int64, baseGoldUpper: Int64,
         difficulty: Double, runDurationLower: TimeInterval, runDurationUpper: TimeInterval, itemTypes: [ItemType]) {
        self.id = id
        self.shortName = shortName
        self.fullName = fullName
        self.description = description
        self.requiredLevel = requiredLevel
        self.missionMessage = missionMessage
        self.baseXPLower = baseXPLower
        self.baseXPUpper = baseXPUpper
        self.baseGoldLower = baseGoldLower
        self.baseGoldUpper = baseGoldUpper
        self.difficulty = difficulty
        self.runDurationLower = runDurationLower
        self.runDurationUpper = runDurationUpper
        self.itemTypes = itemTypes
    }

    init(id: UUID, shortName: String, fullName: String, description: String, requiredLevel: Int, missionMessage: String, baseXPLower: Int, baseXPUpper: Int, baseGoldLower: Int, baseGoldUpper: Int, difficulty: Double, runDurationLower: TimeInterval, runDurationUpper: TimeInterval, itemTypes: [ItemType]) {
        self.id = id
        self.shortName = shortName
        self.fullName = fullName
        self.description = description
        self.requiredLevel = requiredLevel
        self.missionMessage = missionMessage
        self.baseXPLower = Int64(baseXPLower)
        self.baseXPUpper = Int64(baseXPUpper)
        self.baseGoldLower = Int64(baseGoldLower)
        self.baseGoldUpper = Int64(baseGoldUpper)
        self.difficulty = difficulty
        self.runDurationLower = runDurationLower
        self.runDurationUpper = runDurationUpper
        self.itemTypes = itemTypes
    }
}
enum ItemType: Codable {
    case treasure
}

enum AlertType {
    case levelUp, gainsUpdate, viewUnlocked, story
}

extension Int64 {
    var formattedWithSeparator: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}
//
//struct FloatingText: Identifiable {
//    let id = UUID()
//    var text: String
//    var position: CGPoint
//    var opacity: Double
//}

// MARK: - Game Data

class GameData: ObservableObject {
    // Dev Vars
    @Published var isTestMode: Bool = false
    @Published var easyXP: Bool = false
    @Published var extraMoney: Bool = true
    // Locked Views
    @Published var unlockedViews: Set<String> = ["CharacterSheet", "ArcaneLibrary"]
    // Script Vars
    @Published var wizard: Wizard
    @Published var wizardTitle: String = "Uninitiated"
//    @Published var purchasedSpells: [Spell] = []
//    @Published var gold: Int = 0
//    @Published var inventory: [Item]
    @Published var currentRun: Run?
    @Published var completedRuns: [Run]
    @Published var runStartTime: Date?
    @Published var leveledUpDuringLastRun: Bool = false
    @Published var lastUpdateTime: Date
    @Published var lastLevelUp: Int64?
    @Published var passiveXPGained: Int64 = 0
    @Published var passiveGoldGained: Int64 = 0
//    @Published var showPassiveGainAlert = false
//    @Published private(set) var alertQueue: [CustomAlert] = []
//    @Published private(set) var currentAlert: CustomAlert?
    @Published private(set) var alertQueue: [(title: String, message: String, type: AlertType)] = []
    @Published private(set) var currentAlert: (title: String, message: String, type: AlertType)?
    @Published var hasShownGainsUpdateThisSession: Bool = false
    @Published var hasShownWelcomeMessage: Bool = false
    // to handle complications updates along with passiveGainsAlert
    @Published var pendingPassiveXP: Int64 = 0
    @Published var pendingPassiveGold: Int64 = 0
    

    private var unlockedFeatures: Set<String> = []
    
    // MARK: GD - Alert System

    
    func showCustomAlert(title: String, message: String, type: AlertType) {
        alertQueue.append((title: title, message: message, type: type))
        if currentAlert == nil {
            presentNextAlert()
        }
    }
    
    func presentNextAlert() {
        if !alertQueue.isEmpty {
            currentAlert = alertQueue.removeFirst()
        } else {
            currentAlert = nil
        }
    }
    
    func dismissCurrentAlert() {
        currentAlert = nil
        presentNextAlert()
    }

    init() {
        self.wizard = Wizard(name: "Merlin", level: 1, xp: 0, gold: 0, spells: [availableSpells[0]], inventory: [])
        self.completedRuns = []
        self.lastUpdateTime = Date()
        
        if extraMoney {
            self.wizard.gold = 1000000
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }

    func unlockFeature(_ feature: String) {
           if !unlockedViews.contains(feature) {
               unlockedViews.insert(feature)
               let (title, message) = getUnlockMessage(for: feature)
               showCustomAlert(title: title, message: message, type: .viewUnlocked)
               saveUnlockedFeatures()
           }
       }
       
       private func saveUnlockedFeatures() {
           UserDefaults.standard.set(Array(unlockedViews), forKey: "UnlockedViews")
       }
       
       private func loadUnlockedFeatures() {
           if let savedFeatures = UserDefaults.standard.array(forKey: "UnlockedViews") as? [String] {
               unlockedViews = Set(savedFeatures)
           }
       }
    

    private func getUnlockMessage(for feature: String) -> (String, String) {
        switch feature {
        case "RunView":
            return ("A World Awaits!", "Thy skills have grown, brave wizard. New lands and adventures now beckon thee. Venture forth and explore the realm!")
        case "ShopView":
            return ("Mystical Emporium Discovered!", "In thy travels, thou hast stumbled upon a hidden shop of arcane wonders. Its proprietor welcomes thee to peruse the mystical wares.")
        case "InventoryView":
            return ("Enchanted Satchel Acquired!", "A magical satchel has appeared at thy side. 'Tis bound to thee, ready to store the treasures of thy quests.")
        case "HistoryView":
            return ("Chronicles of thy Deeds!", "The bards have begun to sing of thy exploits. Thy legendary tales are now recorded for posterity.")
        default:
            return ("New Power Awakened!", "A new ability has manifested within thee. Explore and discover its secrets!")
        }
    }
    
    func showWelcomeMessage() {
        if !hasShownWelcomeMessage {
            showCustomAlert(
                title: "Hark, Wizard \(wizard.name)!",
                message: "Your magical journey begins! The Arcane Council urges you to study the mystic tomes in the Arcane Sanctum. With each page turned, your powers shall grow.",
                type: .story
            )
            hasShownWelcomeMessage = true
            saveGame()
        }
    }
 
    func checkUnlocks() {
        if !unlockedViews.contains("RunView") && wizard.level >= 2 {
            unlockFeature("RunView")
        }
        if !unlockedViews.contains("ShopView") && completedRuns.contains(where: { $0.location.shortName == "Village" }) {
            unlockFeature("ShopView")
        }
        if !unlockedViews.contains("InventoryView") && completedRuns.contains(where: { $0.location.shortName == "Inn Basement" }) {
            unlockFeature("InventoryView")
        }
        if !unlockedViews.contains("HistoryView") && wizard.level >= 10 {
            unlockFeature("HistoryView")
        }
    }
    
    var totalSuccessChanceBonus: Double {
         wizard.spells.reduce(0) { $0 + $1.successChanceBonus }
     }
    
    
    var xpNeededForLevelUp: Int64 {
        if easyXP {
            return 200 // in easyXP mode, only 200 xp per level
        } else {
            let currentLevel = wizard.level
            if currentLevel < levelUpTitlesAndXP.count {
                return levelUpTitlesAndXP[currentLevel].xpRequired
            } else {
                // For levels beyond our defined array, we'll use a formula
                return Int64(Double(levelUpTitlesAndXP.last!.xpRequired) * pow(1.1, Double(currentLevel - levelUpTitlesAndXP.count)))
            }
        }
    }
//    func getCurrentTitle() -> String {
//         let currentXP = wizard.xp
//         for levelInfo in levelUpTitlesAndXP.reversed() {
//             if currentXP >= levelInfo.xpRequired {
//                 return levelInfo.title
//             }
//         }
//         return levelUpTitlesAndXP[0].title // Default to the first title if something goes wrong
//     }
    func getCurrentTitle() -> String {
         let newTitle = levelUpTitlesAndXP[wizard.level].title
        wizardTitle = newTitle
        return newTitle
     }

    // Around line 611
    func studyArcaneTexts() -> Int64 {
        let baseXP: Int64 = 1
        var additionalXP: Int64 = 0
        
        if wizard.spells.contains(where: { $0.name == "Arcane Amplification" }) {
            additionalXP += 100
        }
        if wizard.spells.contains(where: { $0.name == "Grand Arcane Mastery" }) {
            additionalXP += 1000
        }
        
        let totalXPGain = baseXP + additionalXP
        wizard.xp += totalXPGain
        checkLevelUp()
        checkUnlocks()
        return totalXPGain
    }

    func startRun(location: Location) {
        leveledUpDuringLastRun = false
        let duration: TimeInterval = isTestMode ? 10 : TimeInterval.random(in: location.runDuration)
        runStartTime = Date()
        currentRun = Run(location: location, duration: duration, xpGained: 0, goldGained: 0, itemsGained: [], creaturesDefeated: [], succeeded: false)
        scheduleRogueEvent(for: location)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.completeRun()
        }
    }

      
      func completeRun() {
          guard var run = currentRun else { return }
          
        let baseSuccessChance = 1.0 - run.location.difficulty
          let adjustedSuccessChance = min(baseSuccessChance + totalSuccessChanceBonus, 1.0)
          run.succeeded = Double.random(in: 0...1) < adjustedSuccessChance
          
          if run.succeeded {
              run.xpGained = Int64.random(in: run.location.baseXP)
              run.goldGained = Int64.random(in: run.location.baseGold)
          } else {
              run.xpGained = Int64(Double(run.location.baseXP.lowerBound) * 0.1)
              run.goldGained = Int64(Double(run.location.baseGold.lowerBound) * 0.1)
          }
          
          run.itemsGained = generateItems(for: run.location)
          run.creaturesDefeated = generateCreatures()
          
          wizard.xp += run.xpGained
          wizard.gold += run.goldGained
          wizard.inventory.append(contentsOf: run.itemsGained)
          consolidateAndSortInventory()
          completedRuns.append(run)
          currentRun = nil
          
          checkLevelUp()
          runStartTime = nil
          saveGame()
          checkUnlocks()
      }

    func generateItems(for location: Location) -> [Item] {
        let count = Int.random(in: 1...3)
        var items: [Item] = []
        
        for _ in 0..<count {
              let availableTreasures = treasureList.filter { $0.minLevel <= wizard.level }
              if let treasure = availableTreasures.randomElement() {
                  items.append(Item(name: treasure.name, quantity: 1))
              }
          }
        
        return items
    }
    
    
    func consolidateAndSortInventory() {
            var consolidatedItems: [String: Int] = [:]
            
            // Consolidate items
            for item in wizard.inventory {
                consolidatedItems[item.name, default: 0] += item.quantity
            }
            
            // Create new inventory array and sort by gold value
            wizard.inventory = consolidatedItems.map { Item(name: $0.key, quantity: $0.value) }
                .sorted { item1, item2 in
                    let value1 = treasureList.first(where: { $0.name == item1.name })?.goldValue ?? 0
                    let value2 = treasureList.first(where: { $0.name == item2.name })?.goldValue ?? 0
                    return value1 > value2
                }
            
            saveGame()
        }
    
    func checkLevelUp() {
        let initialLevel = wizard.level
        // Also checks that wizard is below Max level (55)
        while wizard.level < levelUpTitlesAndXP.count && wizard.xp >= levelUpTitlesAndXP[wizard.level].xpRequired {
              wizard.level += 1
          }
        if wizard.level > initialLevel {
            leveledUpDuringLastRun = true
            let newTitle = getCurrentTitle()
            showCustomAlert(
                title: "Hark! Thou hast ascended!",
                message: "Thy prowess has grown. Thou art now level \(wizard.level), a \(newTitle)!",
                type: .levelUp
            )
            lastLevelUp = Int64(wizard.level)
        }
        updateComplications()
        objectWillChange.send()
    }
    
    func purchaseSpell(_ spell: Spell) {
        if wizard.gold >= spell.goldCost && wizard.level >= spell.requiredLevel {
            wizard.gold -= spell.goldCost
            wizard.spells.append(spell)
            wizard.xpPerHour += spell.xpPerHour
            wizard.goldPerHour += spell.goldPerHour
        saveGame()
        checkUnlocks()
        }
    }
    
    
    func generateCreatures() -> [String] {
        let count = Int.random(in: 1...3)
        let availableCreatures = creatures.filter { $0.minLevel <= wizard.level }
        return (0..<count).compactMap { _ in availableCreatures.randomElement()?.name }
      }
    
    func isLocationUnlocked(_ location: Location) -> Bool {
         return wizard.level >= location.requiredLevel
     }
     
    func nextUnlockedLocation() -> Location? {
        return allLocations.sorted { $0.requiredLevel > $1.requiredLevel }
            .first { !isLocationUnlocked($0) }
    }
    
    @MainActor
    public func updatePassiveGains() async {
        let now = Date()
        let elapsedHours = now.timeIntervalSince(lastUpdateTime) / 3600
        
        let passiveXPGained = Int64(wizard.xpPerHour * elapsedHours)
        let passiveGoldGained = Int64(wizard.goldPerHour * elapsedHours)
        
        wizard.xp += passiveXPGained
        wizard.gold += passiveGoldGained
        
        pendingPassiveXP += passiveXPGained
        pendingPassiveGold += passiveGoldGained
        
        lastUpdateTime = now
        
        checkLevelUp()
        saveGame()
        updateComplications()
        scheduleNextBackgroundRefresh()
    }

    func showPassiveGainsAlert() {
        if (pendingPassiveXP > 0 || pendingPassiveGold > 0) && !hasShownGainsUpdateThisSession {
            showCustomAlert(
                title: "Whilst thou rested...",
                message: "Thy coffers have grown by \(pendingPassiveGold)🟡 and thy knowledge by \(pendingPassiveXP) XP.",
                type: .gainsUpdate
            )
            hasShownGainsUpdateThisSession = true
            pendingPassiveXP = 0
            pendingPassiveGold = 0
        }
    }
        func scheduleNextBackgroundRefresh() {
            let earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
            WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: earliestBeginDate, userInfo: nil) { error in
                if let error = error {
                    print("Error scheduling background refresh: \(error.localizedDescription)")
                }
            }
        }



//
//  MARK: GD - Save Game
//
    func saveGame() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(wizard) {
            UserDefaults.standard.set(encoded, forKey: "SavedWizard")
        }
        UserDefaults.standard.set(lastUpdateTime, forKey: "LastUpdateTime")
        UserDefaults.standard.set(Array(unlockedViews), forKey: "UnlockedViews")
        UserDefaults.standard.set(Array(unlockedFeatures), forKey: "UnlockedFeatures")
        UserDefaults.standard.set(hasShownWelcomeMessage, forKey: "HasShownWelcomeMessage")
        if let encodedRuns = try? encoder.encode(completedRuns) {
             UserDefaults.standard.set(encodedRuns, forKey: "CompletedRuns")
         }
        }

    func loadGame() {
        let decoder = JSONDecoder()
        if let savedWizard = UserDefaults.standard.data(forKey: "SavedWizard"),
           let loadedWizard = try? decoder.decode(Wizard.self, from: savedWizard) {
            wizard = loadedWizard
        }
        lastUpdateTime = UserDefaults.standard.object(forKey: "LastUpdateTime") as? Date ?? Date()
        unlockedViews = Set(UserDefaults.standard.array(forKey: "UnlockedViews") as? [String] ?? ["CharacterSheet", "ArcaneLibrary"])
        unlockedFeatures = Set(UserDefaults.standard.array(forKey: "UnlockedFeatures") as? [String] ?? [])
        hasShownWelcomeMessage = UserDefaults.standard.bool(forKey: "HasShownWelcomeMessage")
        // Decode completedRuns
        if let savedRuns = UserDefaults.standard.data(forKey: "CompletedRuns"),
           let loadedRuns = try? decoder.decode([Run].self, from: savedRuns) {
            completedRuns = loadedRuns
        } else {
            completedRuns = []
        }
        // load title
        _ = getCurrentTitle()
    }
    
    // MARK: GD - Rogue Events
    @Published var currentRogueEvent: RogueEvent?
    @Published var showRogueEvent = false
    
    private func scheduleRogueEvent(for location: Location) {
        let minDelay = location.runDurationLower
        let maxDelay = location.runDurationUpper * 0.7
        let delay = Double.random(in: minDelay...maxDelay)

        DispatchQueue.main.asyncAfter(deadline: .now() +  delay) {
            self.triggerRogueEvent()
        }
    }

    private func triggerRogueEvent() {
        guard currentRun != nil else { return }
        currentRogueEvent = rogueEvents.randomElement()
        showRogueEvent = true

        // If the app is in the background, send a notification
        if WKExtension.shared().applicationState == .background {
            sendRogueEventNotification()
        }
    }

    private func sendRogueEventNotification() {
        guard let event = currentRogueEvent else { return }
        let content = UNMutableNotificationContent()
        content.title = "Rogue Event!"
        content.body = event.question
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    
}

// MARK: GD Extensions (Complications)

extension GameData {
    func updateComplications() {
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
    }
}

// MARK: - Game Content

struct LevelInfo {
    let level: Int
    let title: String
    let xpRequired: Int64
}

let levelUpTitlesAndXP: [LevelInfo] = [
    LevelInfo(level: 0, title: "Uninitiated", xpRequired: 0), // Dummy entry
    LevelInfo(level: 1, title: "Apprentice", xpRequired: 0),
    LevelInfo(level: 2, title: "Novice", xpRequired: 10),
    LevelInfo(level: 3, title: "Initiate", xpRequired: 50),
    LevelInfo(level: 4, title: "Scholar", xpRequired: 200),
    LevelInfo(level: 5, title: "Adept", xpRequired: 500),
    LevelInfo(level: 6, title: "Magus", xpRequired: 1500),
    LevelInfo(level: 7, title: "Conjurer", xpRequired: 2500),
    LevelInfo(level: 8, title: "Warlock", xpRequired: 5000),
    LevelInfo(level: 9, title: "Sorcerer", xpRequired: 7500),
    LevelInfo(level: 10, title: "Enchanter", xpRequired: 9_999),
    LevelInfo(level: 11, title: "Summoner", xpRequired: 12_000),
    LevelInfo(level: 12, title: "Illusionist", xpRequired: 14_000),
    LevelInfo(level: 13, title: "Elementalist", xpRequired: 30_000),
    LevelInfo(level: 14, title: "Thaumaturge", xpRequired: 40_000),
    LevelInfo(level: 15, title: "Necromancer", xpRequired: 50_000),
    LevelInfo(level: 16, title: "Diviner", xpRequired: 70_000),
    LevelInfo(level: 17, title: "Chronomancer", xpRequired: 99_999),
    LevelInfo(level: 18, title: "Mystic", xpRequired: 135_000),
    LevelInfo(level: 19, title: "Archmage", xpRequired: 200_000),
    LevelInfo(level: 20, title: "Spellbinder", xpRequired: 300_000),
    LevelInfo(level: 21, title: "Loremaster", xpRequired: 450_000),
    LevelInfo(level: 22, title: "Runeweaver", xpRequired: 675_000),
    LevelInfo(level: 23, title: "Astral Sage", xpRequired: 1_000_000),
    LevelInfo(level: 24, title: "Eldritch Knight", xpRequired: 1_500_000),
    LevelInfo(level: 25, title: "Void Walker", xpRequired: 3_000_000),
    LevelInfo(level: 26, title: "Starshaper", xpRequired: 5_000_000),
    LevelInfo(level: 27, title: "Planeswalker", xpRequired: 8_000_000),
    LevelInfo(level: 28, title: "Reality Bender", xpRequired: 11_000_000),
    LevelInfo(level: 29, title: "Cosmic Weaver", xpRequired: 17_000_000),
    LevelInfo(level: 30, title: "Aether Lord", xpRequired: 24_000_000),
    LevelInfo(level: 31, title: "Time Lord", xpRequired: 40_000_000),
    LevelInfo(level: 32, title: "Dimension Hopper", xpRequired: 53_000_000),
    LevelInfo(level: 33, title: "Multiverse Sage", xpRequired: 64_000_000),
    LevelInfo(level: 34, title: "Infinity Mage", xpRequired: 75_000_000),
    LevelInfo(level: 35, title: "Omniscient One", xpRequired: 100_000_000),
    LevelInfo(level: 36, title: "Reality Architect", xpRequired: 200_000_000),
    LevelInfo(level: 37, title: "Cosmic Puppeteer", xpRequired: 300_000_000),
    LevelInfo(level: 38, title: "Nexus Master", xpRequired: 500_000_000),
    LevelInfo(level: 39, title: "Eternity Shaper", xpRequired: 700_000_000),
    LevelInfo(level: 40, title: "Pandimensional", xpRequired: 999_999_999),
    LevelInfo(level: 41, title: "Void Emperor", xpRequired: 2_000_000_000),
    LevelInfo(level: 42, title: "Quantum Overlord", xpRequired: 3_000_000_000),
    LevelInfo(level: 43, title: "Celestial Arbiter", xpRequired:5_000_000_000),
    LevelInfo(level: 44, title: "Cosmic Architect", xpRequired: 10_000_000_000),
    LevelInfo(level: 45, title: "Omniverse Sage", xpRequired: 20_000_000_000),
    LevelInfo(level: 46, title: "Reality Tyrant", xpRequired: 50_000_000_000),
    LevelInfo(level: 47, title: "Existence Weaver", xpRequired: 60_000_000_000),
    LevelInfo(level: 48, title: "Infinity Sovereign", xpRequired: 70_000_000_000),
    LevelInfo(level: 49, title: "Cosmic Harmony", xpRequired: 80_000_000_000),
    LevelInfo(level: 50, title: "Primordial Force", xpRequired: 99_999_999_999),
    LevelInfo(level: 51, title: "Living Paradox", xpRequired: 200_000_000_000),
    LevelInfo(level: 52, title: "Entropy Master", xpRequired: 300_000_000_000),
    LevelInfo(level: 53, title: "Singularity", xpRequired: 400_000_000_000),
    LevelInfo(level: 54, title: "Cosmic Constant", xpRequired: 500_000_000_000),
    LevelInfo(level: 55, title: "Beyond Comprehension", xpRequired: 999_999_999_999)
]

let availableSpells = [
    Spell(name: "Enchanted Dart", description: "A simple but effective spell.", effect: "No additional effects", requiredLevel: 1, goldCost: 0, successChanceBonus: 0),
    Spell(name: "Magic Missile", description: "You will succeed better with stronger attack.", effect: "Raises your chances of success by 2% in each run", requiredLevel: 1, goldCost: Int64(50), successChanceBonus: 0.02),
    Spell(name: "Curse", description: "Powerful chant that distracts your enemies.", effect: "Raises your chances of success by 2% in each run", requiredLevel: 2, goldCost: Int64(150), successChanceBonus: 0.02),
    Spell(name: "Summon Familiar", description: "Call forth a magical companion.", effect: "Accumulates 1 XP every 5 minutes, even when not in a run", requiredLevel: 3, goldCost: Int64(400), successChanceBonus: 0, xpPerHour: 30000),
    Spell(name: "Invisible Hound", description: "This hound is tiny, but will go find treasures for you.", effect: "Generates 1 gold every 10 minutes", requiredLevel: 4, goldCost: Int64(1000), successChanceBonus: 0, goldPerHour: 6),
    Spell(name: "Levitating Shield", description: "This shield follows you and carries loot.", effect: "Generates 1 gold every 10 minutes", requiredLevel: 5, goldCost: Int64(1500), successChanceBonus: 0, goldPerHour: 6),
    Spell(name: "Fireball", description: "Engulf your enemies in flames", effect: "Increases XP gain by 5% for each run", requiredLevel: 6, goldCost: Int64(2500), successChanceBonus: 0.05),
    Spell(
        name: "Arcane Amplification",
        description: "A powerful spell that amplifies the knowledge gained from arcane texts.",
        effect: "Increases XP gained from studying arcane texts by 100 times.",
        requiredLevel: 4,
        goldCost: Int64(10000),
        successChanceBonus: 0,
        xpPerHour: 0,
        goldPerHour: 0
    ),
    Spell(
        name: "Grand Arcane Mastery",
        description: "An extraordinary spell that vastly increases the wizard's capacity to absorb arcane knowledge.",
        effect: "Adds 1000 XP to the base XP gained from studying arcane texts.",
        requiredLevel: 8,
        goldCost: Int64(50000),
        successChanceBonus: 0,
        xpPerHour: 0,
        goldPerHour: 0
    ),
    Spell(name: "Teleport", description: "Instantly move to a nearby location", effect: "Reduces run duration by 10%", requiredLevel: 8, goldCost: Int64(4000), successChanceBonus: 0),
    Spell(name: "Midas Touch", description: "Turn objects into gold", effect: "Generates 1 gold every 10 minutes", requiredLevel: 9, goldCost: Int64(10000), successChanceBonus: 0, goldPerHour: 6),
    Spell(name: "Time Stop", description: "Briefly freeze time around you", effect: "Doubles XP and gold gain for the next run", requiredLevel: 10, goldCost: Int64(15000), successChanceBonus: 0)
]

// Locations

let allLocations: [Location] = [
    Location(
        id: UUID(),
        shortName: "Inn Basement",
        fullName: "The Dusty Inn Basement",
        description: "A dimly lit cellar filled with cobwebs and old crates.",
        requiredLevel: 1,
        missionMessage: "Clearing out the cobwebs",
        baseXPLower: 10,
        baseXPUpper: 20,
        baseGoldLower: 5,
        baseGoldUpper: 15,
        difficulty: 0.1,
        runDurationLower: 10,
        runDurationUpper: 60,
        itemTypes: [.treasure]
    ),
    Location(
        id: UUID(),
        shortName: "Village",
        fullName: "Willowbrook Village",
        description: "A quaint settlement with friendly faces and simple quests.",
        requiredLevel: 2,
        missionMessage: "Helping the villagers",
        baseXPLower: 15,
        baseXPUpper: 25,
        baseGoldLower: 10,
        baseGoldUpper: 20,
        difficulty: 0.2,
        runDurationLower: 120,
        runDurationUpper: 240,
        itemTypes: [.treasure]
    ),
    Location(
        id: UUID(),
        shortName: "Sewers",
        fullName: "The Winding Sewers",
        description: "A maze of dank tunnels beneath the village, home to unsavory creatures.",
        requiredLevel: 4,
        missionMessage: "Exploring the murky depths",
        baseXPLower: 25,
        baseXPUpper: 40,
        baseGoldLower: 15,
        baseGoldUpper: 30,
        difficulty: 0.3,
        runDurationLower: 180,
        runDurationUpper: 300,
        itemTypes: [.treasure]
    ),
    Location(
        id: UUID(),
        shortName: "Graveyard",
        fullName: "Whispering Willows Cemetery",
        description: "An ancient burial ground where restless spirits roam.",
        requiredLevel: 6,
        missionMessage: "Laying spirits to rest",
        baseXPLower: 35,
        baseXPUpper: 55,
        baseGoldLower: 25,
        baseGoldUpper: 45,
        difficulty: 0.4,
        runDurationLower: 240,
        runDurationUpper: 360,
        itemTypes: [.treasure]
    ),
    Location(
        id: UUID(),
        shortName: "Dark Forest",
        fullName: "The Whispering Woods",
        description: "A dense, misty forest where ancient magic lingers in the air.",
        requiredLevel: 8,
        missionMessage: "Unraveling forest mysteries",
        baseXPLower: 50,
        baseXPUpper: 75,
        baseGoldLower: 35,
        baseGoldUpper: 60,
        difficulty: 0.5,
        runDurationLower: 300,
        runDurationUpper: 420,
        itemTypes: [.treasure]
    ),
    Location(
        id: UUID(),
        shortName: "Abandoned Keep",
        fullName: "Ironhold Fortress",
        description: "Once a proud stronghold, now a crumbling ruin teeming with danger.",
        requiredLevel: 10,
        missionMessage: "Reclaiming lost treasures",
        baseXPLower: 70,
        baseXPUpper: 100,
        baseGoldLower: 50,
        baseGoldUpper: 80,
        difficulty: 0.6,
        runDurationLower: 360,
        runDurationUpper: 480,
        itemTypes: [.treasure]
    ),
    Location(
        id: UUID(),
        shortName: "World's End",
        fullName: "The Edge of Reality",
        description: "The very limits of existence, where reality unravels.",
        requiredLevel: 57,
        missionMessage: "Battling cosmic horrors",
        baseXPLower: 500,
        baseXPUpper: 1000,
        baseGoldLower: 1000,
        baseGoldUpper: 2000,
        difficulty: 0.95,
        runDurationLower: 600,
        runDurationUpper: 900,
        itemTypes: [.treasure]
    )
]

// Rogue Events

struct RogueEvent: Identifiable {
    let id = UUID()
    let question: String
    let optionA: String
    let optionB: String
    let outcomeA: RogueEventOutcome
    let outcomeB: RogueEventOutcome
    let outcomeTextA: String
    let outcomeTextB: String
}

enum RogueEventOutcome {
    case addGold(percentage: Double)
    case subtractGold(percentage: Double)
    case addXP(percentage: Double)
    case subtractXP(percentage: Double)
    case succeedRun
    case failRun
    case addXPGeneration(amount: Double)
    case addGoldGeneration(amount: Double)
}

let rogueEvents: [RogueEvent] = [
    RogueEvent(
        question: "You encounter a mysterious old wizard offering to enhance your magical abilities. Do you...",
        optionA: "Accept his offer",
        optionB: "Politely decline",
        outcomeA: .addXP(percentage: 5),
        outcomeB: .addGold(percentage: 2),
        outcomeTextA: "The wizard's spell surges through you, expanding your arcane knowledge!",
        outcomeTextB: "The wizard nods approvingly at your caution and rewards you with a small pouch of gold."
    ),
    RogueEvent(
        question: "A mischievous imp offers to play a game of chance. Do you...",
        optionA: "Take the risk",
        optionB: "Ignore the imp",
        outcomeA: .subtractGold(percentage: 10),
        outcomeB: .addXPGeneration(amount: 1),
        outcomeTextA: "The imp cackles as it vanishes with a portion of your gold!",
        outcomeTextB: "As you walk away, you feel a strange tingling. Your ability to learn has slightly improved!"
    ),
    // Add 8 more events here...
]

// MARK: Background Image

struct BackgroundView: View {
    let imageName: String
    
    var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: WKInterfaceDevice.current().screenBounds.width,
                       height: WKInterfaceDevice.current().screenBounds.height)
                .clipped()
            
            RadialGradient(
                gradient: Gradient(colors: [.black.opacity(0.3), .black.opacity(1)]),
                center: .center,
                startRadius: WKInterfaceDevice.current().screenBounds.width * 0.3,
                endRadius: WKInterfaceDevice.current().screenBounds.width * 0.7
            )
            .blendMode(.multiply)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Text Decoration


struct TextShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom("Lancelot", size: 18))
            .shadow(color: .black.opacity(0.7), radius: 2, x: -2, y: -2)
            .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: -2)
            .shadow(color: .black.opacity(0.7), radius: 2, x: -2, y: 2)
            .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: 2)

    }
}

extension View {
    func withTextShadow() -> some View {
        self.modifier(TextShadowModifier())
    }
}

struct BoldShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom("Lancelot", size: 24))
            .shadow(color: .black.opacity(0.8), radius: 2, x: -2, y: -2)
            .shadow(color: .black.opacity(0.8), radius: 2, x: 2, y: -2)
            .shadow(color: .black.opacity(0.8), radius: 2, x: -2, y: 2)
            .shadow(color: .black.opacity(0.8), radius: 2, x: 2, y: 2)

    }
}

extension View {
    func withBoldShadow() -> some View {
        self.modifier(BoldShadowModifier())
    }
}

struct CustomNavigationTitleView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .withBoldShadow()
//            .font(.custom("Lancelot", size: 26))
//            .foregroundColor(.white)

    }
}

struct ExperienceProgressBar: View {
    var progress: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.9)]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: min(CGFloat(self.progress) * geometry.size.width, geometry.size.width))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            }
            .cornerRadius(5)
            .blur(radius: 0.5)
        }
    }
}


// MARK: - Views
struct ContentView: View {
    @StateObject private var gameData = GameData()
    @State private var showSplash = true
    @State private var splashOpacity: Double = 1.0

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .opacity(splashOpacity)
                    .onTapGesture {
                        WKInterfaceDevice.current().play(.click)
                        endSplash()
                    }
                    .onAppear {
                        gameData.loadGame()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            endSplash()
                        }
                    }
            } else {
                mainContent
            }
            
            if gameData.currentAlert != nil {
                CustomAlertView()
                    .environmentObject(gameData)
            }
            if gameData.showRogueEvent {
                RogueEventView()
                    .environmentObject(gameData)
            }
        }
        .withTextShadow()
        .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification)) { _ in
            Task {
                await gameData.updatePassiveGains()
                gameData.showPassiveGainsAlert()
            }
        }


    }
    
    var mainContent: some View {
        TabView {
            WizardView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Character")
                }
            
            ArcaneLibraryView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Library")
                }
            
            Group {
                if gameData.unlockedViews.contains("RunView") {
                    RunView()
                } else {
                    PlaceholderView()
                }
            }
            .tabItem {
                Image(systemName: "map.fill")
                Text(gameData.unlockedViews.contains("RunView") ? "Quest" : "???")
            }
            
            Group {
                if gameData.unlockedViews.contains("ShopView") {
                    SpellShopView()
                } else {
                    PlaceholderView()
                }
            }
            .tabItem {
                Image(systemName: "wand.and.stars")
                Text(gameData.unlockedViews.contains("ShopView") ? "Shop" : "???")
            }
            
            Group {
                if gameData.unlockedViews.contains("InventoryView") {
                    InventoryView()
                } else {
                    PlaceholderView()
                }
            }
            .tabItem {
                Image(systemName: "bag.fill")
                Text(gameData.unlockedViews.contains("InventoryView") ? "Satchel" : "???")
            }
            
            Group {
                if gameData.unlockedViews.contains("HistoryView") {
                    HistoryView()
                } else {
                    PlaceholderView()
                }
            }
            .tabItem {
                Image(systemName: "scroll.fill")
                Text(gameData.unlockedViews.contains("HistoryView") ? "History" : "???")
            }
        }
        .environmentObject(gameData)
        .withTextShadow()
        .onAppear {
            Task {
                await gameData.updatePassiveGains()
            }
            gameData.checkUnlocks()
            if !gameData.hasShownWelcomeMessage {
                gameData.showWelcomeMessage()
            }
        }
    }
    

    func endSplash() {
        withAnimation(.easeOut(duration: 0.3)) {
            splashOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showSplash = false
        }
    }

//    func async updatePassiveGains() {
//        gameData.updatePassiveGains()
//        gameData.checkUnlocks()
//    }
}


// MARK: Splash

struct SplashView: View {
    var body: some View {
        ZStack {
            // Background image
            Image("WizardSplash")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            // Text content
            VStack(spacing: 10) {
                Text("Watch Wizard")
                    .font(.custom("Lancelot", size: 32))
                    .shadow(color: .black.opacity(0.8), radius: 3, x: -3, y: -3)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 3, y: -3)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: -3, y: 3)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 3, y: 3)
                
                Text("Your Magical Journey Awaits!")
                    .withBoldShadow()
            }
            .padding()
        }
    }
}


// MARK: - Wizard View

struct WizardView: View {
    @EnvironmentObject var gameData: GameData
    @State private var selectedSpell: Spell?

    var body: some View {
        ZStack {
                BackgroundView(imageName: "Mirror")
                
                ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(gameData.wizard.name), \n\(gameData.wizardTitle)")
                        .withBoldShadow()
                    // Use the renamed progress bar here
                    ExperienceProgressBar(progress: CGFloat(gameData.wizard.xp) / CGFloat(gameData.xpNeededForLevelUp))
                        .frame(height: 5) // was 15
                        .padding(.vertical, 0) //was 5
                    Text("Level: \(gameData.wizard.level)")
                        .withTextShadow()
                    Text("XP: \(gameData.wizard.xp.formattedWithSeparator)/\(gameData.xpNeededForLevelUp.formattedWithSeparator)")
                        .withTextShadow()
                    Text("XP per hour: \(String(format: "%.1f", gameData.wizard.xpPerHour))")
                        .withTextShadow()
                    Text("Gold: \(gameData.wizard.gold)🟡")
                        .withTextShadow()
                    Text("Gold per hour: \(String(format: "%.1f", gameData.wizard.goldPerHour))")
                        .withTextShadow()
                    Text("Known Spells:")
                        .withBoldShadow()
                    ForEach(gameData.wizard.spells) { spell in
                        Button(action: {
                            selectedSpell = spell
                        }) {
                            Text("\(spell.name)")
                                .withTextShadow()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Character Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedSpell) { spell in
                SpellDetailView(spell: spell)
            }
        }
        .onReceive(gameData.$wizard) { _ in
            // This will trigger a view update whenever the wizard object changes
        }
    }
}


struct SpellDetailView: View {
    let spell: Spell

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(spell.name)
                    .font(.headline)
                
                Text("Description:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(spell.description)
                
                Text("Effect:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(spell.effect)
                
                Text("Required Level: \(spell.requiredLevel)")
                    .font(.subheadline)
            }
            .padding()
        }
    }
}

struct SpellDetailPurchaseView: View {
    @EnvironmentObject var gameData: GameData
    let spell: Spell
    @Binding var isPresented: Bool
    @State private var showingInsufficientGoldAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(spell.name)
                    .font(.headline)
                
                Text("Description:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(spell.description)
                
                Text("Effect:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(spell.effect)
                
                Text("Required Level: \(spell.requiredLevel)")
                    .font(.subheadline)
                
                if gameData.wizard.gold >= spell.goldCost {
                    Button(action: {
                        gameData.purchaseSpell(spell)
                        isPresented = false
                    }) {
                        Text("Buy: \(spell.goldCost)🟡")
                            .frame(maxWidth: .infinity)
                            .padding()
//                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                } else {
                    Text("You do not have \(spell.goldCost)🟡. Gather more gold, adventurer!")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
        }
    }
}

// MARK: - Arcane Library View
struct ArcaneLibraryView: View {
    @EnvironmentObject var gameData: GameData
    @State private var showParticles = false
    @State private var showFloatingText = false
    @State private var lastXPGain: Int64 = 1

    var body: some View {
        ZStack {
            BackgroundView(imageName: "library")
            VStack(spacing: 15) {
                Text("Arcane Sanctum")
                    .withBoldShadow()
                
                Text("Delve into ancient tomes to expand thy knowledge:")
                    .withTextShadow()
                    .fixedSize(horizontal: false, vertical: true)
                Text("XP: \(gameData.wizard.xp)")
                    .withBoldShadow()
                Button(action: {
                    lastXPGain = gameData.studyArcaneTexts()
                    WKInterfaceDevice.current().play(.click)
                    showParticles = true
                    showFloatingText = false // Reset
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showFloatingText = true
                    }
                }) {
                    Text("Study Arcane Texts")
                        .padding()
                        .cornerRadius(10)
                        .withTextShadow()
                }
            }
            .padding()
            
            ParticleEffect(isActive: $showParticles)
            
            if showFloatingText {
                FloatingTextView(text: "+\(lastXPGain) XP")
                    .position(x: WKInterfaceDevice.current().screenBounds.width / 2,
                              y: WKInterfaceDevice.current().screenBounds.height / 2)
            }
        }
    }
}
struct FloatingTextView: View {
    let text: String
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Text(text)
            .foregroundColor(.yellow)
            .withBoldShadow()
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2)) {
                    offset = -100
                    opacity = 0
                }
            }
    }
}


// MARK: - Placeholder View

struct PlaceholderView: View {
    var body: some View {
        VStack {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
            Text("This mystical power lies dormant. Continue thy quests to unlock its secrets.")
                .multilineTextAlignment(.center)
                .padding()
        }
        .foregroundColor(.gray)
    }
}


// MARK: - Run View

struct RunView: View {
    @EnvironmentObject var gameData: GameData
    @State private var selectedLocation: Location?
    @State private var showSummary = false
    @State private var lastCompletedRun: Run?
    @State private var didLevelUp = false
    @State private var viewDidAppear = false

    
    @StateObject private var runTimer = RunTimer()
    
    var sortedLocations: [Location] {
        return allLocations.sorted { $0.requiredLevel > $1.requiredLevel }
    }

    var body: some View {
        ZStack {
            if showSummary, let lastRun = lastCompletedRun {
                RunSummaryView(
                    run: lastRun,
                    wizardName: gameData.wizard.name,
                    didLevelUp: gameData.leveledUpDuringLastRun,
                    showSummary: $showSummary
                )
            } else {
                BackgroundView(imageName: "choose")
                questView
            }
        }
        .onChange(of: showSummary) { oldValue, newValue in
            if !newValue {
                lastCompletedRun = nil
                didLevelUp = false
            }
        }
        .onReceive(gameData.$currentRun) { run in
            if run == nil && !gameData.completedRuns.isEmpty {
                DispatchQueue.main.async {
                    self.lastCompletedRun = self.gameData.completedRuns.last
                    self.didLevelUp = self.gameData.wizard.level > (self.lastCompletedRun?.location.requiredLevel ?? 0)
                    self.showSummary = true
                    self.gameData.checkUnlocks()
                }
            }
        }
        .sheet(item: $selectedLocation) { location in
            LocationDetailView(location: location, gameData: gameData)
        }
        .onAppear {
            if !viewDidAppear {
                showSummary = false
                lastCompletedRun = nil
                viewDidAppear = true
            }
        }
    }

    var questView: some View {
        ScrollView {
            VStack(spacing: 15) {
                if let currentRun = gameData.currentRun {
                    Text("\(gameData.wizard.name) is \(currentRun.location.missionMessage)")
                        .withTextShadow()
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("Adventuring: \(currentRun.location.shortName)")
                    if let startTime = gameData.runStartTime {
                        let progress = min(max(0, runTimer.currentTime.timeIntervalSince(startTime)), currentRun.duration)
                        ProgressView(value: progress, total: currentRun.duration)
                            .padding(.horizontal)
                    }
                } else {
                    Text("Choose Thy Quest")
                        .withBoldShadow()
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    ForEach(sortedLocations) { location in
                        if gameData.isLocationUnlocked(location) {
                            Button(action: {
                                selectedLocation = location
                            }) {
                                Text(location.shortName)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .buttonStyle(BorderedButtonStyle(tint: .white))
                            .withTextShadow()
                        } else if location == gameData.nextUnlockedLocation() {
                            Button(action: {
                                // Show level up message
                            }) {
                                Text(location.shortName)
                                    .frame(maxWidth: .infinity)
                                    .padding()
//                                    .withTextShadow()
                            }.withTextShadow()
                            .buttonStyle(BorderedButtonStyle(tint: .gray))
                            .disabled(true)
                            .overlay(
                                Text("Level \(location.requiredLevel) to unlock")
//                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(3)
                                    .background(Color.black.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(.top, 30)
                                    .withTextShadow()
                            )
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

class RunTimer: ObservableObject {
    @Published var currentTime = Date()
    
    init() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentTime = Date()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}




struct LocationDetailView: View {
    let location: Location
    @ObservedObject var gameData: GameData
    @Environment(\.presentationMode) var presentationMode
    
    var successChance: Double {
        let baseChance = (1.0 - location.difficulty)
        let totalChance = min(baseChance + gameData.totalSuccessChanceBonus, 1.0)
        return totalChance * 100
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(location.fullName)
                    .font(.headline)
                Text(location.description)
                    .font(.body)
                Text("Required Level: \(location.requiredLevel)")
                Text("XP: \(location.baseXP.lowerBound)-\(location.baseXP.upperBound)")
                Text("Gold: \(location.baseGold.lowerBound)-\(location.baseGold.upperBound)")
                Text("Success Chance: \(String(format: "%.1f", successChance))%")
                
                Button("Start Quest") {
                    gameData.startRun(location: location)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(BorderedButtonStyle(tint: .green))
                .padding(.top)
            }
            .padding()
        }
    }
}


struct RunSummaryView: View {
    let run: Run
    let wizardName: String
    let didLevelUp: Bool
    @Binding var showSummary: Bool
    @EnvironmentObject var gameData: GameData

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("\(wizardName) has returned from \(run.location.shortName)")
                    .withTextShadow()
                    .multilineTextAlignment(.center)

                if run.succeeded {
                    Text("Quest Successful!")
                        .foregroundColor(.green)
                        .withBoldShadow()
                } else {
                    Text("Forced to Retreat...")
                        .foregroundColor(.red)
                        .withBoldShadow()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("XP Gained: \(run.xpGained)")
                    Text("Gold Acquired: \(run.goldGained)🟡")
                    if !run.itemsGained.isEmpty {
                        Text("Items Found:")
                        ForEach(run.itemsGained, id: \.name) { item in
                            Text("• \(item.name) x\(item.quantity)")
                                .padding(.leading)
                        }
                    }
                    if !run.creaturesDefeated.isEmpty {
                        Text("Creatures Vanquished:")
                        Text(run.creaturesDefeated.joined(separator: ", "))
                            .padding(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if didLevelUp {
                              VStack {
                                  Text("Level Up!")
                                      .withBoldShadow()
                                      .padding()
                                      .background(Color.white.opacity(0.2))
                                      .cornerRadius(10)
                                  
                                  Text("\(wizardName) has reached level \(gameData.wizard.level)!!")
                                      .foregroundColor(.white)
                                      .padding(.top, 5)
                              }
                          }

                Button("Onward to New Adventures!") {
                    showSummary = false
                }
                .buttonStyle(BorderedButtonStyle(tint: .blue))
                .padding(.top)
            }
            .padding()
        }
    }
}

// MARK: - Inventory View

struct InventoryView: View {
    @EnvironmentObject var gameData: GameData
    @State private var selectedItem: Item?
    @State private var showingSellAllConfirmation = false

    var body: some View {
        ZStack {
            BackgroundView(imageName: "satchel")
            NavigationView {
                VStack(spacing: 0) {
                                    CustomNavigationTitleView(title: "Adventurer's Satchel")
                        .frame(height: 5)
                        .padding(.bottom, 10)
                                    
                List {
                    Section {
                        HStack {
                            Text("Gold:")
                            Spacer()
                            Text("\(gameData.wizard.gold)🟡")
                                .fontWeight(.bold).foregroundColor(.yellow)
                        }
//                        .withTextShadow()
                    }.withTextShadow()
                    
                    Section(header: Text("Trade")) {
                        Button("Sell All Items") {
                            showingSellAllConfirmation = true
                        }
  
                    }.withTextShadow()
                    
                        Section(header: Text("Sell Treasures")) {
                            ForEach(gameData.wizard.inventory, id: \.name) { item in
                                Button(action: {
                                    selectedItem = item
                                    
                                }) {
                                    HStack {
                                        Text(item.name)
                                        Spacer()
                                        Text("x\(item.quantity)")
                                    }
//                                    .withTextShadow()
                                }
                                
                            }
                        }
                    }
                        .withTextShadow()
                }
                .navigationBarHidden(true)
                .sheet(item: $selectedItem) { item in
                    SellItemView(item: item, gameData: gameData, isPresented: Binding(
                        get: { selectedItem != nil },
                        set: { if !$0 { selectedItem = nil } }
                    ))
                    .onAppear {
                        gameData.consolidateAndSortInventory()}
                }
                .alert(isPresented: $showingSellAllConfirmation) {
                    sellAllConfirmationAlert
                }
                
            }
        }
    }

    var sellAllConfirmationAlert: Alert {
        let totalGold: Int64 = gameData.wizard.inventory.reduce(0) { sum, item in
            let itemValue = treasureList.first(where: { $0.name == item.name })?.goldValue ?? 0
            return sum + Int64(item.quantity) * Int64(itemValue)
        }
        return Alert(
            title: Text("Sell All Items?"),
            message: Text("You will receive \(totalGold)🟡"),
            primaryButton: .default(Text("Sell All")) {
                sellAllItems()
            },
            secondaryButton: .cancel()
        )
    }

    func sellAllItems() {
        for item in gameData.wizard.inventory {
            if let treasure = treasureList.first(where: { $0.name == item.name }) {
                let goldValue = Int64(item.quantity) * treasure.goldValue
                gameData.wizard.gold += goldValue
            }
        }
        gameData.wizard.inventory.removeAll()
        gameData.saveGame()
    }
}


struct SellItemView: View {
    let item: Item
    @ObservedObject var gameData: GameData
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Sell \(item.name)?")
                .font(.headline)
            Text("Quantity: \(item.quantity)")
            Text("You will receive \(sellValue)🟡")
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(BorderedButtonStyle(tint: .red))
                
                Button("Sell") {
                    sellItem()
                    isPresented = false
                }
                .buttonStyle(BorderedButtonStyle(tint: .blue))
            }
        }
        .padding()
    }
    
    var sellValue: Int64 {
        Int64(item.quantity) * Int64(treasureList.first(where: { $0.name == item.name })?.goldValue ?? 0)
    }
    
    func sellItem() {
        if let index = gameData.wizard.inventory.firstIndex(where: { $0.name == item.name }) {
            gameData.wizard.gold += sellValue
            gameData.wizard.inventory.remove(at: index)
            gameData.saveGame()
        }
    }
}
// MARK: - SpellShop View

struct SpellShopView: View {
    @EnvironmentObject var gameData: GameData
    @State private var showingXPConversionView = false
    @State private var selectedSpell: Spell?

    var availableSpellsForPurchase: [Spell] {
        availableSpells.filter { spell in
            spell.name != "Enchanted Dart" &&
            spell.requiredLevel <= gameData.wizard.level &&
            !gameData.wizard.spells.contains(where: { $0.name == spell.name })
        }
    }
    
    var nextAvailableSpell: Spell? {
        availableSpells
            .filter { spell in
                spell.requiredLevel > gameData.wizard.level &&
                !gameData.wizard.spells.contains(where: { $0.id == spell.id })
            }
            .min(by: { $0.requiredLevel < $1.requiredLevel })
    }

    var body: some View {
        ZStack {
            BackgroundView(imageName: "emporium")
            NavigationView {
                VStack(spacing: 0) {
                    CustomNavigationTitleView(title: "Mystic Emporium")
                        .frame(height: 5)
                        .padding(.bottom, 10)
                    
                    List {
                        Section(header: Text("Arcane Exchange")) {
                            Button("Convert Gold to Arcane Knowledge") {
                                showingXPConversionView = true
                            }
                        }
                        
                        Section(header: Text("Purchase Spells")) {
                            ForEach(availableSpellsForPurchase) { spell in
                                if !gameData.wizard.spells.contains(where: { $0.id == spell.id }) {
                                    Button(action: {
                                        selectedSpell = spell
                                    }) {
                                        HStack {
                                            Text(spell.name)
                                            Spacer()
                                            Text("\(spell.goldCost)🟡")
                                        }
                                    }
                                }
                            }
                            
                            if let nextSpell = nextAvailableSpell {
                                nextSpellButton(for: nextSpell)
                            }
                        }
                    }
                    //                .navigationTitle("Mystic Emporium")
                    //                .navigationBarTitleDisplayMode(.inline)
                    .sheet(item: $selectedSpell) { spell in
                        SpellDetailPurchaseView(spell: spell, isPresented: Binding(
                            get: { selectedSpell != nil },
                            set: { if !$0 { selectedSpell = nil } }
                        ))
                    }
                    .sheet(isPresented: $showingXPConversionView) {
                        GoldToXPConversionView(isPresented: $showingXPConversionView)
                    }
                }
                .withTextShadow()
                .navigationBarHidden(true)
            }
        }
    }

    func nextSpellButton(for spell: Spell) -> some View {
        Button(action: {
            // Show level up message
        }) {
            HStack {
                Text(spell.name)
                Spacer()
                Text("\(spell.goldCost)🟡")
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .listRowBackground(Color.clear)
        .disabled(true)
        .overlay(
            Text("Level \(spell.requiredLevel) to unlock")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(4)
                .background(Color.black.opacity(0.6))
                .cornerRadius(4)
                .padding(.top, 30)
        )
    }
}

struct GoldToXPConversionView: View {
    @EnvironmentObject var gameData: GameData
    @Binding var isPresented: Bool
    @State private var goldToConvert: Double = 0
    
    let conversionRate: Int64 = 1 // 1 gold = 1 XP
    
    var maxConversion: Int64 {
        min(Int64(gameData.wizard.gold), gameData.xpNeededForLevelUp - gameData.wizard.xp)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Convert Gold to XP")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Gold to Convert: \(Int(goldToConvert))")
                .font(.body)
            
            Text("You will gain \(Int(goldToConvert * Double(conversionRate))) XP")
                .font(.caption)
            
            CustomSlider(value: $goldToConvert, bounds: 0...Double(maxConversion))
                .frame(height: 30)
                .padding(.horizontal)
            
            HStack {
                Button("Convert") {
                    convertGoldToXP()
                }
                .buttonStyle(BorderedButtonStyle(tint: .blue))
                .disabled(goldToConvert == 0)
                
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(BorderedButtonStyle(tint: .red))
            }
        }
        .padding()
        .focusable()
        .digitalCrownRotation($goldToConvert, from: 0, through: Double(maxConversion), by: 1, sensitivity: .high, isContinuous: false, isHapticFeedbackEnabled: true)
    }
    
    
    func convertGoldToXP() {
        let amountToConvert = Int64(goldToConvert)
        print("Attempting to convert \(amountToConvert) gold to XP")
        if amountToConvert <= gameData.wizard.gold && amountToConvert <= maxConversion {
            DispatchQueue.global(qos: .userInitiated).async {
                let initialLevel = self.gameData.wizard.level
                let newGold = self.gameData.wizard.gold - amountToConvert
                let newXP = self.gameData.wizard.xp + (amountToConvert * self.conversionRate)
                print("Converted \(amountToConvert) gold to \(amountToConvert * self.conversionRate) XP")
                print("New XP: \(newXP), XP needed for level up: \(self.gameData.xpNeededForLevelUp)")
                
                DispatchQueue.main.async {
                    self.gameData.wizard.gold = newGold
                    self.gameData.wizard.xp = newXP
                    self.gameData.checkLevelUp()
                    self.gameData.saveGame()
                    print("Game saved. New level: \(self.gameData.wizard.level)")
                    self.gameData.objectWillChange.send()
                    self.isPresented = false
                    
                    // Check for level up and show alert if needed
                    if self.gameData.wizard.level > initialLevel {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.gameData.showCustomAlert(
                                title: "Level Up!",
                                message: "You've reached level \(self.gameData.wizard.level)!",
                                type: .levelUp
                            )
                        }
                    }
                }
            }
        }
    }

                    }




struct CustomSlider: View {
    @Binding var value: Double
    let bounds: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Image(systemName: "minus")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: max(0, min(geometry.size.width - 40, (geometry.size.width - 40) * (value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))), height: 4)
                }
                .frame(height: 30)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let newValue = bounds.lowerBound + (bounds.upperBound - bounds.lowerBound) * Double((gesture.location.x - 20) / (geometry.size.width - 40))
                            value = max(bounds.lowerBound, min(bounds.upperBound, newValue))
                        }
                )
                
                Image(systemName: "plus")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 20)
            }
        }
    }
}

// MARK: - History View

struct HistoryView: View {
    @EnvironmentObject var gameData: GameData
    
    var body: some View {
        ZStack {
            BackgroundView(imageName: "PaperRoll")
            NavigationView {

                    VStack(spacing: 0) {
                        CustomNavigationTitleView(title: "Heroic Deeds")
                            .frame(height: 5)
                            .padding(.bottom, 10)
                    List {
                        ForEach(gameData.completedRuns.indices.reversed(), id: \.self) { index in
                            let run = gameData.completedRuns[index]
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(run.location.shortName): \(run.succeeded ? "Success" : "Failure")")
                                    .withBoldShadow()
                                Text("XP: +\(run.xpGained), Gold: +\(run.goldGained)")
                                    .withTextShadow()
                                Text("Items: \(run.itemsGained.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", "))")
                                    .withTextShadow()
                                Text("Defeated: \(run.creaturesDefeated.joined(separator: ", "))")
                                    .withTextShadow()
                            }
                            .listRowBackground(Color.clear) // Make list rows transparent
                        }
                    }
                    .listStyle(PlainListStyle()) // Use plain style to remove default list background
                }
             
            }
            .navigationBarHidden(true)
        }
    }
}



// MARK: Custom Alert
struct CustomAlertView: View {
    @EnvironmentObject var gameData: GameData
    
    var body: some View {
        if let customAlert = gameData.currentAlert {
            ZStack {
                Image(backgroundImageName(for: customAlert.type))
                    .resizable()
                    .scaledToFill()
                    .frame(width: WKInterfaceDevice.current().screenBounds.width,
                           height: WKInterfaceDevice.current().screenBounds.height)
                    .clipped()
                
                RadialGradient(
                    gradient: Gradient(colors: [.black.opacity(0.3), .black.opacity(1)]),
                    center: .center,
                    startRadius: WKInterfaceDevice.current().screenBounds.width * 0.3,
                    endRadius: WKInterfaceDevice.current().screenBounds.width * 0.7
                )
                .blendMode(.multiply)
                ScrollView {
                    VStack(spacing: 15) {
                        Text(customAlert.title)
                            .withBoldShadow()
                            .multilineTextAlignment(.center)
                        // lines below make sure text wrap!
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: WKInterfaceDevice.current().screenBounds.width * 0.8)
                        
                        Text(customAlert.message)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: WKInterfaceDevice.current().screenBounds.width * 0.8)
                            .withTextShadow()
                        
                        Button("Alright!") {
                            gameData.dismissCurrentAlert()
                        }
                        .withTextShadow()
                        .buttonStyle(BorderedButtonStyle(tint: .white))
                    }
                    .padding()
                    .background(Color.black.opacity(0))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    func backgroundImageName(for alertType: AlertType) -> String {
        switch alertType {
        case .levelUp:
            return "LevelUpBackground"
        case .gainsUpdate:
            return "GainsUpdateBackground"
        case .viewUnlocked:
            return "ViewUnlockedBackground"
        case .story:
               return "RandomEventBackground"
        }
    }
}

// MARK: Rogue Events View

struct RogueEventView: View {
    @EnvironmentObject var gameData: GameData
    @State private var showOutcome = false
    @State private var selectedOption: String?

    var body: some View {
        ZStack {
            BackgroundView(imageName: "randomEventBackground")
                .scaledToFill()
                .frame(width: WKInterfaceDevice.current().screenBounds.width,
                       height: WKInterfaceDevice.current().screenBounds.height)
                .clipped()
            
            RadialGradient(
                gradient: Gradient(colors: [.black.opacity(0.3), .black.opacity(1)]),
                center: .center,
                startRadius: WKInterfaceDevice.current().screenBounds.width * 0.3,
                endRadius: WKInterfaceDevice.current().screenBounds.width * 0.7
            )
            .blendMode(.multiply)
            ScrollView {
                VStack(spacing: 20) {
                    if let event = gameData.currentRogueEvent {
                        if !showOutcome {
                            Text(event.question)
                                .withTextShadow()
                                .multilineTextAlignment(.center)
                            
                            Button(event.optionA) {
                                selectedOption = "A"
                                showOutcome = true
                                handleOutcome(event.outcomeA)
                            }
                            .withTextShadow()
                            .buttonStyle(BorderedButtonStyle(tint: .blue))
                            
                            Button(event.optionB) {
                                selectedOption = "B"
                                showOutcome = true
                                handleOutcome(event.outcomeB)
                            }
                            .withTextShadow()
                            .buttonStyle(BorderedButtonStyle(tint: .green))
                        } else {
                            Text(selectedOption == "A" ? event.outcomeTextA : event.outcomeTextB)
                                .withTextShadow()
                                .multilineTextAlignment(.center)
                            
                            Button("Continue") {
                                gameData.showRogueEvent = false
                                gameData.currentRogueEvent = nil
                            }
                            .withTextShadow()
                            .buttonStyle(BorderedButtonStyle(tint: .blue))
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func handleOutcome(_ outcome: RogueEventOutcome) {
        // Implement outcome logic here
        // This will modify gameData based on the outcome
    }
}

// MARK: Particle effect


struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
}

import SwiftUI

struct ParticleEffect: View {
    @Binding var isActive: Bool
    @State private var particles: [Particle] = []
    @State private var shockwaveScale: CGFloat = 0.0
    @State private var shockwaveOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Shockwave effect
            RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]),
                           center: .center,
                           startRadius: 1,
                           endRadius: 100)
                .scaleEffect(shockwaveScale)
                .opacity(shockwaveOpacity)
            
            // Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.yellow)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onChange(of: isActive) { oldValue,newValue in
            if newValue {
                generateParticles()
                triggerShockwave()
            }
        }
    }

    private func generateParticles() {
        particles = (0..<50).map { _ in /// was <20
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...WKInterfaceDevice.current().screenBounds.width),
                    y: CGFloat.random(in: 0...WKInterfaceDevice.current().screenBounds.height)
                ),
                size: CGFloat.random(in: 1...7), // was 2...6
                opacity: Double.random(in: 0.1...1)  // was 0.5...1
            )
        }
        
        withAnimation(.easeOut(duration: 0.5)) {
            particles = particles.map { particle in
                var newParticle = particle
                newParticle.position = CGPoint(
                    x: newParticle.position.x + CGFloat.random(in: -20...20),
                    y: newParticle.position.y + CGFloat.random(in: -20...20)
                )
                newParticle.opacity = 0
                return newParticle
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.particles = []
            self.isActive = false
        }
    }

    private func triggerShockwave() {
        shockwaveScale = 0.0
        shockwaveOpacity = 0.7
        
        withAnimation(.easeOut(duration: 0.5)) {
            shockwaveScale = 2.0
            shockwaveOpacity = 0.0
        }
    }
}




// MARK: - Complications

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    let gameData = GameData()
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let date = Date()
        
        switch complication.family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "Lvl \(gameData.wizard.level)"),
                line2TextProvider: CLKSimpleTextProvider(text: "XP: \(gameData.wizard.xp)")
            )
            handler(CLKComplicationTimelineEntry(date: date, complicationTemplate: template))
            
        case .circularSmall:
            let progress = Float(gameData.wizard.xp) / Float(gameData.xpNeededForLevelUp)
            let template = CLKComplicationTemplateCircularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: "\(gameData.wizard.level)"),
                fillFraction: progress,
                ringStyle: .closed
            )
            handler(CLKComplicationTimelineEntry(date: date, complicationTemplate: template))
            
        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody(
                           headerTextProvider: CLKSimpleTextProvider(text: "Watch Wizard"),
                           body1TextProvider: CLKSimpleTextProvider(text: "Level \(gameData.wizard.level) - \(gameData.wizardTitle)"),
                           body2TextProvider: CLKSimpleTextProvider(text: "XP: \(gameData.wizard.xp.formattedWithSeparator)/\(gameData.xpNeededForLevelUp.formattedWithSeparator)")
                       )
            handler(CLKComplicationTimelineEntry(date: date, complicationTemplate: template))
            
        default:
            handler(nil)
        }
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        switch complication.family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "Lvl 5"),
                line2TextProvider: CLKSimpleTextProvider(text: "XP: 450")
            )
            handler(template)
            
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: "5"),
                fillFraction: 0.75,
                ringStyle: .closed
            )
            handler(template)
            
        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "Watch Wizard"),
                body1TextProvider: CLKSimpleTextProvider(text: "Level 5 - Adept"),
                body2TextProvider: CLKSimpleTextProvider(text: "XP: 450/500")
            )
            handler(template)
            
        default:
            handler(nil)
        }
    }
}




// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
