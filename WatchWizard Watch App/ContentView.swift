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

struct Run {
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

struct Location: Identifiable,Equatable {
    let id = UUID()
    let shortName: String
    let fullName: String
    let description: String
    let requiredLevel: Int
    let missionMessage: String
    let baseXP: ClosedRange<Int>
    let baseGold: ClosedRange<Int>
    let difficulty: Double // 0.0 to 1.0, where 1.0 is most difficult
    let runDuration: ClosedRange<TimeInterval>
    let itemTypes: [ItemType] = [.treasure]
    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.id == rhs.id
    }
}

enum ItemType {
    case treasure
}

// MARK: - Game Data

class GameData: ObservableObject {
    // Dev Vars
    @Published var isTestMode: Bool = true
    @Published var easyXP: Bool = false
    @Published var extraMoney: Bool = false
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
    @Published var showPassiveGainAlert = false
    @Published var showLevelUpAlert = false
    
    
    init() {
        self.wizard = Wizard(name: "Merlin", level: 1, xp: 0, gold: 0, spells: [availableSpells[0]], inventory: [])
        self.completedRuns = []
        self.lastUpdateTime = Date()
        
        if extraMoney {
            self.wizard.gold = 1000
        }
    }


    var totalSuccessChanceBonus: Double {
         wizard.spells.reduce(0) { $0 + $1.successChanceBonus }
     }
    
    var xpNeededForLevelUp: Int {
        if easyXP {
            return 5 // in easyXP mode, only 5 xp per level
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

    
    func startRun(location: Location) {
        leveledUpDuringLastRun = false
        let duration: TimeInterval
            if isTestMode {
                duration = 3 // seconds for testing
            } else {
                duration = TimeInterval.random(in: location.runDuration)
            }
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
          
          checkAndHandleLevelUp()
          runStartTime = nil
          saveGame()
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
        var didLevelUp = false
        while wizard.xp >= xpNeededForLevelUp {
            wizard.level += 1
            didLevelUp = true
        }
        leveledUpDuringLastRun = didLevelUp
    }
    
    
    func checkAndHandleLevelUp() {
        let oldLevel = wizard.level
        checkLevelUp()
        if wizard.level > oldLevel {
            lastLevelUp = wizard.level
            showLevelUpAlert = true
        }
    }
    
    func purchaseSpell(_ spell: Spell) {
        if wizard.gold >= spell.goldCost && wizard.level >= spell.requiredLevel {
            wizard.gold -= spell.goldCost
            wizard.spells.append(spell)
            wizard.xpPerHour += spell.xpPerHour
            wizard.goldPerHour += spell.goldPerHour
        saveGame()
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
         return allLocations.first { !isLocationUnlocked($0) }
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
            showPassiveGainAlert = true
        } else {
            showPassiveGainAlert = false
        }
           checkAndHandleLevelUp()
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
    }

    func loadGame() {
        if let savedWizard = UserDefaults.standard.data(forKey: "SavedWizard") {
            let decoder = JSONDecoder()
            if let loadedWizard = try? decoder.decode(Wizard.self, from: savedWizard) {
                wizard = loadedWizard
            }
        }
        lastUpdateTime = UserDefaults.standard.object(forKey: "LastUpdateTime") as? Date ?? Date()
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
    50,    // Level 1 to 2
    200,   // Level 2 to 3
    500,   // Level 3 to 4
    1000,  // Level 4 to 5
    2000,  // Level 5 to 6
    3500,  // Level 6 to 7
    5500,  // Level 7 to 8
    8000,  // Level 8 to 9
    11000, // Level 9 to 10
    15000  // Level 10 to 11
]

let availableSpells = [
    Spell(name: "Enchanted Dart", description: "A simple but effective spell.", effect: "No additional effects", requiredLevel: 1, goldCost: 0, successChanceBonus: 0),
    Spell(name: "Magic Missile", description: "You will succeed better with stronger attack.", effect: "Raises your chances of success by 2% in each run", requiredLevel: 1, goldCost: 50, successChanceBonus: 0.02),
    Spell(name: "Curse", description: "Powerful chant that distracts your enemies.", effect: "Raises your chances of success by 2% in each run", requiredLevel: 2, goldCost: 150, successChanceBonus: 0.02),
    Spell(name: "Summon Familiar", description: "Call forth a magical companion.", effect: "Accumulates 1 XP every 5 minutes, even when not in a run", requiredLevel: 3, goldCost: 400, successChanceBonus: 0, xpPerHour: 12),
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
        shortName: "Inn Basement",
        fullName: "The Dusty Inn Basement",
        description: "A dimly lit cellar filled with cobwebs and old crates.",
        requiredLevel: 1,
        missionMessage: "Clearing out the cobwebs",
        baseXP: 10...20,
        baseGold: 5...15,
        difficulty: 0.1,
        runDuration: 60...120 // 1-2 minutes
    ),
    Location(
        shortName: "Village",
        fullName: "Willowbrook Village",
        description: "A quaint settlement with friendly faces and simple quests.",
        requiredLevel: 2,
        missionMessage: "Helping the villagers",
        baseXP: 15...25,
        baseGold: 10...20,
        difficulty: 0.2,
        runDuration: 120...240 // 2-4 minutes
    ),
    // ... WIP Add more locations later
    Location(
        shortName: "World's End",
        fullName: "The Edge of Reality",
        description: "The very limits of existence, where reality unravels.",
        requiredLevel: 57,
        missionMessage: "Battling cosmic horrors",
        baseXP: 500...1000,
        baseGold: 1000...2000,
        difficulty: 0.95,
        runDuration: 600...900 // 10-15 minutes
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
                        withAnimation(.easeOut(duration: 0.3)) {
                            splashOpacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showSplash = false
                        }
                    }
                    .onAppear {
                        gameData.loadGame()
                        // Delay the start of automatic fade-out
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeOut(duration: 1.0)) {
                                splashOpacity = 0
                            }
                        }
                        // Remove splash view from the hierarchy after fade-out
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showSplash = false
                        }
                    }
            } else {
                TabView {
                    WizardView()
                    RunView()
                    InventoryView()
                    SpellShopView()
                    HistoryView()
                }
                .environmentObject(gameData)
                .alert("Hark! Thou hast ascended!", isPresented: $gameData.showLevelUpAlert) {
                                  Button("View Character Sheet") {
                                      // Add navigation to character sheet if needed
                                  }
                              } message: {
                                  Text("Thy prowess has grown. Thou art now level \(gameData.lastLevelUp ?? 0)!")
                              }
                              .alert("Whilst thou rested...", isPresented: $gameData.showPassiveGainAlert) {
                                  Button("Splendid!") {
                                      gameData.passiveXPGained = 0
                                      gameData.passiveGoldGained = 0
                                  }
                              } message: {
                                  Text("Thy coffers have grown by \(gameData.passiveGoldGained)🟡 and thy knowledge by \(gameData.passiveXPGained) XP.")
                              }
                              .onAppear {
                                  gameData.updatePassiveGains()
                              }
                          }
                      }
                      .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification)) { _ in
                          gameData.updatePassiveGains()
                      }
                      .withTextShadow()
