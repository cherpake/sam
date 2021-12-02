//
//  AppDelegate.swift
//  sam
//
//  Created by Evgeny Cherpak on 03/08/2020.
//

import UIKit
import BackgroundTasks

extension Notification.Name {
    static let menuCommandRefresh = Notification.Name("SAM.menuCommandRefresh")
    static let menuCommandSettings = Notification.Name("SAM.menuCommandSettings")
}

//@main
@objc public class AppDelegate: UIResponder, UIApplicationDelegate {
    
    @objc var window: UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.filter({
            return $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
        }).first else { return nil }
        
        guard let windowScene = scene as? UIWindowScene else { return nil }
        return windowScene.windows.first
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // MARK: Registering Launch Handlers for Tasks
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.cherpake.sam.refresh", using: nil) { task in
            // Downcast the parameter to an app refresh task as this identifier is used for a refresh request.
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        #if targetEnvironment(macCatalyst)
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NSApplicationDidResignActiveNotification"), object: nil, queue: .main) { (notification) in
            self.scheduleAppRefresh()
        }
        #else
        NotificationCenter.default.addObserver(forName: UIScene.willDeactivateNotification, object: nil, queue: .main) { (notification) in
            self.scheduleAppRefresh()
        }
        #endif
        
        return true
    }
    
    // MARK: -
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.cherpake.sam.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60 * 60) // Fetch no earlier than 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    // Fetch the latest feed entries from server.
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Network.instance.getCampaignsReport { (report, error) in
            if let reportData = report?.toJSONRepresentation {
                NotificationCenter.default.post(name: .backgroundRefreshTodayData, object: self, userInfo: ["report":reportData])
                task.setTaskCompleted(success: true)
            } else {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    #if targetEnvironment(macCatalyst)
    public override func buildMenu(with builder: UIMenuBuilder) {
        guard builder.system == .main else { return }
        
        // The format menu doesn't make sense
        builder.remove(menu: .format)
        builder.remove(menu: .edit)
        
        guard let fileMenu = builder.menu(for: .file) else { return }
        let refreshCommand = UIKeyCommand(input: "R", modifierFlags: .command, action: #selector(self.refresh))
        refreshCommand.title = NSLocalizedString("Refresh", comment: "")
        
        let settingsCommand = UIKeyCommand(input: ",", modifierFlags: .command, action: #selector(self.settings))
        settingsCommand.title = NSLocalizedString("Settings...", comment: "")
        
        let additinalMenu = UIMenu(title: "", image: nil, identifier: UIMenu.Identifier("settings"), options: [.displayInline], children: [refreshCommand,settingsCommand])
        builder.insertChild(additinalMenu, atStartOfMenu: fileMenu.identifier)
    }
    #endif
    
    @objc func refresh() {
        NotificationCenter.default.post(name: .menuCommandRefresh, object: nil)
    }
    
    @objc func settings() {
        NotificationCenter.default.post(name: .menuCommandSettings, object: nil)
    }
    
    // MARK: UISceneSession Lifecycle
    
    public func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    public func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
}
