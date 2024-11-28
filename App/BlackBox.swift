//
//  App.swift
//  Cemono
//
//  Created by Evgeny Cherpak on 14/10/2020.
//

import Foundation
#if os(iOS)
import UIKit
#endif
import StoreKit

private extension UserDefaults {
    
    var blackbox_appStoreAppId: Int? {
        get {
            let value = self.integer(forKey: #function)
            return (value > 0) ? value : nil
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var blackbox_askedUserForReview: Bool {
        get {
            return self.bool(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var blackbox_askedUserForShare: Bool {
        get {
            return self.bool(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var blackbox_appLanchCount: Int {
        get {
            return self.integer(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var blackbox_userScore: Int {
        get {
            return self.integer(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var blackbox_lastReviewShown: TimeInterval {
        get {
            return self.double(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
}

public extension Notification.Name {
    static let BlackBoxUpdateNotification = Notification.Name("BlackBoxUpdateNotification")
}

@objc public class Blackbox: NSObject {
    
    @objc public static let instance = Blackbox()
    
    public var appStoreId: Int? = UserDefaults.standard.blackbox_appStoreAppId
    public var handleReviewRequest: (() -> ())? = nil
    
    public var minimalLaunchesBeforeReviewPrompt: Int = 0
    public var minimalScoreBeforeReviewPrompt: Int = 25
//    #if DEBUG
//    public var minimalRepeatIntervalBeforeReviewPrompt: Double = 60 * 15 // 15 min
//    #else
    public var minimalRepeatIntervalBeforeReviewPrompt: Double = 60 * 60 * 24 * 7 // 1 day
//    #endif
    
    @objc public var analytics: ((String, Dictionary<String, String>?) -> Void)? = nil

    override init() {
        super.init()
        fetchAppStoreId()
        #if os(iOS)
        NotificationCenter
            .default
            .addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { notification in
                UserDefaults.standard.blackbox_appLanchCount += 1
            }
        #endif
    }
    
    private func fetchAppStoreId() {
        guard self.appStoreId == nil else { return }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "itunes.apple.com"
        urlComponents.path = "/lookup"
        urlComponents.queryItems = {
            guard let bundleId = Bundle.main.bundleIdentifier else { return nil }
            return [URLQueryItem(name: "bundleId", value: bundleId)]
        }()
        
        guard let url = urlComponents.url else { return }
        URLSession.shared.dataTask(with: URLRequest(url: url)) { (data, response, error) in
            struct ResultsResponse: Codable {
                var results: [Track]
            }
            struct Track: Codable {
                var trackId: Int
            }
            
            guard error == nil else { return }
            guard let data = data else { return }
            guard let result = try? JSONDecoder().decode(ResultsResponse.self, from: data) else { return }
            guard let appStoreId = result.results.first?.trackId else { return }
            self.appStoreId = appStoreId
            UserDefaults.standard.blackbox_appStoreAppId = appStoreId
        }.resume()
    }
    
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    @objc public func openReviewPage() {
//        #if DEBUG
//        showReviewRequest()
//        #endif
        guard let appStoreId = appStoreId else { return }
        let urlString = "https://apps.apple.com/app/id\(appStoreId)?action=write-review"
        guard let url = URL(string: urlString) else { return }
        #if os(iOS)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.blackbox_lastReviewShown = now
        analytics?("Open Review Page", nil)
    }
    
    private var requestWorkItem: DispatchWorkItem?
    
    #if !os(tvOS)
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    @objc public func minimalRequirmentsAreMet() -> Bool {
        guard UserDefaults.standard.blackbox_appLanchCount >= minimalLaunchesBeforeReviewPrompt else { return false }
        guard UserDefaults.standard.blackbox_userScore >= minimalScoreBeforeReviewPrompt else { return false }
        return true
    }
    
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    @objc public func shouldShowReviewRequest(force: Bool) -> Bool {
        let now = Date().timeIntervalSince1970
        
        if !force {
            guard minimalRequirmentsAreMet() else { return false }
        }
        
        if UserDefaults.standard.blackbox_lastReviewShown > 0 {
            guard
                UserDefaults.standard.blackbox_lastReviewShown + minimalRepeatIntervalBeforeReviewPrompt <= now
            else {
                debugPrint(" [BLACKBOX] not enough time passed to request review since \(UserDefaults.standard.blackbox_lastReviewShown) - now \(now)")
                return false
            }
        }
                
        return true
    }
    
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    @objc public func showReviewRequestIfNeeded(force: Bool = false) {
        guard shouldShowReviewRequest(force: force) else { return }
        
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.blackbox_lastReviewShown = now
        if let handleReviewRequest {
            handleReviewRequest()
        } else {
            showReviewRequest()
        }
    }
    
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    @objc public func showReviewRequest() {
        // https://www.avanderlee.com/swift/skstorereviewcontroller-app-ratings/
        DispatchQueue.main.async {
            #if os(iOS)
            if let scene = UIApplication.shared.connectedScenes.filter({ $0 is UIWindowScene && $0.activationState == .foregroundActive }).first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
                self.analytics?("Review Request", nil)
            }
            #else
            SKStoreReviewController.requestReview()
            #endif
        }
    }
    #endif
    
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    @objc public func increaseUserScore(_ by: Int) {
        guard by > 0 else { return }
        UserDefaults.standard.blackbox_userScore += by
        
        // Post notification here
        NotificationCenter.default.post(name: .BlackBoxUpdateNotification, object: self)

        self.requestWorkItem?.cancel()
        let requestWorkItem = DispatchWorkItem {
            #if !os(tvOS)
            self.showReviewRequestIfNeeded()
            #endif
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: requestWorkItem)
        self.requestWorkItem = requestWorkItem
    }
    
}