//                      .environment(\.font, Font.custom("Lancelot", size: 16))
                  }
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

// MARK: - Run View

struct RunView: View {
    @EnvironmentObject var gameData: GameData
    @State private var selectedLocation: Location?
    @State private var timer: Timer?
    @State private var currentTime = Date()
    @State private var showSummary = false
    @State private var lastCompletedRun: Run?
    @State private var didLevelUp = false

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
                questView
            }
        }
        .onChange(of: showSummary) { _, newValue in
            if !newValue {
                lastCompletedRun = nil
                didLevelUp = false
            }
        }
        .onReceive(gameData.$currentRun) { run in
            if run == nil && !gameData.completedRuns.isEmpty {
                lastCompletedRun = gameData.completedRuns.last
                didLevelUp = gameData.wizard.level > (lastCompletedRun?.location.requiredLevel ?? 0)
                showSummary = true
            }
        }
    }

    var questView: some View {
        ScrollView {
            VStack(spacing: 15) {
                if let currentRun = gameData.currentRun {
                    Text("\(gameData.wizard.name) is \(currentRun.location.missionMessage)")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("Adventuring: \(currentRun.location.shortName)")
                    ProgressView(value: currentTime.timeIntervalSince(gameData.runStartTime ?? Date()), total: currentRun.duration)
                        .padding(.horizontal)
                } else {
                    Text("Choose Thy Quest")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    ForEach(allLocations) { location in
                        if gameData.isLocationUnlocked(location) {
                            Button(action: {
                                selectedLocation = location
                            }) {
                                Text(location.shortName)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .buttonStyle(BorderedButtonStyle(tint: .blue))
                        } else if location == gameData.nextUnlockedLocation() {
                            Button(action: {
                                // Show level up message
                            }) {
                                Text(location.shortName)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .buttonStyle(BorderedButtonStyle(tint: .gray))
                            .disabled(true)
                            .overlay(
                                Text("Level \(location.requiredLevel) to unlock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(4)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(4)
                                    .padding(.top, 30)
                            )
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedLocation) { location in
            LocationDetailView(location: location, gameData: gameData)
        }
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.currentTime = Date()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
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
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if run.succeeded {
                    Text("Quest Successful!")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    Text("Forced to Retreat")
                        .foregroundColor(.red)
                        .font(.title2)
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
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "coins")
                            .foregroundColor(.yellow)
                        Text("Gold:")
                        Spacer()
                        Text("\(gameData.wizard.gold)🟡")
                            .fontWeight(.bold).foregroundColor(.yellow)
                    }
                }

                Section(header: Text("Trade")) {
                    Button("Sell All Items") {
                        showingSellAllConfirmation = true
                    }
                    .foregroundColor(.blue)
                }

                Section(header: Text("Sell Items")) {
                    ForEach(gameData.wizard.inventory, id: \.name) { item in
                        Button(action: {
                            selectedItem = item
                        }) {
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text("x\(item.quantity)")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Adventurer's Satchel")
            .navigationBarTitleDisplayMode(.inline)
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
//                !gameData.purchasedSpells.contains(where: { $0.id == spell.id })
                !gameData.wizard.spells.contains(where: { $0.id == spell.id })
            }
            .min(by: { $0.requiredLevel < $1.requiredLevel })
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Arcane Exchange")) {
                    Button("Convert Gold to Arcane Knowledge") {
                        showingXPConversionView = true
                    }
                }

                Section(header: Text("Purchase Spells")) {
                    ForEach(availableSpellsForPurchase) { spell in
//                        if !gameData.purchasedSpells.contains(where: { $0.id == spell.id }) {
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
            .navigationTitle("Mystic Emporium")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingXPConversionView) {
                GoldToXPConversionView(isPresented: $showingXPConversionView)
                    .presentationDetents([.height(250)]) // Adjust height as needed
                    .presentationDragIndicator(.hidden)
                    .interactiveDismissDisabled(true) // This prevents dismissal by dragging down
            }
//            .sheet(isPresented: $showingXPConversionView) {
//                GoldToXPConversionView(isPresented: $showingXPConversionView)
//            }
            .sheet(item: $selectedSpell) { spell in
                SpellDetailPurchaseView(spell: spell, isPresented: Binding(
                    get: { selectedSpell != nil },
                    set: { if !$0 { selectedSpell = nil } }
                ))
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
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Convert Gold to XP")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Gold to Convert: \(Int(goldToConvert))")
                .font(.body)
            
            Text("You will gain \(Int(goldToConvert * Double(conversionRate))) XP")
                .font(.caption)
            
            CustomSlider(value: $goldToConvert, bounds: 0...Double(gameData.wizard.gold))
                .frame(height: 30)
                .padding(.horizontal)
            
            HStack {
                Button("Convert") {
                    convertGoldToXP()
                    isPresented = false
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
        .digitalCrownRotation($goldToConvert, from: 0, through: Double(gameData.wizard.gold), by: 1, sensitivity: .high, isContinuous: false, isHapticFeedbackEnabled: true)
    }
    
    func convertGoldToXP() {
        let amountToConvert = Int(goldToConvert)
        if amountToConvert <= gameData.wizard.gold {
            gameData.wizard.gold -= amountToConvert
            gameData.wizard.xp += amountToConvert * conversionRate
            gameData.checkLevelUp()
        gameData.saveGame()
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
        NavigationView {
            ZStack {
                BackgroundView(imageName: "PaperRoll")
            List {
                ForEach(gameData.completedRuns.indices.reversed(), id: \.self) { index in
                    let run = gameData.completedRuns[index]
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(run.location.shortName): \(run.succeeded ? "Success" : "Failure")")
                            .font(.headline)
                        Text("XP: +\(run.xpGained), Gold: +\(run.goldGained)")
                        Text("Items: \(run.itemsGained.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", "))")
                            .font(.footnote)
                        Text("Defeated: \(run.creaturesDefeated.joined(separator: ", "))")
                            .font(.footnote)
                    }
                         .listRowBackground(Color.clear) // Make list rows transparent
                     }
                 }
                 .listStyle(PlainListStyle()) // Use plain style to remove default list background
             }
            .navigationTitle("Heroic Deeds")
            .navigationBarTitleDisplayMode(.inline)
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
