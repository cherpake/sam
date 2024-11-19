//
//  BlackBox.swift
//  Sam2
//
//  Created by Evgeny Cherpak on 09/03/2023.
//

import Foundation
import StoreKit

private extension UserDefaults {
    var appStoreId: Int? {
        get {
            return self.object(forKey: #function) as? Int
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var appLanchCount: Int {
        get {
            return self.integer(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var userScore: Int {
        get {
            return self.integer(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var lastReviewShown: TimeInterval {
        get {
            return self.double(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
}


class Blackbox {
    public static let instance = Blackbox()
        
    public var minimalLaunchesBeforeReviewPrompt: Int = 0
    public var minimalScoreBeforeReviewPrompt: Int = 15
    public var minimalRepeatIntervalBeforeReviewPrompt: Double = 60 * 60 * 24 // 1 day

    init() {
        fetchAppStoreId()
        
        #if os(iOS)
        NotificationCenter
            .default
            .addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { notification in
                UserDefaults.standard.appLanchCount += 1
            }
        #elseif os(macOS)
        NotificationCenter
            .default
            .addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { notification in
                UserDefaults.standard.appLanchCount += 1
            }
        #endif
        
    }
    
    private func fetchAppStoreId() {
        guard UserDefaults.standard.appStoreId == nil else { return }
        
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
            UserDefaults.standard.appStoreId = appStoreId
        }.resume()
    }
    
    private var requestWorkItem: DispatchWorkItem?
    
    func showReviewRequest(force: Bool = false) {
        let now = Date().timeIntervalSince1970
        
        if !force {
            guard UserDefaults.standard.appLanchCount >= minimalLaunchesBeforeReviewPrompt else { return }
            guard UserDefaults.standard.userScore >= minimalScoreBeforeReviewPrompt else { return }
            if UserDefaults.standard.lastReviewShown > 0 {
                guard UserDefaults.standard.lastReviewShown < now - minimalRepeatIntervalBeforeReviewPrompt else { return }
            }
        }
        
        // https://www.avanderlee.com/swift/skstorereviewcontroller-app-ratings/
        self.requestWorkItem?.cancel()
        let requestWorkItem = DispatchWorkItem {
            UserDefaults.standard.lastReviewShown = now
            
            #if os(iOS)
            if let scene = UIApplication.shared.connectedScenes.filter({ $0 is UIWindowScene && $0.activationState == .foregroundActive }).first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
            #endif
            
            #if os(macOS)
            SKStoreReviewController.requestReview()
            #endif
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: requestWorkItem)
        self.requestWorkItem = requestWorkItem
    }
    
    func increaseUserScore(_ by: Int) {
        guard by > 0 else { return }
        UserDefaults.standard.userScore += by
        showReviewRequest()
    }
}
