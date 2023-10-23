//
//  APIStarterApp.swift
//  APIStarter
//
//  Created by Nien Lam on 10/12/23.
//

import SwiftUI
import AVFoundation

@main
struct APIStarterApp: App {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if AVAudioSession.sharedInstance().recordPermission != .granted {
            AVAudioSession.sharedInstance().requestRecordPermission { (isGranted) in
                print("Microphone permissions \(isGranted)")
            }
        }
        return true
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
