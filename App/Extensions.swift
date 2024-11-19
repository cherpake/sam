//
//  Extensions.swift
//  sam
//
//  Created by Evgeny Cherpak on 03/03/2023.
//

import Foundation
import SwiftUI

public class Application {
    
    public class var appBundleId: String? {
        return Bundle.main.bundleIdentifier
    }
    
    public class var appDisplayName: String? {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
    }
    
    public class var appBundleName: String? {
        return Bundle.main.infoDictionary?["CFBundleName"] as? String
    }
    
    public class var appVersion: String {
        return "\((appDisplayName ?? appBundleName)!) v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] ?? ""))"
    }
    
    public class var receiptData: Data? {
        guard let url = Bundle.main.appStoreReceiptURL else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }
    
}

extension String {
    private static var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .current
        return df
    }
    
    private static var dateTimeFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        df.timeZone = .current
        return df
    }
    
    public init(date: Date, includeTime: Bool = false) {
        if includeTime {
            self.init(stringLiteral: String.dateTimeFormatter.string(from: date))
        } else {
            self.init(stringLiteral: String.dateFormatter.string(from: date))
        }
    }
    
    func countryFlag() -> String {
        let flagBase = UnicodeScalar("🇦").value - UnicodeScalar("A").value

        let flag = self
            .uppercased()
            .unicodeScalars
            .compactMap({ UnicodeScalar(flagBase + $0.value)?.description })
            .joined()
        return flag
    }

}

extension UserDefaults {
    
    public subscript<T>(key: String) -> T? {
        get {
            return value(forKey: key) as? T
        }
        set {
            set(newValue, forKey: key)
        }
    }
    
    public subscript<T: RawRepresentable>(key: String) -> T? {
        get {
            if let rawValue = value(forKey: key) as? T.RawValue {
                return T(rawValue: rawValue)
            }
            return nil
        }
        set {
            set(newValue?.rawValue, forKey: key)
        }
    }

    public subscript<T: Codable>(key: String) -> T? {
        get {
            guard let data = value(forKey: key) as? Data else { return nil }
            return try? JSONDecoder().decode(T.self, from: data)
        }
        set {
            guard let newValue = newValue else {
                set(nil, forKey: key)
                return
            }
            guard let data = try? JSONEncoder().encode(newValue) else {
                assert(false, "Unable to code Codable object \(newValue) for \(key)")
                return
            }
            set(data, forKey: key)
        }
    }

}

@propertyWrapper
struct NullEncodable<T>: Codable where T: Codable {
    
    var wrappedValue: T?

    init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch wrappedValue {
        case .some(let value): try container.encode(value)
        case .none: try container.encodeNil()
        }
    }
}

extension ToggleStyle where Self == CheckBoxToggleStyle {

    static var checkboxStyle: CheckBoxToggleStyle {
        return CheckBoxToggleStyle()
    }
    
}

// Custom Toggle Style
struct CheckBoxToggleStyle: ToggleStyle {

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                    .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
                    .imageScale(.large)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
