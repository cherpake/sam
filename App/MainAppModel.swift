//
//  MainAppModel.swift
//  Sam2
//
//  Created by Evgeny Cherpak on 01/11/2024.
//

import Foundation
import Combine
import SwiftUI

enum StatusFilter: Int, RawRepresentable, CaseIterable {
    case all
    case enabled
    case disabled
}

enum ViewMode {
    case normal
    case allKeywords
}

extension ReportRow: Identifiable {
    var id: String {
        return "\(self.metadata.campaignId ?? 0):\(self.metadata.adGroupId ?? 0):\(self.metadata.keywordId ?? 0)"
    }
}

extension RowMetadata: Identifiable {
    var id: String {
        return "\(self.campaignId ?? 0):\(self.adGroupId ?? 0):\(self.keywordId ?? 0)"
    }
}

extension ReportRow: Hashable {
    static func == (lhs: ReportRow, rhs: ReportRow) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.metadata)
    }
}

extension RowMetadata: Hashable {
    static func == (lhs: RowMetadata, rhs: RowMetadata) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.campaignId)
        hasher.combine(self.adGroupId)
        hasher.combine(self.keywordId)
    }
}

class MainAppModel: ObservableObject {
    
    var cancallables = [AnyCancellable]()
    
    #if os(macOS)
    let timer = Timer.publish(every: 15 * 60.0, on: .main, in: .common).autoconnect()
    
    init() {
        fetchOrgId()
        registerForUpdates()
        timer
            .sink { [weak self] timer in
                Task {
                    try await self?.updateTodayReport(force: true)
                }
            }
            .store(in: &cancallables)
    }
    #else
    init() {
        fetchOrgId()
        registerForUpdates()
    }
    #endif
    
