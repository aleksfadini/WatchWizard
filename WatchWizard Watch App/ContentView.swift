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

// MARK: - Data Structures

class Wizard: ObservableObject, Equatable, Codable {
    @Published var name: String
    @Published var level: Int
    @Published var xp: Int
    @Published var gold: Int
    @Published var spells: [Spell]
    @Published var inventory: [Item]
    @Published var xpPerHour: Double = 0
    @Published var goldPerHour: Double = 0
    
    enum CodingKeys: String, CodingKey {
        case name, level, xp, gold, spells, inventory, xpPerHour, goldPerHour
    }
    init(name: String, level: Int, xp: Int, gold: Int, spells: [Spell], inventory: [Item]) {
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
           xp = try container.decode(Int.self, forKey: .xp)
           gold = try container.decode(Int.self, forKey: .gold)
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
    var goldCost: Int
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
    var xpGained: Int
    var goldGained: Int
    var itemsGained: [Item]
    var creaturesDefeated: [String]
    var succeeded: Bool
}


struct Monster {
    let name: String
    let minLevel: Int
}

struct Treasure {
    let name: String
    let goldValue: Int
    let minLevel: Int
}

struct Location: Identifiable, Equatable, Codable {
    let id: UUID
    let shortName: String
    let fullName: String
    let description: String
    let requiredLevel: Int
    let missionMessage: String
    let baseXPLower: Int
    let baseXPUpper: Int
    let baseGoldLower: Int
    let baseGoldUpper: Int
    let difficulty: Double
    let runDurationLower: TimeInterval
    let runDurationUpper: TimeInterval
    let itemTypes: [ItemType]

    var baseXP: ClosedRange<Int> {
        baseXPLower...baseXPUpper
    }

    var baseGold: ClosedRange<Int> {
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        shortName = try container.decode(String.self, forKey: .shortName)
        fullName = try container.decode(String.self, forKey: .fullName)
        description = try container.decode(String.self, forKey: .description)
        requiredLevel = try container.decode(Int.self, forKey: .requiredLevel)
        missionMessage = try container.decode(String.self, forKey: .missionMessage)
        baseXPLower = try container.decode(Int.self, forKey: .baseXPLower)
        baseXPUpper = try container.decode(Int.self, forKey: .baseXPUpper)
        baseGoldLower = try container.decode(Int.self, forKey: .baseGoldLower)
        baseGoldUpper = try container.decode(Int.self, forKey: .baseGoldUpper)
        difficulty = try container.decode(Double.self, forKey: .difficulty)
        runDurationLower = try container.decode(TimeInterval.self, forKey: .runDurationLower)
        runDurationUpper = try container.decode(TimeInterval.self, forKey: .runDurationUpper)
        itemTypes = try container.decode([ItemType].self, forKey: .itemTypes)
    }

    init(id: UUID, shortName: String, fullName: String, description: String, requiredLevel: Int, missionMessage: String, baseXPLower: Int, baseXPUpper: Int, baseGoldLower: Int, baseGoldUpper: Int, difficulty: Double, runDurationLower: TimeInterval, runDurationUpper: TimeInterval, itemTypes: [ItemType]) {
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
}
enum ItemType: Codable {
    case treasure
}

// MARK: - Game Data

class GameData: ObservableObject {
    // Dev Vars
    @Published var isTestMode: Bool = true
    @Published var easyXP: Bool = false
    @Published var extraMoney: Bool = true
    // Locked Views
    @Published var unlockedViews: Set<String> = ["CharacterSheet", "ArcaneLibrary"]
    // Script Vars
    @Published var wizard: Wizard
//    @Published var purchasedSpells: [Spell] = []
//    @Published var gold: Int = 0
//    @Published var inventory: [Item]
    @Published var currentRun: Run?
    @Published var completedRuns: [Run]
    @Published var runStartTime: Date?
    @Published var leveledUpDuringLastRun: Bool = false
    @Published var lastUpdateTime: Date
    @Published var lastLevelUp: Int?
    @Published var passiveXPGained: Int = 0
    @Published var passiveGoldGained: Int = 0
//    @Published var showPassiveGainAlert = false
    @Published private(set) var alertQueue: [CustomAlert] = []
    @Published private(set) var currentAlert: CustomAlert?

    

    private var unlockedFeatures: Set<String> = []
    
    // MARK: GD - Alert System
    
