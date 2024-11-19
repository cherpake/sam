//
//  Settings.swift
//  sam
//
//  Created by Evgeny Cherpak on 01/03/2023.
//

import Foundation

extension UserDefaults {
    
    #if os(macOS)
    var windowFrame: NSRect? {
        get {
            if let value = self.string(forKey: #function) {
                return NSRectFromString(value)
            }
            return nil
        }
        set {
            if let rect = newValue {
                self.set(NSStringFromRect(rect), forKey: #function)
            }
        }
    }
    #endif
    
    var clientId: String? {
        get {
            return self.string(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var teamId: String? {
        get {
            return self.string(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var keyId: String? {
        get {
            return self.string(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var privateKey: String? {
        get {
            return self.string(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var publicKey: String? {
        get {
            return self.string(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var clientSecret: String? {
        get {
            
            return self.string(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var orgId: Int64? {
        get {
            return self.object(forKey: #function) as? Int64
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
    var acls: [ACLS] {
        get {
            return self[#function] ?? [ACLS]()
        }
        set {
            self[#function] = newValue
        }
    }
    
    var countriesFilter: StatusFilter {
        get {
            if let value = self.object(forKey: #function) as? Int, let filter = StatusFilter(rawValue: value) {
                return filter
            } else {
                return .all
            }
        }
        set {
            self.set(newValue.rawValue, forKey: #function)
        }
    }
    
    var campaignFilter: StatusFilter {
        get {
            if let value = self.object(forKey: #function) as? Int, let filter = StatusFilter(rawValue: value) {
                return filter
            } else {
                return .all
            }
        }
        set {
            self.set(newValue.rawValue, forKey: #function)
        }
    }
    
    var campaignOrdering: SortOrder {
        get {
            if let value = self.object(forKey: #function) as? String, let filter = SortOrder(rawValue: value) {
                return filter
            } else {
                return .descending
            }
        }
        set {
            self.set(newValue.rawValue, forKey: #function)
        }
    }
    
    var groupFilter: StatusFilter {
        get {
            if let value = self.object(forKey: #function) as? Int, let filter = StatusFilter(rawValue: value) {
                return filter
            } else {
                return .all
            }
        }
        set {
            self.set(newValue.rawValue, forKey: #function)
        }
    }
    
    var groupOrdering: SortOrder {
        get {
            if let value = self.object(forKey: #function) as? String, let filter = SortOrder(rawValue: value) {
                return filter
            } else {
                return .descending
            }
        }
        set {
            self.set(newValue.rawValue, forKey: #function)
        }
    }
    
    var keywordFilter: StatusFilter {
        get {
            if let value = self.object(forKey: #function) as? Int, let filter = StatusFilter(rawValue: value) {
                return filter
            } else {
                return .all
            }
        }
        set {
            self.set(newValue.rawValue, forKey: #function)
        }
    }
    
    var keywordOrdering: SortOrder {
        get {
            if let value = self.object(forKey: #function) as? String, let filter = SortOrder(rawValue: value) {
                return filter
            } else {
                return .descending
            }
        }
        set {
            self.set(newValue.rawValue, forKey: #function)
        }
    }
    
    var dateRange: DateRange {
        get {
            return self[#function] ?? .init(value: 0, interval: .days)
        }
        set {
            self[#function] = newValue
        }
    }

    var showAllKeywords: Bool {
        get {
            return self.bool(forKey: #function)
        }
        set {
            self.set(newValue, forKey: #function)
        }
    }
    
}
