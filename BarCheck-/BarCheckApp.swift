//
//  BarCheck_App.swift
//  BarCheck_
//
//  Created by Isaac Petrella on 10/17/23.
//

import SwiftUI
import Firebase

@main
struct BarCheckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var bookmarkViewModel = BookmarkViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bookmarkViewModel)
        }
    }
}


// MARK: Initializing Firebase
class AppDelegate: NSObject, UIApplicationDelegate{
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: 
    [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    // MARK: Phone Auth Needs to Initialize Remote Notifications
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) async
    -> UIBackgroundFetchResult {
        return .noData
}
}
