//
//  WatchWizardApp.swift
//  WatchWizard Watch App
//
//  Created by Alessandro Fadini on 7/5/24.
//

import SwiftUI

@main
struct WatchWizard_Watch_AppApp: App {
    @StateObject private var gameData = GameData()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameData)
        }
    }
}
