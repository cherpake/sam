//
//  StatusView.swift
//  sam
//
//  Created by Evgeny Cherpak on 01/03/2023.
//

import SwiftUI

enum StatusValue: Int {
    case running
    case paused
    case onHold // campaign/ad group paused
    case unknown
}

struct StatusView: View {
    var campaign: Status?
    var adGroup: Status?
    var keyword: Status?
    
    private func value(
        campaign: Status?,
        adGroup: Status?,
        keyword: Status?
    ) -> StatusValue {
        var result: StatusValue = .unknown
        guard let campaign else { return result }
        switch campaign {
        case .enabled:
            result = .running
        case .paused:
            result = .paused
        default:
            break
        }
        if let adGroup {
            switch adGroup {
            case .enabled:
                if result == .paused {
                    result = .onHold
                }
            case .paused:
                result = .paused
            default:
                break
            }
        }
        if let keyword {
            switch keyword {
            case .active:
                if result == .paused || result == .onHold {
                    result = .onHold
                }
            case .paused:
                result = .paused
            default:
                break
            }
        }
        return result
    }
    
    var body: some View {
        Image(systemName: {
            switch value(campaign: campaign, adGroup: adGroup, keyword: keyword) {
            case .running:
                return "circlebadge.fill"
            case .paused:
                return "pause.fill"
            case .onHold:
                return "exclamationmark.triangle.fill"
            case .unknown:
                return "rectangle.fill"
            }
        }())
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 12.0, height: 12.0)
            .foregroundColor({
                switch value(campaign: campaign, adGroup: adGroup, keyword: keyword) {
                case .running:
                    return Color.green
                case .paused:
                    return Color.primary
                case .onHold:
                    return Color.orange
                case .unknown:
                    return Color.red
                }
            }())
    }
}