    var alertBinding: Binding<CustomAlert?> {
        Binding(
            get: { self.currentAlert },
            set: { _ in self.dismissCurrentAlert() }
        )
    }
    
        struct CustomAlert: Identifiable {
            let id = UUID()
            let title: String
            let message: String
            let type: AlertType
        }

        enum AlertType {
            case levelUp, passiveGains, featureUnlock
        }
        
    func showAlert(_ alert: CustomAlert) {
        if alert.type == .featureUnlock && unlockedFeatures.contains(alert.title) {
            return // Don't show feature unlock alert if it has been shown before
        }

        alertQueue.append(alert)
        if currentAlert == nil {
            currentAlert = alertQueue.first
        }

        if alert.type == .featureUnlock {
            unlockedFeatures.insert(alert.title)
        }
    }
    
    func dismissCurrentAlert() {
        DispatchQueue.main.async {
            if !self.alertQueue.isEmpty {
                self.alertQueue.removeFirst()
            }
            self.currentAlert = self.alertQueue.first
        }
    }
    
    init() {
        self.wizard = Wizard(name: "Merlin", level: 1, xp: 0, gold: 0, spells: [availableSpells[0]], inventory: [])
        self.completedRuns = []
        self.lastUpdateTime = Date()
        
        if extraMoney {
            self.wizard.gold = 100000
        }
    }