    private func registerForUpdates() {
        #if os(macOS)
        NotificationCenter.default.addObserver(forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task {
                try await self?.updateTodayReport(force: true)
            }
        }
        #endif
        
        $adGroupsFilter
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] update in
                Task {
                    try await self?.updateAdGroupsReport()
                }
            }
            .store(in: &cancallables)
        
        $keywordsFilter
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] update in
                Task {
                    try await self?.updateKeywordsReport()
                }
            }
            .store(in: &cancallables)
    }
    
    #if os(iOS)
    @Published var path = NavigationPath("campaigns")
    #endif
    
    @Published var viewMode: ViewMode = UserDefaults.standard.showAllKeywords ? .allKeywords : .normal
    
    func changeMode(_ viewMode: ViewMode) {
        selectedAdGroupId = nil
        adGroupsReport = nil
        keywordsReport = nil
        
        self.viewMode = viewMode
        
        UserDefaults.standard.showAllKeywords = viewMode == .allKeywords
        
        updateReports()
    }
    
    @Published var campaignSelection: CampaignViewItem.ID? = nil//Set<CampaignViewItem.ID>()
    @Published var adGroupSelection = Set<AdGroupsViewItem.ID>()
    @Published var keywordSelection = Set<KeywordsViewItem.ID>()
    
    @Published var campaingsReport: ReportResponse? = nil
    @Published var campaingsReportUpdated: TimeInterval = 0
    
    @Published var todayReport: ReportResponse? = nil
    @Published var todayReportUpdated: TimeInterval = 0
    
    @Published var adGroupsReport: ReportResponse? = nil
    @Published var adGroupsReportUpdate: TimeInterval = 0
    @Published var adGroupsFilter = [String]() // IDs
    
    @Published var keywordsReport: ReportResponse? = nil
    @Published var keywordsReportUpdate: TimeInterval = 0
    @Published var keywordsFilter = [String]() // IDs

    @Published var selectedCampaignId: Int64? = nil {
        didSet {
            updateReports()
        }
    }
    
    @Published var selectedAdGroupId: Int64? = nil {
        didSet {
            updateReports()
        }
    }
    
    @Published var dateRange: DateRange = UserDefaults.standard.dateRange {
        didSet {
            UserDefaults.standard.dateRange = dateRange
            updateReports()
        }
    }
    
    func updateReports() {
        // Update
        Task {
            try await updateCampaingsReport(force: true)
            try await updateTodayReport()
        }
        Task {
            if let _ = selectedCampaignId {
                try await updateAdGroupsReport()
            }
        }
        Task {
            if selectedAdGroupId != nil || viewMode == .allKeywords {
                try await updateKeywordsReport()
            }
        }
    }
    
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
    
    private func fetchOrgId() {
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
                                self.updateReports()
                            }
                        }
                    }
                } catch let error {
                    debugPrint(error)
                }
            }
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
    
    func updateTodayReport(force: Bool = false) async throws {
        let now = Date().timeIntervalSince1970
        if now - todayReportUpdated < 5*60 && !force {
            return
        }
        
        let request = ReportingRequest(
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
            timeZone: .ortz)
        let result = try await SearchAds.instance.getCampaignReport(report: request)?.reportingDataResponse
        DispatchQueue.main.async {
            self.todayReport = result
            self.todayReportUpdated = now
            
            // Check if we just got campaigns report
            if self.dateRange.value == 0 {
                self.campaingsReport = self.todayReport
                self.campaingsReportUpdated = now
            }
        }
    }
    
    func updateCampaingsReport(force: Bool = false) async throws {
        let now = Date().timeIntervalSince1970
        if now - campaingsReportUpdated < 5*60 && !force {
            return
        }
        
        let dateRange = self.dateRange
        let request = ReportingRequest(
            startTime: .init(date: dateRange.startDate()),
            endTime: .init(date: dateRange.endDate()),
            selector: ReportSelector(
                conditions: [
                ],
                orderBy: [
                    .init(field: .campaignId, sortOrder: .ascending)
                ],
                pagination: Pagination(offset: 0, limit: 1000)),
            returnGrandTotals: true,
            returnRowTotals: true,
            timeZone: .ortz)
        
        let result = try await SearchAds.instance.getCampaignReport(report: request)?.reportingDataResponse
        DispatchQueue.main.async {
            self.campaingsReport = result
            self.campaingsReportUpdated = now
            
            // Check if we just got todays report
            if self.dateRange.value == 0 {
                self.todayReport = self.campaingsReport
                self.todayReportUpdated = now
            }
        }
    }
    
    func updateAdGroupsReport() async throws {
        guard let campaignId = selectedCampaignId else { return }
        let now = Date().timeIntervalSince1970
        
        var conditions = [Condition]()
        if adGroupsFilter.count > 0 {
            conditions.append(Condition(field: Fields.adGroupId, op: .inRange, values: adGroupsFilter))
        }
        
        let request = ReportingRequest(
            startTime: .init(date: self.dateRange.startDate()),
            endTime: .init(date: self.dateRange.endDate()),
            selector: ReportSelector(
                conditions: conditions,
                orderBy: [
                    .init(field: .adGroupId, sortOrder: .ascending)
                ],
                pagination: Pagination(offset: 0, limit: 1000)),
            returnGrandTotals: true,
            returnRowTotals: true,
            timeZone: .ortz)
        
        let result = try await SearchAds.instance.getAdGroupReport(campaignId: campaignId, report: request)?.reportingDataResponse
        DispatchQueue.main.async {
            self.adGroupsReport = result
            self.adGroupsReportUpdate = now
        }
    }
    
    func updateKeywordsReport() async throws {
        guard let campaignId = selectedCampaignId else { return }
        let now = Date().timeIntervalSince1970
        
        if viewMode == .allKeywords {
            do {
                try await updateAdGroupsReport()
            } catch {

            }
        }
        
        var conditions = [Condition]()
        if keywordsFilter.count > 0 {
            conditions.append(Condition(field: Fields.keywordId, op: .inRange, values: keywordsFilter))
        }
        
        let request = ReportingRequest(
            startTime: .init(date: self.dateRange.startDate()),
            endTime: .init(date: self.dateRange.endDate()),
            selector: ReportSelector(
                conditions: conditions,
                orderBy: [
                    .init(field: .adGroupId, sortOrder: .ascending)
                ],
                pagination: Pagination(offset: 0, limit: 1000)),
            returnGrandTotals: true,
            returnRowTotals: true,
            timeZone: .ortz)
        
        let result = try await SearchAds.instance.getKeywordsReport(campaignId: campaignId, adGroupId: selectedAdGroupId, report: request)?.reportingDataResponse
        DispatchQueue.main.async {
            self.keywordsReport = result
            self.keywordsReportUpdate = now
        }
    }
    
    func changeCampaign(campaign: CampaignViewItem, update: UpdateCampaignRequest) async throws {
        guard let id = Int64(campaign.id) else { return }
        let _  = try await SearchAds.instance.updateCampaign(campaignId: id, update: update)
        try await updateCampaingsReport(force: true)
    }
    
    func changeAdGroups(adGroups: [AdGroupsViewItem], update: AdGroupUpdate) async throws {
        for adGroup in adGroups {
            if let id = Int64(adGroup.id) {
                let _ = try await SearchAds.instance.updateAdGroup(campaignId: adGroup.campaignId, adGroupId: id, update: update)
            }
        }
        try await updateAdGroupsReport()
    }
    
    func changeKeywordStatus(keywords: [KeywordsViewItem], status: Status) async throws {
        // Keywords can come from different ad groups so we should group them!
        let adGroups = Set(keywords.compactMap({ $0.adGroupId }))
        for adGroup in adGroups {
            let adGroupKeywords = keywords.filter({ $0.adGroupId == adGroup })
            guard let first = adGroupKeywords.first else { continue }
            
            let _ = try await SearchAds.instance.updateKeywords(campaignId: first.campaignId,
                                                                adGroupId: first.adGroupId,
                                                                updates: adGroupKeywords.compactMap({
                if let id = Int64($0.id) {
                    return KeywordUpdate(id: id, status: status)
                } else {
                    return nil
                }
            }))
        }
        
        try await updateKeywordsReport()
    }
    
    func changeKeywordBid(keywords: [KeywordsViewItem], bid: Money) async throws {
        // Keywords can come from different ad groups so we should group them!
        let adGroups = Set(keywords.compactMap({ $0.adGroupId }))
        for adGroup in adGroups {
            let adGroupKeywords = keywords.filter({ $0.adGroupId == adGroup })
            guard let first = adGroupKeywords.first else { continue }
            
            let _ = try await SearchAds.instance.updateKeywords(campaignId: first.campaignId,
                                                                adGroupId: first.adGroupId,
                                                                updates: adGroupKeywords.compactMap({
                if let id = Int64($0.id) {
                    return KeywordUpdate(id: id, bidAmount: bid)
                } else {
                    return nil
                }
            }))
        }
        
        try await updateKeywordsReport()
    }
    
    // MARK: -
    
    func adGroupViewItems() -> [AdGroupsViewItem] {
        let adGroups = self
            .adGroupsReport?
            .row
            .compactMap { row in
                if
                    let id = row.metadata.adGroupId,
                    let campaignId = row.metadata.campaignId,
                    let name = row.metadata.adGroupName,
                    let spend = Float(row.total.localSpend.amount),
                    let bid = Float(row.metadata.defaultBidAmount?.amount ?? "0"),
                    let status = row.metadata.adGroupStatus // Need also campaign status!
                {
                    return AdGroupsViewItem(
                        id: "\(id)",
                        campaignId: campaignId,
                        name: name,
                        installs: row.total.totalInstalls,
                        spend: spend,
                        bid: bid,
                        currency: row.total.localSpend.currency,
                        status: status,
                        campaignStatus: self.campaingsReport?.row.first(where: { $0.metadata.campaignId == row.metadata.campaignId })?.metadata.campaignStatus
                    )
                } else {
                    return nil
                }
            } ?? [AdGroupsViewItem]()
        return adGroups
    }
    
    func delete(adGroups: [AdGroupsViewItem]) async throws {
        await withTaskGroup(of: Void.self) { tg in
            adGroups.forEach { group in
                tg.addTask {
                    if let id = Int64(group.id) {
                        try? await SearchAds.instance.deleteAdGroup(campaignId: group.campaignId, adGroupId: id)
                    }
                }
            }
        }
        updateReports()
    }
    
    
    func updateCampaignBudget(campaign: CampaignViewItem, amount: String) async {
        guard let id = Int64(campaign.id) else { return }
        let _ = try? await SearchAds.instance.updateCampaign(
            campaignId: id,
            update: UpdateCampaignRequest(
                campaign: CampaignUpdate(
                    dailyBudgetAmount: Money(
                        amount: amount,
                        currency: campaign.currency
                    )
                ),
                clearGeoTargetingOnCountryOrRegionChange: false))
        try? await updateCampaingsReport()
    }
}
