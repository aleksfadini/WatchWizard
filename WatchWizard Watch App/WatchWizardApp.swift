//
//  WatchWizardApp.swift
//  WatchWizard Watch App
//
//  Created by Alessandro Fadini on 7/5/24.
//

import SwiftUI
//import WatchKit

@main
struct WatchWizardApp: App {
    @StateObject private var gameData = GameData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameData)
                .onAppear {
                    WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: 60), userInfo: nil) { error in
                        if let error = error {
                            print("Failed to schedule background refresh: \(error.localizedDescription)")
                        } else {
                            Task {
                                await self.gameData.updatePassiveGains()
                            }
                        }
                    }
                }
        }
    }
}