    func unlockFeature(_ feature: String) {
        unlockedViews.insert(feature)
        
        let (title, message) = getUnlockMessage(for: feature)
        showAlert(CustomAlert(title: title, message: message, type: .featureUnlock))
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
    
    
    var xpNeededForLevelUp: Int {
        if easyXP {
            return 200 // in easyXP mode, only 200 xp per level
        } else {
            let currentLevel = wizard.level
            if currentLevel <= levelUpXPRequirements.count {
                return levelUpXPRequirements[currentLevel - 1]
            } else {
                // For levels beyond our defined array, we'll use a formula
                return Int(Double(levelUpXPRequirements.last!) * pow(1.2, Double(currentLevel - levelUpXPRequirements.count)))
            }
        }
    }

    func studyArcaneTexts() {
        wizard.xp += 1
        checkLevelUp()
        checkUnlocks()
    }

    func startRun(location: Location) {
        leveledUpDuringLastRun = false
        let duration: TimeInterval = isTestMode ? 3 : TimeInterval.random(in: location.runDuration)
        runStartTime = Date()
        currentRun = Run(location: location, duration: duration, xpGained: 0, goldGained: 0, itemsGained: [], creaturesDefeated: [], succeeded: false)
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
              run.xpGained = Int.random(in: run.location.baseXP)
              run.goldGained = Int.random(in: run.location.baseGold)
          } else {
              run.xpGained = Int(Double(run.location.baseXP.lowerBound) * 0.1)
              run.goldGained = Int(Double(run.location.baseGold.lowerBound) * 0.1)
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
        while wizard.xp >= xpNeededForLevelUp {
            wizard.level += 1
        }
        if wizard.level > initialLevel {
            leveledUpDuringLastRun = true
            showAlert(CustomAlert(title: "Hark! Thou hast ascended!", message: "Thy prowess has grown. Thou art now level \(wizard.level)!", type: .levelUp))
            lastLevelUp = wizard.level
        }
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
    
    func updatePassiveGains() {
        let now = Date()
        let elapsedHours = now.timeIntervalSince(lastUpdateTime) / 3600
        
        passiveXPGained = Int(wizard.xpPerHour * elapsedHours)
        passiveGoldGained = Int(wizard.goldPerHour * elapsedHours)
        
        wizard.xp += passiveXPGained
        wizard.gold += passiveGoldGained
        
        lastUpdateTime = now
        if passiveXPGained > 0 || passiveGoldGained > 0 {
               showAlert(CustomAlert(title: "Whilst thou rested...", message: "Thy coffers have grown by \(passiveGoldGained)🟡 and thy knowledge by \(passiveXPGained) XP.", type: .passiveGains))
           }

        checkLevelUp()
        saveGame()
    }

//
//  MARK: Save Game
//
    func saveGame() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(wizard) {
            UserDefaults.standard.set(encoded, forKey: "SavedWizard")
        }
        UserDefaults.standard.set(lastUpdateTime, forKey: "LastUpdateTime")
        UserDefaults.standard.set(Array(unlockedViews), forKey: "UnlockedViews")
         UserDefaults.standard.set(Array(unlockedFeatures), forKey: "UnlockedFeatures")
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
        
        // Decode completedRuns
        if let savedRuns = UserDefaults.standard.data(forKey: "CompletedRuns"),
           let loadedRuns = try? decoder.decode([Run].self, from: savedRuns) {
            completedRuns = loadedRuns
        } else {
            completedRuns = []
        }
    }
    
}

// MARK: - Game Content

let treasureList = [
    Treasure(name: "Copper Coin", goldValue: 1, minLevel: 1),
    Treasure(name: "Silver Ring", goldValue: 5, minLevel: 2),
    Treasure(name: "Golden Chalice", goldValue: 50, minLevel: 5),
    Treasure(name: "Ancient Coin", goldValue: 20, minLevel: 3),
    Treasure(name: "Jeweled Necklace", goldValue: 100, minLevel: 7),
    Treasure(name: "Enchanted Ring", goldValue: 200, minLevel: 10),
    Treasure(name: "Dragon's Scale", goldValue: 500, minLevel: 15),
    Treasure(name: "Mithril Armor", goldValue: 1000, minLevel: 20),
    Treasure(name: "Elven Tiara", goldValue: 300, minLevel: 12),
    Treasure(name: "Crystal Shard", goldValue: 75, minLevel: 8),
    Treasure(name: "Phoenix Feather", goldValue: 250, minLevel: 18),
    Treasure(name: "Obsidian Dagger", goldValue: 150, minLevel: 9),
    Treasure(name: "Platinum Bracelet", goldValue: 400, minLevel: 14),
    Treasure(name: "Mystic Orb", goldValue: 600, minLevel: 16)
]


let creatures = [
    Monster(name: "Goblin", minLevel: 1),
    Monster(name: "Orc", minLevel: 2),
    Monster(name: "Troll", minLevel: 4),
    Monster(name: "Skeleton", minLevel: 3),
    Monster(name: "Zombie", minLevel: 5),
    Monster(name: "Ghost", minLevel: 7),
    Monster(name: "Vampire", minLevel: 10),
    Monster(name: "Werewolf", minLevel: 8),
    Monster(name: "Harpy", minLevel: 6),
    Monster(name: "Minotaur", minLevel: 12),
    Monster(name: "Chimera", minLevel: 15),
    Monster(name: "Dragon", minLevel: 20),
    Monster(name: "Basilisk", minLevel: 18),
    Monster(name: "Hydra", minLevel: 22),
    Monster(name: "Manticore", minLevel: 16),
    Monster(name: "Griffon", minLevel: 14),
    Monster(name: "Cyclops", minLevel: 13),
    Monster(name: "Medusa", minLevel: 17)
]

let levelUpXPRequirements = [
    10,    // Level 1 to 2
    50,   // Level 2 to 3
    100,   // Level 3 to 4
    200,  // Level 4 to 5
    500,  // Level 5 to 6
    1000,  // Level 6 to 7
    2500,  // Level 7 to 8
    5500,  // Level 8 to 9
    10000, // Level 9 to 10
    30000  // Level 10 to 11
]

let availableSpells = [
    Spell(name: "Enchanted Dart", description: "A simple but effective spell.", effect: "No additional effects", requiredLevel: 1, goldCost: 0, successChanceBonus: 0),
    Spell(name: "Magic Missile", description: "You will succeed better with stronger attack.", effect: "Raises your chances of success by 2% in each run", requiredLevel: 1, goldCost: 50, successChanceBonus: 0.02),
    Spell(name: "Curse", description: "Powerful chant that distracts your enemies.", effect: "Raises your chances of success by 2% in each run", requiredLevel: 2, goldCost: 150, successChanceBonus: 0.02),
    Spell(name: "Summon Familiar", description: "Call forth a magical companion.", effect: "Accumulates 1 XP every 5 minutes, even when not in a run", requiredLevel: 3, goldCost: 400, successChanceBonus: 0, xpPerHour: 30000),
    Spell(name: "Invisible Hound", description: "This hound is tiny, but will go find treasures for you.", effect: "Generates 1 gold every 10 minutes", requiredLevel: 4, goldCost: 1000, successChanceBonus: 0, goldPerHour: 6),
    Spell(name: "Levitating Shield", description: "This shield follows you and carries loot.", effect: "Generates 1 gold every 10 minutes", requiredLevel: 5, goldCost: 1500, successChanceBonus: 0, goldPerHour: 6),
    Spell(name: "Fireball", description: "Engulf your enemies in flames", effect: "Increases XP gain by 5% for each run", requiredLevel: 6, goldCost: 2500, successChanceBonus: 0.05),
    Spell(name: "Teleport", description: "Instantly move to a nearby location", effect: "Reduces run duration by 10%", requiredLevel: 7, goldCost: 4000, successChanceBonus: 0),
    Spell(name: "Midas Touch", description: "Turn objects into gold", effect: "Generates 1 gold every 10 minutes", requiredLevel: 9, goldCost: 10000, successChanceBonus: 0, goldPerHour: 6),
    Spell(name: "Time Stop", description: "Briefly freeze time around you", effect: "Doubles XP and gold gain for the next run", requiredLevel: 10, goldCost: 15000, successChanceBonus: 0)
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
        runDurationLower: 60,
        runDurationUpper: 120,
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
        }
        .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification)) { _ in
            updatePassiveGains()
        }
        .withTextShadow()
        .alert(item: gameData.alertBinding) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .withTextShadow()
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
            updatePassiveGains()
            gameData.checkUnlocks()
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

