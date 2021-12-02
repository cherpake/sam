//
//  SceneDelegate.swift
//  sam
//
//  Created by Evgeny Cherpak on 03/08/2020.
//

import UIKit
//import BackgroundTasks
import SVProgressHUD

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var viewController: ViewController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        UIRefreshControl.appearance().tintColor = UIColor.systemBlue
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.systemBlue, .font: UIFont(name: "Avenir-Medium", size: 28.0)!]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.systemBlue, .font: UIFont(name: "Avenir-Medium", size: 20.0)!]
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.systemBlue
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.lightGray, .font: UIFont(name: "Avenir-Light", size: 12.0)!], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont(name: "Avenir-Light", size: 12.0)!], for: .selected)

        SVProgressHUD.setDefaultStyle(.custom)
        SVProgressHUD.setDefaultMaskType(.gradient)
        SVProgressHUD.setBackgroundColor(UIColor.black.withAlphaComponent(0.75))
        SVProgressHUD.setForegroundColor(UIColor.white)
        SVProgressHUD.setMinimumDismissTimeInterval(0.3)
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        viewController = ViewController()
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UINavigationController(rootViewController: viewController!)
        window?.makeKeyAndVisible()
   
//        #if false
//        DispatchQueue.main.async {
//            let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.cherpake.sam.refresh", using: nil) { (task) in
//                if let task = task as? BGAppRefreshTask {
//                    self.handleAppRefreshTask(task: task)
//                }
//            }
//            if registered {
//                #if targetEnvironment(macCatalyst)
//                NotificationCenter.default.addObserver(self, selector: #selector(self.scheduleBackgroundFetch), name: NSNotification.Name("NSApplicationDidResignActiveNotification"),object: nil)
//                NotificationCenter.default.addObserver(self, selector: #selector(self.cancelScheduledBackgroundFetch), name: NSNotification.Name("NSApplicationDidBecomeActiveNotification"),object: nil)
//                #else
//                NotificationCenter.default.addObserver(self, selector: #selector(self.scheduleBackgroundFetch), name: UIApplication.didEnterBackgroundNotification, object: nil)
//                NotificationCenter.default.addObserver(self, selector: #selector(self.cancelScheduledBackgroundFetch), name: UIApplication.didBecomeActiveNotification, object: nil)
//                #endif
//            } else {
//                debugPrint("Failed to register background task")
//            }
//        }
//        #endif
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

}

//extension SceneDelegate {
//
//    func handleAppRefreshTask(task: BGAppRefreshTask) {
//        task.expirationHandler = {
//            task.setTaskCompleted(success: false)
//        }
//
//        viewController?.updateTodayStats(completion: { [weak self] (success) in
//            task.setTaskCompleted(success: success)
//            if success {
//                self?.scheduleBackgroundFetch()
//            }
//        })
//    }
//
//    @objc func cancelScheduledBackgroundFetch() {
////        debugPrint("Cancel all pending tasks \(BGTaskScheduler.shared)")
////        BGTaskScheduler.shared.cancelAllTaskRequests()
//    }
//
//    @objc func scheduleBackgroundFetch() {
////        BGTaskScheduler.shared.cancelAllTaskRequests()
//
//        let fetchTask = BGAppRefreshTaskRequest(identifier: "com.cherpake.sam.refresh")
//        fetchTask.earliestBeginDate = Date(timeIntervalSinceNow: 1*60*60)
//        do {
//            try BGTaskScheduler.shared.submit(fetchTask)
//            debugPrint("Submitted task: \(fetchTask)")
//        } catch {
//            debugPrint("Unable to submit task: \(error.localizedDescription)")
//        }
//    }
//
//}
