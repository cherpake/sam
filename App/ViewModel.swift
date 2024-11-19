//
//  ViewModel.swift
//  sam
//
//  Created by Evgeny Cherpak on 01/03/2023.
//

import Foundation
import Combine
#if os(iOS)
import UIKit
#endif

class ViewModel: ObservableObject {
    #if os(macOS)
    let timer = Timer.publish(every: 15 * 60.0, on: .main, in: .common).autoconnect()
    var cancallables = [AnyCancellable]()
    
    init() {
        timer
            .sink { [weak self] timer in
                self?.fetchTodaysTotals()
            }
            .store(in: &cancallables)
    }
    #endif
    
    @Published var clientId: String = UserDefaults.standard.clientId ?? "" {
        didSet {
            UserDefaults.standard.clientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
            SearchAds.instance.clientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
            fetchOrgId()
        }
    }
    @Published var clientSecret: String = UserDefaults.standard.clientSecret ?? "" {
        didSet {
            UserDefaults.standard.clientSecret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
            SearchAds.instance.clientSecret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
            fetchOrgId()
        }
    }
    @Published var acls: [ACLS] = UserDefaults.standard.acls {
        didSet {
            UserDefaults.standard.acls = acls
        }
    }
    @Published var orgId: Int64 = UserDefaults.standard.orgId ?? 0 {
        didSet {
            UserDefaults.standard.orgId = orgId
        }
    }
    @Published var dateRange: DateRange = UserDefaults.standard.dateRange {
        didSet {
            UserDefaults.standard.dateRange = dateRange
        }
    }
    @Published var selectedCampaign: Campaign? = nil {
        didSet {
            if oldValue != selectedCampaign {
                adGroups = nil
                selectedAdGroup = nil
                adGroupReport = nil
            }
        }
    }
    @Published var selectedAdGroup: AdGroup? = nil {
        didSet {
            if oldValue != selectedAdGroup {
                keywords = nil
                keywordsReport = nil
            }
        }
    }
    
    @Published var report: ReportResponse? = nil // all campaign report
    @Published var todaysReport: ReportResponse? = nil // all campaign report
    
    @Published var adGroupReport: ReportResponse? = nil // all ad groups for selected campaign
    @Published var keywordsReport: ReportResponse? = nil // all keywords for selected ad group
    
    @Published var campaigns: [Campaign]? = nil {
        didSet {
            if selectedCampaign == nil {
                #if os(macOS)
                DispatchQueue.main.async {
                    self.selectedCampaign = self.campaigns?.first
                }
                #else
                if UIDevice.current.userInterfaceIdiom == .pad {
                    DispatchQueue.main.async {
                        self.selectedCampaign = self.campaigns?.first
                    }
                }
                #endif
            }
        }
    }
    @Published var adGroups: [AdGroup]? = nil 
    @Published var keywords: [Keyword]? = nil // keyword for selected ad group
    
    @Published var selectedAdGroupsIds: Set<Int64>? = nil // selected keywords (subset of keywords)
    @Published var selectedKeywordIds: Set<Int64>? = nil // selected keywords (subset of keywords)
    
    @Published var allKeywords: Bool = UserDefaults.standard.showAllKeywords {
        didSet {
            UserDefaults.standard.showAllKeywords = allKeywords
        }
    }
    
    func fetchOrgId() {
        Task {
            if clientId.count > 0, clientSecret.count > 0 {
                do {
                    if let acls = try await SearchAds.instance.getACLS() {
                        DispatchQueue.main.async {
                            self.acls = acls
                            
                            // Make sure we have orgId
                            guard let first = acls.first else { return }
                            if UserDefaults.standard.orgId == nil {
                                self.orgId = first.orgId
                            }
                        }
                    }
                } catch let error {
                    debugPrint(error)
                }
            }
        }
    }
    
    #warning("Filter based on state!!!")
    
    func fetchTodaysTotals() {
        Task {
            guard let report = try await SearchAds.instance.getCampaignReport(
                report: ReportingRequest(
                    startTime: .init(date: DateRange(value: 0, interval: .days).startDate()),
                    endTime: .init(date: DateRange(value: 0, interval: .days).startDate()),
                    selector: ReportSelector(
                        conditions: [],
                        orderBy: [
                            .init(field: .campaignId, sortOrder: .ascending)
                        ],
                        pagination: Pagination(offset: 0, limit: 1000)),
                    returnGrandTotals: true,
                    returnRowTotals: true,
                    timeZone: .ortz)) else { return }
            
            DispatchQueue.main.async {
                self.todaysReport = report.reportingDataResponse
                // Update if we just fetched it
                if self.dateRange.interval == .days && self.dateRange.value == 0 {
                    self.report = report.reportingDataResponse
                }
            }
        }
    }
    
}