    func updatePassiveGains() {
        gameData.updatePassiveGains()
        gameData.checkUnlocks()
    }
}

//enum AlertItem: Identifiable {
//    case levelUp, passiveGains
//    var id: Self { self }
//}
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
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(gameData.wizard.name), \nthe Wizard")
                        .withBoldShadow()
                    Text("Level: \(gameData.wizard.level)")
                        .withTextShadow()
                    Text("XP: \(gameData.wizard.xp)/\(gameData.xpNeededForLevelUp)")
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

    var body: some View {
            ZStack {
                BackgroundView(imageName: "library")
                VStack(spacing: 15) {
                    Text("Arcane Sanctum")
                        .withBoldShadow()
                    
                    Text("Delve into ancient tomes to expand thy knowledge:")
                        .withTextShadow()
                        .fixedSize(horizontal: false, vertical: true)
                    Button(action: {
                        gameData.studyArcaneTexts()
                    }) {
                        Text("Study Arcane Texts")
                            .padding()
                            .cornerRadius(10)
                            .withTextShadow()
                    }
                    
                    Text("XP: \(gameData.wizard.xp)")
                        .withTextShadow()
                }
                .padding()
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
                                      .font(.title)
                                      .foregroundColor(.blue)
                                      .padding()
                                      .background(Color.blue.opacity(0.2))
                                      .cornerRadius(10)
                                  
                                  Text("\(wizardName) has reached level \(gameData.wizard.level)!!")
                                      .font(.caption)
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
        let totalGold = gameData.wizard.inventory.reduce(0) { sum, item in
            sum + (item.quantity * (treasureList.first(where: { $0.name == item.name })?.goldValue ?? 0))
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
                let goldValue = item.quantity * treasure.goldValue
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
    
    var sellValue: Int {
        item.quantity * (treasureList.first(where: { $0.name == item.name })?.goldValue ?? 0)
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
    
    let conversionRate = 1 // 1 gold = 1 XP
    
    var maxConversion: Int {
        min(gameData.wizard.gold, gameData.xpNeededForLevelUp - gameData.wizard.xp)
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
        let amountToConvert = Int(goldToConvert)
        print("Attempting to convert \(amountToConvert) gold to XP")
        if amountToConvert <= gameData.wizard.gold && amountToConvert <= maxConversion {
            DispatchQueue.global(qos: .userInitiated).async {
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
                    // Add this line to trigger a refresh of the main view
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.gameData.objectWillChange.send()
                    }
                    
//                    // Check if level up occurred and present the alert
//                    if self.gameData.showLevelUpAlert {
//                        self.isPresented = false  // Close the conversion view
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                            self.gameData.objectWillChange.send()
//                        }
//                        // The level up alert will be shown by the main ContentView
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

// MARK: - Complications

class ComplicationController: NSObject, CLKComplicationDataSource {
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let gameData = GameData()
        let date = Date()
        
        switch complication.family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "Lvl \(gameData.wizard.level)"),
                line2TextProvider: CLKSimpleTextProvider(text: "XP: \(gameData.wizard.xp)")
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
