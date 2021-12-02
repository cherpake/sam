//
//  Settings.swift
//  sam
//
//  Created by Evgeny Cherpak on 03/08/2020.
//

import Foundation
import Cemono

class Settings {
    
    static let instace = Settings()
    
    var certificateData: Data? {
        get {
            return UserDefaults.standard[#function]
        }
        set {
            UserDefaults.standard[#function] = newValue
        }
    }
    
    var certificatePassword: String? {
        get {
            return UserDefaults.standard[#function]
        }
        set {
            UserDefaults.standard[#function] = newValue
        }
    }
    
    var ACLS: Network.ACLSResponseData? {
        get {
            return UserDefaults.standard[#function]
        }
        set {
            UserDefaults.standard[#function] = newValue
        }
    }
    
    var timeZone: Network.TimeZoneData {
        get {
            return UserDefaults.standard[#function] ?? Network.TimeZoneData.ORTZ
        }
        set {
            UserDefaults.standard[#function] = newValue
        }
    }
    
}
