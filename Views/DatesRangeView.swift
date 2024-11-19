//
//  DatesRangeView.swift
//  sam
//
//  Created by Evgeny Cherpak on 02/03/2023.
//

import SwiftUI

enum RangeInterval: Int, RawRepresentable, Codable {
    case days
}

struct DateRange: Codable {
    var value: Int
    var interval: RangeInterval
}

extension DateRange {
    func displayValue() -> String {
        switch interval {
        case .days:
            if value == 0 {
                return "Today"
            } else if value == 1 {
                return "Yesterday"
            } else {
                return "Last \(value) days"
            }
        }
    }
    
    func startDate() -> Date {
        switch interval {
        case .days:
            if value == 0 {
                var components = Calendar.current.dateComponents(in: .current, from: Date.now)
                components.hour = 0
                components.minute = 0
                components.second = 0
                return Calendar.current.date(from: components)!
            } else {
                return Calendar.current.date(byAdding: .day, value: -1 * value, to: Date.now)!
            }
        }
    }
    
    func endDate() -> Date {
        switch interval {
        case .days:
            if value == 0 {
                var components = Calendar.current.dateComponents(in: .current, from: Date.now)
                components.hour = 23
                components.minute = 59
                components.second = 59
                return Calendar.current.date(from: components)!
            } else {
                return Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!
            }
        }
    }
}

extension DateRange: Hashable, Identifiable {
    var id: ObjectIdentifier {
        return ObjectIdentifier(DateRange.self)
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
        hasher.combine(interval)
    }
}

struct DatesRangeView: View {
    @Binding var dateRange: DateRange
    
    var availableRanges: [DateRange] = [
        .init(value: 0, interval: .days),
        .init(value: 1, interval: .days),
        .init(value: 7, interval: .days),
        .init(value: 30, interval: .days),
        .init(value: 90, interval: .days),
        .init(value: 180, interval: .days),
    ]
    
    var body: some View {
        Menu {
            #warning("This will create issues down the road when we have a different type of interval")
            ForEach(availableRanges, id: \.value) { r in
                Button() {
                    dateRange = r
                } label: {
                    HStack {
                        if r == dateRange {
                            Image(systemName: "checkmark")
                        }
                        Text(r.displayValue())
                    }
                }
            }
        } label: {
            Image(systemName: "calendar")
            #if !os(iOS)
            Text(dateRange.displayValue())
            #endif
        }
        .fixedSize(horizontal: true, vertical: true)
    }
}
